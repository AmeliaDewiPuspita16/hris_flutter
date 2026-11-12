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
import '../../data/inventory_item_request_demo_repository.dart';
import '../../domain/item_request_status.dart';
import '../../domain/item_request_entry.dart';
import '../bloc/list/item_request_list_bloc.dart';
import '../bloc/list/item_request_list_event.dart';
import '../bloc/list/item_request_list_state.dart';
import '../bloc/verification/item_request_verification_bloc.dart';
import '../bloc/verification/item_request_verification_event.dart';
import '../bloc/verification/item_request_verification_state.dart';
import '../widgets/item_request_cancel_dialog.dart';
import '../widgets/item_request_decision_dialog.dart';
import '../widgets/item_request_detail_sheet.dart';
import '../widgets/item_request_empty_state.dart';
import '../widgets/item_request_filter_bar.dart';
import '../widgets/item_request_filter_sheet.dart';
import '../widgets/item_request_row.dart';
import '../widgets/item_request_verification_tab.dart';
import 'add_item_request_screen.dart';

/// Layar Inventory > Item Request. Padanan halaman web
/// `inventory/item-request`:
///
/// - Tab **Request** ("Request Items"): daftar request SEMUA user, tombol
///   Add Request (FAB), dan Edit / Cancel pada request milik sendiri yang
///   masih pending.
/// - Tab **Verification** ("Verification Requests"): antrean Approve /
///   Reject. Hanya tampil untuk akun yang diizinkan server (lihat
///   [ItemRequestVerificationState.showTab]); user biasa cuma melihat daftar
///   Request tanpa tab bar.
///
/// Tab "Management" dan "Report" di web belum dibuat di aplikasi.
class ItemRequestScreen extends StatefulWidget {
  const ItemRequestScreen({
    super.key,
    this.repository,
    this.itemRequestRepository,
  });

  /// Repository DEMO untuk bagian yang belum tersambung ke API (Add, Edit,
  /// Cancel, dan tab Verification). Diisi test; kalau kosong layar membuat
  /// sendiri.
  final InventoryItemRequestDemoRepository? repository;

  /// Repository API. Kalau kosong diambil dari `RepositoryProvider`.
  final InventoryItemRequestRepository? itemRequestRepository;

  @override
  State<ItemRequestScreen> createState() =>
      _ItemRequestScreenState();
}

class _ItemRequestScreenState extends State<ItemRequestScreen> {
  /// DEMO — hapus bersama file `inventory_item_request_demo_repository.dart` bila
  /// semua bagian sudah tersambung ke [_itemRequests].
  late final InventoryItemRequestDemoRepository _repository;
  late final InventoryItemRequestRepository _itemRequests;
  late final ItemRequestListBloc _listBloc;
  late final ItemRequestVerificationBloc _verifyBloc;

  final _searchController = TextEditingController();
  String _query = '';
  int _tabIndex = 0;

  /// Menunda permintaan ke server sampai pengguna berhenti mengetik.
  Timer? _searchDebounce;

  /// Pilihan chip status; diganti isi `options.statuses` begitu termuat.
  List<ItemRequestStatus> _statuses = ItemRequestFilterBar.defaultStatuses;

  /// Penyaring daftar Request, dipilih lewat tombol filter di samping search.
  ItemRequestFilter _requestFilter = ItemRequestFilter.none;

  /// id request yang sedang dibatalkan; barisnya dikunci selama itu.
  final Set<int> _busyIds = {};

