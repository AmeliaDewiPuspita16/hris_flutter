import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../domain/executive_dashboard.dart';
import 'est_session_row.dart';

/// Kartu proyek di "Performa Proyek": progres jam, status, dan baris sesi.
class EstProjectCard extends StatelessWidget {
  const EstProjectCard({
    super.key,
    required this.project,
    this.onTap,
    required this.onToggleSession,
  });

  final ExecutiveProjectModel project;

  /// Null = kartu tidak bisa diketuk (detail proyek belum tersambung).
  final VoidCallback? onTap;

  final VoidCallback onToggleSession;

  Color get _progressColor => switch (project.status) {
        'over_budget' => AppColors.rejected,
        'at_risk' => AppColors.orange,
        _ => AppColors.primary,
      };

  Color get _barColor => switch (project.status) {
        'over_budget' => AppColors.rejected,
        'at_risk' => AppColors.orange,
        _ => AppColors.primaryText,
      };

  Color get _progressTextColor => switch (project.status) {
        'over_budget' => AppColors.rejected,
        'at_risk' => AppColors.orange,
        _ => AppColors.primaryText,
      };

  String get _statusLabel => switch (project.status) {
        'over_budget' => 'Over Budget',
        'at_risk' => 'At Risk',
        'completed' => 'Selesai',
        _ => 'On Track',
      };

  Color get _statusBg => switch (project.status) {
        'over_budget' => AppColors.rejectedBg,
        'at_risk' => AppColors.orangeBg,
        'completed' => AppColors.presentBg,
        _ => AppColors.inProgressBg,
      };

  Color get _statusText => switch (project.status) {
        'over_budget' => AppColors.rejected,
        'at_risk' => AppColors.orange,
        'completed' => AppColors.primaryText,
        _ => AppColors.inProgress,
      };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _progressColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      project.name[0],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '#${project.jobNumber ?? '-'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSub,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _statusBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _statusText,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${project.usedHoursLabel} / ${project.budgetHoursLabel} Jam',
                  style: TextStyle(fontSize: 12, color: AppColors.textSub),
                ),
                Text(
                  '${project.progressPercent}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _progressTextColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: project.progress,
                backgroundColor: AppColors.bg,
                valueColor: AlwaysStoppedAnimation<Color>(_barColor),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 10),
            EstSessionRow(project: project, onToggleSession: onToggleSession),
          ],
        ),
      ),
    );
  }
}
