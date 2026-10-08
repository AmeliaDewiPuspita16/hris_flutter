import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/widgets/app_card.dart';
import '../../domain/indent_approval_item.dart';
import 'indent_driver_badge.dart';

/// Versi alternatif [IndentApprovalCard] untuk tab "Supervisor Approval".
///
/// Bedanya dengan versi pertama:
/// - Tanggal & jam jadi strip header di atas kartu (info "kapan" paling
///   dulu terbaca), jam disingkat jadi 'HH:mm – HH:mm'.
/// - Nama + badge driver, lalu tujuan, lalu remark.
/// - Approve hijau penuh dan lebih lebar; Reject tombol teks merah yang
///   lebih sempit — aksi utamanya lebih menonjol, Reject tetap jelas tapi
///   tidak bersaing.
///
/// Cara pakai: di `indent_supervisor_approval_tab.dart`, ganti
/// `IndentApprovalCard(` dengan `IndentApprovalCardAlt(` (dan import file ini).
class IndentApprovalCardAlt extends StatelessWidget {
  const IndentApprovalCardAlt({
    super.key,
    required this.item,
    required this.onApprove,
    required this.onReject,
  });

  final IndentApprovalItem item;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  /// '10:00:00 s/d 13:00:00' -> '10:00 – 13:00'. Kalau formatnya tak sesuai,
  /// dikembalikan apa adanya supaya tidak ada info yang hilang.
  String get _shortTimeRange {
    final parts = item.timeRange.split(' s/d ');
    if (parts.length != 2 || parts.any((p) => p.length < 5)) {
      return item.timeRange;
    }
    return '${parts[0].substring(0, 5)} – ${parts[1].substring(0, 5)}';
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: tanggal (kiri) & jam (kanan)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.neutralBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.event_outlined, size: 14, color: AppColors.textMid),
                const SizedBox(width: 5),
                Text(
                  item.date,
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.schedule_outlined, size: 14, color: AppColors.textMid),
                const SizedBox(width: 5),
                Text(
                  _shortTimeRange,
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Nama + badge driver
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              IndentDriverBadge(withDriver: item.withDriver),
            ],
          ),
          const SizedBox(height: 6),

          // Tujuan
          Row(
            children: [
              const Icon(Icons.place_outlined, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  item.destination,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Remark
          Text(
            item.remark,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(height: 1.4),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 8),

          // Aksi: Reject (teks, sempit) + Approve (penuh, lebar)
          Row(
            children: [
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 40,
                  child: TextButton(
                    onPressed: onReject,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.rejected,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Reject',
                      style: AppTextStyles.buttonText.copyWith(
                        color: AppColors.rejected,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check, size: 16),
                    label: Text(
                      'Approve',
                      style: AppTextStyles.buttonText.copyWith(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
