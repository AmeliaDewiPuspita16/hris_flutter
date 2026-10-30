import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../domain/executive_dashboard.dart';
import 'est_stat_card.dart';

/// Tiga kartu ringkasan: proyek aktif, DW hari ini, jam terpakai.
class EstStatCards extends StatelessWidget {
  const EstStatCards({super.key, required this.summary});

  final ExecutiveSummaryModel summary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: EstStatCard(
            value: '${summary.activeProjects}',
            label: 'Proyek Aktif',
            icon: Icons.domain_outlined,
            iconColor: AppColors.primaryText,
            iconBgColor: AppColors.presentBg,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: EstStatCard(
            value: '${summary.totalWorkerToday}',
            label: 'Total DW Hari Ini',
            icon: Icons.groups_outlined,
            iconColor: AppColors.orange,
            iconBgColor: AppColors.orangeBg,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: EstStatCard(
            value: '${summary.hoursUsedPct}%',
            label: 'Jam Terpakai',
            icon: Icons.schedule_outlined,
            iconColor: AppColors.primaryLight,
            iconBgColor: AppColors.presentBg,
          ),
        ),
      ],
    );
  }
}
