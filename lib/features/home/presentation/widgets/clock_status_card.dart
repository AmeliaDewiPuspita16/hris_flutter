import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/attendance_status.dart';

class ClockStatusCard extends StatelessWidget {
  const ClockStatusCard({
    super.key,
    required this.status,
    required this.date,
    required this.onActionTap,
  });

  final AttendanceStatus status;
  final DateTime date;
  final VoidCallback onActionTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormatter.fullDate(date),
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textMid,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: ColoredBox(
              color: AppColors.primary,
              child: Stack(
                children: [
                  const Positioned(top: -56, right: -36, child: _CornerGlow()),
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TODAY · ${status.shiftLabel.toUpperCase()}',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _ShiftRow(status: status),
                        const SizedBox(height: 14),
                        Divider(
                          height: 1,
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                        const SizedBox(height: 14),
                        _StatusRow(status: status, onActionTap: onActionTap),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lingkaran samar di pojok kanan atas, biar bidang hijaunya tidak datar.
class _CornerGlow extends StatelessWidget {
  const _CornerGlow();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      height: 170,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.05),
      ),
    );
  }
}

class _ShiftRow extends StatelessWidget {
  const _ShiftRow({required this.status});

  final AttendanceStatus status;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          status.shiftTime,
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            status.location,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.status, required this.onActionTap});

  final AttendanceStatus status;
  final VoidCallback onActionTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryLight,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            status.statusText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: onActionTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.card,
            foregroundColor: AppColors.primary,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
            shape: const StadiumBorder(),
          ),
          child: Text(
            status.actionLabel,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