  @override
  void initState() {
    super.initState();
    // Data demo di memori: instance ini dioper juga ke layar Add/Edit supaya
    // perubahan yang dibuat di sana langsung tampak di daftar.
    _repository = widget.repository ?? InventoryItemRequestDemoRepository();

    _itemRequests = widget.itemRequestRepository ??
        context.read<InventoryItemRequestRepository>();

    _listBloc = ItemRequestListBloc(repository: _itemRequests)
      ..add(const ItemRequestListStarted());
    _loadStatusOptions();

    // Dimulai untuk semua user: server yang memutuskan siapa verifier
    // (401/403 -> tab disembunyikan).
    _verifyBloc = ItemRequestVerificationBloc(repository: _repository)
      ..add(const ItemRequestVerificationStarted());
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
  List<ItemRequestEntry> _filter(List<ItemRequestEntry> items) {
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
    _listBloc.add(ItemRequestListFilterChanged(
      ItemRequestListFilter(
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
      _requestFilter = ItemRequestFilter(
        status: code,
        onlyMine: _requestFilter.onlyMine,
      );
    });
    _applyListFilter();
  }

  void _toggleMine() {
    setState(() {
      _requestFilter = ItemRequestFilter(
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
      _requestFilter = ItemRequestFilter.none;
    });
    _applyListFilter();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Request berubah di server: daftar dimuat ulang, dan antrean verifikasi
  /// ikut bila tab itu aktif untuk user ini.
  void _reloadAll() {
    _listBloc.add(const ItemRequestListRefreshed());
    if (_verifyBloc.state.showTab) {
      _verifyBloc.add(const ItemRequestVerificationRefreshed());
    }
  }

  Future<void> _addRequest() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddItemRequestScreen(repository: _repository),
      ),
    );
    if (saved != true || !mounted) return;

    _reloadAll();
    // Kosongkan search & penyaring supaya request baru tidak tersaring.
    _clearFilters();
    _toast('Request submitted');
  }

  Future<void> _edit(ItemRequestEntry item) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddItemRequestScreen(
          repository: _repository,
          initialItem: item,
        ),
      ),
    );
    if (saved != true || !mounted) return;

    _reloadAll();
    _toast('Request updated');
  }

  Future<void> _cancel(ItemRequestEntry item) async {
    if (!await ItemRequestCancelDialog.show(context, item)) return;
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
      AppLogger.error('Cancel item request gagal tak terduga', e, stack);
      if (!mounted) return;
      _toast('An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) setState(() => _busyIds.remove(item.id));
    }
  }

  /// Keputusan verifier. Approve minta konfirmasi dulu karena tidak bisa
  /// dibatalkan dari aplikasi; Reject sekalian menanyakan alasan opsional.
  Future<void> _decide(
    ItemRequestEntry item, {
    required bool approved,
  }) async {
    String? reason;

    if (approved) {
      if (!await showItemRequestApproveDialog(context, item)) return;
    } else {
      reason = await showItemRequestRejectDialog(context, item);
      if (reason == null) return;
    }

    if (!mounted) return;
    _verifyBloc.add(ItemRequestVerificationDecided(
      item: item,
      approved: approved,
      reason: reason,
    ));
  }

  /// Ketuk kartu di tab Request: buka detail. Edit / Cancel hanya muncul bila
  /// server mengizinkan (request milik sendiri yang masih pending).
  void _openDetail(ItemRequestEntry item) {
    showItemRequestDetailSheet(
      context,
      item,
      repository: _itemRequests,
      onEdit: item.canEdit ? () => _edit(item) : null,
      onCancel: item.canCancel ? () => _cancel(item) : null,
    );
  }

  /// Ketuk kartu di tab Verification: detail dengan tombol Approve / Reject.
  void _openVerificationDetail(ItemRequestEntry item) {
    showItemRequestDetailSheet(
      context,
      item,
      onApprove: () => _decide(item, approved: true),
      onReject: () => _decide(item, approved: false),
    );
  }

  Future<void> _refreshRequests() async {
    _listBloc.add(const ItemRequestListRefreshed());
    await _listBloc.stream
        .firstWhere((s) => s.status != ItemRequestListStatus.loading);
  }

  Future<void> _refreshVerifications() async {
    _verifyBloc.add(const ItemRequestVerificationRefreshed());
    await _verifyBloc.stream
        .firstWhere((s) => s.status != ItemRequestVerificationStatus.loading);
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
      _listBloc.add(const ItemRequestListNextPageRequested());
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
                  BlocBuilder<ItemRequestVerificationBloc,
                      ItemRequestVerificationState>(
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
              child: BlocBuilder<ItemRequestVerificationBloc,
                  ItemRequestVerificationState>(
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
    return BlocBuilder<ItemRequestVerificationBloc, ItemRequestVerificationState>(
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
    return BlocConsumer<ItemRequestVerificationBloc,
        ItemRequestVerificationState>(
      bloc: _verifyBloc,
      listenWhen: (previous, current) =>
          current.notice != null && !identical(previous.notice, current.notice),
      listener: (context, state) {
        final notice = state.notice!;
        _toast(notice.message);
        // Approve/reject mengubah status request di daftar Request.
        if (!notice.isError) {
          _listBloc.add(const ItemRequestListRefreshed());
        }
      },
      builder: (context, state) {
        if (state.isFirstLoad) return const _VerificationSkeleton();

        if (state.status == ItemRequestVerificationStatus.failure) {
          return AppErrorView(
            message: state.errorMessage ?? 'Failed to load verification requests.',
            onRetry: () =>
                _verifyBloc.add(const ItemRequestVerificationRefreshed()),
          );
        }

        return ItemRequestVerificationTab(
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
          child: ItemRequestFilterBar(
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
    return BlocBuilder<ItemRequestListBloc, ItemRequestListState>(
      bloc: _listBloc,
      builder: (context, state) {
        if (state.isFirstLoad) return const _RequestListSkeleton();

        if (state.status == ItemRequestListStatus.failure) {
          return AppErrorView(
            message: state.errorMessage ?? 'Failed to load the request list.',
            onRetry: () => _listBloc.add(const ItemRequestListRefreshed()),
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
                        ItemRequestEmptyState(
                          icon: Icons.search_off_rounded,
                          title: 'No matching requests',
                          message:
                              'Try a different keyword or clear the filters.',
                          actionLabel: 'Clear filters',
                          onAction: _clearFilters,
                        )
                      else
                        const ItemRequestEmptyState(
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
                          child: ItemRequestRow(
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

/// Meniru [ItemRequestRow]: kode + badge status, jumlah + barang,
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
