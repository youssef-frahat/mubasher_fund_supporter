import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/app_config/app_colors.dart';
import '../../../../core/services/biometric_service.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../cubit/auth_cubit.dart';

class BiometricLockScreen extends StatefulWidget {
  const BiometricLockScreen({super.key});

  @override
  State<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends State<BiometricLockScreen> {
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerBiometricAuth();
    });
  }

  Future<void> _triggerBiometricAuth() async {
    if (_isAuthenticating) return;
    setState(() => _isAuthenticating = true);

    try {
      final authenticated = await BiometricService.authenticateUser(
        context,
        localizedReason: 'يرجى استخدام البصمة لفتح تطبيق وثيقة وتأمين حسابك 🔒',
      );

      if (authenticated && mounted) {
        AppSnackBar.showSuccess(context, 'تم التحقق من البصمة بنجاح! 🔓');
        context.go(Routes.home);
      }
    } finally {
      if (mounted) {
        setState(() => _isAuthenticating = false);
      }
    }
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
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Lock Icon Emblem with Glow Ring
                Container(
                  width: 110.r,
                  height: 110.r,
                  padding: EdgeInsets.all(20.r),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.12),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 30,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Center(
                    child: FaIcon(
                      FontAwesomeIcons.fingerprint,
                      color: AppColors.primary,
                      size: 54.r,
                    ),
                  ),
                ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                 .scale(duration: 1500.ms, begin: const Offset(0.95, 0.95), end: const Offset(1.05, 1.05)),
                SizedBox(height: 24.h),

                Text(
                  'تطبيق وثيقة محمّي ببصمتك 🔒',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fadeIn(delay: 200.ms),
                SizedBox(height: 8.h),

                Text(
                  'يرجى تأكيد البصمة لفتح المحفظة وتأمين حسابك الاستثماري',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 12.sp,
                  ),
                ).animate().fadeIn(delay: 300.ms),
                SizedBox(height: 36.h),

                // Unlock App Button
                Container(
                  padding: EdgeInsets.all(20.r),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: border),
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isAuthenticating ? null : _triggerBiometricAuth,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                          ),
                          icon: const FaIcon(FontAwesomeIcons.fingerprint, color: Colors.black, size: 18),
                          label: Text(
                            _isAuthenticating ? 'جاري التحقق...' : 'فتح التطبيق بالبصمة 👆',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 14.h),

                      // Password Sign In Option
                      OutlinedButton.icon(
                        onPressed: () {
                          context.read<AuthCubit>().signOut();
                          context.go(Routes.login);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          side: BorderSide(color: border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                        icon: Icon(Icons.lock_outline, color: textSecondary, size: 18.r),
                        label: Text(
                          'الدخول باستخدام البريد وكلمة المرور 🔑',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
