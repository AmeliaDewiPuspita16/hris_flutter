import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/logging/app_logger.dart';
import '../../../../../../core/network/api_exception.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/widgets/app_error_view.dart';
import '../../../../../../core/widgets/app_shimmer.dart';
import '../../../../../../core/widgets/back_header.dart';
import '../../../../../auth/presentation/bloc/auth/auth_bloc.dart';
import '../../data/indent_vehicle_repository.dart';
import '../../domain/indent_approval_item.dart';
import '../../domain/indent_assign_result.dart';
import '../../domain/indent_pending_item.dart';
import '../../domain/indent_request_item.dart';
import '../bloc/approval/indent_approval_bloc.dart';
import '../bloc/approval/indent_approval_event.dart';
import '../bloc/approval/indent_approval_state.dart';
import '../bloc/list/indent_request_list_bloc.dart';
import '../bloc/list/indent_request_list_event.dart';
import '../bloc/list/indent_request_list_state.dart';
import '../bloc/pending/indent_pending_bloc.dart';
import '../bloc/pending/indent_pending_event.dart';
import '../bloc/pending/indent_pending_state.dart';
import '../widgets/indent_assign_sheet.dart';
import '../widgets/indent_feedback_banner.dart';
import '../widgets/indent_feedback_sheet.dart';
import '../widgets/indent_pending_assignment_tab.dart';
import '../widgets/indent_request_row.dart';
import '../widgets/indent_supervisor_approval_tab.dart';
import '../widgets/indent_tab_bar.dart';
import '../widgets/indent_delete_dialog.dart';
import 'add_indent_screen.dart';

/// Layar "Indent Vehicle" (menu Data). Urutan dari atas: search, tab bar,
/// lalu isi tab yang aktif.
///
/// - Tab 0 "Pending Vehicle Assignment" — admin driver menetapkan plat &
///   driver lewat tombol Assign, lewat API. Isinya hanya terisi untuk
///   akun `driver-admin` (server yang menentukan).
/// - Tab 1 "Supervisor Approval"       — atasan (role `hod`) approve/reject
///   request lewat API. Yang di-approve masuk ke antrean admin di server.
/// - Tab 2 "List of User Requests"     — daftar semua request, dari API.
class IndentVehicleScreen extends StatefulWidget {
  const IndentVehicleScreen({super.key, this.initialTabIndex = 2});

  /// Tab yang aktif saat layar dibuka. Default 2 (List of User Requests)
  /// karena itu tampilan yang dilihat semua user; admin driver / HOD nanti
  /// bisa dibuka langsung ke tab 0 / 1.
  final int initialTabIndex;

  @override
  State<IndentVehicleScreen> createState() => _IndentVehicleScreenState();
}

class _IndentVehicleScreenState extends State<IndentVehicleScreen> {
  static const _tabLabels = [
    'Pending Vehicle Assignment',
    'Supervisor Approval',
    'List of User Requests',
  ];

  late int _tabIndex = widget.initialTabIndex;

  // Daftar "List of User Requests" dipegang bloc (data dari API). Dibuat di
  // sini, bukan lewat BlocProvider, supaya handler di State ini bisa
  // memakainya langsung.
  late final IndentRequestListBloc _requestBloc;
  final _requestScrollController = ScrollController();

  // Tab Pending Vehicle Assignment juga dipegang bloc. Dimulai untuk semua
  // akun: server membalas `admin: false` (tanpa data) untuk yang bukan
  // driver-admin, jadi tidak perlu mencocokkan nama role di sini.
  late final IndentPendingBloc _pendingBloc;
  // Tab Supervisor Approval juga dipegang bloc. Hanya dimulai untuk akun
  // berperan `hod`: server membalas 404 untuk akun lain.
  late final IndentApprovalBloc _approvalBloc;
  late final bool _isHod;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthBloc>().state.session?.user;
    _requestBloc = IndentRequestListBloc(
      repository: context.read<IndentVehicleRepository>(),
      currentUserId: user?.id,
    )..add(const IndentRequestListStarted());
    _requestScrollController.addListener(_onRequestScroll);

    _isHod = user?.hasRole('hod') ?? false;
    _approvalBloc = IndentApprovalBloc(
      repository: context.read<IndentVehicleRepository>(),
    );
    if (_isHod) _approvalBloc.add(const IndentApprovalStarted());

