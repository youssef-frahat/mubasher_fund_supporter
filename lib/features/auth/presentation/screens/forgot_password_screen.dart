import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../../../../core/app_config/app_colors.dart';
import '../../../../core/language/language_cubit.dart';
import '../../../../core/widgets/app_snackbar.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = AppColors.getBackground(context);
    final textPrimary = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          context.tr('resetPasswordTitle'),
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 16.sp),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            AppSnackBar.showError(context, state.message);
          } else if (state is Unauthenticated) {
            AppSnackBar.showSuccess(context, context.tr('resetEmailSent'));
            context.pop();
          }
        },
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 20.h),
              Icon(Icons.lock_reset, size: 80.sp, color: AppColors.primary),
              SizedBox(height: 24.h),
              Text(
                context.tr('resetPasswordTitle'),
                style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 20.sp),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              Text(
                context.tr('resetPasswordSub'),
                style: TextStyle(color: textSecondary, fontSize: 12.sp),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 36.h),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: textPrimary),
                decoration: InputDecoration(
                  labelText: context.tr('email'),
                  prefixIcon: Icon(Icons.email_outlined, color: textSecondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              BlocBuilder<AuthCubit, AuthState>(
                builder: (context, state) {
                  final isLoading = state is AuthLoading;
                  return ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            final email = _emailController.text.trim();
                            final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                            if (email.isEmpty) {
                              AppSnackBar.showWarning(context, context.tr('enterEmailErr'));
                            } else if (!emailRegex.hasMatch(email)) {
                              AppSnackBar.showWarning(context, context.tr('invalidEmailErr'));
                            } else {
                              context.read<AuthCubit>().resetPassword(email);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      backgroundColor: AppColors.primary,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                          )
                        : Text(
                            context.tr('sendResetLink'),
                            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14.sp),
                          ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
