import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/attendance_entry.dart';

/// Satu baris harian di daftar Log Absensi.
class AttendanceRow extends StatelessWidget {
  const AttendanceRow({super.key, required this.entry});

  final AttendanceEntry entry;

  ({Color fg, Color bg, String label})? get _badge {
    switch (entry.status) {
      case AttendanceStatus.tepatWaktu:
        return (
          fg: AppColors.present,
          bg: AppColors.presentBg,
          label: 'TEPAT WAKTU'
        );
      case AttendanceStatus.lembur:
        return (
          fg: AppColors.present,
          bg: AppColors.presentBg,
          label: 'LBR 4,5J'
        );
      case AttendanceStatus.terlambat:
        return (
          fg: AppColors.rejected,
          bg: AppColors.rejectedBg,
          label: 'TELAT 14M'
        );
      case AttendanceStatus.liburHari:
        return (fg: AppColors.neutral, bg: AppColors.neutralBg, label: 'LIBUR');
      case AttendanceStatus.berlangsung:
        // hari berjalan, belum ada hasil final — tanpa badge.
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final badge = _badge;
    final isOngoing = entry.status == AttendanceStatus.berlangsung;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 34,
            child: Column(
              children: [
                Text(entry.day,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text)),
                const SizedBox(height: 1),
                Text(entry.weekday,
                    style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                        letterSpacing: 0.3)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.primaryText,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isOngoing ? AppColors.pending : AppColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(entry.secondaryText,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: badge.bg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(badge.label,
                  style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: badge.fg,
                      letterSpacing: 0.2)),
            ),
        ],
      ),
    );
  }
}
