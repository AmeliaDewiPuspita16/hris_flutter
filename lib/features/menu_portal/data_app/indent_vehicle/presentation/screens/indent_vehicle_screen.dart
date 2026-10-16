import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/widgets/app_error_view.dart';
import '../../../../../../core/widgets/back_header.dart';
import '../../../../../auth/presentation/bloc/auth/auth_bloc.dart';
import '../../data/indent_vehicle_repository.dart';
import '../../domain/indent_approval_demo_data.dart';
import '../../domain/indent_approval_item.dart';
import '../../domain/indent_assign_result.dart';
import '../../domain/indent_pending_demo_data.dart';
import '../../domain/indent_pending_item.dart';
import '../../domain/indent_request_item.dart';
import '../bloc/list/indent_request_list_bloc.dart';
import '../bloc/list/indent_request_list_event.dart';
import '../bloc/list/indent_request_list_state.dart';
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
///   driver lewat tombol Assign (sudah jadi).
/// - Tab 1 "Supervisor Approval"       — atasan approve/reject request
///   (sudah jadi). Yang di-approve diteruskan ke tab 0.
/// - Tab 2 "List of User Requests"     — daftar semua request (sudah jadi).
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

  List<IndentPendingItem> _pending = IndentPendingDemoData.items();
  List<IndentApprovalItem> _approvals = IndentApprovalDemoData.items();
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthBloc>().state.session?.user;
    _requestBloc = IndentRequestListBloc(
      repository: context.read<IndentVehicleRepository>(),
      currentUserId: user?.id,
      currentUserName: user?.name,
    )..add(const IndentRequestListStarted());
  }

  @override
  void dispose() {
    _requestBloc.close();
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

  List<IndentPendingItem> get _filteredPending {
    if (_query.trim().isEmpty) return _pending;

    final q = _query.trim().toLowerCase();
    return _pending.where((r) {
      return r.name.toLowerCase().contains(q) ||
          r.destination.toLowerCase().contains(q) ||
          r.remark.toLowerCase().contains(q);
    }).toList();
  }

  List<IndentApprovalItem> get _filteredApprovals {
    if (_query.trim().isEmpty) return _approvals;

    final q = _query.trim().toLowerCase();
    return _approvals.where((r) {
      return r.name.toLowerCase().contains(q) ||
          r.destination.toLowerCase().contains(q) ||
          r.remark.toLowerCase().contains(q);
    }).toList();
  }

  /// Keputusan atasan. Approve → request pindah ke Pending Vehicle
  /// Assignment (menunggu admin menetapkan kendaraan); Reject → keluar dari
  /// daftar.
  ///
  /// TODO(api): kirim keputusan ke server; di web request yang ditolak
  /// tampil di List of User Requests dan yang disetujui jadi "Approved".
  void _decide(IndentApprovalItem item, {required bool approved}) {
    setState(() {
      _approvals = _approvals.where((r) => r.id != item.id).toList();
      if (approved) {
        _pending = [
          ..._pending,
          IndentPendingItem(
            id: item.id,
            name: item.name,
            destination: item.destination,
            date: item.date,
            timeRange: item.timeRange,
            remark: item.remark,
            withDriver: item.withDriver,
          ),
        ];
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          approved
              ? 'Request ${item.name} disetujui'
              : 'Request ${item.name} ditolak',
        ),
      ),
    );
  }

  /// Buka sheet Assign Vehicle. Kalau admin menekan Assign, request keluar
  /// dari daftar pending (karena sudah punya kendaraan).
  ///
  /// TODO(api): kirim hasilnya ke server; di web request ini lalu muncul di
  /// List of User Requests dengan Vehicle/Driver terisi dan Approve
  /// "Approved". Sekarang cuma dihapus dari list lokal.
  Future<void> _assign(IndentPendingItem item) async {
    final result = await showModalBottomSheet<IndentAssignResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => IndentAssignSheet(item: item),
    );

    if (result == null || !mounted) return;

    setState(() {
      _pending = _pending.where((r) => r.id != item.id).toList();
    });

    final driverText = result.driver == null ? '' : ' · ${result.driver}';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Kendaraan ${result.plateNumber}$driverText '
          'ditetapkan untuk ${item.name}',
        ),
      ),
    );
  }

  /// buka sheet feedback; kalau dikirim, reting disimpan ke item.
  ///
  /// TODO (api) : kirim rating + catatan ke server (endpoint belum ada). Catatan
  /// juga belum diismpan di model, tambahkan field-nya bila API menyediakan.
  Future<void> _giveFeedback(IndentRequestItem item) async {
    final result = await showModalBottomSheet<({int rating, String? note})>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => IndentFeedbackSheet(item: item));

    if (result == null || !mounted) return;

    _requestBloc.add(
      IndentRequestLocalUpdated(item.copyWith(rating: result.rating)),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Terima kasih atas feedback Anda')),
    );
  }

    /// Edit request milik sendiri (selama belum di-approve). Form Add Indent
  /// dipakai ulang dalam mode edit; hasilnya menggantikan item lama.
  ///
  /// TODO(api): kirim perubahan ke endpoint update (belum ada). Server juga
  /// harus menolak kalau request sudah di-approve.
  Future<void> _editIndent(IndentRequestItem item) async {
    final updated = await Navigator.of(context).push<IndentRequestItem>(
      MaterialPageRoute(builder: (_) => AddIndentScreen(initialItem: item)),
    );

    if (updated == null || !mounted) return;

    _requestBloc.add(IndentRequestLocalUpdated(updated));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Request updated')),
    );
  }

  /// Hapus request milik sendiri. Hanya bisa selama belum di-approve
  /// (tombolnya memang cuma muncul untuk [IndentRequestItem.canModify]).
  ///
  /// TODO(api): panggil endpoint hapus (belum ada). Server juga harus
  /// menolak kalau request sudah di-approve (dobel pengaman).
  Future<void> _deleteIndent(IndentRequestItem item) async {
    final confirmed = await IndentDeleteDialog.show(context, item);
    if (!confirmed || !mounted) return;

    _requestBloc.add(IndentRequestLocalRemoved(item.id));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Request dihapus')),
    );
  }

  /// Buka form Add Indent; kalau disubmit, request baru ditaruh paling atas
  /// di List of User Requests (status On Waiting).
  Future<void> _addIndent() async {
    final newItem = await Navigator.of(context).push<IndentRequestItem>(
      MaterialPageRoute(builder: (_) => const AddIndentScreen()),
    );

    if (newItem == null || !mounted) return;

    _requestBloc.add(IndentRequestLocalAdded(newItem));
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
      body: SafeArea(
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
                  IndentTabBar(
                    labels: _tabLabels,
                    activeIndex: _tabIndex,
                    badgeCounts: {
                      0: _pending.length,
                      1: _approvals.length,
                    },
                    onChanged: (i) => setState(() => _tabIndex = i),
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
                  IndentPendingAssignmentTab(
                    items: _filteredPending,
                    onAssign: _assign,
                  ),
                  IndentSupervisorApprovalTab(
                    items: _filteredApprovals,
                    onApprove: (item) => _decide(item, approved: true),
                    onReject: (item) => _decide(item, approved: false),
                  ),
                  _buildListOfRequests(),
                ],
              ),
            ),
          ],
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

  Widget _buildListOfRequests() {
    return BlocBuilder<IndentRequestListBloc, IndentRequestListState>(
      bloc: _requestBloc,
      builder: (context, state) {
        if (state.isFirstLoad) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.status == IndentRequestListStatus.failure) {
          return AppErrorView(
            message: state.errorMessage ?? 'Gagal memuat daftar request.',
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
                      child: Text('Tidak ada data',
                          style: AppTextStyles.bodyMuted),
                    ),
                  ],
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  // Padding bawah ekstra (88) supaya baris terakhir tidak
                  // tertutup FAB.
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                  itemCount: results.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = results[index];
                    if (item.needsFeedback) {
                      return IndentFeedbackBanner(
                        item: item,
                        onGiveFeedback: () => _giveFeedback(item),
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

  /// Menunggu sampai muat ulang selesai supaya indikator tarik-refresh
  /// berhenti tepat saat datanya sudah datang.
  Future<void> _refreshRequests() async {
    _requestBloc.add(const IndentRequestListRefreshed());
    await _requestBloc.stream
        .firstWhere((s) => s.status != IndentRequestListStatus.loading);
  }
}
