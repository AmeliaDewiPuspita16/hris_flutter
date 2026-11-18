import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../core/network/api_exception.dart';
import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../../core/widgets/app_error_view.dart';
import '../../../../../../../core/widgets/app_shimmer.dart';
import '../../../../../../../core/widgets/app_text_field.dart';
import '../../../../../../../core/widgets/flash_highlight.dart';
import '../../data/it_request_repository.dart';
import '../../domain/it_request_detail.dart';
import '../../domain/it_request_item.dart';
import '../bloc/list/it_request_list_bloc.dart';
import '../bloc/list/it_request_list_event.dart';
import '../bloc/list/it_request_list_state.dart';
import '../screens/add_it_request_screen.dart';
import '../screens/it_request_detail_screen.dart';
import 'it_request_card.dart';
import 'it_request_feedback_banner.dart';
import 'it_request_feedback_sheet.dart';

/// Isi tab "Form IT & Media": tombol ajukan request (di-gate oleh feedback
/// yang belum diselesaikan) + daftar SEMUA permintaan (bukan cuma riwayat
/// sendiri) dengan pencarian — sama polanya dengan tab "All Request" di
/// `EstRequestScreen`, mengikuti tabel penuh yang sama di versi web.
///
/// Beda dengan EST: pencarian di sini menjangkau SEMUA request, termasuk
/// yang belum tergulir — selama kata kunci terisi, bloc memuat halaman
/// sisanya (lihat `ItRequestListBloc._loadMore`).
///
/// Dipakai baik sebagai body utuh untuk staff biasa (tanpa tab) maupun
/// sebagai tab pertama untuk tim IT — isinya sama karena tim IT juga bisa
/// mengajukan permintaan sendiri seperti staff lain.
class ItFormAndMediaTab extends StatelessWidget {
  const ItFormAndMediaTab({super.key, this.repository, this.highlightId});

  /// Diisi test; di aplikasi diambil dari [RepositoryProvider].
  final ItRequestRepository? repository;

  /// id request dari notifikasi yang di-tap; kartunya dikedipkan.
  final int? highlightId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ItRequestListBloc(
        repository: repository ?? context.read<ItRequestRepository>(),
      )..add(const ItRequestListStarted()),
      child: _ItFormAndMediaView(highlightId: highlightId),
    );
  }
}

class _ItFormAndMediaView extends StatefulWidget {
  const _ItFormAndMediaView({this.highlightId});

  final int? highlightId;

  @override
  State<_ItFormAndMediaView> createState() => _ItFormAndMediaViewState();
}

class _ItFormAndMediaViewState extends State<_ItFormAndMediaView> {
  /// Sisa ruang gulir yang memicu pemuatan halaman berikutnya.
  static const _loadMoreThreshold = 320.0;

