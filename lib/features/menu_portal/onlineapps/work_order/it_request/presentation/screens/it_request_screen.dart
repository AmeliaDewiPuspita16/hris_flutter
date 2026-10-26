import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/widgets/app_error_view.dart';
import '../../../../../../../core/widgets/app_shimmer.dart';
import '../../../../../../../core/widgets/back_header.dart';
import '../../../../../../auth/presentation/bloc/auth/auth_bloc.dart';
import '../../data/it_request_repository.dart';
import '../../domain/approve_request_item.dart';
import '../bloc/approval/it_request_approval_bloc.dart';
import '../bloc/approval/it_request_approval_event.dart';
import '../bloc/approval/it_request_approval_state.dart';
import '../widgets/approve_request_tab.dart';
import '../widgets/it_form_and_media_tab.dart';
import '../widgets/it_request_reject_dialog.dart';
import '../widgets/it_request_tab_bar.dart';
import '../widgets/list_request_tab.dart';
import '../widgets/report_tab.dart';

/// Tab-tab di [ItRequestScreen], urut sama dengan web.
enum ItRequestTab {
  form('Form IT & Media'),
  approve('Approve Request'),
  list('List Request'),
  report('Report');

  const ItRequestTab(this.label);

  final String label;
}

/// Halaman IT Request.
///
/// Tab yang tampil tergantung role:
/// - `hod`: Approve Request — antrean request dari department-nya.
/// - `it media` / `admin` (lihat `AuthUser.canManageItRequest`): List
///   Request dan Report.
/// - Form IT & Media selalu ada. Kalau hanya itu yang tampil (bukan HOD,
///   bukan tim IT), halaman tampil tanpa tab bar.
class ItRequestScreen extends StatefulWidget {
  const ItRequestScreen({
    super.key,
    this.isItTeam,
    this.isHod,
    this.initialTab = ItRequestTab.form,
  });

  /// Null berarti dihitung dari role user yang sedang login lewat
  /// [AuthBloc] (`AuthUser.canManageItRequest`). Diisi test untuk override
  /// tanpa perlu menyediakan `AuthBloc` sungguhan.
  final bool? isItTeam;

  /// Null berarti dihitung dari role `hod` user yang sedang login lewat
  /// [AuthBloc]. Diisi test untuk override, sama seperti [isItTeam].
  final bool? isHod;

  /// Tab yang aktif saat layar ini dibuka. Kalau tab itu tidak tampil
  /// untuk role user, jatuh ke Form IT & Media.
  final ItRequestTab initialTab;

  @override
  State<ItRequestScreen> createState() => _ItRequestScreenState();
}

class _ItRequestScreenState extends State<ItRequestScreen> {
  late final List<ItRequestTab> _tabs;
  late int _tabIndex;

  // Hanya dimulai untuk akun berperan `hod` — antrean approval milik HOD.
  late final ItRequestApprovalBloc _approvalBloc;
  late final bool _isHod;

  @override
  void initState() {
    super.initState();
    // AuthBloc hanya dibaca bila ada yang tidak di-override, supaya test
    // yang mengisi keduanya tidak perlu menyediakan AuthBloc.
    final user = widget.isItTeam == null || widget.isHod == null
        ? context.read<AuthBloc>().state.session?.user
        : null;
    final isItTeam = widget.isItTeam ?? user?.canManageItRequest ?? false;
    _isHod = widget.isHod ?? user?.hasRole('hod') ?? false;

    _tabs = [
      ItRequestTab.form,
      if (_isHod) ItRequestTab.approve,
      if (isItTeam) ...[ItRequestTab.list, ItRequestTab.report],
    ];
    final initial = _tabs.indexOf(widget.initialTab);
    _tabIndex = initial < 0 ? 0 : initial;

    _approvalBloc = ItRequestApprovalBloc(
      repository: context.read<ItRequestRepository>(),
    );
    if (_isHod) _approvalBloc.add(const ItRequestApprovalStarted());
  }

