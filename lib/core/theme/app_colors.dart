import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Hijau
  static const primary = Color(0xFF0E4A34);      // hijau tua
  static const primaryMid = Color(0xFF2D6A4F);   // hijau sedang, untuk gradient
  static const primaryLight = Color(0xFFE1F5EE); // tint hijau muda

  // Accent — emas
  static const accent = Color(0xFFD69E2E);
  static const accentLight = Color(0xFFECC94B);

  // Warna netral (abu/putih) 
  static const bg = Color(0xFFF7F8F5); 
  static const card = Color(0xFFFFFFFF);    
  static const border = Color(0xFFE5E4DE); 

  static const text = Color(0xFF1A1D1B);         // textPrimaryColor
  static const textMid = Color(0xFF5F5E5A);      // textSecondaryColor
  static const textSub = Color(0xFF76756B);      // antara textMid & textMuted
  static const textMuted = Color(0xFF888780);    // textMutedColor

  // Status 
  static const present = Color(0xFF3B6D11);      // successColor
  static const presentMid = Color(0xFF5B8F2A);
  static const presentBg = Color(0xFFE1F5EE);    // moduleBgTeal

  static const pending = Color(0xFF712B13);      // moduleIconCoral
  static const pendingBg = Color(0xFFFAECE7);    // moduleBgCoral

  static const rejected = Color(0xFFD85A30);     // dangerDotColor
  static const rejectedBg = Color(0xFFFCEAE3);   // tint dari rejected

  static const neutral = Color(0xFF888780);      // inactiveNavColor
  static const neutralBg = Color(0xFFEDEDE7);

  static const bannerAccent = Color(0xFFB7E4C7);

  static const modulePurpleBg = Color(0xFFEEEDFE);
  static const modulePurpleIcon = Color(0xFF3C3489);
  static const moduleTealBg = Color(0xFFE1F5EE);
  static const moduleTealIcon = Color(0xFF085041);
  static const moduleCoralBg = Color(0xFFFAECE7);
  static const moduleCoralIcon = Color(0xFF712B13);
  static const moduleBlueBg = Color(0xFFE6F1FB);
  static const moduleBlueIcon = Color(0xFF0C447C);

  // Hero tetap hijau (sama dengan primary)
  static const heroGreen = Color(0xFF0E4A34);
  static const heroGreenMid = Color(0xFF2D6A4F);

  /// Gradient hijau utama — selaras dengan heroGradient
  static const primaryGradient = LinearGradient(
    begin: Alignment(-0.6, -1),
    end: Alignment(0.6, 1),
    colors: [primary, primaryMid],
  );

  /// Gradient hijau hero card
  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [heroGreen, heroGreenMid],
  );
}