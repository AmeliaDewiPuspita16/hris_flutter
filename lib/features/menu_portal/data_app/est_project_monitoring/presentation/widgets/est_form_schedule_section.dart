import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import 'est_form_fields.dart';
import 'est_form_section.dart';

/// Tanggal tampilan, mis. `5 Agt 2026`.
String estFormatDate(DateTime d) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agt',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

/// Seksi "Jadwal": tanggal mulai, estimasi selesai, dan durasi.
class EstFormScheduleSection extends StatelessWidget {
  const EstFormScheduleSection({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.onPickStart,
    required this.onPickEnd,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;

  @override
  Widget build(BuildContext context) {
    return EstFormSection(
      title: 'Jadwal',
      icon: Icons.calendar_today_outlined,
      children: [
        Row(
          children: [
            Expanded(
              child: EstFormDateField(
                label: 'Tanggal Mulai',
                value: startDate != null ? estFormatDate(startDate!) : null,
                hint: 'Pilih tanggal',
                onTap: () => onPickStart(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: EstFormDateField(
                label: 'Estimasi Selesai',
                value: endDate != null ? estFormatDate(endDate!) : null,
                hint: 'Pilih tanggal',
                onTap: () => onPickEnd(),
              ),
            ),
          ],
        ),
        if (startDate != null && endDate != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.presentBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.primaryText,
                  size: 14,
                ),
                const SizedBox(width: 8),
                Text(
                  'Durasi proyek: ${endDate!.difference(startDate!).inDays} hari',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
