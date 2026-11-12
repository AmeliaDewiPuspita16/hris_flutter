import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_text_styles.dart';
import '../../domain/item_request_entry.dart';
import 'item_request_empty_state.dart';
import 'item_request_verification_card.dart';

/// Isi tab "Verification": antrean item request yang menunggu
/// keputusan. State-nya dipegang `ItemRequestVerificationBloc` di layar induk
/// supaya badge jumlah di tab bar ikut berubah begitu ada yang diputuskan.
class ItemRequestVerificationTab extends StatelessWidget {
  const ItemRequestVerificationTab({
    super.key,
    required this.items,
    required this.pending,
    required this.onApprove,
    required this.onReject,
    required this.onRefresh,
    this.onOpen,
    this.busyIds = const {},
    this.loadingMore = false,
  });

  final List<ItemRequestEntry> items;

  /// Total antrean dari server (`pending-count`) — bisa lebih besar dari
  /// [items] bila belum semua halaman termuat atau sedang mencari.
  final int pending;

  final ValueChanged<ItemRequestEntry> onApprove;
  final ValueChanged<ItemRequestEntry> onReject;
  final RefreshCallback onRefresh;

  /// Ketuk kartu: buka halaman detail request itu.
  final ValueChanged<ItemRequestEntry>? onOpen;

  /// id request yang keputusannya sedang dikirim; kartunya dikunci.
  final Set<int> busyIds;

  /// Sedang memuat halaman berikutnya: indikator kecil di dasar daftar.
  final bool loadingMore;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: items.isEmpty
          // ListView (bukan Center saja) supaya tarik-untuk-refresh tetap
          // bisa dipakai saat daftar kosong.
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                ItemRequestEmptyState(
                  icon: Icons.fact_check_outlined,
                  title: 'All caught up',
                  message: 'No requests are waiting for verification.',
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              // +1 untuk baris keterangan jumlah di atas, +1 untuk indikator
              // halaman berikutnya.
              itemCount: items.length + 1 + (loadingMore ? 1 : 0),
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

                if (index == items.length + 1) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }

                final item = items[index - 1];
                final busy = busyIds.contains(item.id);
                return Opacity(
                  opacity: busy ? 0.5 : 1,
                  child: IgnorePointer(
                    ignoring: busy,
                    child: ItemRequestVerificationCard(
                      item: item,
                      onApprove: () => onApprove(item),
                      onReject: () => onReject(item),
                      onTap: onOpen == null ? null : () => onOpen!(item),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
