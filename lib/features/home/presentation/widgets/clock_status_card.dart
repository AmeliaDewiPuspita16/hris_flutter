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
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textMid),
              const SizedBox(width: 8),
              Text(
                DateFormatter.fullDate(date),
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMid,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 190,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset('assets/images/drone.png', fit: BoxFit.cover),
                  const Positioned(bottom: -30, left: -30, child: _CornerGlow()),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          AppColors.primary,
                          AppColors.primary,
                          AppColors.primary.withValues(alpha: 0),
                        ],
                        stops: const [0, 0.42, 0.85],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ShiftBadge(label: status.shiftLabel),
                        const SizedBox(height: 12),
                        Text(
                          status.shiftTime.replaceAll('–', ' – '),
                          style: const TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 14, color: Colors.white.withValues(alpha: 0.85)),
                            const SizedBox(width: 4),
                            Text(
                              status.location,
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 12.5,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Divider(height: 1, color: Colors.white.withValues(alpha: 0.2)),
                        const SizedBox(height: 12),
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

/// Pil kecil "OFFICE HOURS" di pojok kiri-atas kartu.
class _ShiftBadge extends StatelessWidget {
  const _ShiftBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.access_time_rounded, size: 12, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Lingkaran samar di pojok kartu, biar bidang hijaunya tidak datar.
class _CornerGlow extends StatelessWidget {
  const _CornerGlow();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.06),
      ),
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.activeDot,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: status.isClockedIn
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Clocked in at ${status.clockInTime}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      status.workedDuration ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 11.5,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                )
              : const Text(
                  'You have not clocked in yet',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            shape: const StadiumBorder(),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.access_time_rounded, size: 15, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                status.actionLabel,
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.chevron_right, size: 16, color: AppColors.primary),
            ],
          ),
        ),
      ],
    );
  }
}
