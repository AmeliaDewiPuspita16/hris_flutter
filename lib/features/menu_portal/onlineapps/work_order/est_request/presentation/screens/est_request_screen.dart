import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../../core/widgets/app_error_view.dart';
import '../../../../../../../core/widgets/app_shimmer.dart';
import '../../../../../../../core/widgets/app_text_field.dart';
import '../../../../../../auth/presentation/bloc/auth/auth_bloc.dart';
import '../../../../../shared/presentation/widgets/portal_category_page.dart';
import '../../data/est_request_repository.dart';
import '../../domain/est_approval_item.dart';
import '../../domain/est_request_item.dart';
import '../bloc/approval/est_approval_bloc.dart';
import '../bloc/approval/est_approval_event.dart';
import '../bloc/approval/est_approval_state.dart';
import '../bloc/list/est_request_list_bloc.dart';
import '../bloc/list/est_request_list_event.dart';
import '../bloc/list/est_request_list_state.dart';
import '../widgets/est_approval_detail_sheet.dart';
import '../widgets/est_approve_hod_tab.dart';
import '../widgets/est_decision_dialog.dart';
import '../widgets/est_request_row.dart';
import '../widgets/est_request_tab_bar.dart';
import 'add_est_request_screen.dart';
import 'est_request_detail_screen.dart';

