import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/profile_cover.dart';

/// Menggambar cover kartu profil memenuhi ruang yang tersedia.
///
/// Urutan: gambar lokal [file] (preview sebelum upload) → gambar
/// `cover.imageUrl` → gradasi `cover.colors` → gambar bawaan aplikasi
/// (kalau server belum mengirim cover sama sekali).
///
/// Gambar selalu menutupi kotaknya (BoxFit.cover), lalu diperbesar sebesar
/// `position.size / 100` dan digeser ke titik `position.x/y`. Rasio kartu
/// di aplikasi berbeda dari web (7:3), jadi potongannya mirip, tidak
/// identik.
class CoverBackground extends StatelessWidget {
  const CoverBackground({super.key, this.cover, this.file, this.position});

  static const fallbackAsset = 'assets/images/drone.png';

  final ProfileCover? cover;

  /// Gambar dari perangkat yang belum di-upload; menang atas [cover].
  final File? file;

  /// Menimpa `cover.position`, mis. selama user menggeser di layar atur
  /// posisi.
  final CoverPosition? position;

  @override
  Widget build(BuildContext context) {
    final c = cover;
    final pos = position ?? c?.position ?? CoverPosition.defaultPosition;

    if (file != null) return _positioned(FileImage(file!), pos);
    if (c != null && c.isImage) {
      return _positioned(NetworkImage(c.imageUrl!), pos);
    }
    if (c != null && c.colors.isNotEmpty) return gradient(c.colors);
    return _positioned(
      const AssetImage(fallbackAsset),
      const CoverPosition(x: 100),
    );
  }

  /// Gradasi diagonal seperti thumbnail preset di web.
  static Widget gradient(List<Color> colors) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors.length == 1 ? [colors.first, colors.first] : colors,
          ),
        ),
        child: const SizedBox.expand(),
      );

  Widget _positioned(ImageProvider image, CoverPosition pos) {
    final zoom = pos.size / 100;
    final alignment = pos.alignment;
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        return ClipRect(
          child: OverflowBox(
            alignment: alignment,
            minWidth: w * zoom,
            maxWidth: w * zoom,
            minHeight: h * zoom,
            maxHeight: h * zoom,
            child: Image(
              image: image,
              fit: BoxFit.cover,
              alignment: alignment,
              gaplessPlayback: true,
              errorBuilder: (_, __, ___) =>
                  gradient([AppColors.primary, AppColors.primaryMid]),
            ),
          ),
        );
      },
    );
  }
}

/// Gelap tipis dari kiri supaya judul putih di atas cover tetap terbaca,
/// apa pun cover-nya (gambar terang atau gradasi oranye sekalipun).
class CoverReadabilityOverlay extends StatelessWidget {
  const CoverReadabilityOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
            // gradient: LinearGradient(
            //   begin: Alignment.centerLeft,
            //   end: Alignment.centerRight,
            //   stops: [0, 0.55, 1],
            //   colors: [Color(0x99000000), Color(0x33000000), Color(0x00000000)],
            // ),
            ),
        child: SizedBox.expand(),
      ),
    );
  }
}
