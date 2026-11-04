import 'package:flutter/material.dart';

/// Latar halaman login MODE TERANG.
///
/// Dua lapis, keduanya hanya di sekitar ilustrasi di dasar halaman supaya
/// area form tetap bersih:
///  1. semburat hijau mint yang memudar ke atas dari dasar halaman;
///  2. tekstur garis (bg_login.png) yang sangat samar dan memudar habis di
///     bagian atas — dulu garis ini memenuhi seluruh halaman dan terlihat
///     ramai di belakang form.
///
/// Taruh di belakang konten, misalnya:
/// `Positioned.fill(child: IgnorePointer(child: LoginLightBackdrop()))`.
class LoginLightBackdrop extends StatelessWidget {
  const LoginLightBackdrop({super.key});

  static const _texture = 'assets/images/bg_login.png';

  /// Hijau mint untuk semburat di dasar halaman.
  static const _glow = Color(0xFFD4EBDD);

  /// Kepekatan tekstur garis. Naikkan kalau terlalu samar, turunkan kalau
  /// masih terasa ramai.
  static const double _textureOpacity = 0.08;

  /// Tinggi semburat mint, sebagai pecahan dari tinggi halaman.
  static const double _glowHeightFactor = 0.45;

  /// Garis tidak terlihat di atas [_textureFadeStart] dan penuh di
  /// [_textureFadeEnd] (pecahan dari tinggi halaman, dihitung dari atas).
  static const double _textureFadeStart = 0.55;
  static const double _textureFadeEnd = 0.80;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1) Semburat mint dari dasar.
        Align(
          alignment: Alignment.bottomCenter,
          child: FractionallySizedBox(
            widthFactor: 1,
            heightFactor: _glowHeightFactor,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [_glow, Color(0x00D4EBDD)],
                ),
              ),
            ),
          ),
        ),
        // 2) Tekstur garis, memudar ke atas.
        ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.transparent, Colors.black],
            stops: [0, _textureFadeStart, _textureFadeEnd],
          ).createShader(bounds),
          child: Image.asset(
            _texture,
            fit: BoxFit.cover,
            opacity: const AlwaysStoppedAnimation<double>(_textureOpacity),
          ),
        ),
      ],
    );
  }
}
