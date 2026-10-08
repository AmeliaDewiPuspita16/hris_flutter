import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_text_styles.dart';
import '../../domain/indent_approval_item.dart';
import 'indent_approval_card.dart';

/// Isi tab "Supervisor Approval": daftar request yang menunggu keputusan
/// atasan, dengan Approve/Reject langsung dari kartu.
///
/// State list-nya dipegang `IndentVehicleScreen` (parent), sama seperti
/// `IndentPendingAssignmentTab`, supaya badge jumlah di tab bar ikut update
/// begitu ada yang diputuskan.
class IndentSupervisorApprovalTab extends StatelessWidget {
  const IndentSupervisorApprovalTab({
    super.key,
    required this.items,
    required this.onApprove,
    required this.onReject,
  });

  final List<IndentApprovalItem> items;
  final ValueChanged<IndentApprovalItem> onApprove;
  final ValueChanged<IndentApprovalItem> onReject;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          'Tidak ada request yang menunggu approval',
          style: AppTextStyles.bodyMuted,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        return IndentApprovalCardAlt(
          item: item,
          onApprove: () => onApprove(item),
          onReject: () => onReject(item),
        );
      },
    );
  }
}
