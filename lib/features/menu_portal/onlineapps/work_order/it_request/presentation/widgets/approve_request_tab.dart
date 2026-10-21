import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_text_styles.dart';
import '../../domain/approve_request_item.dart';
import 'approve_request_card.dart';

/// Isi tab "Approve Request": daftar permintaan IT/Media yang menunggu
/// keputusan, dengan approve/reject langsung dari kartu (padanan tab
/// "Approve Request" di web: Name, Department, Support Type, Description,
/// dan tombol aksi).
///
/// State list-nya dipegang [ItRequestScreen] (parent), bukan di sini,
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
          'No requests waiting for approval',
          style: AppTextStyles.bodyMuted,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 16, 8),
          child: Text(
            '${items.length} ${items.length == 1 ? 'request' : 'requests'} waiting for approval',
            style: AppTextStyles.label,
          ),
        ),
        Expanded(
          child: ListView.separated(
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
          ),
        ),
      ],
    );
  }
}
