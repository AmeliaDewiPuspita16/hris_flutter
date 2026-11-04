import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_text_styles.dart';
import '../../domain/stationery_request_item.dart';
import 'stationery_verification_card.dart';

/// Isi tab "Verification": antrean request stationery yang menunggu
/// keputusan. State-nya dipegang `StationeryVerificationBloc` di layar induk
/// supaya badge jumlah di tab bar ikut berubah begitu ada yang diputuskan.
class StationeryVerificationTab extends StatelessWidget {
  const StationeryVerificationTab({
    super.key,
    required this.items,
    required this.pending,
    required this.onApprove,
    required this.onReject,
    required this.onRefresh,
    this.busyIds = const {},
  });

  final List<StationeryRequestItem> items;

  /// Total antrean dari server (`summary.pending`) — bisa lebih besar dari
  /// [items] bila sedang disaring pencarian.
  final int pending;

  final ValueChanged<StationeryRequestItem> onApprove;
  final ValueChanged<StationeryRequestItem> onReject;
  final RefreshCallback onRefresh;

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
                    'No requests waiting for verification',
                    style: AppTextStyles.bodyMuted,
                  ),
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              // +1 untuk baris keterangan jumlah di atas.
              itemCount: items.length + 1,
              separatorBuilder: (_, index) =>
                  SizedBox(height: index == 0 ? 0 : 10),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(2, 0, 0, 8),
                    child: Text(
                      '$pending ${pending == 1 ? 'request' : 'requests'} waiting for verification',
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
                    child: StationeryVerificationCard(
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
