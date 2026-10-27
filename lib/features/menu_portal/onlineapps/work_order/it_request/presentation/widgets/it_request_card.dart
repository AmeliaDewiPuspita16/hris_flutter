import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../../core/utils/date_formatter.dart';
import '../../../../../../../core/widgets/app_card.dart';
import '../../domain/it_request_item.dart';
import '../../domain/it_request_status.dart';
import '../../domain/it_request_type.dart';
import 'it_request_rating_stars.dart';

/// Satu baris riwayat permintaan IT/Media milik staff: kotak ikon kategori
/// di kiri, lalu jenis + kategori, badge status, deskripsi, tanggal, dan
/// rating (kalau sudah dinilai), dengan chevron di kanan — dipakai untuk
/// item yang TIDAK sedang menunggu rating (item yang menunggu rating pakai
/// [ItRequestFeedbackBanner]).
class ItRequestCard extends StatelessWidget {
  const ItRequestCard({super.key, required this.item, this.onTap});

  final ItRequestItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isMedia = item.type == ItRequestType.media;
    final (color, background) = _toneFor(item);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_iconFor(item), size: 22, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isMedia ? Icons.palette_outlined : Icons.computer_outlined,
                      size: 13,
                      color: color,
                    ),
                    const SizedBox(width: 4),
                    // Expanded supaya badge status selalu mepet ke kanan.
                    Expanded(
                      child: Text(
                        '${item.type.label} · ${item.category.label}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusBadge(status: item.status),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 12, color: AppColors.textMuted),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        DateFormatter.shortDate(item.createdAt),
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textMuted),
                      ),
                    ),
                    if (item.rating != null)
                      ItRequestRatingStars(rating: item.rating!, size: 13),
                  ],
                ),
              ],
            ),
          ),
          if (onTap != null)
            const Padding(
              padding: EdgeInsets.only(left: 2, top: 30),
              child: Icon(Icons.chevron_right_rounded,
                  size: 22, color: AppColors.textMuted),
            ),
        ],
      ),
    );
  }

  /// Media selalu ungu. IT dibedakan per kategori: perangkat keras biru,
  /// meeting/event ungu muda, sisanya hijau.
  static (Color, Color) _toneFor(ItRequestItem item) {
    if (item.type == ItRequestType.media) {
      return (AppColors.violet, AppColors.violetBg);
    }
    final category = item.category.label.toLowerCase();
    if (_hasAny(category, const ['hardware', 'computer', 'laptop', 'printer'])) {
      return (AppColors.itRequest, AppColors.itRequestBg);
    }
    if (_hasAny(category, const ['meeting', 'event', 'zoom'])) {
      return (AppColors.violet, AppColors.violetBg);
    }
    return (AppColors.primaryMid, AppColors.primaryLight);
  }

  /// Ikon ditebak dari label kategori dari server (bukan kode tetap), jadi
  /// kategori baru tetap dapat ikon umum alih-alih error.
  static IconData _iconFor(ItRequestItem item) {
    final category = item.category.label.toLowerCase();
    final description = item.description.toLowerCase();

    if (_hasAny(category, const ['meeting', 'event', 'zoom'])) {
      return Icons.groups_outlined;
    }
    if (_hasAny(category, const ['hardware', 'computer', 'laptop'])) {
      return Icons.laptop_mac_outlined;
    }
    if (_hasAny(category, const ['printer'])) return Icons.print_outlined;
    if (_hasAny(category, const ['network', 'internet', 'wifi'])) {
      return Icons.wifi_rounded;
    }
    if (_hasAny(category, const ['account', 'email', 'access'])) {
      return Icons.manage_accounts_outlined;
    }
    if (item.type == ItRequestType.media) {
      return _hasAny(category, const ['video', 'dokumentasi', 'documentation'])
          ? Icons.videocam_outlined
          : Icons.image_outlined;
    }
    // "Others": tebak dari isi permintaan supaya ikonnya tetap bermakna.
    if (_hasAny(description, const ['kartu nama', 'id card', 'name card'])) {
      return Icons.badge_outlined;
    }
    if (_hasAny(description, const ['infocus', 'proyektor', 'projector'])) {
      return Icons.videocam_outlined;
    }
    return Icons.computer_outlined;
  }

  static bool _hasAny(String text, List<String> keywords) =>
      keywords.any(text.contains);
}

/// Badge status berbentuk pill dengan ikon kecil di depan label.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final ItRequestStatus status;

  IconData get _icon => switch (status.code) {
        'waiting' => Icons.schedule_rounded,
        'progress' => Icons.autorenew_rounded,
        'done' || 'wait_checked' => Icons.hourglass_bottom_rounded,
        'finished' => Icons.check_circle_rounded,
        'rejected' || 'cancelled' => Icons.cancel_rounded,
        _ => Icons.circle_outlined,
      };

  @override
  Widget build(BuildContext context) {
    // Lebar dibatasi supaya label status yang sangat panjang dari server
    // tetap terpotong rapi, bukan meluber ke luar kartu.
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 120),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: status.background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon, size: 11, color: status.color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                status.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: status.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
