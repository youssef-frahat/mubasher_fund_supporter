import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/app_config/app_colors.dart';
import '../../../../core/widgets/social_login_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/language/language_cubit.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordObscured = true;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
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
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
            child: BlocConsumer<AuthCubit, AuthState>(
              listener: (context, state) {
                if (state is Authenticated) {
                  AppSnackBar.showSuccess(context, 'أهلاً بك! تم إنشاء الحساب وتأمين دخولك بنجاح 🚀');
                  context.go(Routes.home);
                } else if (state is OtpSent) {
                  _showEmailConfirmationDialog(context, state.email);
                } else if (state is AuthError) {
                  AppSnackBar.showError(context, state.message);
                }
              },
              builder: (context, state) {
                final isLoading = state is AuthLoading;

                return Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: CircleAvatar(
                          radius: 38.r,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                          child: FaIcon(
                            FontAwesomeIcons.userPlus,
                            color: AppColors.primary,
                            size: 32.r,
                          ),
                        ),
                      ).animate().scale(delay: 150.ms, duration: 400.ms, curve: Curves.easeOutBack),
                      SizedBox(height: 18.h),

                      Text(
                        context.tr('createAccountTitle'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 24.sp,
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

                      Container(
                        padding: EdgeInsets.all(20.r),
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(color: border),
                        ),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _nameController,
                              style: TextStyle(color: textPrimary),
                              decoration: InputDecoration(
                                labelText: context.tr('fullName'),
                                labelStyle: TextStyle(color: textSecondary),
                                prefixIcon: Icon(Icons.person_outline, color: textSecondary),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                              ),
                              validator: (val) {
                                final trimmed = val?.trim() ?? '';
                                if (trimmed.isEmpty) return context.tr('enterNameErr');
                                if (trimmed.length < 3) return context.tr('nameMinLengthErr');
                                if (RegExp(r'^[0-9!@#\$%^&*()_+=\-\[\]{};:"\\|,.<>/?]+$').hasMatch(trimmed)) {
                                  return context.tr('nameInvalidErr');
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 14.h),

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
                              validator: (val) {
                                final trimmed = val?.trim() ?? '';
                                final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                                if (trimmed.isEmpty) return context.tr('enterEmailErr');
                                if (!emailRegex.hasMatch(trimmed)) return context.tr('invalidEmailErr');
                                return null;
                              },
                            ),
                            SizedBox(height: 14.h),

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
                              validator: (val) {
                                final trimmed = val ?? '';
                                if (trimmed.isEmpty) return context.tr('enterPassErr');
                                if (trimmed.length < 8) return context.tr('passMinLengthErr');
                                final hasLetter = RegExp(r'[a-zA-Zآ-ي]').hasMatch(trimmed);
                                final hasDigit = RegExp(r'[0-9]').hasMatch(trimmed);
                                if (!hasLetter || !hasDigit) return context.tr('passComplexityErr');
                                return null;
                              },
                            ),
                            SizedBox(height: 14.h),

                            Row(
                              children: [
                                Checkbox(
                                  value: _acceptedTerms,
                                  activeColor: AppColors.primary,
                                  onChanged: (val) => setState(() => _acceptedTerms = val ?? false),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => context.push(Routes.termsConditions),
                                    child: RichText(
                                      text: TextSpan(
                                        style: TextStyle(color: textSecondary, fontSize: 11.sp),
                                        children: [
                                          TextSpan(text: context.tr('agreeToTermsPrefix')),
                                          TextSpan(
                                            text: context.tr('termsAndPrivacy'),
                                            style: TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.bold,
                                              decoration: TextDecoration.underline,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),
                      SizedBox(height: 20.h),

                      ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                if (!_acceptedTerms) {
                                  AppSnackBar.showWarning(context, context.tr('agreeTermsErr'));
                                  return;
                                }
                                if (_formKey.currentState!.validate()) {
                                  final name = _nameController.text.trim();
                                  final email = _emailController.text.trim();
                                  final password = _passwordController.text.trim();
                                  context.read<AuthCubit>().signUpWithEmail(email, password, name);
                                } else {
                                  AppSnackBar.showWarning(context, context.tr('invalidLoginFormNotice'));
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
                                context.tr('register'),
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      SizedBox(height: 20.h),

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

                      SocialLoginButton(
                        label: context.tr('continueWithGoogle'),
                        isLoading: isLoading,
                        onPressed: () {
                          context.read<AuthCubit>().signInWithGoogle();
                        },
                      ),
                      SizedBox(height: 24.h),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            context.tr('alreadyHaveAccount'),
                            style: TextStyle(color: textSecondary, fontSize: 13.sp),
                          ),
                          GestureDetector(
                            onTap: () => context.pop(),
                            child: Text(
                              context.tr('login'),
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

  void _showEmailConfirmationDialog(BuildContext context, String email) {
    final surface = AppColors.getSurface(context);
    final textPrimary = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70.r,
                height: 70.r,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: FaIcon(
                    FontAwesomeIcons.paperPlane,
                    color: AppColors.primary,
                    size: 32.r,
                  ),
                ),
              ),
              SizedBox(height: 16.h),

              Text(
                'تم إرسال رابط تأكيد الحساب 📩',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10.h),

              Text(
                'تم إرسال رابط تفعيل الحساب إلى البريد الإلكتروني:\n$email\n\nيرجى فتح البريد الضغط على زر التفعيل لتأكيد وثيقة حسابك وتوثيقه بشارة (موثّق 🟢).',
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 12.sp,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20.h),

              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go(Routes.login);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                icon: const Icon(Icons.login, color: Colors.black),
                label: const Text(
                  'الانتقال لتسجيل الدخول 🚀',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
