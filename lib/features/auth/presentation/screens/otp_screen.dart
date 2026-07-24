import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/app_config/app_colors.dart';
import '../../../../core/app_config/font_styles.dart';
import '../../../../core/widgets/animated_glass_card.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class OtpScreen extends StatefulWidget {
  final String email;
  const OtpScreen({super.key, required this.email});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: BlocConsumer<AuthCubit, AuthState>(
                      listener: (context, state) {
                        if (state is Authenticated) {
                          context.go(Routes.home);
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
                              Icon(Icons.mark_email_read_outlined, size: 60.sp, color: Colors.white)
                                  .animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                              SizedBox(height: 16.h),
                              Text(
                                'Check Your Email',
                                textAlign: TextAlign.center,
                                style: FontStyles.displayLarge.copyWith(color: Colors.white),
                              ).animate().fadeIn(delay: 100.ms),
                              SizedBox(height: 8.h),
                              Text(
                                'We sent a verification code to ${widget.email}',
                                textAlign: TextAlign.center,
                                style: FontStyles.bodyLarge.copyWith(color: Colors.white70),
                              ).animate().fadeIn(delay: 200.ms),
                              SizedBox(height: 32.h),
                              TextField(
                                controller: _otpController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white, fontSize: 24.sp, letterSpacing: 8.0),
                                decoration: InputDecoration(
                                  hintText: '000000',
                                  hintStyle: const TextStyle(color: Colors.white70),
                                  filled: true,
                                  fillColor: Colors.white.withValues(alpha: 0.1),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ).animate().fadeIn(delay: 300.ms),
                              SizedBox(height: 24.h),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppColors.primary,
                                  padding: EdgeInsets.symmetric(vertical: 16.h),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                                ),
                                onPressed: isLoading ? null : () {
                                  if (_otpController.text.isNotEmpty) {
                                    context.read<AuthCubit>().verifyOtp(widget.email, _otpController.text.trim());
                                  }
                                },
                                child: isLoading 
                                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator())
                                    : Text('Verify Code', style: FontStyles.titleMedium.copyWith(color: AppColors.primary)),
                              ).animate().fadeIn(delay: 400.ms),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
