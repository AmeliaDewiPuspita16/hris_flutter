import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/attendance_summary.dart';

/// Kartu ringkasan (Hadir / Terlambat / Jam Lembur) di puncak Log Absensi.
class AttendanceSummaryCard extends StatelessWidget {
  const AttendanceSummaryCard({super.key, required this.summary});

  final AttendanceSummary summary;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: _StatColumn(
              value: '${summary.present}',
              label: 'Hadir',
              color: AppColors.text,
            ),
          ),
          const _StatDivider(),
          Expanded(
            child: _StatColumn(
              value: '${summary.late}',
              label: 'Terlambat',
              color: AppColors.rejected,
            ),
          ),
          const _StatDivider(),
          Expanded(
            child: _StatColumn(
              value: '${summary.overtimeHrs}',
              label: 'Jam Lembur',
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 32, color: AppColors.border);
  }
}
