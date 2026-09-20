import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../domain/list_request_demo_data.dart';
import '../../domain/list_request_item.dart';
import '../../domain/list_request_status.dart';
import 'list_request_row.dart';

/// Isi tab "List Request": dua counter On Waiting / On Progress yang juga
/// berfungsi sebagai filter (mengikuti dua "tab" berwarna di versi web),
/// lalu daftar permintaan sesuai filter yang aktif.
///
/// Filter Month/Year/Status seperti di web belum diimplementasikan di
/// iterasi ini — cuma dua counter utamanya dulu.
class ListRequestTab extends StatefulWidget {
  const ListRequestTab({super.key});

  @override
  State<ListRequestTab> createState() => _ListRequestTabState();
}

class _ListRequestTabState extends State<ListRequestTab> {
  final List<ListRequestItem> _items = ListRequestDemoData.items();
  ListRequestStatus _filter = ListRequestStatus.onWaiting;

  @override
  Widget build(BuildContext context) {
    final onWaitingCount =
        _items.where((i) => i.status == ListRequestStatus.onWaiting).length;
    final onProgressCount =
        _items.where((i) => i.status == ListRequestStatus.onProgress).length;
    final filtered = _items.where((i) => i.status == _filter).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: _CounterChip(
                label: 'On Waiting',
                count: onWaitingCount,
                color: AppColors.pending,
                background: AppColors.pendingBg,
                active: _filter == ListRequestStatus.onWaiting,
                onTap: () => setState(() => _filter = ListRequestStatus.onWaiting),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _CounterChip(
                label: 'On Progress',
                count: onProgressCount,
                color: AppColors.present,
                background: AppColors.presentBg,
                active: _filter == ListRequestStatus.onProgress,
                onTap: () => setState(() => _filter = ListRequestStatus.onProgress),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Center(
              child: Text('Tidak ada data', style: AppTextStyles.bodyMuted),
            ),
          )
        else
          for (var i = 0; i < filtered.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            ListRequestRow(
              item: filtered[i],
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Detail belum tersedia')),
              ),
            ),
          ],
      ],
    );
  }
}

class _CounterChip extends StatelessWidget {
  const _CounterChip({
    required this.label,
    required this.count,
    required this.color,
    required this.background,
    required this.active,
    required this.onTap,
  });

  final String label;
  final int count;
  final Color color;
  final Color background;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? color : Colors.transparent,
            width: 1.4,
          ),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textMid)),
          ],
        ),
      ),
    );
  }
}
