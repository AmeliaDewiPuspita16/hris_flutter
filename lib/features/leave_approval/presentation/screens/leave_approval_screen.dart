import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/header_title_row.dart';
import '../../../pengajuan/domain/leave_type.dart';
import '../../data/leave_approval_repository.dart';
import '../../domain/leave_approval_request.dart';
import '../../domain/leave_approval_status.dart';
import '../bloc/leave_approval_bloc.dart';
import '../bloc/leave_approval_event.dart';
import '../bloc/leave_approval_state.dart';
import '../widgets/leave_approval_card.dart';
import '../widgets/leave_approval_detail_sheet.dart';
import '../widgets/leave_decision_sheet.dart';

enum _ApprovalTab { pending, history }

/// Halaman Leave Approvals untuk HOD: pengajuan bawahan (Annual Leave,
/// Permission, Off in Lieu, Overtime, Medical Check) yang menunggu
/// keputusan, beserta riwayat keputusan yang sudah diambil.
///
/// Halaman ini sumber data approval Leave yang sebenarnya — BUKAN turunan
/// dari tab Notifications. Angka "pending" di badge menu HRIS dan banner
/// Beranda dibaca dari [repository] yang sama.
///
/// Dibuka lewat push dari menu HRIS atau banner Beranda, jadi header punya
/// tombol kembali ([showBack]).
class LeaveApprovalScreen extends StatelessWidget {
  const LeaveApprovalScreen({
    super.key,
    required this.repository,
    this.onPendingCountChanged,
    this.onDecided,
    this.showBack = true,
  });

  /// Wajib diisi pemanggil dan dipakai bersama (dipegang `BerandaScreen`),
  /// bukan dibuat baru di sini — kalau tidak, keputusan yang diambil di
  /// layar ini tidak akan terlihat oleh badge di Beranda.
  final LeaveApprovalRepository repository;

  /// Dipanggil tiap jumlah pending berubah (setelah dimuat atau setelah ada
  /// keputusan), supaya badge di Beranda ikut bergerak tanpa perlu menunggu
  /// layar ini ditutup.
  final ValueChanged<int>? onPendingCountChanged;

  /// Dipanggil setelah sebuah keputusan berhasil tersimpan. Dipakai untuk
  /// menyinkronkan notifikasi Leave yang bersangkutan.
  final ValueChanged<LeaveApprovalRequest>? onDecided;

  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LeaveApprovalBloc(repository: repository)
        ..add(const LeaveApprovalStarted()),
      // Header hijau sampai ke balik status bar → ikon status bar terang.
      // Diset di sini karena layar ini dibuka lewat push, di luar
      // AnnotatedRegion milik BerandaScreen.
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: AppColors.primary,
          body: _LeaveApprovalView(
            showBack: showBack,
            onPendingCountChanged: onPendingCountChanged,
            onDecided: onDecided,
          ),
        ),
      ),
    );
  }
}

class _LeaveApprovalView extends StatefulWidget {
  const _LeaveApprovalView({
    required this.showBack,
    this.onPendingCountChanged,
    this.onDecided,
  });

  final bool showBack;
  final ValueChanged<int>? onPendingCountChanged;
  final ValueChanged<LeaveApprovalRequest>? onDecided;

  @override
  State<_LeaveApprovalView> createState() => _LeaveApprovalViewState();
}

class _LeaveApprovalViewState extends State<_LeaveApprovalView> {
  final _searchController = TextEditingController();

  _ApprovalTab _tab = _ApprovalTab.pending;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Aksi ───────────────────────────────────────────────────────────

  Future<void> _refresh() async {
    final bloc = context.read<LeaveApprovalBloc>();
    bloc.add(const LeaveApprovalRefreshed());
    // Biarkan indikator tarik-untuk-muat berputar sampai pemuatan selesai.
    await bloc.stream.firstWhere(
      (s) => s.status != LeaveApprovalLoadStatus.loading,
    );
  }

  Future<void> _openDetail(LeaveApprovalRequest request) async {
    final decision = await showLeaveApprovalDetailSheet(context, request);
    if (decision == null || !mounted) return;

    await _startDecision(request, decision);
  }

  Future<void> _startDecision(
    LeaveApprovalRequest request,
    LeaveApprovalDecision decision,
  ) async {
    final bloc = context.read<LeaveApprovalBloc>();

    final note = await showLeaveDecisionSheet(
      context,
      request: request,
      decision: decision,
    );
    // null = dibatalkan.
    if (note == null) return;

    bloc.add(LeaveApprovalDecided(
      request.id,
      decision,
      note: note.isEmpty ? null : note,
    ));
  }

  // ── Penyaringan ────────────────────────────────────────────────────

  bool get _hasActiveFilter => _query.trim().isNotEmpty;

  // Filter jenis (chip All/Annual Leave/…) sengaja dihapus — search sudah
  // menyaring berdasarkan nama jenis lewat haystack di bawah, dan daftar
  // pending satu HOD biasanya cuma beberapa item, jadi chip kategori
  // terpisah cuma menambah baris berwarna tanpa banyak manfaat. Mudah
  // dikembalikan nanti kalau volumenya jadi besar.
  List<LeaveApprovalRequest> _applyFilter(List<LeaveApprovalRequest> items) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return items;

