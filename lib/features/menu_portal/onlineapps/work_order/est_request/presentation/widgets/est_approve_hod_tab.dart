import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_text_styles.dart';
import '../../domain/est_request_item.dart';
import 'est_approve_hod_card.dart';

/// Isi tab "Approve HOD": daftar request EST yang rencana kerjanya sudah
/// disusun tim EST ([EstRequestStatus.waitApprovalHod]) dan menunggu
/// keputusan HOD, dengan approve/reject langsung dari kartu.
///
/// State list-nya dipegang [EstRequestScreen] (parent), bukan di sini,
/// supaya badge jumlah di tab bar ikut update begitu ada yang diputuskan.
class EstApproveHodTab extends StatelessWidget {
  const EstApproveHodTab({
    super.key,
    required this.items,
    required this.onApprove,
    required this.onReject,
  });

  final List<EstRequestItem> items;
  final ValueChanged<EstRequestItem> onApprove;
  final ValueChanged<EstRequestItem> onReject;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          'Tidak ada request yang menunggu approval HOD',
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
        return EstApproveHodCard(
          item: item,
          onApprove: () => onApprove(item),
          onReject: () => onReject(item),
        );
      },
    );
  }
}
