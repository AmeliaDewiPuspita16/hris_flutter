import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_text_styles.dart';
import '../../domain/indent_my_request_item.dart';
import 'indent_my_request_card.dart';

/// Isi tab "My Request": daftar request milik user yang login. Daftarnya
/// dipegang `IndentMyRequestBloc` (lewat `IndentVehicleScreen`). Tarik ke
/// bawah untuk memuat ulang; berlaku juga saat daftar kosong.
class IndentMyRequestTab extends StatelessWidget {
  const IndentMyRequestTab({
    super.key,
    required this.items,
    required this.onRefresh,
    this.isFiltered = false,
  });

  final List<IndentMyRequestItem> items;
  final Future<void> Function() onRefresh;

  /// True bila daftar kosong karena pencarian, bukan karena belum ada
  /// request; pesannya dibedakan.
  final bool isFiltered;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: items.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 120),
                Center(
                  child: Text(
                    isFiltered ? 'No data' : "You haven't made any requests yet",
                    style: AppTextStyles.bodyMuted,
                  ),
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              // Padding bawah ekstra (88) supaya kartu terakhir tidak
              // tertutup FAB.
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) =>
                  IndentMyRequestCard(item: items[index]),
            ),
    );
  }
}
