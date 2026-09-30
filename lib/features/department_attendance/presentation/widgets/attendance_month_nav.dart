import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Baris pemilih bulan di dalam kartu kalender: panah bulan sebelumnya /
/// berikutnya di kiri-kanan, dan label bulan di tengah yang bisa diketuk
/// untuk membuka pemilih bulan.
///
/// [onPrevious] / [onNext] null = panah mati (sudah di batas bulan yang boleh
/// dibuka).
class AttendanceMonthNav extends StatelessWidget {
  const AttendanceMonthNav({
    super.key,
    required this.month,
    required this.onPrevious,
    required this.onNext,
    required this.onPick,
  });

  final DateTime month;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onPick;

  static const _months = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  String get _label => '${_months[month.month - 1]} ${month.year}';

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Arrow(
          icon: Icons.chevron_left,
          label: 'Previous month',
          onTap: onPrevious,
        ),
        Expanded(
          child: InkWell(
            onTap: onPick,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _label,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    size: 18,
                    color: AppColors.textMid,
                  ),
                ],
              ),
            ),
          ),
        ),
        _Arrow(
          icon: Icons.chevron_right,
          label: 'Next month',
          onTap: onNext,
        ),
      ],
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            icon,
            size: 22,
            color: onTap == null ? AppColors.border : AppColors.textMid,
          ),
        ),
      ),
    );
  }
}
