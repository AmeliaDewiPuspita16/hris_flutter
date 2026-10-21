import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_text_styles.dart';
import '../../domain/indent_pending_item.dart';
import 'indent_pending_card.dart';

/// Isi tab "Pending Vehicle Assignment": daftar request yang belum
/// ditetapkan kendaraannya, masing-masing dengan tombol Assign.
///
/// Daftarnya dipegang 'IndentPendingBloc' (lewat `IndentVehicleScreen`),
/// jadi badge jumlah di tab bar ikut update begitu ada yang di-assign.
/// Tarik ke bawah untuk memuat ulang; berlaku juga saat daftar kosong.
class IndentPendingAssignmentTab extends StatelessWidget {
  const IndentPendingAssignmentTab({
    super.key,
    required this.items,
    required this.onAssign,
    required this.onRefresh,
    this.busyIds = const {},
  });

  final List<IndentPendingItem> items;
  final ValueChanged<IndentPendingItem> onAssign;
  final Future<void> Function() onRefresh;

  /// id request yang penugasannya sedang dikirim; kartunya diredupkan dan
  /// tidak bisa disentuh sampai server membalas.
  final Set<String> busyIds;

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
                    'No requests waiting for a vehicle',
                    style: AppTextStyles.bodyMuted,
                  ),
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = items[index];
                final busy = busyIds.contains(item.id);
                return Opacity(
                  opacity: busy ? 0.5 : 1,
                  child: IgnorePointer(
                    ignoring: busy,
                    child: IndentPendingCard(
                      item: item,
                      onAssign: () => onAssign(item),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
