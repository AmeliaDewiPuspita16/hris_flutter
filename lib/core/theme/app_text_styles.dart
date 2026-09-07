import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Kumpulan TextStyle 
class AppTextStyles {
  AppTextStyles._();

  static const fontFamily = 'Poppins';

  static const h1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 26,
    fontWeight: FontWeight.w800,
    color: Colors.white,
    height: 1.2,
  );

  static const h2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: AppColors.text,
  );

  static const h3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w800,
    color: Colors.white,
  );

  static const sectionTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
  );

  static const label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textSub,
  );

  static const body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    color: AppColors.text,
  );

  static const bodyMuted = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    color: AppColors.textMuted,
    height: 1.6,
  );

  static const caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    color: AppColors.textMuted,
  );

  static const buttonText = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );
}
