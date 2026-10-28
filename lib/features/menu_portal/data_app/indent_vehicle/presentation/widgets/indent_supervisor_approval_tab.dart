import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/widgets/flash_highlight.dart';
import '../../domain/indent_approval_item.dart';
import 'indent_approval_card.dart';

/// Isi tab "Supervisor Approval": daftar request yang menunggu keputusan
/// atasan, dengan Approve/Reject langsung dari kartu.
///
/// Daftarnya dipegang `IndentApprovalBloc` (lewat `IndentVehicleScreen`),
/// jadi badge jumlah di tab bar ikut update begitu ada yang diputuskan.
/// Tarik ke bawah untuk memuat ulang; berlaku juga saat daftar kosong.
class IndentSupervisorApprovalTab extends StatelessWidget {
  const IndentSupervisorApprovalTab({
    super.key,
    required this.items,
    required this.onApprove,
    required this.onReject,
    required this.onRefresh,
    this.busyIds = const {},
    this.highlightId,
  });

  final List<IndentApprovalItem> items;
  final ValueChanged<IndentApprovalItem> onApprove;
  final ValueChanged<IndentApprovalItem> onReject;
  final Future<void> Function() onRefresh;

  /// id request yang keputusannya sedang dikirim; kartunya diredupkan dan
  /// tidak bisa disentuh sampai server membalas.
  final Set<String> busyIds;

  /// id request dari notifikasi yang di-tap; kartunya dikedipkan.
  final String? highlightId;

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
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = items[index];
                final busy = busyIds.contains(item.id);
                return FlashHighlight(
                  key: ValueKey('hl-${item.id}'),
                  active: item.id == highlightId,
                  child: Opacity(
                    opacity: busy ? 0.5 : 1,
                    child: IgnorePointer(
                      ignoring: busy,
                      child: IndentApprovalCardAlt(
                        item: item,
                        onApprove: () => onApprove(item),
                        onReject: () => onReject(item),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