  @override
  void dispose() {
    _approvalBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: BackHeader(
        title: 'IT Request',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: BlocListener<ItRequestApprovalBloc, ItRequestApprovalState>(
        bloc: _approvalBloc,
        listenWhen: (previous, current) =>
            current.notice != null &&
            !identical(previous.notice, current.notice),
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.notice!.message)),
          );
        },
        child: _tabs.length == 1 ? const ItFormAndMediaTab() : _buildTabView(),
      ),
    );
  }

  /// Keputusan HOD, dikirim ke server lewat [ItRequestApprovalBloc]. Ada
  /// dialog konfirmasi dulu karena keputusan tidak bisa dibatalkan dari
  /// aplikasi (sama seperti Supervisor Approval di Indent Vehicle). Reject
  /// sekalian menanyakan alasan opsional.
  Future<void> _decide(
    ApproveRequestItem item, {
    required bool approved,
  }) async {
    String? reason;

    if (approved) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Approve request?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.requesterName,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                item.description,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Approve'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    } else {
      reason = await showItRequestRejectDialog(context, item);
      if (reason == null) return;
    }

    if (!mounted) return;
    _approvalBloc.add(ItRequestApprovalDecided(
      item: item,
      approved: approved,
      reason: reason,
    ));
  }

  /// Tarik-untuk-refresh tab approval.
  Future<void> _refreshApprovals() async {
    if (!_isHod) return;

    _approvalBloc.add(const ItRequestApprovalRefreshed());
    await _approvalBloc.stream
        .firstWhere((s) => s.status != ItRequestApprovalStatus.loading);
  }

  Widget _buildApprovalTab() {
    return BlocBuilder<ItRequestApprovalBloc, ItRequestApprovalState>(
      bloc: _approvalBloc,
      builder: (context, state) {
        if (state.isFirstLoad) {
          return const _ApprovalTabSkeleton();
        }

        if (state.status == ItRequestApprovalStatus.failure) {
          return AppErrorView(
            message: state.errorMessage ?? 'Failed to load the approval list.',
            onRetry: () =>
                _approvalBloc.add(const ItRequestApprovalRefreshed()),
          );
        }

        return ApproveRequestTab(
          items: state.items,
          pending: state.pending,
          busyIds: state.busyIds,
          onRefresh: _refreshApprovals,
          onApprove: (item) => _decide(item, approved: true),
          onReject: (item) => _decide(item, approved: false),
        );
      },
    );
  }

  Widget _buildTabView() {
    // IndexedStack menjaga semua tab tetap "hidup" di belakang layar, jadi
    // scroll position dan state form/filter tiap tab tidak reset saat
    // pindah-pindah tab.
    final children = [
      for (final tab in _tabs)
        switch (tab) {
          ItRequestTab.form => const ItFormAndMediaTab(),
          ItRequestTab.approve => _buildApprovalTab(),
          ItRequestTab.list => const ListRequestTab(),
          ItRequestTab.report => const ReportTab(),
        },
    ];
    final approveIndex = _tabs.indexOf(ItRequestTab.approve);

    return Column(
      children: [
        const SizedBox(height: 12),
        BlocBuilder<ItRequestApprovalBloc, ItRequestApprovalState>(
          bloc: _approvalBloc,
          buildWhen: (previous, current) => previous.pending != current.pending,
          builder: (context, state) => ItRequestTabBar(
            labels: [for (final tab in _tabs) tab.label],
            activeIndex: _tabIndex,
            badgeCounts: {
              if (approveIndex >= 0) approveIndex: state.pending,
            },
            onChanged: (i) => setState(() => _tabIndex = i),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(child: IndexedStack(index: _tabIndex, children: children)),
      ],
    );
  }
}

/// Skeleton tab Approval selagi daftar pertama dimuat: baris keterangan
/// jumlah di atas, lalu kartu-kartu yang meniru [ApproveRequestCard]
/// (requester + badge, deskripsi, dua tombol Reject / Approve).
class _ApprovalTabSkeleton extends StatelessWidget {
  const _ApprovalTabSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(2, 0, 0, 12),
          child: AppShimmer(child: ShimmerLine(width: 160, height: 12)),
        ),
        ShimmerList(
          itemCount: 4,
          itemBuilder: (context) => const ShimmerCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: ShimmerLine(width: 140, height: 14),
                      ),
                    ),
                    SizedBox(width: 8),
                    ShimmerBox(width: 60, height: 20, borderRadius: 20),
                  ],
                ),
                SizedBox(height: 10),
                ShimmerLine(height: 11),
                SizedBox(height: 6),
                ShimmerLine(width: 190, height: 11),
                SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: ShimmerBox(height: 38, borderRadius: 10)),
                    SizedBox(width: 10),
                    Expanded(child: ShimmerBox(height: 38, borderRadius: 10)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
