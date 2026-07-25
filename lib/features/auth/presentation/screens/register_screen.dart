import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/app_config/app_colors.dart';
import '../../../../core/widgets/social_login_button.dart';
import '../../../../core/services/avatar_picker_service.dart';
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
  bool _acceptedTerms = true;
  File? _avatarFile;

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
                      // Header Avatar Picker (Optional)
                      Center(
                        child: GestureDetector(
                          onTap: () async {
                            final file = await AvatarPickerService.pickAndCropAvatar(context);
                            if (file != null && mounted) {
                              setState(() => _avatarFile = file);
                            }
                          },
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 42.r,
                                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                                backgroundImage: _avatarFile != null ? FileImage(_avatarFile!) : null,
                                child: _avatarFile == null
                                    ? FaIcon(FontAwesomeIcons.userPlus, color: AppColors.primary, size: 30.r)
                                    : null,
                              ),
                              CircleAvatar(
                                radius: 14.r,
                                backgroundColor: AppColors.primary,
                                child: const Icon(Icons.camera_alt, color: Colors.black, size: 14),
                              ),
                            ],
                          ),
                        ),
                      ).animate().scale(delay: 150.ms, duration: 400.ms, curve: Curves.easeOutBack),
                      SizedBox(height: 8.h),
                      Text(
                        _avatarFile == null ? 'إضافة صورة شخصية (اختياري 📸)' : 'تم اختيار الصورة وتعشيبها بنجاح ✨',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _avatarFile == null ? textSecondary : AppColors.primary,
                          fontSize: 11.sp,
                          fontWeight: _avatarFile == null ? FontWeight.normal : FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12.h),

                      Text(
                        'إنشاء حساب جديد',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ).animate().fadeIn(delay: 250.ms),
                      SizedBox(height: 6.h),

                      Text(
                        'انضم إلى مباشر للخدمات والاستشارات المالية الذكية',
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
                            // Full Name Input
                            TextFormField(
                              controller: _nameController,
                              style: TextStyle(color: textPrimary),
                              decoration: InputDecoration(
                                labelText: 'الاسم بالكامل',
                                labelStyle: TextStyle(color: textSecondary),
                                prefixIcon: Icon(Icons.person_outline, color: textSecondary),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                              ),
                              validator: (val) => val == null || val.isEmpty ? 'يرجى إدخال الاسم' : null,
                            ),
                            SizedBox(height: 14.h),

                            // Email Input
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: TextStyle(color: textPrimary),
                              decoration: InputDecoration(
                                labelText: 'البريد الإلكتروني',
                                labelStyle: TextStyle(color: textSecondary),
                                prefixIcon: Icon(Icons.email_outlined, color: textSecondary),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                              ),
                              validator: (val) => val == null || !val.contains('@') ? 'بريد إلكتروني غير صحيح' : null,
                            ),
                            SizedBox(height: 14.h),

                            // Password Input
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _isPasswordObscured,
                              style: TextStyle(color: textPrimary),
                              decoration: InputDecoration(
                                labelText: 'كلمة المرور',
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
                              validator: (val) => (val?.length ?? 0) < 6 ? 'كلمة المرور 6 أحرف على الأقل' : null,
                            ),
                            SizedBox(height: 14.h),

                            // Terms & Conditions Checkbox
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
                                          const TextSpan(text: 'أوافق على '),
                                          TextSpan(
                                            text: 'الشروط والأحكام وسياسة الخصوصية',
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

                      // Submit Register Button
                      ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                if (!_acceptedTerms) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('يرجى الموافقة على الشروط والأحكام للمتابعة'),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                  return;
                                }
                                if (_formKey.currentState!.validate()) {
                                  context.read<AuthCubit>().signUpWithEmail(
                                        _emailController.text.trim(),
                                        _passwordController.text,
                                        _nameController.text.trim(),
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
                                'تسجيل حساب جديد',
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

                      // Google Sign Up Button
                      SocialLoginButton(
                        label: 'التسجيل باستخدام Google',
                        isLoading: isLoading,
                        onPressed: () {
                          context.read<AuthCubit>().signInWithGoogle();
                        },
                      ),
                      SizedBox(height: 24.h),

                      // Already have account login link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'لديك حساب بالفعل؟ ',
                            style: TextStyle(color: textSecondary, fontSize: 13.sp),
                          ),
                          GestureDetector(
                            onTap: () => context.pop(),
                            child: Text(
                              'تسجيل الدخول',
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
