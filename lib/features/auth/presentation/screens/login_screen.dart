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
                        SizedBox(height: 24.h),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primary,
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                          ),
                          onPressed: isLoading ? null : () {
                            if (_emailController.text.isNotEmpty) {
                              context.read<AuthCubit>().sendOtp(_emailController.text.trim());
                            }
                          },
                          child: isLoading 
                              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator())
                              : Text('Continue with Email', style: FontStyles.titleMedium.copyWith(color: AppColors.primary)),
                        ).animate().fadeIn(delay: 600.ms),
                        SizedBox(height: 24.h),
                        Row(
                          children: [
                            Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.3))),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              child: Text('OR', style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
                            ),
                            Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.3))),
                          ],
                        ).animate().fadeIn(delay: 700.ms),
                        SizedBox(height: 24.h),
                        SocialLoginButton(
                          label: 'Continue with Google',
                          icon: Icons.g_mobiledata, // Placeholder for Google Icon
                          iconColor: Colors.red,
                          isLoading: isLoading,
                          onPressed: () => context.read<AuthCubit>().signInWithGoogle(),
                        ),
                        SizedBox(height: 12.h),
                        SocialLoginButton(
                          label: 'Continue with Apple',
                          icon: Icons.apple,
                          iconColor: Colors.black,
                          isLoading: isLoading,
                          onPressed: () => context.read<AuthCubit>().signInWithApple(),
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
