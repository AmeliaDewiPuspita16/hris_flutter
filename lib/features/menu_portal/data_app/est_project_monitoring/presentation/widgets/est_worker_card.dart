import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../domain/project_worker.dart';
import 'est_detail_format.dart';

/// Kartu worker di "Tim Proyek". Geser ke kiri = [onTransfer]; null berarti
/// geser dimatikan. [onSubstitute]/[onEndSubstitute] null = tombol tanpa efek.
class EstWorkerCard extends StatelessWidget {
  const EstWorkerCard({
    super.key,
    required this.worker,
    this.onTransfer,
    this.onSubstitute,
    this.onEndSubstitute,
  });

  final ProjectWorkerModel worker;
  final Future<void> Function()? onTransfer;
  final VoidCallback? onSubstitute;
  final VoidCallback? onEndSubstitute;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('worker_${worker.workerId}'),
      direction: onTransfer == null
          ? DismissDirection.none
          : DismissDirection.endToStart,
      confirmDismiss: (_) async {
        await onTransfer?.call();
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.primaryText.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.swap_horiz_rounded,
              color: AppColors.primaryText,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              'Pindahkan',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: estCardDecoration(radius: 14, blur: 6),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: worker.isClockedIn ? AppColors.primary : AppColors.bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  worker.initials,
                  style: TextStyle(
                    color:
                        worker.isClockedIn ? Colors.white : AppColors.textSub,
                    fontSize: 15,
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
                    worker.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      _AttendanceBadge(worker: worker),
                      if (worker.isClockedIn && worker.clockIn != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          'masuk ${worker.clockIn}',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSub,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (worker.isSubstitute &&
                      worker.substituteForName != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.orangeBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Pengganti ${worker.substituteForName}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.orange,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Aksi pengganti
            if (worker.isSubstitute && worker.assignmentId != null)
              GestureDetector(
                onTap: onEndSubstitute,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.rejectedBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Akhiri',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.rejected,
                    ),
                  ),
                ),
              )
            else
              GestureDetector(
                onTap: onSubstitute,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.presentBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.person_add_alt_1_outlined,
                    size: 16,
                    color: AppColors.primaryText,
                  ),
                ),
              ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_left, size: 16, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _AttendanceBadge extends StatelessWidget {
  const _AttendanceBadge({required this.worker});

  final ProjectWorkerModel worker;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = switch (worker.attendanceCondition) {
      2 => (AppColors.presentBg, AppColors.primaryText, 'Sedang Bekerja'),
      3 => (AppColors.presentBg, AppColors.present, 'Sudah Pulang'),
      _ => (AppColors.bg, AppColors.textSub, 'Belum Absen'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}
