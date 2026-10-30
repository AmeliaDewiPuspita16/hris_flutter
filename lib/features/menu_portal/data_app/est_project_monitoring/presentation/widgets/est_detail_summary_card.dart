import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../domain/executive_dashboard.dart';
import 'est_detail_format.dart';

/// Ringkasan proyek di atas detail: nama, nomor job, lokasi, status, progres
/// jam, dan tanggal mulai/target.
class EstDetailSummaryCard extends StatelessWidget {
  const EstDetailSummaryCard({super.key, required this.project});

  final ExecutiveProjectModel project;

  @override
  Widget build(BuildContext context) {
    final (statusBg, statusFg, statusLabel) = estStatusStyle(project.status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: estCardDecoration(radius: 16, blur: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '#${project.jobNumber ?? '-'} · ${project.location}',
                      style: TextStyle(fontSize: 11, color: AppColors.textSub),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusFg,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${estFmtHours(project.usedHours)} / ${estFmtHours(project.budgetHours.toDouble())} jam',
                style: TextStyle(fontSize: 12, color: AppColors.textSub),
              ),
              Text(
                '${project.progressPercent}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: project.progress,
              backgroundColor: AppColors.presentBg,
              valueColor: AlwaysStoppedAnimation<Color>(
                estIsAlertStatus(project.status)
                    ? estProgressColor(project.status)
                    : AppColors.primaryText,
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _SummaryChip(
                icon: Icons.calendar_today_outlined,
                label: estFmtDate(project.startDate),
              ),
              _SummaryChip(
                icon: Icons.flag_outlined,
                label: 'Target: ${estFmtDate(project.targetEndDate)}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.presentBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppColors.primaryText),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.primaryText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
