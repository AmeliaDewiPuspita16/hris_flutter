import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_text_styles.dart';
import '../../domain/est_approval_item.dart';
import 'est_approve_hod_card.dart';

/// Isi tab "Approve HOD": antrean request EST dari department HOD yang
/// menunggu keputusan. Approve/reject bisa langsung dari kartu, atau
/// setelah membuka detail lewat [onOpenDetail].
///
/// State list-nya dipegang `EstApprovalBloc` di [EstRequestScreen]
/// (parent), bukan di sini, supaya badge jumlah di tab bar ikut update
/// begitu ada yang diputuskan.
class EstApproveHodTab extends StatelessWidget {
  const EstApproveHodTab({
    super.key,
    required this.items,
    required this.pending,
    required this.onOpenDetail,
    required this.onApprove,
    required this.onReject,
    required this.onRefresh,
    this.busyIds = const {},
  });

  final List<EstApprovalItem> items;

  /// Total antrean dari server (`summary.pending`) — bisa lebih besar dari
  /// [items] kalau antreannya melebihi satu halaman.
  final int pending;

  final ValueChanged<EstApprovalItem> onOpenDetail;
  final ValueChanged<EstApprovalItem> onApprove;
  final ValueChanged<EstApprovalItem> onReject;
  final RefreshCallback onRefresh;

  /// id request yang keputusannya sedang dikirim; kartunya dikunci supaya
  /// Approve/Reject tidak terkirim dua kali.
  final Set<int> busyIds;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: items.isEmpty
          // ListView (bukan Center saja) supaya tarik-untuk-refresh tetap
          // bisa dipakai saat daftar kosong.
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 120),
                Center(
                  child: Text(
                    'No requests waiting for HOD approval',
                    style: AppTextStyles.bodyMuted,
                  ),
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              // +1 untuk baris keterangan jumlah di atas, supaya ikut
              // ter-scroll bersama kartu.
              itemCount: items.length + 1,
              separatorBuilder: (_, index) =>
                  SizedBox(height: index == 0 ? 0 : 10),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(2, 0, 0, 8),
                    child: Text(
                      '$pending ${pending == 1 ? 'request' : 'requests'} waiting for approval',
                      style: AppTextStyles.label,
                    ),
                  );
                }

                final item = items[index - 1];
                final busy = busyIds.contains(item.id);
                return Opacity(
                  opacity: busy ? 0.5 : 1,
                  child: IgnorePointer(
                    ignoring: busy,
                    child: EstApproveHodCard(
                      item: item,
                      onTap: () => onOpenDetail(item),
                      onApprove: () => onApprove(item),
                      onReject: () => onReject(item),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
