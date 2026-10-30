import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/not_ready.dart';
import 'owner_badge_row.dart';

/// Satu kartu kategori di halaman Records, Data, dan Online Apps: kotak ikon bergradasi warna
/// kategori, judul + badge owner (bisa lebih dari satu) bernada sama, dan
/// tombol chevron bulat di kanan. Latar kartu memudar dari putih ke tint
/// warna kategori.
///
/// Kategori yang sudah bisa dibuka diberi garis tepi berwarna kategorinya
/// supaya menonjol; yang belum tetap diredupkan lewat [NotReady].
class PortalCategoryCard extends StatelessWidget {
  const PortalCategoryCard({
    super.key,
    required this.icon,
    required this.label,
    required this.owners,
    required this.color,
    required this.background,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final List<String> owners;

  /// Warna utama kategori (ikon, badge, chevron) dan tint-nya.
  final Color color;
  final Color background;

  /// Null = belum siap: kartu diredupkan dan tidak bisa diketuk.
  final VoidCallback? onTap;

  bool get _isReady => onTap != null;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    // Di mode gelap tint-nya dilunakkan supaya kartu tetap terbaca sebagai
    // permukaan gelap, bukan blok warna.
    // Warna kategori yang gelap (mis. hijau tua) tidak terbaca di atas
    // permukaan gelap — untuk teks/garis/chevron diterangkan.
    final fg = AppColors.isDark ? AppColors.onDark(color) : color;
    final tint = AppColors.isDark
        ? Color.lerp(AppColors.card, background, 0.55)!
        : background;

    return NotReady(
      isReady: _isReady,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: LinearGradient(
            colors: [AppColors.card, AppColors.card, tint],
            stops: const [0, 0.45, 1],
          ),
          border: Border.all(
            color: _isReady ? fg.withValues(alpha: 0.45) : AppColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: fg.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
              child: Row(
                children: [
                  _IconBox(icon: icon, color: color),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: AppTextStyles.body.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 6),
                        OwnerBadgeRow(
                          owners: owners,
                          color: fg,
                          background: AppColors.isDark
                              ? fg.withValues(alpha: 0.16)
                              : background,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: fg.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.chevron_right_rounded,
                        size: 20, color: fg),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Kotak ikon 52px bergradasi dari warna kategori yang dicerahkan ke warna
/// aslinya, ikon putih di tengah.
class _IconBox extends StatelessWidget {
  const _IconBox({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(color, Colors.white, 0.3)!, color],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(icon, size: 26, color: Colors.white),
    );
  }
}