    return items.where((r) {
      final haystack = '${r.requesterName} ${r.department} ${r.position} '
              '${r.type.label} ${r.reason ?? ''}'
          .toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  // ── Tampilan ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // SnackBar hasil keputusan + sinkronisasi ke pemanggil.
        BlocListener<LeaveApprovalBloc, LeaveApprovalState>(
          listenWhen: (previous, current) =>
              current.feedback != null &&
              !identical(previous.feedback, current.feedback),
          listener: (context, state) {
            final feedback = state.feedback!;

            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(feedback.message),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: feedback.isError ? AppColors.rejected : null,
                ),
              );

            final decided = feedback.decided;
            if (decided != null) widget.onDecided?.call(decided);
          },
        ),
        // Kabari Beranda tiap jumlah pending berubah.
        BlocListener<LeaveApprovalBloc, LeaveApprovalState>(
          listenWhen: (previous, current) =>
              current.status == LeaveApprovalLoadStatus.success &&
              previous.pendingCount != current.pendingCount,
          listener: (context, state) =>
              widget.onPendingCountChanged?.call(state.pendingCount),
        ),
      ],
      // Strip status bar memakai warna header (primary), bukan warna
      // halaman — kalau tidak, ada garis beda warna tepat di atas header.
      child: ColoredBox(
        color: AppColors.primary,
        child: SafeArea(
          bottom: false,
          child: ColoredBox(
            color: AppColors.bg,
            child: BlocBuilder<LeaveApprovalBloc, LeaveApprovalState>(
              builder: (context, state) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(state.pendingCount),
                  Expanded(child: _buildBody(state)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(int pendingCount) {
    Widget tabButton(_ApprovalTab tab, String label, IconData icon,
        {int badge = 0}) {
      final active = _tab == tab;
      final foreground =
          active ? AppColors.primary : Colors.white.withValues(alpha: 0.75);

      return Expanded(
        child: InkWell(
          onTap: () => setState(() => _tab = tab),
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: active ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: foreground),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: foreground,
                  ),
                ),
                if (badge > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    constraints: const BoxConstraints(minWidth: 18),
                    height: 18,
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.rejected,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      '$badge',
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      // Solid primary, sudut bawah bulat — sama dengan header Leave Request.
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HeaderTitleRow(title: 'Leave Approvals', showBack: widget.showBack),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                tabButton(
                  _ApprovalTab.pending,
                  'Pending',
                  Icons.hourglass_empty_rounded,
                  badge: pendingCount,
                ),
                tabButton(
                  _ApprovalTab.history,
                  'History',
                  Icons.history_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(LeaveApprovalState state) {
    if (state.status == LeaveApprovalLoadStatus.loading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == LeaveApprovalLoadStatus.failure && state.items.isEmpty) {
      return _ErrorState(
        message: state.errorMessage ?? 'Failed to load approvals.',
        onRetry: () =>
            context.read<LeaveApprovalBloc>().add(const LeaveApprovalRefreshed()),
      );
    }

    final isPendingTab = _tab == _ApprovalTab.pending;
    final source = isPendingTab ? state.pending : state.history;
    final filtered = _applyFilter(source);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSearchBar(),
        const SizedBox(height: 12),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: filtered.isEmpty
                ? _buildEmpty(isPendingTab, hasAnyInTab: source.isNotEmpty)
                : _buildList(state, filtered, isPendingTab),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: SizedBox(
        height: 38,
        child: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _query = value),
          style: const TextStyle(fontSize: 13, color: AppColors.text),
          decoration: InputDecoration(
            hintText: 'Search name, department, reason',
            hintStyle:
                const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
            prefixIcon:
                const Icon(Icons.search, size: 18, color: AppColors.textMuted),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(
                      Icons.close,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                  ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.zero,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList(
    LeaveApprovalState state,
    List<LeaveApprovalRequest> items,
    bool isPendingTab,
  ) {
    return ListView.separated(
      // Selalu bisa ditarik walau isinya sedikit, supaya refresh tetap
      // berfungsi.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        20,
        6,
        20,
        MediaQuery.paddingOf(context).bottom + 24,
      ),
      itemCount: items.length + (isPendingTab ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (isPendingTab && index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              items.length == 1
                  ? '1 request waiting for your decision'
                  : '${items.length} requests waiting for your decision',
              style: AppTextStyles.caption,
            ),
          );
        }

        final request = items[isPendingTab ? index - 1 : index];

        return LeaveApprovalCard(
          request: request,
          processing: state.processingIds.contains(request.id),
          onTap: () => _openDetail(request),
          onApprove: isPendingTab
              ? () => _startDecision(request, LeaveApprovalDecision.approve)
              : null,
          onReject: isPendingTab
              ? () => _startDecision(request, LeaveApprovalDecision.reject)
              : null,
        );
      },
    );
  }

  Widget _buildEmpty(bool isPendingTab, {required bool hasAnyInTab}) {
    // Ada isi di tab ini tapi tersaring habis → pesan pencarian; kalau tab
    // memang kosong → pesan sesuai tab.
    final filteredOut = hasAnyInTab && _hasActiveFilter;

    final (icon, title, subtitle) = filteredOut
        ? (Icons.search_off_rounded, 'No data found', 'Try a different search or filter.')
        : isPendingTab
            ? (
                Icons.check_circle_outline_rounded,
                "You're all caught up",
                'No requests are waiting for your decision.',
              )
            : (
                Icons.history_rounded,
                'No history yet',
                'Requests you approve or reject will appear here.',
              );

    // ListView (bukan Center saja) supaya RefreshIndicator tetap bisa
    // ditarik di keadaan kosong.
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(32, 64, 32, 24),
      children: [
        Icon(icon, size: 40, color: AppColors.textMuted),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: AppTextStyles.caption,
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 40,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMuted,
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
