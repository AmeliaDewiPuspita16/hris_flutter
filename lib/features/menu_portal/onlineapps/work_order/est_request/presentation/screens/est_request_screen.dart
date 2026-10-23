import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../../core/widgets/app_error_view.dart';
import '../../../../../../../core/widgets/back_header.dart';
import '../../../../../../auth/presentation/bloc/auth/auth_bloc.dart';
import '../../data/est_request_repository.dart';
import '../../domain/est_approval_item.dart';
import '../../domain/est_request_demo_data.dart';
import '../../domain/est_request_item.dart';
import '../../domain/est_request_status.dart';
import '../../domain/est_work_detail.dart';
import '../bloc/approval/est_approval_bloc.dart';
import '../bloc/approval/est_approval_event.dart';
import '../bloc/approval/est_approval_state.dart';
import '../widgets/est_approval_detail_sheet.dart';
import '../widgets/est_approve_hod_tab.dart';
import '../widgets/est_decision_dialog.dart';
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
/// Pembagian requester vs HOD mengikuti role `hod` user yang login (lewat
/// `AuthBloc`), sama seperti `ItRequestScreen`.
///
/// - Requester biasa (`isHod: false`): cuma daftar All Request, tanpa tab —
///   perilakunya persis seperti sebelum tab HOD ditambahkan.
/// - HOD (`isHod: true`): tab All Request / Approve HOD, mengikuti pola
///   Form IT & Media / Approve Request di `ItRequestScreen`.
class EstRequestScreen extends StatefulWidget {
  const EstRequestScreen({
    super.key,
    this.isHod,
    this.initialTabIndex = 0,
  });

  /// Null berarti dihitung dari role `hod` user yang sedang login lewat
  /// [AuthBloc]. Diisi test untuk override tanpa perlu `AuthBloc` sungguhan.
  final bool? isHod;

  /// Tab yang aktif saat layar ini dibuka (0 All Request, 1 Approve HOD).
  /// Dipakai tag "EST" di banner approval Beranda untuk masuk langsung ke
  /// tab Approve HOD. Diabaikan kalau bukan HOD.
  final int initialTabIndex;

  @override
  State<EstRequestScreen> createState() => _EstRequestScreenState();
}

class _EstRequestScreenState extends State<EstRequestScreen> {
  late int _tabIndex = widget.initialTabIndex;

  List<EstRequestItem> _items = EstRequestDemoData.items();
  final _searchController = TextEditingController();
  String _query = '';

  // Antrean approval milik HOD. Hanya dimulai untuk akun berperan `hod`.
  late final EstApprovalBloc _approvalBloc;
  late final bool _isHod;

  @override
  void initState() {
    super.initState();
    // AuthBloc hanya dibaca bila isHod tidak di-override.
    final user = widget.isHod == null
        ? context.read<AuthBloc>().state.session?.user
        : null;
    _isHod = widget.isHod ?? user?.hasRole('hod') ?? false;

    _approvalBloc = EstApprovalBloc(
      repository: context.read<EstRequestRepository>(),
    );
    if (_isHod) _approvalBloc.add(const EstApprovalStarted());
  }

  @override
  void dispose() {
    _approvalBloc.close();
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
      const SnackBar(content: Text('Thank you for your feedback!')),
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
          const SnackBar(content: Text('Thank you for your feedback!')),
        );
      case EstRequestStatus.onWaiting:
      case EstRequestStatus.waitApprovalHod:
        break;
    }
  }

  /// Buka detail request dari tab Approve HOD. Sheet-nya pop `true`
  /// (Approve) / `false` (Reject) / `null` (ditutup saja), lalu keputusannya
  /// diteruskan ke [_decide] — jalur yang sama dengan tombol di kartu.
  Future<void> _openApprovalDetail(EstApprovalItem item) async {
    final approved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EstApprovalDetailSheet(item: item),
    );

    if (approved == null || !mounted) return;
    // Approve dari sheet sudah lewat satu ketukan yang disengaja setelah
    // membaca detail, jadi dialog konfirmasi dilewati. Reject tetap
    // menampilkan dialog karena sekalian menanyakan alasan.
    await _decide(item, approved: approved, confirm: false);
  }

  /// Keputusan HOD, dikirim ke server lewat [EstApprovalBloc]. Approve dari
  /// kartu ada dialog konfirmasi dulu karena tidak bisa dibatalkan dari
  /// aplikasi; Reject sekalian menanyakan alasan opsional.
  Future<void> _decide(
    EstApprovalItem item, {
    required bool approved,
    bool confirm = true,
  }) async {
    String? reason;

    if (approved) {
      if (confirm) {
        if (!await showEstApproveDialog(context, item)) return;
      }
    } else {
      reason = await showEstRejectDialog(context, item);
      if (reason == null) return;
    }

    if (!mounted) return;
    _approvalBloc.add(EstApprovalDecided(
      item: item,
      approved: approved,
      reason: reason,
    ));
  }

  /// Tarik-untuk-refresh tab approval.
  Future<void> _refreshApprovals() async {
    if (!_isHod) return;

    _approvalBloc.add(const EstApprovalRefreshed());
    await _approvalBloc.stream
        .firstWhere((s) => s.status != EstApprovalStatus.loading);
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
                  if (_isHod) ...[
                    const SizedBox(height: 12),
                    BlocBuilder<EstApprovalBloc, EstApprovalState>(
                      bloc: _approvalBloc,
                      buildWhen: (previous, current) =>
                          previous.pending != current.pending,
                      builder: (context, state) => EstRequestTabBar(
                        labels: const ['All Request', 'Approve HOD'],
                        activeIndex: _tabIndex,
                        badgeCounts: {1: state.pending},
                        onChanged: (i) => setState(() => _tabIndex = i),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: _isHod ? _buildHodTabs() : _buildAllRequestList(),
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
      _buildApprovalTab(),
    ];

    return IndexedStack(index: _tabIndex, children: tabs);
  }

  /// BlocConsumer (bukan BlocBuilder) karena selain menggambar daftar, tab
  /// ini juga menampilkan snackbar hasil keputusan. IndexedStack membangun
  /// semua tab, jadi snackbar tetap muncul walau HOD sedang di All Request.
  Widget _buildApprovalTab() {
    return BlocConsumer<EstApprovalBloc, EstApprovalState>(
      bloc: _approvalBloc,
      listenWhen: (previous, current) =>
          current.notice != null &&
          !identical(previous.notice, current.notice),
      listener: (context, state) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.notice!.message)),
        );
      },
      builder: (context, state) {
        if (state.isFirstLoad) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.status == EstApprovalStatus.failure) {
          return AppErrorView(
            message: state.errorMessage ?? 'Failed to load the approval list.',
            onRetry: () => _approvalBloc.add(const EstApprovalRefreshed()),
          );
        }

        return EstApproveHodTab(
          items: state.items,
          pending: state.pending,
          busyIds: state.busyIds,
          onRefresh: _refreshApprovals,
          onOpenDetail: _openApprovalDetail,
          onApprove: (item) => _decide(item, approved: true),
          onReject: (item) => _decide(item, approved: false),
        );
      },
    );
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
                    'Complete the feedback above first to open '
                    'a new request.',
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
              child: Text('No data', style: AppTextStyles.bodyMuted),
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
