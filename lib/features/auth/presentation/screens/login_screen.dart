import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/app_config/app_colors.dart';
import '../../../../core/widgets/social_login_button.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../../../../core/language/language_cubit.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordObscured = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = AppColors.getBackground(context);
    final surface = AppColors.getSurface(context);
    final textPrimary = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);
    final border = AppColors.getBorder(context);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
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

                return Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Brand Logo Header
                      Center(
                        child: CircleAvatar(
                          radius: 40.r,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                          child: FaIcon(
                            FontAwesomeIcons.vault,
                            color: AppColors.primary,
                            size: 36.r,
                          ),
                        ),
                      ).animate().scale(delay: 150.ms, duration: 400.ms, curve: Curves.easeOutBack),
                      SizedBox(height: 18.h),

                      Text(
                        'مرحباً بك مجدداً',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 26.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1, end: 0),
                      SizedBox(height: 6.h),

                      Text(
                        context.tr('appSubtitle'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 12.sp,
                        ),
                      ).animate().fadeIn(delay: 350.ms),
                      SizedBox(height: 28.h),

                      // Input Box Container
                      Container(
                        padding: EdgeInsets.all(20.r),
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(color: border),
                        ),
                        child: Column(
                          children: [
                            // Email Input Field
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: TextStyle(color: textPrimary),
                              decoration: InputDecoration(
                                labelText: context.tr('email'),
                                labelStyle: TextStyle(color: textSecondary),
                                prefixIcon: Icon(Icons.email_outlined, color: textSecondary),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                              ),
                              validator: (val) => val == null || !val.contains('@') ? 'بريد إلكتروني غير صحيح' : null,
                            ),
                            SizedBox(height: 14.h),

                            // Password Input Field
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _isPasswordObscured,
                              style: TextStyle(color: textPrimary),
                              decoration: InputDecoration(
                                labelText: context.tr('password'),
                                labelStyle: TextStyle(color: textSecondary),
                                prefixIcon: Icon(Icons.lock_outline, color: textSecondary),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordObscured ? Icons.visibility_off : Icons.visibility,
                                    color: textSecondary,
                                  ),
                                  onPressed: () {
                                    setState(() => _isPasswordObscured = !_isPasswordObscured);
                                  },
                                ),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                              ),
                            ),
                            SizedBox(height: 8.h),

                            // Forgot Password Link
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                onPressed: () => context.push(Routes.forgotPassword),
                                child: Text(
                                  context.tr('forgotPassword'),
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),
                      SizedBox(height: 20.h),

                      // Main Login Button
                      ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                final email = _emailController.text.trim();
                                if (email.isNotEmpty) {
                                  context.read<AuthCubit>().sendOtp(email);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('يرجى كتابة البريد الإلكتروني')),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                        child: isLoading
                            ? SizedBox(
                                width: 20.r,
                                height: 20.r,
                                child: const CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                              )
                            : Text(
                                context.tr('login'),
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      SizedBox(height: 20.h),

                      // Divider OR
                      Row(
                        children: [
                          Expanded(child: Divider(color: border)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12.w),
                            child: Text('أو', style: TextStyle(color: textSecondary, fontSize: 12.sp)),
                          ),
                          Expanded(child: Divider(color: border)),
                        ],
                      ),
                      SizedBox(height: 20.h),

                      // Pure White Google Sign In Button with Multi-Colored Logo & Blue Ripple
                      SocialLoginButton(
                        label: 'متابعة باستخدام Google',
                        isLoading: isLoading,
                        onPressed: () {
                          context.read<AuthCubit>().signInWithGoogle();
                        },
                      ),
                      SizedBox(height: 26.h),

                      // Register Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'ليس لديك حساب حتى الآن؟ ',
                            style: TextStyle(color: textSecondary, fontSize: 13.sp),
                          ),
                          GestureDetector(
                            onTap: () => context.push(Routes.register),
                            child: Text(
                              context.tr('register'),
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
