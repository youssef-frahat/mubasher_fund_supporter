import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthState {}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final User user;
  Authenticated(this.user);
}

class Unauthenticated extends AuthState {}

class OtpSent extends AuthState {
  final String email;
  OtpSent(this.email);
}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}
