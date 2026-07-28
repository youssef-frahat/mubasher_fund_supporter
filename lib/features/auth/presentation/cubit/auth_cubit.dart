import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart' as google_auth;
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../../../../core/supabase/supabase_service.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial()) {
    _checkAuthStatus();
  }

  void _checkAuthStatus() {
    final client = SupabaseService.client;
    if (client == null) {
      emit(Unauthenticated());
      return;
    }
    
    final session = client.auth.currentSession;
    if (session?.user != null) {
      _syncUserProfileToSupabase(session!.user);
      emit(Authenticated(session.user));
    } else {
      emit(Unauthenticated());
    }

    client.auth.onAuthStateChange.listen((data) {
      if (data.session != null) {
        _syncUserProfileToSupabase(data.session!.user);
        emit(Authenticated(data.session!.user));
      } else {
        emit(Unauthenticated());
      }
    });
  }

  Future<void> _syncUserProfileToSupabase(User user) async {
    final client = SupabaseService.client;
    if (client == null) return;
    try {
      final name = user.userMetadata?['full_name'] ??
          user.userMetadata?['name'] ??
          user.email?.split('@').first ??
          'مستثمر وثيقة';
      final phone = user.userMetadata?['phone'] ?? user.phone ?? user.email;
      final avatarUrl = user.userMetadata?['avatar_url'];
      final isVerified = user.emailConfirmedAt != null || user.appMetadata['provider'] == 'google';

      await client.from('profiles').upsert({
        'id': user.id,
        'full_name': name,
        'phone': phone,
        'avatar_url': avatarUrl,
        'is_verified': isVerified,
        'updated_at': DateTime.now().toIso8601String(),
      });
      debugPrint('✅ User profile auto-synced to Supabase: ${user.id} ($name)');
    } catch (e) {
      debugPrint('⚠️ User profile auto-sync notice: $e');
    }
  }

  // --- Email Registration ---
  Future<void> signUpWithEmail(String email, String password, String fullName) async {
    emit(AuthLoading());
    try {
      final client = SupabaseService.client;
      if (client == null) throw Exception('Supabase not initialized');

      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );

      if (response.session != null && response.user != null) {
        await _syncUserProfileToSupabase(response.user!);
        emit(Authenticated(response.user!));
      } else if (response.user != null) {
        emit(OtpSent(email));
      }
    } catch (e) {
      emit(AuthError('فشل إنشاء الحساب: $e'));
      emit(Unauthenticated());
    }
  }

  // --- Email & Password Sign In ---
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    emit(AuthLoading());
    try {
      final client = SupabaseService.client;
      if (client == null) throw Exception('Supabase not initialized');

      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        emit(Authenticated(response.user!));
      } else {
        emit(AuthError('يرجى التحقق من البريد الإلكتروني وكلمة المرور'));
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(AuthError('خطأ في تسجيل الدخول: بيانات الدخول غير صحيحة أو الحساب غير مفعل بعد'));
      emit(Unauthenticated());
    }
  }

  // --- Google Auth ---
  Future<void> signInWithGoogle() async {
    emit(AuthLoading());
    try {
      const webClientId = '839907844431-hm1sj5q6sep7vi6bhii0v006d4rr2ci2.apps.googleusercontent.com'; 
      final googleSignIn = google_auth.GoogleSignIn(
        serverClientId: webClientId,
      );
      final googleUser = await googleSignIn.signIn();
      final googleAuth = await googleUser?.authentication;
      final accessToken = googleAuth?.accessToken;
      final idToken = googleAuth?.idToken;

      if (accessToken == null || idToken == null) {
        throw Exception('Google Auth Failed: Tokens are null.');
      }

      final client = SupabaseService.client;
      await client!.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
    } catch (e) {
      emit(AuthError('Google Sign-In failed: $e'));
      emit(Unauthenticated());
    }
  }

  // --- Password Reset ---
  Future<void> resetPassword(String email) async {
    emit(AuthLoading());
    try {
      final client = SupabaseService.client;
      if (client == null) throw Exception('Supabase not initialized');
      
      await client.auth.resetPasswordForEmail(email);
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError('Failed to send reset email: $e'));
      emit(Unauthenticated());
    }
  }

  Future<void> signOut() async {
    emit(AuthLoading());
    final client = SupabaseService.client;
    if (client != null) {
      await client.auth.signOut();
    }
  }

  // --- Profile Update & Avatar Upload ---
  Future<bool> updateProfile({
    required String fullName,
    String? phone,
    dynamic avatarFile,
  }) async {
    final client = SupabaseService.client;
    if (client == null) return false;

    final user = client.auth.currentUser;
    if (user == null) return false;

    try {
      String? avatarUrl = user.userMetadata?['avatar_url'];

      if (avatarFile != null) {
        final filePath = 'avatars/${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final fileBytes = await avatarFile.readAsBytes();
        
        await client.storage.from('avatars').uploadBinary(
              filePath,
              fileBytes,
              fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
            );

        avatarUrl = client.storage.from('avatars').getPublicUrl(filePath);
      }

      final updatedMetadata = Map<String, dynamic>.from(user.userMetadata ?? {});
      updatedMetadata['full_name'] = fullName;
      if (phone != null) updatedMetadata['phone'] = phone;
      if (avatarUrl != null) updatedMetadata['avatar_url'] = avatarUrl;

      await client.auth.updateUser(
        UserAttributes(data: updatedMetadata),
      );

      // Upsert into profiles table
      await client.from('profiles').upsert({
        'id': user.id,
        'full_name': fullName,
        'phone': phone,
        'avatar_url': avatarUrl,
        'updated_at': DateTime.now().toIso8601String(),
      });

      final refreshedUser = client.auth.currentUser;
      if (refreshedUser != null) {
        emit(Authenticated(refreshedUser));
      }
      return true;
    } catch (e) {
      debugPrint('Profile update error: $e');
      return false;
    }
  }
}
