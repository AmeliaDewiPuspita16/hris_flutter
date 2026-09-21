import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../domain/it_request_demo_data.dart';
import '../../domain/it_request_item.dart';
import '../screens/add_it_request_screen.dart';
import 'it_request_card.dart';
import 'it_request_feedback_banner.dart';
import 'it_request_feedback_sheet.dart';

/// Isi tab "Form IT & Media": tombol ajukan request (di-gate oleh feedback
/// yang belum diselesaikan) + daftar SEMUA permintaan (bukan cuma riwayat
/// sendiri) dengan pencarian — sama polanya dengan tab "All Request" di
/// `EstRequestScreen`, mengikuti tabel penuh yang sama di versi web.
///
/// Dipakai baik sebagai body utuh untuk staff biasa (tanpa tab) maupun
/// sebagai tab pertama untuk tim IT.
class ItFormAndMediaTab extends StatefulWidget {
  const ItFormAndMediaTab({super.key});

  @override
  State<ItFormAndMediaTab> createState() => _ItFormAndMediaTabState();
}

class _ItFormAndMediaTabState extends State<ItFormAndMediaTab> {
  List<ItRequestItem> _items = ItRequestDemoData.items();
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ItRequestItem> get _awaitingFeedback =>
      _items.where((r) => r.awaitingFeedback).toList();

  bool get _canAddRequest => _awaitingFeedback.isEmpty;

  List<ItRequestItem> get _filtered {
    final visible = _items.where((r) => !r.awaitingFeedback);
    if (_query.trim().isEmpty) return visible.toList();

    final q = _query.trim().toLowerCase();
    return visible.where((r) {
      return r.requesterName.toLowerCase().contains(q) ||
          r.department.toLowerCase().contains(q) ||
          r.description.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _giveFeedback(ItRequestItem item) async {
    final rating = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ItRequestFeedbackSheet(description: item.description),
    );

    if (rating == null || !mounted) return;

    setState(() {
      _items = [
        for (final r in _items)
          if (r.id == item.id) r.copyWith(awaitingFeedback: false) else r,
      ];
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Terima kasih atas feedbacknya!')),
    );
  }

  Future<void> _addRequest() async {
    final newItem = await Navigator.of(context).push<ItRequestItem>(
      MaterialPageRoute(builder: (_) => const AddItRequestScreen()),
    );

    if (newItem == null || !mounted) return;

    setState(() => _items = [newItem, ..._items]);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Request submitted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final results = _filtered;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        for (final item in _awaitingFeedback) ...[
          ItRequestFeedbackBanner(
            item: item,
            onGiveFeedback: () => _giveFeedback(item),
          ),
          const SizedBox(height: 12),
        ],
        if (_canAddRequest)
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: _addRequest,
              icon: const Icon(Icons.add, size: 18),
              label: Text('Add Request', style: AppTextStyles.buttonText),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.accentBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_outline, size: 16, color: AppColors.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Selesaikan feedback di atas dulu untuk membuka '
                    'pengajuan baru.',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.text,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _query = v),
          style: AppTextStyles.body,
          decoration: InputDecoration(
            hintText: 'Search request...',
            hintStyle: AppTextStyles.body.copyWith(color: AppColors.textMuted),
            prefixIcon: const Icon(Icons.search, size: 19, color: AppColors.textMuted),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 4),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primaryMid, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (results.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Center(
              child: Text('Tidak ada data', style: AppTextStyles.bodyMuted),
            ),
          )
        else
          for (var i = 0; i < results.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            ItRequestCard(item: results[i]),
          ],
      ],
    );
  }
}
