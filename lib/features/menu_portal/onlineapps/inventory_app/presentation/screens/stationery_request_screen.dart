import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/logging/app_logger.dart';
import '../../../../../../core/network/api_exception.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/widgets/app_error_view.dart';
import '../../../../../../core/widgets/app_shimmer.dart';
import '../../../../../../core/widgets/app_text_field.dart';
import '../../../../shared/presentation/widgets/portal_category_page.dart';
import '../../../work_order/est_request/presentation/widgets/est_request_tab_bar.dart';
import '../../data/inventory_item_request_repository.dart';
import '../../data/inventory_stationery_repository.dart';
import '../../domain/stationery_request_status.dart';
import '../../domain/stationery_request_item.dart';
import '../bloc/list/stationery_request_list_bloc.dart';
import '../bloc/list/stationery_request_list_event.dart';
import '../bloc/list/stationery_request_list_state.dart';
import '../bloc/verification/stationery_verification_bloc.dart';
import '../bloc/verification/stationery_verification_event.dart';
import '../bloc/verification/stationery_verification_state.dart';
import '../widgets/stationery_cancel_dialog.dart';
import '../widgets/stationery_decision_dialog.dart';
import '../widgets/stationery_detail_sheet.dart';
import '../widgets/stationery_empty_state.dart';
import '../widgets/stationery_filter_bar.dart';
import '../widgets/stationery_filter_sheet.dart';
import '../widgets/stationery_request_row.dart';
import '../widgets/stationery_verification_tab.dart';
import 'add_stationery_request_screen.dart';

/// Layar Inventory > Item Request. Padanan halaman web
/// `inventory/item-request`:
///
/// - Tab **Request** ("Request Items"): daftar request SEMUA user, tombol
///   Add Request (FAB), dan Edit / Cancel pada request milik sendiri yang
///   masih pending.
/// - Tab **Verification** ("Verification Requests"): antrean Approve /
///   Reject. Hanya tampil untuk akun yang diizinkan server (lihat
///   [StationeryVerificationState.showTab]); user biasa cuma melihat daftar
///   Request tanpa tab bar.
///
/// Tab "Management" dan "Report" di web belum dibuat di aplikasi.
class StationeryRequestScreen extends StatefulWidget {
  const StationeryRequestScreen({
    super.key,
    this.repository,
    this.itemRequestRepository,
  });

  /// Repository DEMO untuk bagian yang belum tersambung ke API (Add, Edit,
  /// Cancel, dan tab Verification). Diisi test; kalau kosong layar membuat
  /// sendiri.
  final InventoryStationeryRepository? repository;

  /// Repository API. Kalau kosong diambil dari `RepositoryProvider`.
  final InventoryItemRequestRepository? itemRequestRepository;

  @override
  State<StationeryRequestScreen> createState() =>
      _StationeryRequestScreenState();
}

class _StationeryRequestScreenState extends State<StationeryRequestScreen> {
  /// DEMO — hapus bersama file `inventory_stationery_repository.dart` bila
  /// semua bagian sudah tersambung ke [_itemRequests].
  late final InventoryStationeryRepository _repository;
  late final InventoryItemRequestRepository _itemRequests;
  late final StationeryRequestListBloc _listBloc;
  late final StationeryVerificationBloc _verifyBloc;

  final _searchController = TextEditingController();
  String _query = '';
  int _tabIndex = 0;

  /// Menunda permintaan ke server sampai pengguna berhenti mengetik.
  Timer? _searchDebounce;

  /// Pilihan chip status; diganti isi `options.statuses` begitu termuat.
  List<StationeryRequestStatus> _statuses = StationeryFilterBar.defaultStatuses;

  /// Penyaring daftar Request, dipilih lewat tombol filter di samping search.
  StationeryRequestFilter _requestFilter = StationeryRequestFilter.none;

  /// id request yang sedang dibatalkan; barisnya dikunci selama itu.
  final Set<int> _busyIds = {};

