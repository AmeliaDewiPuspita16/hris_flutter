import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../../core/widgets/app_error_view.dart';
import '../../data/it_request_repository.dart';
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
/// yang belum diselesaikan) + riwayat permintaan sendiri.
///
/// Dipakai baik sebagai body utuh untuk staff biasa (tanpa tab) maupun
/// sebagai tab pertama untuk tim IT — isinya sama karena tim IT juga bisa
/// mengajukan permintaan sendiri seperti staff lain.
class ItFormAndMediaTab extends StatelessWidget {
  const ItFormAndMediaTab({super.key, this.repository});

  /// Diisi test; di aplikasi diambil dari [RepositoryProvider].
  final ItRequestRepository? repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ItRequestListBloc(
        repository: repository ?? context.read<ItRequestRepository>(),
      )..add(const ItRequestListStarted()),
      child: const _ItFormAndMediaView(),
    );
  }
}

class _ItFormAndMediaView extends StatefulWidget {
  const _ItFormAndMediaView();

  @override
  State<_ItFormAndMediaView> createState() => _ItFormAndMediaViewState();
}

class _ItFormAndMediaViewState extends State<_ItFormAndMediaView> {
  /// Sisa ruang gulir yang memicu pemuatan halaman berikutnya.
  static const _loadMoreThreshold = 320.0;

  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final remaining = _scrollController.position.maxScrollExtent -
        _scrollController.position.pixels;
    if (remaining > _loadMoreThreshold) return;

    context
        .read<ItRequestListBloc>()
        .add(const ItRequestListNextPageRequested());
  }

  /// Item yang sudah dikerjakan tapi belum dinilai — ditampilkan sebagai
  /// banner, bukan kartu riwayat biasa.
  ///
  /// `canRate` datang langsung dari server, menggantikan tebakan lama
  /// `status.code == 'done' && rating == null` — server yang tahu pasti
  /// kapan sebuah request boleh dinilai.
  ///
  /// Server juga memberi tahu TOTAL yang menunggu rating lewat
  /// `summary.awaitingRating` (dipakai [ItRequestListState.canAddRequest]),
  /// tapi tidak memberi tahu YANG MANA di luar `canRate` per item — daftarnya
  /// diurut "terbaru dulu", bukan dikelompokkan per status. Jadi banner ini
  /// cuma menampilkan yang kebetulan sudah termuat di halaman ini; kalau ada
  /// yang menunggu rating di halaman berikutnya yang belum digulir, tombol
  /// "+ Add Request" tetap terkunci (itu authoritative), tapi bannernya baru
  /// muncul setelah halaman itu ikut termuat.
  bool _isAwaitingFeedback(ItRequestItem item) => item.canRate;

  Future<void> _giveFeedback(ItRequestItem item) async {
    final rating = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ItRequestFeedbackSheet(description: item.description),
    );

    if (rating == null || !mounted) return;

    context
        .read<ItRequestListBloc>()
        .add(ItRequestLocalFeedbackGiven(id: item.id, rating: rating));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Terima kasih atas feedbacknya!')),
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
        final showFab =
            state.status == ItRequestListStatus.success && state.canAddRequest;

        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: showFab
              ? FloatingActionButton(
                  onPressed: _addRequest,
                  backgroundColor: AppColors.orange,
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
    if (state.isFirstLoad) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == ItRequestListStatus.failure && state.items.isEmpty) {
      return AppErrorView(
        message: state.errorMessage ?? 'Gagal memuat riwayat request.',
        onRetry: () => context
            .read<ItRequestListBloc>()
            .add(const ItRequestListRefreshed()),
      );
    }

    final awaiting = state.items.where(_isAwaitingFeedback).toList();
    final history = state.items.where((i) => !_isAwaitingFeedback(i)).toList();

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          for (final item in awaiting) ...[
            ItRequestFeedbackBanner(
                item: item, onGiveFeedback: () => _giveFeedback(item)),
            const SizedBox(height: 12),
          ],
          // Server bilang masih ada yang menunggu rating, tapi tidak ada
          // satu pun yang kebetulan termuat di halaman ini untuk ditampilkan
          // sebagai banner di atas — tetap kasih tahu kenapa FAB terkunci.
          if (!state.canAddRequest && awaiting.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.accentBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline,
                      size: 16, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Selesaikan feedback untuk request yang sudah dikerjakan dulu '
                      'untuk membuka pengajuan baru.',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.text, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          if (history.isEmpty && awaiting.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Center(
                child: Text('Tidak ada data', style: AppTextStyles.bodyMuted),
              ),
            )
          else
            for (var i = 0; i < history.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              ItRequestCard(
                  item: history[i], onTap: () => _openDetail(history[i])),
            ],
          if (state.loadingMore)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
          // Ruang ekstra di bawah supaya kartu riwayat terakhir tidak
          // tertutup FAB yang mengambang di kanan-bawah.
          if (state.canAddRequest) const SizedBox(height: 72),
        ],
      ),
    );
  }
}
