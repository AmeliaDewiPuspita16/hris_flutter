import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/widgets/back_header.dart';
import '../../domain/indent_approval_demo_data.dart';
import '../../domain/indent_approval_item.dart';
import '../../domain/indent_assign_result.dart';
import '../../domain/indent_pending_demo_data.dart';
import '../../domain/indent_pending_item.dart';
import '../../domain/indent_request_demo_data.dart';
import '../../domain/indent_request_item.dart';
import '../widgets/indent_assign_sheet.dart';
import '../widgets/indent_pending_assignment_tab.dart';
import '../widgets/indent_request_row.dart';
import '../widgets/indent_tab_bar.dart';
import '../widgets/indent_supervisor_approval_tab.dart';
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

  List<IndentRequestItem> _items = IndentRequestDemoData.items();
  List<IndentPendingItem> _pending = IndentPendingDemoData.items();
  List<IndentApprovalItem> _approvals = IndentApprovalDemoData.items();
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<IndentRequestItem> get _filtered {
    if (_query.trim().isEmpty) return _items;

    final q = _query.trim().toLowerCase();
    return _items.where((r) {
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

  /// Buka form Add Indent; kalau disubmit, request baru ditaruh paling atas
  /// di List of User Requests (status On Waiting).
  Future<void> _addIndent() async {
    final newItem = await Navigator.of(context).push<IndentRequestItem>(
      MaterialPageRoute(builder: (_) => const AddIndentScreen()),
    );

    if (newItem == null || !mounted) return;

    setState(() {
      _items = [newItem, ..._items];
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
    );
  }

  Widget _buildListOfRequests() {
    final results = _filtered;

    if (results.isEmpty) {
      return Center(child: Text('Tidak ada data', style: AppTextStyles.bodyMuted));
    }

    return ListView.separated(
      // Padding bawah ekstra (88) supaya baris terakhir tidak tertutup FAB.
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => IndentRequestRow(item: results[index]),
    );
  }
}
