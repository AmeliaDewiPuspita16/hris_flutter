import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/attendance_summary.dart';

/// Kartu ringkasan (Hadir / Terlambat / Jam Lembur) di puncak Log Absensi.
///
/// Ditampilkan sebagai 3 card terpisah; border tiap card memakai warna yang
/// sama dengan titik status di kalender di bawahnya, supaya artinya
/// konsisten di seluruh layar.
class AttendanceSummaryCard extends StatelessWidget {
  const AttendanceSummaryCard({super.key, required this.summary});

  final AttendanceSummary summary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            value: '${summary.present}',
            label: 'Hadir',
            valueColor: AppColors.text,
            borderColor: AppColors.present,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            value: '${summary.late}',
            label: 'Terlambat',
            valueColor: AppColors.rejected,
            borderColor: AppColors.rejected,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            value: '${summary.overtimeHrs}j',
            label: 'Jam Lembur',
            valueColor: AppColors.text,
            borderColor: AppColors.overtime,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.valueColor,
    required this.borderColor,
  });

  final String value;
  final String label;
  final Color valueColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: valueColor),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
