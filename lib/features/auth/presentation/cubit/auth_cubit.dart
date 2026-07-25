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
    if (session != null && session.user != null) {
      emit(Authenticated(session.user!));
    } else {
      emit(Unauthenticated());
    }

    client.auth.onAuthStateChange.listen((data) {
      if (data.session != null && data.session!.user != null) {
        emit(Authenticated(data.session!.user!));
      } else {
        emit(Unauthenticated());
      }
    });
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

      if (response.user != null) {
        emit(OtpSent(email));
      }
    } catch (e) {
      emit(AuthError('فشل إنشاء الحساب: $e'));
      emit(Unauthenticated());
    }
  }

  // --- OTP Auth (Email) ---
  Future<void> sendOtp(String email) async {
    emit(AuthLoading());
    try {
      final client = SupabaseService.client;
      if (client == null) throw Exception('Supabase not initialized');
      
      await client.auth.signInWithOtp(email: email);
      emit(OtpSent(email));
    } catch (e) {
      emit(AuthError(e.toString()));
      emit(Unauthenticated());
    }
  }

  Future<void> verifyOtp(String email, String token) async {
    emit(AuthLoading());
    try {
      final client = SupabaseService.client;
      if (client == null) throw Exception('Supabase not initialized');
      
      await client.auth.verifyOTP(email: email, token: token, type: OtpType.magiclink);
    } catch (e) {
      emit(AuthError(e.toString()));
      emit(OtpSent(email));
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
}