  /// Id item yang rinciannya sedang diambil sebelum modal feedback dibuka —
  /// null berarti tidak ada yang sedang dalam proses. Cuma satu banner yang
  /// bisa "loading" sekaligus, jadi satu id sudah cukup.
  int? _loadingFeedbackId;

  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    context.read<ItRequestListBloc>().add(ItRequestListSearchChanged(query));
  }

  void _clearSearch() {
    _searchController.clear();
    _onSearchChanged('');
  }

  /// Lewat notifikasi, bukan `ScrollController` sendiri: daftar ini harus
  /// memakai `PrimaryScrollController` supaya geraknya menyatu dengan
  /// header `PortalModulePage` di `ItRequestScreen`.
  bool _onScroll(ScrollNotification notification) {
    if (notification.depth != 0 || notification.metrics.axis != Axis.vertical) {
      return false;
    }
    if (notification.metrics.extentAfter > _loadMoreThreshold) return false;

    context
        .read<ItRequestListBloc>()
        .add(const ItRequestListNextPageRequested());
    return false;
  }

  /// Item MILIK USER LOGIN yang sudah dikerjakan tapi belum dinilai —
  /// ditampilkan sebagai banner, bukan kartu riwayat biasa.
  ///
  /// `canRate` datang langsung dari server, menggantikan tebakan lama
  /// `status.code == 'done' && rating == null` — server yang tahu pasti
  /// kapan sebuah request boleh dinilai. `isMine` WAJIB ikut diperiksa:
  /// daftar ini berisi permintaan SELURUH perusahaan, dan `canRate` cuma
  /// berarti "butuh rating" kalau requester-nya memang user yang sedang
  /// login — bukan permintaan orang lain yang kebetulan lewat di daftar.
  ///
  /// Server juga memberi tahu TOTAL yang menunggu rating lewat
  /// `summary.awaitingRating` (dipakai [ItRequestListState.canAddRequest]),
  /// tapi tidak memberi tahu YANG MANA di luar `canRate` per item — daftarnya
  /// diurut "terbaru dulu" atas SELURUH perusahaan, bukan cuma milik user
  /// login, jadi item yang butuh rating bisa saja tertimbun jauh di halaman
  /// berikutnya. `ItRequestListBloc` sudah menangani ini sendiri (lihat
  /// `_huntForOwnAwaitingItem`) dengan memuat halaman berikutnya secara
  /// otomatis sampai ketemu atau sampai halaman terakhir — jadi cukup baca
  /// `state.items` di sini, tidak perlu logika susul-menyusul halaman lagi.
  bool _isAwaitingFeedback(ItRequestItem item) => item.isMine && item.canRate;

  /// Rincian penuh (termasuk `handling`) belum tentu ada di [item] dari
  /// daftar, jadi diambil dulu supaya modal feedback bisa menampilkan
  /// ringkasan pengerjaan tim IT — bukan cuma deskripsi singkat.
  Future<void> _giveFeedback(ItRequestItem item) async {
    final repository = context.read<ItRequestRepository>();

    setState(() => _loadingFeedbackId = item.id);
    ItRequestDetail detail;
    try {
      detail = await repository.fetchDetail(item.id);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loadingFeedbackId = null);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }
    if (!mounted) return;
    setState(() => _loadingFeedbackId = null);

    final result = await showModalBottomSheet<ItRequestDetail>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          ItRequestFeedbackSheet(detail: detail, repository: repository),
    );

    if (result == null || !mounted) return;

    context.read<ItRequestListBloc>().add(ItRequestFeedbackGiven(result));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thank you for your feedback!')),
    );
  }

  Future<void> _addRequest() async {
    final newItem = await Navigator.of(context).push<ItRequestItem>(
      MaterialPageRoute(builder: (_) => const AddItRequestScreen()),
    );

    if (newItem == null || !mounted) return;

    context.read<ItRequestListBloc>().add(ItRequestLocalItemAdded(newItem));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Request submitted')),
    );
  }

  void _openDetail(ItRequestItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ItRequestDetailScreen(
          item: item,
          repository: context.read<ItRequestRepository>(),
        ),
      ),
    );
  }

  Future<void> _refresh() async {
    final bloc = context.read<ItRequestListBloc>()
      ..add(const ItRequestListRefreshed());
    await bloc.stream
        .firstWhere((s) => s.status != ItRequestListStatus.loading);
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold bersarang di sini, bukan naik ke ItRequestScreen, supaya FAB
    // ini cuma milik tab ini. IndexedStack di ItRequestScreen hanya
    // menggambar & menghitung hit-test tab yang aktif, jadi FAB-nya otomatis
    // tidak ikut nongol saat tab Approve Request / List Request / Report
    // yang aktif.
    return BlocBuilder<ItRequestListBloc, ItRequestListState>(
      builder: (context, state) {
        // FAB baru ditampilkan setelah kita benar-benar tahu jawabannya dari
        // server — selama masih memuat/gagal, lebih aman disembunyikan
        // daripada berkedip muncul-hilang.
        //
        // Disembunyikan juga selama mencari: FAB-nya ikut naik di atas
        // keyboard dan menutupi hasil pencarian.
        final showFab = state.status == ItRequestListStatus.success &&
            state.canAddRequest &&
            !state.isSearching;

        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: showFab
              ? FloatingActionButton(
                  onPressed: _addRequest,
                  backgroundColor: AppColors.solid(AppColors.orange),
                  foregroundColor: Colors.white,
                  tooltip: 'Add Request',
                  child: const Icon(Icons.add),
                )
              : null,
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, ItRequestListState state) {
    // Satu ListView untuk semua keadaan (memuat / gagal / berisi) dengan kolom
    // pencarian sebagai anak pertama yang kuncinya tetap — kalau tiap
    // keadaan punya ListView sendiri, TextField-nya ikut dibangun ulang dan
    // keyboard menutup di tengah mengetik begitu hasil pencarian berganti.
    return RefreshIndicator(
      onRefresh: _refresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            _SearchField(
              key: const ValueKey('it-request-search'),
              controller: _searchController,
              onChanged: _onSearchChanged,
              onClear: _clearSearch,
            ),
            const SizedBox(height: 12),
            ..._buildContent(context, state),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildContent(BuildContext context, ItRequestListState state) {
    if (state.isFirstLoad) {
      return [
        ShimmerList(
          itemCount: 5,
          itemBuilder: (context) => const _RequestCardSkeleton(),
        ),
      ];
    }

    if (state.status == ItRequestListStatus.failure && state.items.isEmpty) {
      return [
        AppErrorView(
          message: state.errorMessage ?? 'Failed to load request history.',
          onRetry: () => context
              .read<ItRequestListBloc>()
              .add(const ItRequestListRefreshed()),
        ),
      ];
    }

    // Selalu dari `visibleItems` (sudah disaring kata kunci), bukan `items`.
    final visible = state.visibleItems;
    final awaiting = visible.where(_isAwaitingFeedback).toList();
    final history = visible.where((i) => !_isAwaitingFeedback(i)).toList();

    return [
      for (final item in awaiting) ...[
        FlashHighlight(
          key: ValueKey('hl-${item.id}'),
          active: item.id == widget.highlightId,
          child: ItRequestFeedbackBanner(
            item: item,
            onGiveFeedback: () => _giveFeedback(item),
            loading: _loadingFeedbackId == item.id,
          ),
        ),
        const SizedBox(height: 12),
      ],
      // Server bilang masih ada yang menunggu rating, tapi tidak ada
      // satu pun yang kebetulan termuat di halaman ini untuk ditampilkan
      // sebagai banner di atas — tetap kasih tahu kenapa FAB terkunci.
      // Tidak ditampilkan saat mencari: bannernya bisa saja ada, hanya
      // tersaring oleh kata kunci.
      if (!state.canAddRequest && awaiting.isEmpty && !state.isSearching)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.accentBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(Icons.lock_outline, size: 16, color: AppColors.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Complete the feedback for finished requests first '
                  'to open a new request.',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.text, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      // Selagi pencarian masih menelusuri halaman berikutnya, jangan buru-buru
      // bilang "tidak ada" — indikator di bawah yang menjelaskannya.
      if (history.isEmpty && awaiting.isEmpty && !state.loadingMore)
        Padding(
          padding: const EdgeInsets.only(top: 24),
          child: Center(
            child: Text(
              state.isSearching
                  ? 'No requests match "${state.searchQuery}"'
                  : 'No data',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMuted,
            ),
          ),
        )
      else
        for (var i = 0; i < history.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          FlashHighlight(
            key: ValueKey('hl-${history[i].id}'),
            active: history[i].id == widget.highlightId,
            child: ItRequestCard(
              item: history[i],
              onTap: () => _openDetail(history[i]),
            ),
          ),
        ],
      if (state.loadingMore)
        state.isSearching
            ? const _SearchingIndicator()
            : const Padding(
                padding: EdgeInsets.only(top: 10),
                child: _RequestCardSkeleton(),
              ),
      // Ruang ekstra di bawah supaya kartu riwayat terakhir tidak
      // tertutup FAB yang mengambang di kanan-bawah.
      if (state.canAddRequest && !state.isSearching) const SizedBox(height: 72),
    ];
  }
}

/// Kolom pencarian + tombol hapus (x) yang muncul begitu ada teks.
///
/// Tombol hapus ditumpuk di atas [AppTextField] lewat `Stack`, bukan lewat
/// parameter suffix, supaya tidak bergantung pada API widget itu.
class _SearchField extends StatelessWidget {
  const _SearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.centerRight,
      children: [
        AppTextField(
          controller: controller,
          hint: 'Search request...',
          icon: Icons.search,
          onChanged: onChanged,
        ),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            if (value.text.isEmpty) return const SizedBox.shrink();

            return IconButton(
              onPressed: onClear,
              tooltip: 'Clear search',
              icon: Icon(Icons.close_rounded,
                  size: 18, color: AppColors.textMid),
            );
          },
        ),
      ],
    );
  }
}

/// Penanda "masih menelusuri request lama" di dasar daftar saat mencari.
class _SearchingIndicator extends StatelessWidget {
  const _SearchingIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 10),
          Text('Searching older requests...', style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

/// Skeleton satu [ItRequestCard]: kotak ikon di kiri, lalu baris jenis +
/// badge status, deskripsi dua baris, dan tanggal.
class _RequestCardSkeleton extends StatelessWidget {
  const _RequestCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const ShimmerCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(width: 46, height: 46, borderRadius: 12),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: ShimmerLine(width: 110, height: 11),
                      ),
                    ),
                    SizedBox(width: 8),
                    ShimmerBox(width: 70, height: 20, borderRadius: 20),
                  ],
                ),
                SizedBox(height: 10),
                ShimmerLine(height: 12),
                SizedBox(height: 6),
                ShimmerLine(width: 160, height: 12),
                SizedBox(height: 10),
                ShimmerLine(width: 80, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
