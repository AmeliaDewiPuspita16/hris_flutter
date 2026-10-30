import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../domain/executive_dashboard.dart';
import '../bloc/detail/exec_project_detail_bloc.dart';
import '../bloc/detail/exec_project_detail_state.dart';
import 'est_detail_format.dart';

/// Kartu timeline proyek: bar waktu berjalan, badge keterlambatan, dan tiga
/// ringkasan (sisa hari, progres, sisa jam).
class EstDetailTimelineCard extends StatelessWidget {
  const EstDetailTimelineCard({super.key, required this.project});

  final ExecutiveProjectModel project;

  @override
  Widget build(BuildContext context) {
    final isCompleted = project.status == 'completed';
    final start = DateTime.tryParse(project.startDate) ?? DateTime.now();
    final end = DateTime.tryParse(project.targetEndDate) ?? DateTime.now();
    final now = DateTime.now();
    final daysLeft = end.difference(now).inDays;
    final totalDays = end.difference(start).inDays;
    final elapsed = now.difference(start).inDays;
    final timeProgress =
        totalDays > 0 ? (elapsed / totalDays).clamp(0.0, 1.0) : 0.0;

    return BlocBuilder<ExecProjectDetailBloc, ExecProjectDetailState>(
      builder: (context, state) {
        // Tentukan apakah proyek selesai melewati target
        final closedAt =
            state is ExecProjectDetailLoaded ? state.data.closedAt : null;
        final closedDate =
            closedAt != null ? DateTime.tryParse(closedAt) : null;
        // completedLate: proyek selesai tapi setelah target_end_date
        final completedLate =
            isCompleted && closedDate != null && closedDate.isAfter(end);

        final bool isLate = isCompleted ? completedLate : daysLeft < 0;
        final Color badgeColor =
            isLate ? AppColors.rejectedBg : AppColors.presentBg;
        final Color badgeFgColor =
            isLate ? AppColors.rejected : AppColors.primaryText;
        final String badgeLabel = isCompleted
            ? (completedLate ? 'Melewati Target' : 'Selesai')
            : (daysLeft >= 0 ? 'Berjalan' : 'Melewati Target');
        final IconData badgeIcon =
            isLate ? Icons.warning_amber_rounded : Icons.check_circle_outline;

        final sisaHariValue = isCompleted
            ? completedLate
                ? 'Lewat'
                : 'Selesai'
            : daysLeft >= 0
                ? '$daysLeft hari'
                : 'Lewat';
        final sisaHariColor = isCompleted
            ? completedLate
                ? AppColors.rejected
                : AppColors.primaryText
            : daysLeft < 30
                ? AppColors.rejected
                : AppColors.primaryText;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: estCardDecoration(radius: 20, blur: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Timeline Proyek',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(badgeIcon, size: 12, color: badgeFgColor),
                        const SizedBox(width: 4),
                        Text(
                          badgeLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: badgeFgColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Stack(
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: isCompleted ? 1.0 : timeProgress,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.primaryText.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    estFmtDate(project.startDate),
                    style: TextStyle(fontSize: 11, color: AppColors.textSub),
                  ),
                  Text(
                    estFmtDate(project.targetEndDate),
                    style: TextStyle(fontSize: 11, color: AppColors.textSub),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _TimelineStat(
                      label: 'Sisa Hari',
                      value: sisaHariValue,
                      icon: Icons.today_outlined,
                      color: sisaHariColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TimelineStat(
                      label: 'Progress',
                      value: '${project.progressPercent}%',
                      icon: Icons.trending_up_outlined,
                      color: AppColors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TimelineStat(
                      label: 'Sisa Jam',
                      value: '${estFmtHours(project.remainingHours)} jam',
                      icon: Icons.schedule_outlined,
                      color: project.remainingHours > 0
                          ? AppColors.primaryText
                          : AppColors.rejected,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TimelineStat extends StatelessWidget {
  const _TimelineStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textSub,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
