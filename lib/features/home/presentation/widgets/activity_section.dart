import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/activity_entry.dart';

/// Daftar aktivitas terbaru di bagian paling bawah Beranda.
class ActivitySection extends StatelessWidget {
  const ActivitySection({
    super.key,
    required this.activities,
    this.enabled = true,
  });

  final List<ActivityEntry> activities;

  /// false = tampil redup dengan penanda "Soon", pola yang sama dengan item
  /// menu HRIS yang `isReady: false`. Dipakai selama API aktivitas belum ada.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    // Hanya aktivitas terbaru yang tampil (lihat ActivityFeed): yang paling
    // lama otomatis tergeser keluar saat ada aktivitas baru.
    final visible = ActivityFeed.latest(activities);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Activity', style: AppTextStyles.sectionTitle),
              if (!enabled) Text('Soon', style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: 12),
          if (visible.isEmpty)
            Text(
              'No recent activity',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          for (final activity in visible)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: IgnorePointer(
                ignoring: !enabled,
                child: Opacity(
                  opacity: enabled ? 1 : 0.45,
                  child: _ActivityTile(activity: activity),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.activity});

  final ActivityEntry activity;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: activity.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(activity.icon, size: 18, color: activity.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  activity.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            activity.timeLabel(),
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 10,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