  @override
  void initState() {
    super.initState();
    // Data demo di memori: instance ini dioper juga ke layar Add/Edit supaya
    // perubahan yang dibuat di sana langsung tampak di daftar.
    _repository = widget.repository ?? InventoryStationeryRepository();

    _itemRequests = widget.itemRequestRepository ??
        context.read<InventoryItemRequestRepository>();

    _listBloc = StationeryRequestListBloc(repository: _itemRequests)
      ..add(const StationeryRequestListStarted());
    _loadStatusOptions();

    // Dimulai untuk semua user: server yang memutuskan siapa verifier
    // (401/403 -> tab disembunyikan).
    _verifyBloc = StationeryVerificationBloc(repository: _repository)
      ..add(const StationeryVerificationStarted());
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _listBloc.close();
    _verifyBloc.close();
    _searchController.dispose();
    super.dispose();
  }

  /// Chip status mengikuti `options.statuses`. Gagal dimuat bukan masalah:
  /// chip bawaan (Pending / Approved / Rejected) tetap dipakai.
  Future<void> _loadStatusOptions() async {
    try {
      final options = await _itemRequests.fetchOptions();
      if (!mounted || options.statuses.isEmpty) return;
      setState(() => _statuses = options.statuses);
    } on ApiException catch (e) {
      AppLogger.info('Opsi status Item Request gagal dimuat: ${e.message}');
    } catch (e, stack) {
      AppLogger.error('Opsi status Item Request gagal tak terduga', e, stack);
    }
  }

  /// Pencarian lokal, khusus antrean Verification (yang masih memakai data
  /// demo). Daftar Request disaring oleh server lewat [_applyListFilter].
  List<StationeryRequestItem> _filter(List<StationeryRequestItem> items) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return items;