    _pendingBloc = IndentPendingBloc(
      repository: context.read<IndentVehicleRepository>(),
    )..add(const IndentPendingStarted());
  }

  @override
  void dispose() {
    _requestBloc.close();
    _approvalBloc.close();
    _pendingBloc.close();
    _requestScrollController
      ..removeListener(_onRequestScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<IndentRequestItem> _filterRequests(List<IndentRequestItem> items) {
    if (_query.trim().isEmpty) return items;

    final q = _query.trim().toLowerCase();
    return items.where((r) {
      return r.name.toLowerCase().contains(q) ||
          r.destination.toLowerCase().contains(q) ||
          r.remark.toLowerCase().contains(q) ||
          (r.vehicle ?? '').toLowerCase().contains(q) ||
          (r.driver ?? '').toLowerCase().contains(q);
    }).toList();
  }

  List<IndentPendingItem> _filterPending(List<IndentPendingItem> items) {
    if (_query.trim().isEmpty) return items;

    final q = _query.trim().toLowerCase();
    return items.where((r) {
      return r.name.toLowerCase().contains(q) ||
          r.destination.toLowerCase().contains(q) ||
          r.remark.toLowerCase().contains(q);
    }).toList();
  }

  List<IndentApprovalItem> _filterApprovals(List<IndentApprovalItem> items) {
    if (_query.trim().isEmpty) return items;

    final q = _query.trim().toLowerCase();
    return items.where((r) {
      return r.name.toLowerCase().contains(q) ||
          r.destination.toLowerCase().contains(q) ||
          r.remark.toLowerCase().contains(q);
    }).toList();
  }

  /// Keputusan atasan, dikirim ke server lewat [IndentApprovalBloc]. Ada
  /// dialog konfirmasi karena keputusan tidak bisa dibatalkan dari
  /// aplikasi. Hasilnya (berhasil/gagal) ditampilkan oleh BlocListener di
  /// [build]. Di server, request yang di-approve masuk ke antrean admin
  /// (tab Pending Vehicle Assignment milik admin), bukan ke tab ini.
  Future<void> _decide(
    IndentApprovalItem item, {
    required bool approved,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(approved ? 'Approve request?' : 'Reject request?'),
        content: Text('${item.name} — ${item.destination}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(approved ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    _approvalBloc.add(IndentApprovalDecided(item: item, approved: approved));
  }

  /// Buka sheet Assign Vehicle. Kalau admin menekan Assign, hasilnya dikirim
  /// ke server lewat [IndentPendingBloc]; request keluar dari daftar pending
  /// hanya bila server sukses. Hasilnya (berhasil/gagal) ditampilkan oleh
  /// BlocListener di [build].
  Future<void> _assign(IndentPendingItem item) async {
    final result = await showModalBottomSheet<IndentAssignResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => IndentAssignSheet(item: item),
    );

    if (result == null || !mounted) return;

    _pendingBloc.add(IndentPendingAssigned(item: item, result: result));
  }

  /// Buka sheet feedback; rating + catatan dikirim ke server dari dalam
  /// sheet (loading dan galat ditampilkan di sana, sheet tetap terbuka bila
  /// gagal). Begitu server menerima, daftar dimuat ulang supaya banner
  /// feedback berganti jadi bintang.
  Future<void> _giveFeedback({
    required String id,
    required String destination,
    required String date,
  }) async {
    final requestId = int.tryParse(id);
    if (requestId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This request has not been saved to the server yet.')),
      );
      return;
    }

    final repository = context.read<IndentVehicleRepository>();
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => IndentFeedbackSheet(
        destination: destination,
        date: date,
        onSubmit: (rating, note) async {
          await repository.submitRating(
            id: requestId,
            rating: rating,
            feedback: note,
          );
          // Di sini (bukan setelah sheet tertutup) supaya daftar tetap
          // diperbarui walau sheet sudah ditutup saat balasan datang.
          _requestBloc.add(const IndentRequestListRefreshed());
        },
      ),
    );

    if (sent != true || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thank you for your feedback')),
    );
  }

  /// Edit request milik sendiri (selama belum di-approve). Form Add Indent
  /// dipakai ulang dalam mode edit; form sendiri yang mengirim perubahan ke
  /// server dan menutup diri dengan `true` bila tersimpan, lalu daftar
  /// dimuat ulang.
  ///
  /// TODO(api): server juga harus menolak edit pada request yang sudah
  /// di-approve; sekarang pembatasannya hanya di aplikasi.
  Future<void> _editIndent(IndentRequestItem item) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AddIndentScreen(initialItem: item)),
    );

    if (saved != true || !mounted) return;

    _requestBloc.add(const IndentRequestListRefreshed());

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Request updated')),
    );
  }

  /// Hapus request milik sendiri. Setelah user mengonfirmasi, permintaan
  /// dikirim ke server; baris baru dibuang dari daftar kalau server sukses.
  Future<void> _deleteIndent(IndentRequestItem item) async {
    final confirmed = await IndentDeleteDialog.show(context, item);
    if (!confirmed || !mounted) return;

    final id = int.tryParse(item.id);
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This request has not been saved to the server yet.')),
      );
      return;
    }

    try {
      await context.read<IndentVehicleRepository>().deleteIndent(id);
      if (!mounted) return;

      // Server sudah menghapus; buang dari daftar tanpa memuat ulang supaya
      // posisi scroll tidak lompat.
      _requestBloc.add(IndentRequestLocalRemoved(item.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request deleted')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e, stack) {
      AppLogger.error('Hapus indent gagal karena galat tak terduga', e, stack);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An unexpected error occurred. Please try again.')),
      );
    }
  }

  /// Buka form Add Indent; kalau tersimpan di server, daftar dimuat ulang
  /// dan request baru muncul paling atas di List of User Requests (status
  /// On Waiting).
  Future<void> _addIndent() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddIndentScreen()),
    );

    if (saved != true || !mounted) return;

    // Muat ulang dari server: request baru (id terbesar) muncul paling atas.
    _requestBloc.add(const IndentRequestListRefreshed());
    setState(() {
      // Pastikan hasilnya langsung kelihatan, dan kosongkan search supaya
      // request baru tidak tersaring.
      _tabIndex = 2;
      _searchController.clear();
      _query = '';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Request submitted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: BackHeader(
        title: 'Indent Vehicle',
        onBack: () => Navigator.of(context).pop(),
      ),
      // FAB oranye di kanan-bawah, sama pola dengan IT Request, HSE, dan EST.
      // Cuma muncul di tab List of User Requests — tab lain (assign &
      // approval) bukan tempat membuat request baru.
      floatingActionButton: _tabIndex == 2
          ? FloatingActionButton(
              onPressed: _addIndent,
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
              tooltip: 'Add Indent',
              child: const Icon(Icons.add),
            )
          : null,
      body: MultiBlocListener(
        listeners: [
          BlocListener<IndentApprovalBloc, IndentApprovalState>(
            bloc: _approvalBloc,
            listenWhen: (previous, current) =>
                current.notice != null &&
                !identical(previous.notice, current.notice),
            listener: (context, state) {
              final notice = state.notice!;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(notice.message)),
              );
              // Approve/reject mengubah kolom Approve di List of User
              // Requests.
              if (!notice.isError) {
                _requestBloc.add(const IndentRequestListRefreshed());
              }
            },
          ),
          BlocListener<IndentPendingBloc, IndentPendingState>(
            bloc: _pendingBloc,
            listenWhen: (previous, current) =>
                current.notice != null &&
                !identical(previous.notice, current.notice),
            listener: (context, state) {
              final notice = state.notice!;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(notice.message)),
              );
              // Assign mengisi kolom Vehicle/Driver di List of User Requests.
              if (!notice.isError) {
                _requestBloc.add(const IndentRequestListRefreshed());
              }
            },
          ),
        ],
        child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Search paling atas (fixed, di luar area scroll), tab bar di
            // bawahnya — urutan yang sama dengan EstRequestScreen.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSearchField(),
                  const SizedBox(height: 12),
                  BlocBuilder<IndentPendingBloc, IndentPendingState>(
                    bloc: _pendingBloc,
                    builder: (context, pendingState) =>
                        BlocBuilder<IndentApprovalBloc, IndentApprovalState>(
                      bloc: _approvalBloc,
                      builder: (context, approvalState) => IndentTabBar(
                        labels: _tabLabels,
                        activeIndex: _tabIndex,
                        badgeCounts: {
                          0: pendingState.items.length,
                          1: approvalState.items.length,
                        },
                        onChanged: (i) => setState(() => _tabIndex = i),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // IndexedStack: semua tab tetap "hidup" di belakang layar,
            // jadi posisi scroll tab list tidak reset saat pindah tab.
            Expanded(
              child: IndexedStack(
                index: _tabIndex,
                children: [
                  _buildPendingAssignment(),
                  _buildSupervisorApproval(),
                  _buildListOfRequests(),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (v) => setState(() => _query = v),
      style: AppTextStyles.body,
      decoration: InputDecoration(
        hintText: 'Search request...',
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.textMuted),
        prefixIcon:
            const Icon(Icons.search, size: 19, color: AppColors.textMuted),
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
    );
  }

  Widget _buildPendingAssignment() {
    return BlocBuilder<IndentPendingBloc, IndentPendingState>(
      bloc: _pendingBloc,
      builder: (context, state) {
        if (state.isFirstLoad) {
          return const _IndentCardList(skeleton: _PendingCardSkeleton());
        }

        if (state.status == IndentPendingStatus.failure) {
          return AppErrorView(
            message: state.errorMessage ?? 'Failed to load the assignment list.',
            onRetry: () => _pendingBloc.add(const IndentPendingRefreshed()),
          );
        }

        return IndentPendingAssignmentTab(
          items: _filterPending(state.items),
          busyIds: state.busyIds,
          onRefresh: _refreshPending,
          onAssign: _assign,
        );
      },
    );
  }

  /// Tarik-untuk-refresh tab pending; berhenti begitu datanya sudah datang.
  Future<void> _refreshPending() async {
    _pendingBloc.add(const IndentPendingRefreshed());
    await _pendingBloc.stream
        .firstWhere((s) => s.status != IndentPendingStatus.loading);
  }

  Widget _buildSupervisorApproval() {
    return BlocBuilder<IndentApprovalBloc, IndentApprovalState>(
      bloc: _approvalBloc,
      builder: (context, state) {
        if (state.isFirstLoad) {
          return const _IndentCardList(skeleton: _ApprovalCardSkeleton());
        }

        if (state.status == IndentApprovalStatus.failure) {
          return AppErrorView(
            message: state.errorMessage ?? 'Failed to load the approval list.',
            onRetry: () => _approvalBloc.add(const IndentApprovalRefreshed()),
          );
        }

        return IndentSupervisorApprovalTab(
          items: _filterApprovals(state.items),
          busyIds: state.busyIds,
          onRefresh: _refreshApprovals,
          onApprove: (item) => _decide(item, approved: true),
          onReject: (item) => _decide(item, approved: false),
        );
      },
    );
  }

  /// Tarik-untuk-refresh tab approval. Akun non-HOD tidak memanggil server
  /// sama sekali (server membalas 404 untuk mereka).
  Future<void> _refreshApprovals() async {
    if (!_isHod) return;

    _approvalBloc.add(const IndentApprovalRefreshed());
    await _approvalBloc.stream
        .firstWhere((s) => s.status != IndentApprovalStatus.loading);
  }

  Widget _buildListOfRequests() {
    return BlocBuilder<IndentRequestListBloc, IndentRequestListState>(
      bloc: _requestBloc,
      builder: (context, state) {
        if (state.isFirstLoad) {
          return const _IndentCardList(skeleton: _RequestRowSkeleton());
        }

        if (state.status == IndentRequestListStatus.failure) {
          return AppErrorView(
            message: state.errorMessage ?? 'Failed to load the request list.',
            onRetry: () => _requestBloc.add(const IndentRequestListRefreshed()),
          );
        }

        final filtered = _filterRequests(state.items);

        // Item yang menunggu feedback ditaruh paling atas supaya langsung
        // terlihat; urutan item lain tidak berubah (sort Dart bersifat
        // stabil jika memakai pola ini).
        final results = [
          ...filtered.where((r) => r.needsFeedback),
          ...filtered.where((r) => !r.needsFeedback),
        ];

        return RefreshIndicator(
          onRefresh: _refreshRequests,
          child: results.isEmpty
              // ListView (bukan Center saja) supaya tarik-untuk-refresh
              // tetap bisa dipakai saat daftar kosong.
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(height: 120),
                    Center(
                      child: Text('No data',
                          style: AppTextStyles.bodyMuted),
                    ),
                  ],
                )
              : ListView.separated(
                  controller: _requestScrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  // Padding bawah ekstra (88) supaya baris terakhir tidak
                  // tertutup FAB.
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                  // +1 untuk skeleton di dasar saat halaman berikutnya
                  // sedang dimuat.
                  itemCount: results.length + (state.loadingMore ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    if (index == results.length) {
                      return const _RequestRowSkeleton();
                    }

                    final item = results[index];
                    if (item.needsFeedback) {
                      return IndentFeedbackBanner(
                        item: item,
                        onGiveFeedback: () => _giveFeedback(
                          id: item.id,
                          destination: item.destination,
                          date: item.date,
                        ),
                      );
                    }
                    return IndentRequestRow(
                      item: item,
                      onDelete: () => _deleteIndent(item),
                      onEdit: () => _editIndent(item),
                    );
                  },
                ),
        );
      },
    );
  }

  /// Dekat dasar daftar -> minta halaman berikutnya. Bloc sendiri yang
  /// menolak bila sedang memuat atau sudah halaman terakhir.
  void _onRequestScroll() {
    if (!_requestScrollController.hasClients) return;

    final position = _requestScrollController.position;
    if (position.maxScrollExtent - position.pixels < 300) {
      _requestBloc.add(const IndentRequestListNextPageRequested());
    }
  }

  /// Menunggu sampai muat ulang selesai supaya indikator tarik-refresh
  /// berhenti tepat saat datanya sudah datang.
  Future<void> _refreshRequests() async {
    _requestBloc.add(const IndentRequestListRefreshed());
    await _requestBloc.stream
        .firstWhere((s) => s.status != IndentRequestListStatus.loading);
  }
}

/// Daftar skeleton layar penuh untuk load pertama tiap tab. [skeleton]
/// adalah satu kartu palsu yang diulang, sehingga bentuknya mengikuti
/// kartu aslinya.
class _IndentCardList extends StatelessWidget {
  const _IndentCardList({required this.skeleton});

  final Widget skeleton;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        ShimmerList(
          itemCount: 4,
          itemBuilder: (context) => skeleton,
        ),
      ],
    );
  }
}

