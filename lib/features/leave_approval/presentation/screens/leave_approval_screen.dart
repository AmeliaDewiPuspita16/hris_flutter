import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_shimmer.dart';
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

/// Kategori approval untuk tombol filter. Cuma dua
/// kelompok (Leave dan Overtime), bukan per jenis cuti — jenis cuti
/// dibedakan lewat label di kartu.
enum _ApprovalCategory { leave, overtime }

/// Halaman Approvals untuk HOD: pengajuan bawahan yang menunggu keputusan,
/// beserta riwayat keputusan yang sudah diambil.
///
/// Melayani dua kategori: Leave (Annual Leave, Permission, Medical Check,
/// Off in Lieu) dan Overtime. Di atas daftar ada dua tombol filter "Leave"
/// dan "Overtime" (ketuk lagi untuk melepas). Tombol ini baru tampil kalau
/// memang ada pengajuan overtime, jadi tampilan tidak berubah selama
/// approval overtime belum tersedia. Tidak ada search: daftar pending satu
/// HOD biasanya hanya beberapa item.
///
/// Halaman ini sumber data approval yang sebenarnya — BUKAN turunan dari
/// tab Notifications. Angka "pending" di badge menu HRIS dan banner Beranda
/// dibaca dari [repository] yang sama.
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
  _ApprovalTab _tab = _ApprovalTab.pending;

  /// Null = semua kategori.
  _ApprovalCategory? _category;

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

  List<LeaveApprovalRequest> _applyFilter(
    List<LeaveApprovalRequest> items,
    _ApprovalCategory? category,
  ) {
    return switch (category) {
      null => items,
      _ApprovalCategory.leave => items.where((r) => !r.isOvertime).toList(),
      _ApprovalCategory.overtime => items.where((r) => r.isOvertime).toList(),
    };
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
              color: active ? AppColors.card : Colors.transparent,
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
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HeaderTitleRow(title: 'Approvals', showBack: widget.showBack),
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
      return const _ApprovalListSkeleton();
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

    // Tombol filter disembunyikan selama belum ada pengajuan overtime sama
    // sekali. Kalau tombol tidak tampil, kategori dianggap "semua" supaya
    // pilihan lama tidak menyaring diam-diam.
    final showFilters = state.items.any((r) => r.isOvertime);
    final category = showFilters ? _category : null;
    final filtered = _applyFilter(source, category);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showFilters) ...[
          _buildFilterBar(category),
          const SizedBox(height: 12),
        ] else
          const SizedBox(height: 16),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: filtered.isEmpty
                ? _buildEmpty(
                    isPendingTab,
                    hasAnyInTab: source.isNotEmpty,
                    hasActiveFilter: category != null,
                  )
                : _buildList(state, filtered, isPendingTab),
          ),
        ),
      ],
    );
  }

  /// Dua tombol filter selebar sama: Leave dan Overtime.
  Widget _buildFilterBar(_ApprovalCategory? category) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          _buildFilterButton(
            value: _ApprovalCategory.leave,
            label: 'Leave',
            icon: Icons.event_available_outlined,
            // Sama dengan warna menu Leave Request (bukan hijau primary).
            color: AppColors.accent,
            selected: category,
          ),
          const SizedBox(width: 10),
          _buildFilterButton(
            value: _ApprovalCategory.overtime,
            label: 'Overtime',
            icon: Icons.more_time_outlined,
            color: AppColors.violet,
            selected: category,
          ),
        ],
      ),
    );
  }

  /// Tombol filter: putih dengan ikon berwarna saat tidak aktif, terisi
  /// warna kategorinya saat aktif. Ketuk lagi untuk melepas. Ikon dan warna
  /// sama dengan menu Leave Request dan Overtime Request.
  Widget _buildFilterButton({
    required _ApprovalCategory value,
    required String label,
    required IconData icon,
    required Color color,
    required _ApprovalCategory? selected,
  }) {
    final active = selected == value;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _category = active ? null : value),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 38,
          decoration: BoxDecoration(
            color: active ? color : AppColors.card,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: active ? Colors.white : color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white : AppColors.textMuted,
                ),
              ),
            ],
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
    final rows = <Object>[
      if (isPendingTab)
        items.length == 1
            ? '1 request waiting for your decision'
            : '${items.length} requests waiting for your decision',
      ...items,
    ];

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
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final row = rows[index];

        if (row is String) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(row, style: AppTextStyles.caption),
          );
        }

        final request = row as LeaveApprovalRequest;

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

  Widget _buildEmpty(
    bool isPendingTab, {
    required bool hasAnyInTab,
    required bool hasActiveFilter,
  }) {
    // Ada isi di tab ini tapi tersaring habis → pesan pencarian; kalau tab
    // memang kosong → pesan sesuai tab.
    final filteredOut = hasAnyInTab && hasActiveFilter;

    final (icon, title, subtitle) = filteredOut
        ? (
            Icons.search_off_rounded,
            'No data found',
            'Try a different filter.',
          )
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
            Icon(
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

/// Skeleton daftar approval selagi data pertama dimuat. Meniru
/// [LeaveApprovalCard]: nama + departemen + status, tanggal, alasan, lalu
/// dua tombol keputusan.
class _ApprovalListSkeleton extends StatelessWidget {
  const _ApprovalListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        ShimmerList(
          itemCount: 4,
          itemBuilder: (context) => const ShimmerCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShimmerLine(width: 130, height: 14),
                          SizedBox(height: 6),
                          ShimmerLine(width: 90, height: 10),
                        ],
                      ),
                    ),
                    SizedBox(width: 8),
                    ShimmerBox(width: 64, height: 20, borderRadius: 20),
                  ],
                ),
                SizedBox(height: 12),
                ShimmerLine(width: 150, height: 11),
                SizedBox(height: 8),
                ShimmerLine(height: 11),
                SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: ShimmerBox(height: 36, borderRadius: 10)),
                    SizedBox(width: 10),
                    Expanded(child: ShimmerBox(height: 36, borderRadius: 10)),
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