    return items.where((r) {
      return r.code.toLowerCase().contains(q) ||
          r.requesterName.toLowerCase().contains(q) ||
          r.itemLabel.toLowerCase().contains(q) ||
          r.description.toLowerCase().contains(q);
    }).toList();
  }

  bool get _filtering => _query.trim().isNotEmpty || _requestFilter.isActive;

  /// Kirim status + kata kunci + "My requests" saat ini ke server.
  void _applyListFilter() {
    _listBloc.add(StationeryRequestListFilterChanged(
      StationeryRequestListFilter(
        status: _requestFilter.status,
        search: _query.trim(),
        mine: _requestFilter.onlyMine,
      ),
    ));
  }

  void _onSearchChanged(String value) {
    setState(() => _query = value);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) _applyListFilter();
    });
  }

  void _setStatus(String? code) {
    setState(() {
      _requestFilter = StationeryRequestFilter(
        status: code,
        onlyMine: _requestFilter.onlyMine,
      );
    });
    _applyListFilter();
  }

  void _toggleMine() {
    setState(() {
      _requestFilter = StationeryRequestFilter(
        status: _requestFilter.status,
        onlyMine: !_requestFilter.onlyMine,
      );
    });
    _applyListFilter();
  }

  void _clearFilters() {
    _searchDebounce?.cancel();
    setState(() {
      _searchController.clear();
      _query = '';
      _requestFilter = StationeryRequestFilter.none;
    });
    _applyListFilter();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Request berubah di server: daftar dimuat ulang, dan antrean verifikasi
  /// ikut bila tab itu aktif untuk user ini.
  void _reloadAll() {
    _listBloc.add(const StationeryRequestListRefreshed());
    if (_verifyBloc.state.showTab) {
      _verifyBloc.add(const StationeryVerificationRefreshed());
    }
  }

  Future<void> _addRequest() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddStationeryRequestScreen(repository: _repository),
      ),
    );
    if (saved != true || !mounted) return;

    _reloadAll();
    // Kosongkan search & penyaring supaya request baru tidak tersaring.
    _clearFilters();
    _toast('Request submitted');
  }

  Future<void> _edit(StationeryRequestItem item) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddStationeryRequestScreen(
          repository: _repository,
          initialItem: item,
        ),
      ),
    );
    if (saved != true || !mounted) return;

    _reloadAll();
    _toast('Request updated');
  }

  Future<void> _cancel(StationeryRequestItem item) async {
    if (!await StationeryCancelDialog.show(context, item)) return;
    if (!mounted) return;

    setState(() => _busyIds.add(item.id));
    try {
      await _repository.cancel(item.id);
      if (!mounted) return;
      _reloadAll();
      _toast('${item.code} cancelled');
    } on ApiException catch (e) {
      if (!mounted) return;
      _toast(e.message);
    } catch (e, stack) {
      AppLogger.error('Cancel request stationery gagal tak terduga', e, stack);
      if (!mounted) return;
      _toast('An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) setState(() => _busyIds.remove(item.id));
    }
  }

  /// Keputusan verifier. Approve minta konfirmasi dulu karena tidak bisa
  /// dibatalkan dari aplikasi; Reject sekalian menanyakan alasan opsional.
  Future<void> _decide(
    StationeryRequestItem item, {
    required bool approved,
  }) async {
    String? reason;

    if (approved) {
      if (!await showStationeryApproveDialog(context, item)) return;
    } else {
      reason = await showStationeryRejectDialog(context, item);
      if (reason == null) return;
    }

    if (!mounted) return;
    _verifyBloc.add(StationeryVerificationDecided(
      item: item,
      approved: approved,
      reason: reason,
    ));
  }

  /// Ketuk kartu di tab Request: buka detail. Edit / Cancel hanya muncul bila
  /// server mengizinkan (request milik sendiri yang masih pending).
  void _openDetail(StationeryRequestItem item) {
    showStationeryDetailSheet(
      context,
      item,
      onEdit: item.canEdit ? () => _edit(item) : null,
      onCancel: item.canCancel ? () => _cancel(item) : null,
    );
  }

  /// Ketuk kartu di tab Verification: detail dengan tombol Approve / Reject.
  void _openVerificationDetail(StationeryRequestItem item) {
    showStationeryDetailSheet(
      context,
      item,
      onApprove: () => _decide(item, approved: true),
      onReject: () => _decide(item, approved: false),
    );
  }

  Future<void> _refreshRequests() async {
    _listBloc.add(const StationeryRequestListRefreshed());
    await _listBloc.stream
        .firstWhere((s) => s.status != StationeryRequestListStatus.loading);
  }

  Future<void> _refreshVerifications() async {
    _verifyBloc.add(const StationeryVerificationRefreshed());
    await _verifyBloc.stream
        .firstWhere((s) => s.status != StationeryVerificationStatus.loading);
  }

  /// Dekat dasar daftar -> minta halaman berikutnya. Lewat notifikasi, bukan
  /// `ScrollController` sendiri: daftar harus memakai
  /// `PrimaryScrollController` supaya menyatu dengan header
  /// `PortalModulePage`.
  bool _onListScroll(ScrollNotification notification) {
    if (notification.depth != 0 || notification.metrics.axis != Axis.vertical) {
      return false;
    }
    if (notification.metrics.extentAfter < 300) {
      _listBloc.add(const StationeryRequestListNextPageRequested());
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return PortalModulePage(
      title: 'Item Request',
      subtitle: 'Request items from stock and track their approval.',
      illustrationAsset: PortalCategoryPage.stationeryIllustration,
      // Add Request hanya relevan di tab Request; di tab Verification tombol
      // ini cuma menutupi kartu.
      floatingActionButton: _verifyBloc.state.showTab && _tabIndex == 1
          ? null
          : FloatingActionButton(
              onPressed: _addRequest,
              backgroundColor: AppColors.solid(AppColors.orange),
              foregroundColor: Colors.white,
              tooltip: 'Add Request',
              child: const Icon(Icons.add),
            ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSearchRow(),
                  BlocBuilder<StationeryVerificationBloc,
                      StationeryVerificationState>(
                    bloc: _verifyBloc,
                    buildWhen: (previous, current) =>
                        previous.showTab != current.showTab ||
                        previous.pending != current.pending,
                    builder: (context, state) {
                      // Bukan verifier (atau belum diketahui): tanpa tab bar.
                      if (!state.showTab) return const SizedBox.shrink();

                      return Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: EstRequestTabBar(
                          labels: const ['Request', 'Verification'],
                          icons: const [
                            Icons.format_list_bulleted_rounded,
                            Icons.fact_check_outlined,
                          ],
                          activeIndex: _tabIndex,
                          badgeCounts: {1: state.pending},
                          onChanged: (i) => setState(() => _tabIndex = i),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: BlocBuilder<StationeryVerificationBloc,
                  StationeryVerificationState>(
                bloc: _verifyBloc,
                buildWhen: (previous, current) =>
                    previous.showTab != current.showTab,
                builder: (context, state) =>
                    state.showTab ? _buildTabs() : _buildRequestList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// IndexedStack menjaga tab Request tetap "hidup" di belakang layar saat
  /// pindah ke Verification, jadi posisi scroll & isi pencarian tidak reset.
  /// Kolom search + tombol filter di kanannya. Filter hanya berlaku untuk
  /// daftar Request, jadi tombolnya disembunyikan saat tab Verification aktif.
  Widget _buildSearchRow() {
    return BlocBuilder<StationeryVerificationBloc, StationeryVerificationState>(
      bloc: _verifyBloc,
      buildWhen: (previous, current) => previous.showTab != current.showTab,
      builder: (context, state) {
        final showFilter = !state.showTab || _tabIndex == 0;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: AppTextField(
                  controller: _searchController,
                  hint: 'Search request...',
                  icon: Icons.search,
                  onChanged: _onSearchChanged,
                ),
              ),
              if (showFilter) ...[
                const SizedBox(width: 10),
                _MineButton(
                  active: _requestFilter.onlyMine,
                  onTap: _toggleMine,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabs() {
    return IndexedStack(
      index: _tabIndex,
      children: [
        // Tab tersembunyi dilepas dari scroll header, lihat
        // `PortalTabScrollScope`.
        PortalTabScrollScope(
          active: _tabIndex == 0,
          child: _buildRequestList(),
        ),
        PortalTabScrollScope(
          active: _tabIndex == 1,
          child: _buildVerificationTab(),
        ),
      ],
    );
  }

  /// BlocConsumer (bukan BlocBuilder) karena selain menggambar antrean, tab
  /// ini juga menampilkan snackbar hasil keputusan. IndexedStack membangun
  /// semua tab, jadi snackbar tetap muncul walau sedang di tab Request.
  Widget _buildVerificationTab() {
    return BlocConsumer<StationeryVerificationBloc,
        StationeryVerificationState>(
      bloc: _verifyBloc,
      listenWhen: (previous, current) =>
          current.notice != null && !identical(previous.notice, current.notice),
      listener: (context, state) {
        final notice = state.notice!;
        _toast(notice.message);
        // Approve/reject mengubah status request di daftar Request.
        if (!notice.isError) {
          _listBloc.add(const StationeryRequestListRefreshed());
        }
      },
      builder: (context, state) {
        if (state.isFirstLoad) return const _VerificationSkeleton();

        if (state.status == StationeryVerificationStatus.failure) {
          return AppErrorView(
            message: state.errorMessage ?? 'Failed to load verification requests.',
            onRetry: () =>
                _verifyBloc.add(const StationeryVerificationRefreshed()),
          );
        }

        return StationeryVerificationTab(
          items: _filter(state.items),
          pending: state.pending,
          busyIds: state.busyIds,
          onRefresh: _refreshVerifications,
          onApprove: (item) => _decide(item, approved: true),
          onReject: (item) => _decide(item, approved: false),
          onOpen: _openVerificationDetail,
        );
      },
    );
  }

  /// Chip status di atas daftar Request (penyaringan oleh server), lalu
  /// daftarnya.
  Widget _buildRequestList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: StationeryFilterBar(
            statuses: _statuses,
            status: _requestFilter.status,
            onStatusChanged: _setStatus,
          ),
        ),
        Expanded(child: _buildRequestBody()),
      ],
    );
  }

  Widget _buildRequestBody() {
    return BlocBuilder<StationeryRequestListBloc, StationeryRequestListState>(
      bloc: _listBloc,
      builder: (context, state) {
        if (state.isFirstLoad) return const _RequestListSkeleton();

        if (state.status == StationeryRequestListStatus.failure) {
          return AppErrorView(
            message: state.errorMessage ?? 'Failed to load the request list.',
            onRetry: () => _listBloc.add(const StationeryRequestListRefreshed()),
          );
        }

        final results = state.items;

        return RefreshIndicator(
          onRefresh: _refreshRequests,
          child: NotificationListener<ScrollNotification>(
            onNotification: _onListScroll,
            child: results.isEmpty
                // ListView (bukan Center saja) supaya tarik-untuk-refresh
                // tetap bisa dipakai saat daftar kosong.
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                    children: [
                      if (_filtering)
                        StationeryEmptyState(
                          icon: Icons.search_off_rounded,
                          title: 'No matching requests',
                          message:
                              'Try a different keyword or clear the filters.',
                          actionLabel: 'Clear filters',
                          onAction: _clearFilters,
                        )
                      else
                        const StationeryEmptyState(
                          icon: Icons.inventory_2_outlined,
                          title: 'No requests yet',
                          message:
                              'Tap + to request an item. Your requests and '
                              'their approval status will show up here.',
                        ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    // Padding bawah ekstra (88) supaya baris terakhir tidak
                    // tertutup FAB "Add Request".
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                    // +1 skeleton di dasar saat halaman berikutnya dimuat.
                    itemCount: results.length + (state.loadingMore ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      if (index == results.length) {
                        return const _RequestRowSkeleton();
                      }

                      final item = results[index];
                      final busy = _busyIds.contains(item.id);
                      return Opacity(
                        opacity: busy ? 0.5 : 1,
                        child: IgnorePointer(
                          ignoring: busy,
                          child: StationeryRequestRow(
                            item: item,
                            onTap: () => _openDetail(item),
                            onEdit: () => _edit(item),
                            onCancel: () => _cancel(item),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        );
      },
    );
  }
}

/// Tombol persegi di samping kolom search: toggle "My requests". Terisi hijau
/// bila aktif.
class _MineButton extends StatelessWidget {
  const _MineButton({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'My requests',
      child: Material(
        color: active ? AppColors.primary : AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: active ? AppColors.primary : AppColors.border,
          ),
        ),
        child: InkWell(
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          onTap: onTap,
          child: SizedBox(
            width: 48,
            child: Icon(
              active ? Icons.person_rounded : Icons.person_outline_rounded,
              size: 22,
              color: active ? Colors.white : AppColors.textMid,
            ),
          ),
        ),
      ),
    );
  }
}

/// Skeleton layar penuh untuk load pertama daftar Request.
class _RequestListSkeleton extends StatelessWidget {
  const _RequestListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        ShimmerList(
          itemCount: 5,
          itemBuilder: (context) => const _RequestRowSkeleton(),
        ),
      ],
    );
  }
}

/// Meniru [StationeryRequestRow]: kode + badge status, jumlah + barang,
/// lalu dua baris alasan.
class _RequestRowSkeleton extends StatelessWidget {
  const _RequestRowSkeleton();

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
                  child: ShimmerLine(width: 170, height: 14),
                ),
              ),
              SizedBox(width: 8),
              ShimmerBox(width: 64, height: 20, borderRadius: 20),
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              ShimmerBox(width: 52, height: 18, borderRadius: 20),
              SizedBox(width: 8),
              ShimmerLine(width: 150, height: 10),
            ],
          ),
          SizedBox(height: 10),
          ShimmerLine(height: 11),
          SizedBox(height: 6),
          ShimmerLine(width: 170, height: 11),
        ],
      ),
    );
  }
}

/// Skeleton tab Verification selagi antrean pertama dimuat.
class _VerificationSkeleton extends StatelessWidget {
  const _VerificationSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(2, 0, 0, 12),
          child: AppShimmer(child: ShimmerLine(width: 190, height: 12)),
        ),
        ShimmerList(
          itemCount: 4,
          itemBuilder: (context) => const ShimmerCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerLine(width: 170, height: 14),
                SizedBox(height: 10),
                Row(
                  children: [
                    ShimmerBox(width: 52, height: 18, borderRadius: 20),
                    SizedBox(width: 8),
                    ShimmerLine(width: 150, height: 10),
                  ],
                ),
                SizedBox(height: 10),
                ShimmerLine(height: 11),
                SizedBox(height: 14),
                Row(
                  children: [
                    Spacer(),
                    ShimmerBox(width: 78, height: 32, borderRadius: 8),
                    SizedBox(width: 8),
                    ShimmerBox(width: 78, height: 32, borderRadius: 8),
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
