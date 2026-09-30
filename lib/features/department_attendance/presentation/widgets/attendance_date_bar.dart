import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_card.dart';

/// Pemilih tanggal di atas daftar: panah kemarin/besok di kiri-kanan, dan
/// ketuk di tengah untuk membuka kalender.
///
/// Panah "besok" mati saat [isToday] — realisasi kehadiran belum ada untuk
/// tanggal yang belum terjadi.
class AttendanceDateBar extends StatelessWidget {
  const AttendanceDateBar({
    super.key,
    required this.date,
    required this.isToday,
    required this.onPrevious,
    required this.onNext,
    required this.onPickDate,
  });

  final DateTime date;
  final bool isToday;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onPickDate;

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  String get _label =>
      '${_weekdays[date.weekday - 1]}, ${DateFormatter.shortDate(date)}';

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          _ArrowButton(
            icon: Icons.chevron_left,
            label: 'Previous day',
            onPressed: onPrevious,
          ),
          Expanded(
            child: InkWell(
              onTap: onPickDate,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 15,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        _label,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (isToday) ...[
                      // const SizedBox(width: 6),
                      // Container(
                      //   padding: const EdgeInsets.symmetric(
                      //     horizontal: 8,
                      //     vertical: 3,
                      //   ),
                      //   decoration: BoxDecoration(
                      //     color: AppColors.presentBg,
                      //     borderRadius: BorderRadius.circular(6),
                      //   ),
                      //   child: const Text(
                      //     'Today',
                      //     style: TextStyle(
                      //       fontSize: 10,
                      //       fontWeight: FontWeight.w700,
                      //       color: AppColors.present,
                      //     ),
                      //   ),
                      // ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          _ArrowButton(
            icon: Icons.chevron_right,
            label: 'Next day',
            onPressed: isToday ? null : onNext,
          ),
        ],
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    // Tanpa `tooltip`: bubble abu-abunya muncul menimpa kartu di bawahnya.
    // Label untuk screen reader tetap dipasang lewat Semantics.
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      excludeSemantics: true,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 22),
        color: AppColors.textMid,
        disabledColor: AppColors.border,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 36, height: 36),
        splashRadius: 18,
      ),
    );
  }
}
