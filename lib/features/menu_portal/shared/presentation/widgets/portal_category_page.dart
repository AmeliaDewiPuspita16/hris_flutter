import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';

/// Kerangka halaman daftar kategori Menu Portal (Records, Data, Online
/// Apps): header
/// bergambar di atas, lalu [children] (kartu kategori) berjarak 12px.
/// Header ikut tergulir bersama daftar.
class PortalCategoryPage extends StatelessWidget {
  const PortalCategoryPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.illustrationAsset = folderIllustration,
    this.sectionLabel,
  });

  static const folderIllustration =
      'assets/icons/header-folder-illustration.svg';
  static const monitorIllustration =
      'assets/icons/header-monitor-illustration.svg';

  final String title;
  final String subtitle;
  final List<Widget> children;

  /// SVG hiasan di kanan header.
  final String illustrationAsset;

  /// Label kecil huruf kapital di atas daftar, mis. "ECOSYSTEM". Null =
  /// tanpa label.
  final String? sectionLabel;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Header terang, jadi ikon status bar harus gelap — sama dengan
      // `BackHeader`.
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: ListView(
          padding: EdgeInsets.zero,
          children: [
            _PortalHeader(
              title: title,
              subtitle: subtitle,
              illustrationAsset: illustrationAsset,
              onBack: () => Navigator.of(context).pop(),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                  16, 4, 16, 24 + MediaQuery.paddingOf(context).bottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (sectionLabel case final label?)
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 10),
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  for (var i = 0; i < children.length; i++) ...[
                    if (i > 0) const SizedBox(height: 12),
                    children[i],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Latar `header-background.svg` sampai ke balik status bar, tombol kembali
/// bulat, judul besar + keterangan, dan ilustrasi map di kanan.
class _PortalHeader extends StatelessWidget {
  const _PortalHeader({
    required this.title,
    required this.subtitle,
    required this.illustrationAsset,
    required this.onBack,
  });

  final String title;
  final String subtitle;
  final String illustrationAsset;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return Stack(
      children: [
        Positioned.fill(
          child: SvgPicture.asset('assets/icons/header-background.svg',
              fit: BoxFit.cover),
        ),
        // Memudarkan ujung bawah latar ke warna halaman supaya sambungannya
        // ke daftar tidak terlihat sebagai garis.
        const Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 40,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x00F1F0EA), AppColors.bg],
              ),
            ),
          ),
        ),
        Positioned(
          right: 4,
          bottom: 12,
          child: SvgPicture.asset(
            illustrationAsset,
            width: 150,
            // Latar & judul tetap terbaca untuk pembaca layar; ilustrasi
            // hanya hiasan.
            excludeFromSemantics: true,
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(16, topInset + 8, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BackButton(onTap: onBack),
              const SizedBox(height: 18),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              // Sisakan ruang untuk ilustrasi di kanan.
              FractionallySizedBox(
                widthFactor: 0.6,
                child: Text(
                  subtitle,
                  style: AppTextStyles.bodyMuted
                      .copyWith(fontSize: 12.5, height: 1.45),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 0,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const SizedBox.square(
          dimension: 38,
          child:
              Icon(Icons.arrow_back_rounded, size: 20, color: AppColors.text),
        ),
      ),
    );
  }
}
