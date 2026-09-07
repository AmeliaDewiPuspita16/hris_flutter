import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const primary = Color(0xFF1B4332);      // hijau tua
  static const primaryMid = Color(0xFF2D6A4F);   // hijau sedang
  static const primaryLight = Color(0xFFE6F2EC); // hijau sangat terang 

  // Accent kuning/emas
  static const accent = Color(0xFFD69E2E);
  static const accentLight = Color(0xFFECC94B);

  // Warna netral (abu/putih)
  static const bg = Color(0xFFF7FAFC);
  static const card = Color(0xFFFFFFFF);
  static const border = Color(0xFFE2E8F0);

  static const text = Color(0xFF1A202C);
  static const textMid = Color(0xFF2D3748);
  static const textSub = Color(0xFF4A5568);
  static const textMuted = Color(0xFF718096);

  // Status
  static const present = Color(0xFF276749);
  static const presentMid = Color(0xFF38A169);
  static const presentBg = Color(0xFFF0FFF4);

  static const pending = Color(0xFFDD6B20);
  static const pendingBg = Color(0xFFFFFAF0);

  static const rejected = Color(0xFFC53030);
  static const rejectedBg = Color(0xFFFFF5F5);

  static const neutral = Color(0xFF718096);
  static const neutralBg = Color(0xFFEDF2F7);

  // Hero tetap hijau (sama dengan primary)
  static const heroGreen = Color(0xFF1B4332);
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