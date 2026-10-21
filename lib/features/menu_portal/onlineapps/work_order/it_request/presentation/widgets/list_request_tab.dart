import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../domain/list_request_demo_data.dart';
import '../../domain/list_request_item.dart';
import '../../domain/list_request_status.dart';
import 'list_request_row.dart';

/// Isi tab "List Request", mengikuti web: daftar SEMUA permintaan langsung
/// terbuka, dengan dua tombol On Waiting / On Progress di atasnya yang
/// berfungsi sebagai filter.
///
/// Menekan salah satu tombol memfilter daftar ke status itu; menekannya lagi
/// (atau tombol yang aktif) mengembalikan daftar ke semua request.
///
/// Filter Month/Year/Status seperti di web belum diimplementasikan di
/// iterasi ini.
///
/// SEMENTARA: [ListRequestDemoData] statis, belum tersambung ke API.
class ListRequestTab extends StatefulWidget {
  const ListRequestTab({super.key});

  @override
  State<ListRequestTab> createState() => _ListRequestTabState();
}

class _ListRequestTabState extends State<ListRequestTab> {
  final List<ListRequestItem> _items = ListRequestDemoData.items();

  /// Null = semua request.
  ListRequestStatus? _filter;

  int _countOf(ListRequestStatus status) =>
      _items.where((i) => i.status == status).length;

  /// Tekan tombol yang belum aktif -> filter ke status itu; tekan yang sudah
  /// aktif -> kembali ke semua.
  void _toggleFilter(ListRequestStatus status) {
    setState(() => _filter = _filter == status ? null : status);
  }

  @override
  Widget build(BuildContext context) {
    final shown = _filter == null
        ? _items
        : _items.where((i) => i.status == _filter).toList();
    final title = _filter == null ? 'All Requests' : _filter!.label;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: _StatusButton(
                label: ListRequestStatus.onWaiting.label,
                count: _countOf(ListRequestStatus.onWaiting),
                color: AppColors.pending,
                background: AppColors.pendingBg,
                active: _filter == ListRequestStatus.onWaiting,
                onTap: () => _toggleFilter(ListRequestStatus.onWaiting),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatusButton(
                label: ListRequestStatus.onProgress.label,
                count: _countOf(ListRequestStatus.onProgress),
                color: AppColors.present,
                background: AppColors.presentBg,
                active: _filter == ListRequestStatus.onProgress,
                onTap: () => _toggleFilter(ListRequestStatus.onProgress),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('$title (${shown.length})', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 10),
        if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Center(
              child: Text('No data', style: AppTextStyles.bodyMuted),
            ),
          )
        else
          for (var i = 0; i < shown.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            ListRequestRow(
              item: shown[i],
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Details are not available yet')),
              ),
            ),
          ],
      ],
    );
  }
}

/// Tombol filter status dengan jumlah di kanan (seperti tombol "On Waiting 8"
/// di web). Saat aktif, bingkainya menebal dan latarnya terisi warna status.
class _StatusButton extends StatelessWidget {
  const _StatusButton({
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: active ? background : AppColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color, width: active ? 1.8 : 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
