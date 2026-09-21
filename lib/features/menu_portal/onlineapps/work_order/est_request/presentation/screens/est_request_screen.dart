import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../../core/widgets/back_header.dart';
import '../../domain/est_request_demo_data.dart';
import '../../domain/est_request_item.dart';
import '../../domain/est_request_status.dart';
import '../../domain/est_work_detail.dart';
import '../widgets/est_request_feedback_banner.dart';
import '../widgets/est_request_feedback_sheet.dart';
import '../widgets/est_request_row.dart';
import '../widgets/maintenance_plan_sheet.dart';
import 'add_est_request_screen.dart';
import 'est_request_detail_screen.dart';

/// Layar "EST Work Order" — daftar SEMUA request (bukan cuma milik sendiri), plus
/// tombol Add Request yang di-gate oleh feedback yang
/// belum diselesaikan.
///
/// Tab Approve Request / List Request khusus admin EST  — fokus pada sisi requester.
class EstRequestScreen extends StatefulWidget {
  const EstRequestScreen({super.key});

  @override
  State<EstRequestScreen> createState() => _EstRequestScreenState();
}

class _EstRequestScreenState extends State<EstRequestScreen> {
  List<EstRequestItem> _items = EstRequestDemoData.items();
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<EstRequestItem> get _awaitingFeedback =>
      _items.where((r) => r.awaitingFeedback).toList();

  bool get _canAddRequest => _awaitingFeedback.isEmpty;

  List<EstRequestItem> get _filtered {
    final visible = _items.where((r) => !r.awaitingFeedback);
    if (_query.trim().isEmpty) return visible.toList();

    final q = _query.trim().toLowerCase();
    return visible.where((r) {
      return r.requesterName.toLowerCase().contains(q) ||
          r.department.toLowerCase().contains(q) ||
          r.location.toLowerCase().contains(q) ||
          r.description.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _giveFeedback(EstRequestItem item) async {
    final rating = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EstRequestFeedbackSheet(description: item.description),
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
    final newItem = await Navigator.of(context).push<EstRequestItem>(
      MaterialPageRoute(builder: (_) => const AddEstRequestScreen()),
    );

    if (newItem == null || !mounted) return;

    setState(() => _items = [newItem, ..._items]);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Request submitted')),
    );
  }

  Future<void> _onTapItem(EstRequestItem item) async {
    switch (item.status) {
      case EstRequestStatus.maintenancePlan:
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => MaintenancePlanSheet(item: item),
        );
      case EstRequestStatus.waitVerifyUser:
      case EstRequestStatus.completed:
        // Kalau requester verifikasi + kasih rating di layar detail, dia
        // pop membawa rating (1-5) — di sini itemnya langsung dianggap
        // selesai & feedback-nya sudah lunas, jadi tidak perlu gate
        // [EstRequestFeedbackBanner] lagi setelahnya.
        final rating = await Navigator.of(context).push<int>(
          MaterialPageRoute(builder: (_) => EstRequestDetailScreen(item: item)),
        );

        if (rating == null || !mounted) return;

        setState(() {
          _items = [
            for (final r in _items)
              if (r.id == item.id)
                r.copyWith(
                  status: EstRequestStatus.completed,
                  workDetail: r.workDetail == null
                      ? null
                      : EstWorkDetail(
                          duration: r.workDetail!.duration,
                          manPower: r.workDetail!.manPower,
                          approvedBy: r.workDetail!.approvedBy,
                          dateApprove: r.workDetail!.dateApprove,
                          startDate: r.workDetail!.startDate,
                          endDate: r.workDetail!.endDate,
                          workBy: r.workDetail!.workBy,
                          verification: 'Verified',
                          feedbackUser: 'Rating: $rating/5',
                        ),
                )
              else
                r,
          ];
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Terima kasih atas feedbacknya!')),
        );
      case EstRequestStatus.onWaiting:
      case EstRequestStatus.waitApprovalHod:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final results = _filtered;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: BackHeader(
        title: 'EST Work Order',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          for (final item in _awaitingFeedback) ...[
            EstRequestFeedbackBanner(
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
              EstRequestRow(item: results[i], onTap: () => _onTapItem(results[i])),
            ],
        ],
      ),
    );
  }
}
