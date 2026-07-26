import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/app_config/app_colors.dart';
import '../../../../core/app_config/font_styles.dart';
import '../../../../core/widgets/animated_glass_card.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/language/language_cubit.dart';
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
  int _secondsRemaining = 60;
  Timer? _timer;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    setState(() {
      _secondsRemaining = 60;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        if (mounted) setState(() => _secondsRemaining--);
      } else {
        _timer?.cancel();
        if (mounted) setState(() => _canResend = true);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _resendCode() {
    if (!_canResend) return;
    context.read<AuthCubit>().sendOtp(widget.email);
    AppSnackBar.showInfo(
      context,
      'تمت إعادة إرسال رمز التحقق بنجاح لبريدك الإلكتروني 📩',
    );
    _startTimer();
  }

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
                          AppSnackBar.showSuccess(
                            context,
                            'تم تأكيد رمز التحقق بنجاح! مرحباً بك 🚀',
                          );
                          context.go(Routes.home);
                        } else if (state is AuthError) {
                          AppSnackBar.showError(context, state.message);
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
                                context.tr('otpTitle'),
                                textAlign: TextAlign.center,
                                style: FontStyles.displayLarge.copyWith(color: Colors.white, fontSize: 20.sp),
                              ).animate().fadeIn(delay: 100.ms),
                              SizedBox(height: 8.h),
                              Text(
                                '${context.tr('otpSubtitle')} ${widget.email}',
                                textAlign: TextAlign.center,
                                style: FontStyles.bodyLarge.copyWith(color: Colors.white70, fontSize: 12.sp),
                              ).animate().fadeIn(delay: 200.ms),
                              SizedBox(height: 28.h),

                              // Digit Only Formatter Protected Input
                              TextField(
                                controller: _otpController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(6),
                                ],
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white, fontSize: 24.sp, letterSpacing: 8.0, fontWeight: FontWeight.bold),
                                decoration: InputDecoration(
                                  hintText: '000000',
                                  hintStyle: const TextStyle(color: Colors.white38),
                                  filled: true,
                                  fillColor: Colors.white.withValues(alpha: 0.12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ).animate().fadeIn(delay: 300.ms),
                              SizedBox(height: 20.h),

                              // Countdown Resend Timer
                              Center(
                                child: _canResend
                                    ? TextButton.icon(
                                        onPressed: _resendCode,
                                        icon: const Icon(Icons.refresh, color: Colors.white),
                                        label: Text(
                                          context.tr('resendOtpCode'),
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                      )
                                    : Text(
                                        '${context.tr('resendInSeconds')} $_secondsRemaining ${context.tr('seconds')}',
                                        style: TextStyle(color: Colors.white70, fontSize: 12.sp),
                                      ),
                              ),
                              SizedBox(height: 20.h),

                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppColors.primary,
                                  padding: EdgeInsets.symmetric(vertical: 14.h),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                                ),
                                onPressed: isLoading
                                    ? null
                                    : () {
                                        final code = _otpController.text.trim();
                                        if (code.length == 6) {
                                          context.read<AuthCubit>().verifyOtp(widget.email, code);
                                        } else {
                                          AppSnackBar.showWarning(
                                            context,
                                            'يرجى كتابة رمز التحقق المكون من 6 أرقام كاملة',
                                          );
                                        }
                                      },
                                child: isLoading
                                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
                                    : Text(
                                        context.tr('verifyOtpBtn'),
                                        style: FontStyles.titleMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                                      ),
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
