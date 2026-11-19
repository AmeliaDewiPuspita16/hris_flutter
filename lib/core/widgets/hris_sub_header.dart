import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

/// Satu tab pada [HrisSubHeader].
class HrisHeaderTab {
  const HrisHeaderTab(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// Header bersama untuk halaman fitur HRIS (Leave, Overtime, Log Absensi).
///
/// Identitas HRIS: hijau tua solid dengan sudut bawah membulat, satu
/// keluarga dengan header hub HRIS. Menggantikan header yang sebelumnya
/// ditulis ulang di tiap layar, supaya tinggi, jarak, dan gaya tab selalu
/// sama.
///
/// Komponen BARU dan berdiri sendiri. Kalau tidak jadi dipakai, kembalikan
/// layar yang diubah lalu hapus file ini.
class HrisSubHeader extends StatelessWidget {
  const HrisSubHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showBack = true,
    this.onBack,
    this.backdrop,
    this.tabs = const [],
    this.selectedIndex = 0,
    this.onTabChanged,
  });

  final String title;
  final String? subtitle;
  final bool showBack;
  final VoidCallback? onBack;

  /// Dekorasi di belakang isi header, mis. gambar gelombang yang sama
  /// dengan header hub HRIS. Otomatis dipotong mengikuti sudut bawah.
  final Widget? backdrop;

  final List<HrisHeaderTab> tabs;
  final int selectedIndex;
  final ValueChanged<int>? onTabChanged;

  static const double _radius = 28;

  /// Dipakai juga untuk strip di balik status bar, supaya tidak ada garis
  /// beda warna di atas header.
  static Color get background => AppColors.primary;

  /// Header gelap -> ikon status bar terang.
  static const SystemUiOverlayStyle overlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  );

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showBack) ...[
            _BackButton(onTap: onBack ?? () => Navigator.maybePop(context)),
            const SizedBox(height: 10),
          ],
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12.5,
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
          ],
          if (tabs.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  for (var i = 0; i < tabs.length; i++)
                    Expanded(
                      child: _TabPill(
                        tab: tabs[i],
                        active: i == selectedIndex,
                        onTap: () => onTabChanged?.call(i),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(_radius),
      ),
      child: ColoredBox(
        color: background,
        child: Stack(
          children: [
            if (backdrop != null) Positioned.fill(child: backdrop!),
            SizedBox(width: double.infinity, child: content),
          ],
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 36,
          height: 36,
          child: Icon(Icons.arrow_back_rounded, size: 20, color: Colors.white),
        ),
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.tab,
    required this.active,
    required this.onTap,
  });

  final HrisHeaderTab tab;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = active
        ? AppColors.primaryText
        : Colors.white.withValues(alpha: 0.75);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          // Aktif: pil putih. Tidak aktif: transparan di atas hijau.
          // Sama seperti header lama.
          color: active ? AppColors.card : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(tab.icon, size: 14, color: fg),
            const SizedBox(width: 5),
            Text(
              tab.label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