/// Layar "EST Request" — daftar SEMUA request (bukan cuma milik sendiri),
/// dari API, plus tombol Add Request. Kerangkanya `PortalModulePage`, sama
/// seperti IT Request dan Indent Vehicle: header bergambar ikut tergulir,
/// search dan tab menempel di bawah status bar.
///
/// Pembagian requester vs HOD mengikuti role `hod` user yang login (lewat
/// `AuthBloc`), sama seperti `ItRequestScreen`.
///
/// - Requester biasa (`isHod: false`): cuma daftar All Request, tanpa tab.
/// - HOD (`isHod: true`): tab All Request / Approve HOD, mengikuti pola
///   Form IT & Media / Approve Request di `ItRequestScreen`.
///
/// Yang SUDAH tersambung ke API: daftar All Request (infinite scroll),
/// layar detail, tab Approve HOD, tambah, edit, dan hapus. Yang belum:
/// rating — dikerjakan bertahap.
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

  // Daftar All Request dipegang bloc (data dari API). Dibuat di sini, bukan
  // lewat BlocProvider, supaya handler di State ini bisa memakainya langsung.
  late final EstRequestListBloc _listBloc;

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

    final repository = context.read<EstRequestRepository>();

    _listBloc = EstRequestListBloc(repository: repository)
      ..add(const EstRequestListStarted());

    _approvalBloc = EstApprovalBloc(repository: repository);
    if (_isHod) _approvalBloc.add(const EstApprovalStarted());
  }

  @override
  void dispose() {
    _listBloc.close();
    _approvalBloc.close();
    _searchController.dispose();
    super.dispose();
  }

  /// Pencarian hanya menyaring request yang SUDAH dimuat (server belum
  /// punya parameter pencarian). Request di halaman yang belum digulir
  /// belum ikut tersaring.
  List<EstRequestItem> _filter(List<EstRequestItem> items) {
    if (_query.trim().isEmpty) return items;

    final q = _query.trim().toLowerCase();
    return items.where((r) {
      return r.requesterName.toLowerCase().contains(q) ||
          r.department.toLowerCase().contains(q) ||
          r.location.toLowerCase().contains(q) ||
          r.description.toLowerCase().contains(q);
    }).toList();
  }

  /// Buka layar detail. Semua baris bisa diketuk: semua user boleh melihat
  /// WO siapa pun, dan flag `can_*` di detail yang menentukan aksinya.
  ///
  /// Layar detail menutup diri dengan `true` bila WO diedit atau dihapus di
  /// sana, jadi daftar dimuat ulang supaya barisnya ikut berubah.
  Future<void> _openDetail(EstRequestItem item) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => EstRequestDetailScreen(item: item)),
    );

    if (changed != true || !mounted) return;

    _listBloc.add(const EstRequestListRefreshed());
  }

  /// Buka form Add Request. Bila form menutup diri dengan `true` (request
  /// tersimpan di server), daftar dimuat ulang supaya request baru muncul
  /// paling atas.
  Future<void> _addRequest() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddEstRequestScreen()),
    );

    if (saved != true || !mounted) return;

    _listBloc.add(const EstRequestListRefreshed());
    setState(() {
      // Kosongkan search supaya request baru tidak tersaring.
      _searchController.clear();
      _query = '';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Request submitted')),
    );
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

  /// Tarik-untuk-refresh daftar All Request; berhenti begitu datanya sudah
  /// datang.
  Future<void> _refreshRequests() async {
    _listBloc.add(const EstRequestListRefreshed());
    await _listBloc.stream
        .firstWhere((s) => s.status != EstRequestListStatus.loading);
  }

  /// Dekat dasar daftar -> minta halaman berikutnya. Bloc sendiri yang
  /// menolak bila sedang memuat atau sudah halaman terakhir.
  ///
  /// Lewat notifikasi, bukan `ScrollController` sendiri: daftar ini harus
  /// memakai `PrimaryScrollController` supaya geraknya menyatu dengan
  /// header `PortalModulePage`.
  bool _onListScroll(ScrollNotification notification) {
    if (notification.depth != 0 ||
        notification.metrics.axis != Axis.vertical) {
      return false;
    }
    if (notification.metrics.extentAfter < 300) {
      _listBloc.add(const EstRequestListNextPageRequested());
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return PortalModulePage(
      title: 'EST Request',
      subtitle: 'Submit repair and project requests and track their status.',
      illustrationAsset: PortalCategoryPage.monitorIllustration,
      // FAB oranye di kanan-bawah, sama pola dengan IT Request & HSE Work
      // Request.
      // TODO(est): sembunyikan saat summary.awaiting_verification > 0
      // (requester wajib memberi rating dulu) begitu rating tersambung.
      floatingActionButton: FloatingActionButton(
        onPressed: _addRequest,
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        tooltip: 'Add Request',
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Search paling atas (fixed, di luar area scroll), tab bar di
            // bawahnya — urutan yang sama dengan IndentVehicleScreen.
            Padding(
              // Header sudah punya jarak bawah sendiri.
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    controller: _searchController,
                    hint: 'Search request...',
                    icon: Icons.search,
                    onChanged: (v) => setState(() => _query = v),
                  ),
                  if (_isHod)
                    BlocBuilder<EstApprovalBloc, EstApprovalState>(
                      bloc: _approvalBloc,
                      buildWhen: (previous, current) =>
                          previous.pending != current.pending ||
                          previous.denied != current.denied,
                      builder: (context, state) {
                        // Server menolak akun ini: tab disembunyikan, bukan
                        // dibiarkan tampil kosong.
                        if (state.denied) return const SizedBox.shrink();

                        return Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: EstRequestTabBar(
                            labels: const ['All Request', 'Approve HOD'],
                            icons: const [
                              Icons.format_list_bulleted_rounded,
                              Icons.check_circle_outline_rounded,
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
              child: !_isHod
                  ? _buildAllRequestList()
                  : BlocBuilder<EstApprovalBloc, EstApprovalState>(
                      bloc: _approvalBloc,
                      buildWhen: (previous, current) =>
                          previous.denied != current.denied,
                      builder: (context, state) => state.denied
                          ? _buildAllRequestList()
                          : _buildHodTabs(),
                    ),
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
    // Tab tersembunyi dilepas dari scroll header, lihat
    // `PortalTabScrollScope`.
    final tabs = [
      PortalTabScrollScope(
        active: _tabIndex == 0,
        child: _buildAllRequestList(),
      ),
      PortalTabScrollScope(
        active: _tabIndex == 1,
        child: _buildApprovalTab(),
      ),
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
        final notice = state.notice!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(notice.message)),
        );
        // Approve/reject mengubah status request di All Request
        // (waiting_hod -> waiting / rejected).
        if (!notice.isError) {
          _listBloc.add(const EstRequestListRefreshed());
        }
      },
      builder: (context, state) {
        if (state.isFirstLoad) {
          return const _ApprovalTabSkeleton();
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
    return BlocBuilder<EstRequestListBloc, EstRequestListState>(
      bloc: _listBloc,
      builder: (context, state) {
        if (state.isFirstLoad) {
          return const _RequestListSkeleton();
        }

        if (state.status == EstRequestListStatus.failure) {
          return AppErrorView(
            message: state.errorMessage ?? 'Failed to load the request list.',
            onRetry: () => _listBloc.add(const EstRequestListRefreshed()),
          );
        }

        final results = _filter(state.items);

        return RefreshIndicator(
          onRefresh: _refreshRequests,
          child: NotificationListener<ScrollNotification>(
            onNotification: _onListScroll,
            child: results.isEmpty
                // ListView (bukan Center saja) supaya tarik-untuk-refresh
                // tetap bisa dipakai saat daftar kosong.
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 120),
                      Center(
                        child: Text('No data', style: AppTextStyles.bodyMuted),
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    // Padding bawah ekstra (88) supaya baris terakhir tidak
                    // tertutup FAB "Add Request" yang mengambang, sama
                    // seperti di HSE.
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
                      return EstRequestRow(
                        item: item,
                        onTap: () => _openDetail(item),
                      );
                    },
                  ),
          ),
        );
      },
    );
  }
}

/// Skeleton layar penuh untuk load pertama daftar All Request.
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

/// Meniru [EstRequestRow]: nama + badge status, tipe + lokasi, dua baris
/// deskripsi, lalu tanggal.
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
                  child: ShimmerLine(width: 160, height: 14),
                ),
              ),
              SizedBox(width: 8),
              ShimmerBox(width: 72, height: 20, borderRadius: 20),
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              ShimmerBox(width: 52, height: 18, borderRadius: 20),
              SizedBox(width: 8),
              ShimmerLine(width: 110, height: 10),
            ],
          ),
          SizedBox(height: 10),
          ShimmerLine(height: 11),
          SizedBox(height: 6),
          ShimmerLine(width: 190, height: 11),
          SizedBox(height: 10),
          ShimmerLine(width: 70, height: 10),
        ],
      ),
    );
  }
}

/// Skeleton tab Approval EST selagi daftar pertama dimuat: baris keterangan
/// jumlah, lalu kartu yang meniru [EstApproveHodCard] (judul, tipe + tanggal,
/// deskripsi, dan baris tombol keputusan).
class _ApprovalTabSkeleton extends StatelessWidget {
  const _ApprovalTabSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
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
                ShimmerLine(width: 170, height: 14),
                SizedBox(height: 10),
                Row(
                  children: [
                    ShimmerBox(width: 64, height: 18, borderRadius: 20),
                    Spacer(),
                    ShimmerLine(width: 70, height: 10),
                  ],
                ),
                SizedBox(height: 10),
                ShimmerLine(height: 11),
                SizedBox(height: 6),
                ShimmerLine(width: 190, height: 11),
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
