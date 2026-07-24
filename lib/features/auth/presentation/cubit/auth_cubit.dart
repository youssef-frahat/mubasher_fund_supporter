import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart' as google_auth;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
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

  // --- OTP Auth (Email) ---
  Future<void> sendOtp(String email) async {
    emit(AuthLoading());
    try {
      final client = SupabaseService.client;
      if (client == null) throw Exception('Supabase not initialized');
      
      await client.auth.signInWithOtp(email: email);
      emit(OtpSent(email)); // New state to transition to OTP screen
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
      // state changes automatically due to listener
    } catch (e) {
      emit(AuthError(e.toString()));
      emit(OtpSent(email));
    }
  }

  // --- Google Auth ---
  Future<void> signInWithGoogle() async {
    emit(AuthLoading());
    try {
      // TODO: Implement Google Sign In once Client IDs are configured
      await Future.delayed(const Duration(seconds: 1));
      throw Exception('Google Sign-In is not fully configured yet. Please configure Client IDs.');
    } catch (e) {
      emit(AuthError(e.toString()));
      emit(Unauthenticated());
    }
  }

  // --- Apple Auth ---
  Future<void> signInWithApple() async {
    emit(AuthLoading());
    try {
      // TODO: Implement Apple Sign In once Client IDs are configured
      await Future.delayed(const Duration(seconds: 1));
      throw Exception('Apple Sign-In is not fully configured yet. Please configure Apple Developer Account.');
    } catch (e) {
      emit(AuthError(e.toString()));
      emit(Unauthenticated());
    }
  }

  Future<void> signOut() async {
    final client = SupabaseService.client;
    if (client != null) {
      await client.auth.signOut();
    }
  }
}
