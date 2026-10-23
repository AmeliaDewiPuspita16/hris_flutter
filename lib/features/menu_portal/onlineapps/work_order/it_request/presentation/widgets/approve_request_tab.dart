import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_text_styles.dart';
import '../../domain/approve_request_item.dart';
import 'approve_request_card.dart';

/// Isi tab "Approve Request": antrean HOD — request IT/Media dari
/// department-nya yang menunggu keputusan, dengan approve/reject langsung
/// dari kartu (padanan tab "Approve Request" di web: Name, Department,
/// Support Type, Description, dan tombol aksi).
///
/// State list-nya dipegang `ItRequestApprovalBloc` di [ItRequestScreen]
/// (parent), bukan di sini, supaya badge jumlah di tab bar ikut update
/// begitu ada yang diputuskan.
class ApproveRequestTab extends StatelessWidget {
  const ApproveRequestTab({
    super.key,
    required this.items,
    required this.onApprove,
    required this.onReject,
    required this.onRefresh,
    required this.pending,
    this.busyIds = const {},
  });

  final List<ApproveRequestItem> items;
  final ValueChanged<ApproveRequestItem> onApprove;
  final ValueChanged<ApproveRequestItem> onReject;
  final RefreshCallback onRefresh;

  /// Total antrean dari server (`summary.pending`) — bisa lebih besar dari
  /// [items] kalau antreannya melebihi satu halaman.
  final int pending;

  /// id request yang keputusannya sedang dikirim; kartunya dikunci.
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
                    'No requests waiting for approval',
                    style: AppTextStyles.bodyMuted,
                  ),
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
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
                    child: ApproveRequestCard(
                      item: item,
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
