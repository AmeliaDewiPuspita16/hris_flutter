import 'package:material_ui/material_ui.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../domain/meter_reading_page.dart';
import '../../domain/meter_reading_state.dart';

/// Deret chip filter status pencatatan: All / Not recorded / Recorded.
///
/// Angkanya dari `summary` server, yang menghitung SELURUH meter periode ini
/// dan TIDAK ikut menyempit saat filter jenis meter atau pencarian dipakai.
/// Karena itu layar mematikan angka ([showCounts] = false) selagi filter
/// jenis / pencarian aktif, supaya angka di chip tidak berbeda dari daftar.
class MeterStateFilterBar extends StatelessWidget {
  const MeterStateFilterBar({
    super.key,
    required this.counts,
    required this.selected,
    required this.onChanged,
    this.showCounts = true,
  });

  final MeterReadingCounts counts;

  /// `MeterReadingState.code` yang aktif. Null berarti chip "All".
  final String? selected;

  final ValueChanged<String?> onChanged;

  /// False menyembunyikan angka di semua chip.
  final bool showCounts;

  @override
  Widget build(BuildContext context) {
    final options = <({String? code, String label, int count, Color color, IconData icon})>[
      (
        code: null,
        label: 'All',
        count: counts.all,
        color: AppColors.primary,
        icon: Icons.apps_rounded,
      ),
      (
        code: MeterReadingState.pending.code,
        label: MeterReadingState.pending.label,
        count: counts.pending,
        color: MeterReadingState.pending.color,
        icon: MeterReadingState.pending.icon,
      ),
      (
        code: MeterReadingState.recorded.code,
        label: MeterReadingState.recorded.label,
        count: counts.recorded,
        color: MeterReadingState.recorded.color,
        icon: MeterReadingState.recorded.icon,
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            _FilterChip(
              label: options[i].label,
              count: showCounts ? options[i].count : null,
              color: options[i].color,
              neutral: options[i].code == null,
              icon: options[i].icon,
              active: selected == options[i].code,
              onTap: () => onChanged(options[i].code),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.color,
    required this.neutral,
    required this.active,
    required this.onTap,
    required this.icon,
  });

  final IconData icon;
  final String label;

  /// Null = angka disembunyikan.
  final int? count;
  final Color color;

  /// Chip "All": ikonnya abu-abu saat tidak aktif, bukan berwarna seperti
  /// dua chip status.
  final bool neutral;

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Satu gaya untuk semua chip: aktif = hijau utama penuh, tidak aktif =
    // kartu putih. Makna status sudah dibawa ikon, bukan warna latar.
    final labelColor = active ? Colors.white : AppColors.text;
    final iconColor =
        active ? Colors.white : (neutral ? AppColors.textMid : color);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AppColors.primaryText.withValues(alpha: 0.45) : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: iconColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: labelColor,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 7),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                decoration: BoxDecoration(
                  color: active
                      ? Colors.white.withValues(alpha: 0.22)
                      : AppColors.neutralBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: active ? Colors.white : AppColors.textMid,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
