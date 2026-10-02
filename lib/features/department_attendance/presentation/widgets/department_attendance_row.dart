import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/department_attendance_entry.dart';
import '../../domain/department_attendance_status.dart';

/// Satu baris karyawan: avatar berwarna status, nama + jabatan/shift, lalu
/// jam masuk dan badge status di sisi kanan.
class DepartmentAttendanceRow extends StatelessWidget {
  const DepartmentAttendanceRow({
    super.key,
    required this.entry,
    required this.isToday,
    required this.onTap,
  });

  final DepartmentAttendanceEntry entry;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = entry.status;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              // Avatar sengaja netral; status cukup terbaca dari badge di
              // sisi kanan.
              decoration: const BoxDecoration(
                color: AppColors.bg,
                shape: BoxShape.circle,
              ),
              child: Text(
                entry.initials,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMid,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    entry.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  entry.clockIn ?? '—',
                  style: AppTextStyles.body.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: entry.clockIn == null
                        ? AppColors.textMuted
                        : AppColors.text,
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: status.background,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    entry.badgeText(isToday: isToday),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: status.color,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
