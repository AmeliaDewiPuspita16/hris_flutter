import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../domain/executive_dashboard.dart';

/// Baris status sesi di kartu proyek, plus tombol buka/tutup sesi
/// (disembunyikan bila sesi sudah selesai).
class EstSessionRow extends StatelessWidget {
  const EstSessionRow({
    super.key,
    required this.project,
    required this.onToggleSession,
  });

  final ExecutiveProjectModel project;
  final VoidCallback onToggleSession;

  @override
  Widget build(BuildContext context) {
    final isOpen = project.isOpen;
    final isClosed = project.sessionStatus == 'closed';

    final Color dotColor;
    final Color badgeBg;
    final Color badgeTextColor;
    final String badgeText;

    if (isOpen) {
      dotColor = AppColors.present;
      badgeBg = AppColors.presentBg;
      badgeTextColor = AppColors.presentMid;
      badgeText = 'Sesi Terbuka';
    } else if (isClosed) {
      dotColor = AppColors.textMuted;
      badgeBg = AppColors.bg;
      badgeTextColor = AppColors.textMuted;
      badgeText = 'Sesi Selesai';
    } else {
      dotColor = AppColors.primaryText;
      badgeBg = AppColors.presentBg;
      badgeTextColor = AppColors.primaryText;
      badgeText = 'Belum Ada Sesi';
    }

    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              // Badge status
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: dotColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          badgeText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: badgeTextColor,
                          ),
                        ),
                      ),
                      if (isOpen && project.sessionOpenedAt != null) ...[
                        const SizedBox(width: 4),
                        Text(
                          '· ${project.sessionOpenedAt}',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.presentMid,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (isOpen && project.notClockedOut > 0) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.orangeBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 11,
                          color: AppColors.orange,
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            '${project.notClockedOut} belum pulang',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        // Tombol aksi (disembunyikan bila sesi sudah selesai)
        if (!isClosed) ...[
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onToggleSession,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isOpen ? AppColors.rejectedBg : AppColors.presentBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isOpen
                      ? AppColors.rejected.withValues(alpha: 0.3)
                      : AppColors.primaryText.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isOpen ? Icons.lock_outline : Icons.play_circle_outline,
                    size: 13,
                    color: isOpen ? AppColors.rejected : AppColors.primaryText,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isOpen ? 'Tutup Sesi' : 'Buka Sesi',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color:
                          isOpen ? AppColors.rejected : AppColors.primaryText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
