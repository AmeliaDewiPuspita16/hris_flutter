import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../../core/widgets/back_header.dart';
import '../../domain/est_request_demo_data.dart';
import '../../domain/est_request_item.dart';
import '../../domain/est_request_status.dart';
import '../../domain/est_work_detail.dart';
import '../widgets/est_approve_hod_tab.dart';
import '../widgets/est_request_feedback_banner.dart';
import '../widgets/est_request_feedback_sheet.dart';
import '../widgets/est_request_row.dart';
import '../widgets/est_request_tab_bar.dart';
import '../widgets/maintenance_plan_sheet.dart';
import 'add_est_request_screen.dart';
import 'est_request_detail_screen.dart';

/// Layar "EST Work Order" — daftar SEMUA request (bukan cuma milik sendiri), plus
/// tombol Add Request yang di-gate oleh feedback yang
/// belum diselesaikan.
///
/// SEMENTARA: pembagian requester vs HOD masih lewat flag [isHod] lokal,
/// sama seperti catatan [isItTeam] di `ItRequestScreen` — pemetaan role asli
/// belum diputuskan.
///
/// - Requester biasa (`isHod: false`): cuma daftar All Request, tanpa tab —
///   perilakunya persis seperti sebelum tab HOD ditambahkan.
/// - HOD (`isHod: true`): tab All Request / Approve HOD, mengikuti pola
///   Form IT & Media / Approve Request di `ItRequestScreen`.
class EstRequestScreen extends StatefulWidget {
  const EstRequestScreen({
    super.key,
    this.isHod = true,
    this.initialTabIndex = 0,
  });

  final bool isHod;

  /// Tab yang aktif saat layar ini dibuka (0 All Request, 1 Approve HOD).
  /// Dipakai tag "EST" di banner approval Beranda untuk masuk langsung ke
  /// tab Approve HOD. Diabaikan kalau [isHod] false.
  final int initialTabIndex;

  @override
  State<EstRequestScreen> createState() => _EstRequestScreenState();
}

class _EstRequestScreenState extends State<EstRequestScreen> {
  late int _tabIndex = widget.initialTabIndex;

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

  List<EstRequestItem> get _pendingHodApproval =>
      _items.where((r) => r.status == EstRequestStatus.waitApprovalHod).toList();

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

  /// Approve naikkan status ke [EstRequestStatus.maintenancePlan] supaya
  /// requester langsung bisa lihat rencana kerja (tombol "Maintenance
  /// Plan" di baris All Request). Reject dikembalikan ke [onWaiting] —
  /// EST-nya masih ada, cuma rencana kerjanya perlu disusun ulang, jadi
  /// tidak dihapus dari daftar seperti pola hapus di IT Request.
  void _decideHod(EstRequestItem item, {required bool approved}) {
    setState(() {
      _items = [
        for (final r in _items)
          if (r.id == item.id)
            r.copyWith(
              status: approved
                  ? EstRequestStatus.maintenancePlan
                  : EstRequestStatus.onWaiting,
            )
          else
            r,
      ];
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          approved
              ? 'Rencana kerja untuk ${item.requesterName} disetujui'
              : 'Rencana kerja untuk ${item.requesterName} dikembalikan ke tim EST',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: BackHeader(
        title: 'EST Work Order',
        onBack: () => Navigator.of(context).pop(),
      ),
      // FAB oranye di kanan-bawah, sama pola dengan IT Request & HSE Work
      // Request — menggantikan tombol "Add Request" full-width yang
      // sebelumnya ada di atas list. Disembunyikan (bukan didisable) saat
      // requester masih punya feedback tertunda; alasannya dijelaskan lewat
      // banner kunci di dalam list (lihat _buildAllRequestList).
      floatingActionButton: _canAddRequest
          ? FloatingActionButton(
              onPressed: _addRequest,
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
              tooltip: 'Add Request',
              child: const Icon(Icons.add),
            )
          : null,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Search dipindah ke atas (fixed, di luar area scroll) dan tab
            // "All Request"/"Approve HOD" ditaruh di bawahnya — mengikuti
            // urutan search-lalu-filter di HseWorkRequestListScreen.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                  if (widget.isHod) ...[
                    const SizedBox(height: 12),
                    EstRequestTabBar(
                      labels: const ['All Request', 'Approve HOD'],
                      activeIndex: _tabIndex,
                      badgeCounts: {1: _pendingHodApproval.length},
                      onChanged: (i) => setState(() => _tabIndex = i),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: widget.isHod ? _buildHodTabs() : _buildAllRequestList(),
            ),
          ],
        ),
      ),
    );
  }

  /// IndexedStack menjaga tab All Request tetap "hidup" di belakang layar
  /// saat pindah ke Approve HOD, jadi posisi scroll & isi pencarian tidak
  /// reset — sama seperti alasan IndexedStack di ItRequestScreen.
  Widget _buildHodTabs() {
    final tabs = [
      _buildAllRequestList(),
      EstApproveHodTab(
        items: _pendingHodApproval,
        onApprove: (item) => _decideHod(item, approved: true),
        onReject: (item) => _decideHod(item, approved: false),
      ),
    ];

    return IndexedStack(index: _tabIndex, children: tabs);
  }

  Widget _buildAllRequestList() {
    final results = _filtered;

    return ListView(
      // Padding bawah ekstra (88) supaya baris terakhir tidak tertutup FAB
      // "Add Request" yang mengambang, sama seperti di HSE.
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
      children: [
        for (final item in _awaitingFeedback) ...[
          EstRequestFeedbackBanner(
            item: item,
            onGiveFeedback: () => _giveFeedback(item),
          ),
          const SizedBox(height: 12),
        ],
        if (!_canAddRequest) ...[
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
        ],
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
    );
  }
}
