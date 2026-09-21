import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/app_notification.dart';

/// Kartu untuk notifikasi yang masih menunggu keputusan.
///
/// Sengaja dibuat lebih berat dari baris biasa — ada aksen warna di tepi
/// kiri dan tombol aksi langsung di dalam kartu — supaya pekerjaan yang
/// menggantung tidak tenggelam di antara notifikasi informasi.
class ActionNeededCard extends StatelessWidget {
  const ActionNeededCard({
    super.key,
    required this.notification,
    required this.onDecide,
  });

  final AppNotification notification;
  final ValueChanged<NotificationDecision> onDecide;

  @override
  Widget build(BuildContext context) {
    final category = notification.category;

    return AppCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: category.color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: category.background,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(category.icon, size: 13, color: category.color),
                                const SizedBox(width: 5),
                                Text(
                                  category.label.toUpperCase(),
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                    color: category.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Text(
                            DateFormatter.relative(notification.createdAt),
                            style: const TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        notification.title,
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        notification.body,
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _DecisionButton(
                              label: 'Approve',
                              filled: true,
                              onTap: () =>
                                  onDecide(NotificationDecision.approved),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _DecisionButton(
                              label: 'Reject',
                              filled: false,
                              onTap: () =>
                                  onDecide(NotificationDecision.rejected),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DecisionButton extends StatelessWidget {
  const _DecisionButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final String label;

  /// Approve diisi penuh, Reject cuma bergaris — keputusan yang lebih sering
  /// dipakai harus lebih menonjol.
  final bool filled;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: AppTextStyles.fontFamily,
      fontSize: 12.5,
      fontWeight: FontWeight.w600,
      color: filled ? Colors.white : AppColors.rejected,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: filled ? AppColors.primary : AppColors.rejected,
          ),
        ),
        child: Text(label, style: style),
      ),
    );
  }
}
