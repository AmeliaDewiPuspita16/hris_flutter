import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_text_styles.dart';
import '../../domain/indent_pending_item.dart';
import 'indent_pending_card.dart';

/// Isi tab "Pending Vehicle Assignment": daftar request yang belum
/// ditetapkan kendaraannya, masing-masing dengan tombol Assign.
///
/// State list-nya dipegang `IndentVehicleScreen` (parent), bukan di sini —
/// sama seperti `EstApproveHodTab` — supaya hasil search dan penghapusan
/// baris setelah assign dikelola di satu tempat.
class IndentPendingAssignmentTab extends StatelessWidget {
  const IndentPendingAssignmentTab({
    super.key,
    required this.items,
    required this.onAssign,
  });

  final List<IndentPendingItem> items;
  final ValueChanged<IndentPendingItem> onAssign;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          'Tidak ada request yang menunggu kendaraan',
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
        return IndentPendingCard(item: item, onAssign: () => onAssign(item));
      },
    );
  }
}
