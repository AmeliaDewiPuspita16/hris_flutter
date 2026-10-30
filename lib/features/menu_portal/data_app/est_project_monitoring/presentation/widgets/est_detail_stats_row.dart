import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../domain/executive_dashboard.dart';
import 'est_detail_format.dart';

/// Tiga kartu ringkas: budget jam, jam terpakai, sisa jam.
class EstDetailStatsRow extends StatelessWidget {
  const EstDetailStatsRow({super.key, required this.project});

  final ExecutiveProjectModel project;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _DetailStatCard(
            icon: Icons.schedule_outlined,
            iconColor: AppColors.primaryText,
            iconBg: AppColors.presentBg,
            label: 'Budget Jam',
            value: '${estFmtHours(project.budgetHours.toDouble())} jam',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _DetailStatCard(
            icon: Icons.timer_outlined,
            iconColor: AppColors.orange,
            iconBg: AppColors.orangeBg,
            label: 'Terpakai',
            value: '${estFmtHours(project.usedHours)} jam',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _DetailStatCard(
            icon: Icons.hourglass_bottom_outlined,
            iconColor: AppColors.primaryText,
            iconBg: AppColors.presentBg,
            label: 'Sisa',
            value: '${estFmtHours(project.remainingHours)} jam',
          ),
        ),
      ],
    );
  }
}

class _DetailStatCard extends StatelessWidget {
  const _DetailStatCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: estCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textSub,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
