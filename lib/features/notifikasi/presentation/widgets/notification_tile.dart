import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/app_notification.dart';

/// Satu baris notifikasi.
///
/// Dibuat rata tanpa kartu, garis pemisah, maupun latar berwarna: dalam
/// daftar panjang, tiap bingkai tambahan justru menambah beban baca. Yang
/// membedakan status cuma tiga hal ringan — ikon kategori di kiri, judul
/// lebih tebal kalau belum dibaca, dan satu titik kecil di kanan.
///
/// Baris yang masih menunggu keputusan memakai widget yang sama, cuma
/// menumbuhkan sepasang tombol di bawah teks — jadi tidak perlu lagi kartu
/// khusus yang bentuknya berbeda sendiri (dulu `ActionNeededCard`).
class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
    this.onDecide,
  });

  final AppNotification notification;
  final VoidCallback onTap;

  /// Diisi hanya untuk notifikasi yang menunggu Approve/Reject. Kalau null,
  /// baris ini tampil sebagai notifikasi informasi biasa.
  final ValueChanged<NotificationDecision>? onDecide;

  @override
  Widget build(BuildContext context) {
    final category = notification.category;
    final isUnread = !notification.isRead;
    final showActions = onDecide != null && notification.needsAction;

    // Kalau sudah diputuskan, hasil keputusannya yang ditampilkan — detail
    // permintaannya sudah tidak relevan lagi.
    final subtitle = notification.decisionLabel ?? notification.body;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 13, 20, 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: category.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(category.icon, size: 17, color: category.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 13,
                      fontWeight:
                          isUnread ? FontWeight.w700 : FontWeight.w500,
                      color: AppColors.text,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 11.5,
                      color: AppColors.textMuted,
                      height: 1.35,
                    ),
                  ),
                  if (showActions) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _DecisionButton(
                          label: 'Approve',
                          filled: true,
                          onTap: () =>
                              onDecide!(NotificationDecision.approved),
                        ),
                        const SizedBox(width: 8),
                        _DecisionButton(
                          label: 'Reject',
                          filled: false,
                          onTap: () =>
                              onDecide!(NotificationDecision.rejected),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  DateFormatter.relative(notification.createdAt),
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 10.5,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 6),
                if (isUnread)
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Tombol keputusan berukuran kecil — sengaja tidak selebar baris supaya
/// tidak mendominasi daftar. Approve diisi penuh, Reject cuma bergaris,
/// karena keputusan yang lebih sering dipakai pantas lebih menonjol.
class _DecisionButton extends StatelessWidget {
  const _DecisionButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: filled ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: filled ? Colors.white : AppColors.textMid,
          ),
        ),
      ),
    );
  }
}