/// Meniru [IndentPendingCard]: judul + badge driver, baris info, tombol
/// Assign selebar kartu.
class _PendingCardSkeleton extends StatelessWidget {
  const _PendingCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const ShimmerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ShimmerLine(width: 150, height: 14),
                ),
              ),
              SizedBox(width: 8),
              ShimmerBox(width: 70, height: 20, borderRadius: 20),
            ],
          ),
          SizedBox(height: 10),
          ShimmerLine(width: 190, height: 11),
          SizedBox(height: 6),
          ShimmerLine(width: 130, height: 11),
          SizedBox(height: 14),
          ShimmerBox(height: 38, borderRadius: 10),
        ],
      ),
    );
  }
}

/// Meniru [IndentApprovalCard]: tanggal + jam, judul + badge, lokasi,
/// keterangan, pemisah, dua tombol keputusan.
class _ApprovalCardSkeleton extends StatelessWidget {
  const _ApprovalCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const ShimmerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ShimmerLine(width: 80, height: 10),
              SizedBox(width: 14),
              ShimmerLine(width: 60, height: 10),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ShimmerLine(width: 140, height: 14),
                ),
              ),
              SizedBox(width: 8),
              ShimmerBox(width: 70, height: 20, borderRadius: 20),
            ],
          ),
          SizedBox(height: 10),
          ShimmerLine(width: 160, height: 11),
          SizedBox(height: 6),
          ShimmerLine(height: 11),
          SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: ShimmerBox(height: 34, borderRadius: 8)),
              SizedBox(width: 10),
              Expanded(child: ShimmerBox(height: 34, borderRadius: 8)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Meniru [IndentRequestRow]: judul + status, keterangan, lalu dua baris
/// info (tanggal / driver).
class _RequestRowSkeleton extends StatelessWidget {
  const _RequestRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const ShimmerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ShimmerLine(width: 150, height: 14),
                ),
              ),
              SizedBox(width: 8),
              ShimmerBox(width: 64, height: 20, borderRadius: 20),
            ],
          ),
          SizedBox(height: 10),
          ShimmerLine(height: 11),
          SizedBox(height: 14),
          Row(
            children: [
              ShimmerLine(width: 90, height: 10),
              SizedBox(width: 16),
              ShimmerLine(width: 70, height: 10),
            ],
          ),
        ],
      ),
    );
  }
}
