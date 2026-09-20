import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_text_styles.dart';
import '../../domain/approve_request_item.dart';
import 'approve_request_card.dart';

/// Isi tab "Approve Request": daftar permintaan yang menunggu keputusan
/// tim IT, dengan approve/reject langsung dari kartu (tanpa buka detail).
///
/// State list-nya dipegang oleh [ItRequestScreen] (parent), bukan di sini —
/// supaya badge jumlah di tab bar ikut update begitu ada yang diputuskan.
class ApproveRequestTab extends StatelessWidget {
  const ApproveRequestTab({
    super.key,
    required this.items,
    required this.onApprove,
    required this.onReject,
  });

  final List<ApproveRequestItem> items;
  final ValueChanged<ApproveRequestItem> onApprove;
  final ValueChanged<ApproveRequestItem> onReject;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          'Tidak ada permintaan yang menunggu',
          style: AppTextStyles.bodyMuted,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        return ApproveRequestCard(
          item: item,
          onApprove: () => onApprove(item),
          onReject: () => onReject(item),
        );
      },
    );
  }
}