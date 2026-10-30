import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Ilustrasi kawasan industri selebar layar di dasar halaman login.
///
/// Teks "Crafted with extra ❤️" dan copyright dipindah ke halaman About
/// (Profile → About this app).
///
/// Pemanggil TIDAK boleh memberi padding horizontal/bawah — ilustrasinya
/// dimaksudkan menempel ke tepi kiri, kanan, dan dasar layar.
class LoginFooter extends StatelessWidget {
  const LoginFooter({super.key});

  static const _illustration = 'assets/images/tps_industrial_campus.webp';
  static const _illustrationDark = 'assets/images/tps_industrial_campus_dark.webp';

  /// Batas tinggi ilustrasi supaya di layar pendek/tablet ia tidak
  /// mendorong form login ke luar layar. Lebih dari ini, gambarnya dipotong
  /// dari atas (langit), bukan dari bawah (bangunan).
  static const double _maxIllustrationHeight = 220;

  @override
  Widget build(BuildContext context) {
    // Tinggi dihitung dari lebar layar, bukan AspectRatio/LayoutBuilder:
    // AspectRatio yang dibatasi tinggi ikut menyempitkan lebarnya, dan
    // LayoutBuilder tidak boleh berada di dalam IntrinsicHeight halaman login.
    final width = MediaQuery.sizeOf(context).width;
    final height = math.min(
      width * 480 / 800, // rasio asli gambar
      _maxIllustrationHeight,
    );

    return SizedBox(
      height: height,
      width: double.infinity,
      // Bagian atas dipudarkan supaya ilustrasi menyatu dengan latar
      // halaman, tanpa garis tepi gambar yang kelihatan.
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (bounds) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black],
          stops: [0, 0.45],
        ).createShader(bounds),
        child: Image.asset(
          AppColors.isDark ? _illustrationDark : _illustration,
          fit: BoxFit.cover,
          alignment: Alignment.bottomCenter,
        ),
      ),
    );
  }
}
