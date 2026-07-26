import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../app_config/app_colors.dart';

class WatheqaAnimatedTitle extends StatefulWidget {
  const WatheqaAnimatedTitle({super.key});

  @override
  State<WatheqaAnimatedTitle> createState() => _WatheqaAnimatedTitleState();
}

class _WatheqaAnimatedTitleState extends State<WatheqaAnimatedTitle> {
  final List<String> _words = ['وثيقة', 'Watheqa'];
  int _wordIndex = 0;
  int _charIndex = 0;
  bool _isDeleting = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _scheduleNextStep(const Duration(milliseconds: 200));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _scheduleNextStep(Duration duration) {
    _timer?.cancel();
    _timer = Timer(duration, _handleTypeStep);
  }

  void _handleTypeStep() {
    if (!mounted) return;

    final currentWord = _words[_wordIndex];

    if (!_isDeleting) {
      if (_charIndex < currentWord.length) {
        setState(() {
          _charIndex++;
        });
        _scheduleNextStep(const Duration(milliseconds: 160));
      } else {
        // Pause at full word for 2.2 seconds
        _isDeleting = true;
        _scheduleNextStep(const Duration(milliseconds: 2200));
      }
    } else {
      if (_charIndex > 0) {
        setState(() {
          _charIndex--;
        });
        _scheduleNextStep(const Duration(milliseconds: 90));
      } else {
        // Switch word and start typing
        _isDeleting = false;
        _wordIndex = (_wordIndex + 1) % _words.length;
        _scheduleNextStep(const Duration(milliseconds: 350));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppColors.getTextPrimary(context);
    final currentWord = _words[_wordIndex];
    final displayedText = currentWord.substring(0, _charIndex);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Typewriter Letter-by-Letter Animation ("وثيقة" ↔ "Watheqa")
        ConstrainedBox(
          constraints: BoxConstraints(minWidth: 80.w),
          child: Text(
            displayedText.isEmpty ? ' ' : displayedText,
            style: TextStyle(
              color: textPrimary,
              fontSize: 20.sp,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.w,
            ),
          )
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .shimmer(duration: 2200.ms, color: AppColors.primary),
        ),

        SizedBox(width: 4.w),

        // Glowing Pulsing Green Identity Dot
        Container(
          width: 6.r,
          height: 6.r,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
        )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scale(duration: 800.ms, begin: const Offset(0.5, 0.5), end: const Offset(1.3, 1.3)),
      ],
    );
  }
}
