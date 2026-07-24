import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/app_config/app_colors.dart';
import '../../../../core/app_config/font_styles.dart';
import '../../../../core/widgets/animated_glass_card.dart';
import '../../../../core/widgets/social_login_button.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: BlocConsumer<AuthCubit, AuthState>(
                listener: (context, state) {
                  if (state is Authenticated) {
                    context.go(Routes.home);
                  } else if (state is OtpSent) {
                    context.push(Routes.otp, extra: state.email);
                  } else if (state is AuthError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
                    );
                  }
                },
                builder: (context, state) {
                  final isLoading = state is AuthLoading;

                  return AnimatedGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(Icons.lock_outline, size: 60.sp, color: Colors.white)
                            .animate().scale(delay: 200.ms, duration: 400.ms, curve: Curves.easeOutBack),
                        SizedBox(height: 16.h),
                        Text(
                          'Welcome Back',
                          textAlign: TextAlign.center,
                          style: FontStyles.displayLarge.copyWith(color: Colors.white),
                        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
                        SizedBox(height: 8.h),
                        Text(
                          'Securely login to your portfolio',
                          textAlign: TextAlign.center,
                          style: FontStyles.bodyLarge.copyWith(color: Colors.white70),
                        ).animate().fadeIn(delay: 400.ms),
                        SizedBox(height: 32.h),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Enter your email',
                            hintStyle: const TextStyle(color: Colors.white70),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: const Icon(Icons.email_outlined, color: Colors.white70),
                          ),
                        ).animate().fadeIn(delay: 500.ms),
                        SizedBox(height: 12.h),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => context.push(Routes.forgotPassword),
                            child: Text(
                              'Forgot Password?',
                              style: FontStyles.bodySmall.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 24.h),
                        ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () {
                                  final email = _emailController.text.trim();
                                  if (email.isNotEmpty) {
                                    context.read<AuthCubit>().sendOtp(email);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            backgroundColor: Theme.of(context).colorScheme.primary,
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Text(
                                  'Continue with Email',
                                  style: FontStyles.labelLarge.copyWith(color: Colors.white),
                                ),
                        ),
                        SizedBox(height: 24.h),
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              child: Text('OR', style: FontStyles.bodySmall.copyWith(color: Colors.grey)),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        SizedBox(height: 24.h),
                        SocialLoginButton(
                          label: 'Continue with Google',
                          iconWidget: Text(
                            'G',
                            style: TextStyle(
                              fontSize: 28.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFDB4437), // Google Red
                            ),
                          ),
                          isLoading: isLoading,
                          onPressed: () {
                            context.read<AuthCubit>().signInWithGoogle();
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
