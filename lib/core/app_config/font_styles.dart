import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FontStyles {
  static TextStyle get headlineSmall => TextStyle(
        fontSize: 24.sp,
        fontWeight: FontWeight.w700,
      );

  static TextStyle get titleLarge => TextStyle(
        fontSize: 22.sp,
        fontWeight: FontWeight.w700,
      );

  static TextStyle get titleMedium => TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.w700,
      );

  static TextStyle get bodyMedium => TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get bodySmall => TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.w400,
      );
}
