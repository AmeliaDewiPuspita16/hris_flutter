import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/widgets/app_shimmer.dart';
import '../../../../../../core/widgets/flash_highlight.dart';
import '../../../../../../core/widgets/app_text_field.dart';
import '../../../../shared/presentation/widgets/portal_category_page.dart';
import '../../data/procurement_repository.dart';
import '../../domain/purchase_requisition_summary.dart';
import '../bloc/list/procurement_list_bloc.dart';
import '../bloc/list/procurement_list_event.dart';
import '../bloc/list/procurement_list_state.dart';
import '../widgets/pr_card.dart';
import '../widgets/pr_status_filter_bar.dart';
import '../../../../../../core/widgets/app_error_view.dart';
import 'pr_detail_screen.dart';

/// Halaman Procurement Monitoring — daftar Purchase Requisition.
///
/// Versi mobile dari tabel PR di web: hanya pemantauan, tanpa "Create PR" dan
/// "Receiving". Filter status, pencarian, dan paginasi semuanya dikerjakan
/// server; filter Section dan rentang tanggal belum ikut.
class ProcurementPage extends StatelessWidget {
  const ProcurementPage({
    super.key,
    this.repository,
    this.initialStatusCode,
    this.highlightId,
  });

  /// Diisi test; di aplikasi diambil dari [RepositoryProvider].
  final ProcurementRepository? repository;

  /// Kode status yang langsung aktif saat halaman dibuka, mis. `pending_hod`
  /// (lihat `PrStatusCode`). Null = chip "Semua".
  final String? initialStatusCode;

  /// id PR dari notifikasi yang di-tap; kartunya dinaikkan ke paling atas
  /// dan dikedipkan. Hilang begitu filter atau pencarian diubah.
  final int? highlightId;

  @override
  Widget build(BuildContext context) {
    final procurement = repository ?? context.read<ProcurementRepository>();

    return BlocProvider(
      create: (_) => ProcurementListBloc(
        repository: procurement,
        initialStatusCode: initialStatusCode,
      )..add(const ProcurementListStarted()),
      child: _ProcurementView(
        repository: procurement,
        highlightId: highlightId,
      ),
    );
  }
}

class _ProcurementView extends StatefulWidget {
  const _ProcurementView({required this.repository, this.highlightId});

  final int? highlightId;

  /// Diteruskan ke layar detail saat sebuah kartu dibuka — detail punya
  /// bloc-nya sendiri, bukan berbagi dengan daftar.
  final ProcurementRepository repository;

  @override
  State<_ProcurementView> createState() => _ProcurementViewState();
}

class _ProcurementViewState extends State<_ProcurementView> {
  /// Jeda sebelum ketikan dikirim ke server. Cukup lama untuk melewati
  /// ketikan beruntun, cukup singkat supaya tidak terasa menggantung.
  static const _searchDebounce = Duration(milliseconds: 400);

  /// Sisa ruang gulir yang memicu pemuatan halaman berikutnya.
  static const _loadMoreThreshold = 320.0;

  final _searchController = TextEditingController();

  Timer? _debounce;

  /// Salinan [_ProcurementView.highlightId] yang dikosongkan saat user
  /// mengganti filter/pencarian, supaya kedipnya tidak muncul lagi.
  late int? _highlightId = widget.highlightId;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Lewat notifikasi, bukan `ScrollController` sendiri: daftar ini harus
  /// memakai `PrimaryScrollController` supaya geraknya menyatu dengan
  /// header `PortalModulePage`.
  bool _onScroll(ScrollNotification notification) {
    if (notification.depth != 0 || notification.metrics.axis != Axis.vertical) {
      return false;
    }
    if (notification.metrics.extentAfter > _loadMoreThreshold) return false;

    context.read<ProcurementListBloc>().add(
          const ProcurementListNextPageRequested(),
        );
    return false;
  }

  /// Menunda pengiriman kata kunci supaya mengetik satu kalimat tidak jadi
  /// satu request per huruf.
  void _onSearchChanged(String value) {
    if (_highlightId != null) setState(() => _highlightId = null);
    _debounce?.cancel();
    _debounce = Timer(_searchDebounce, () {
      if (!mounted) return;
      context.read<ProcurementListBloc>().add(ProcurementListSearched(value));
    });
  }

  Future<void> _openDetail(PurchaseRequisitionSummary requisition) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PrDetailScreen(
          summary: requisition,
          repository: widget.repository,
        ),
      ),
    );

    // Keputusan di layar detail mengubah status PR (dan angka di chip),
    // jadi daftar diambil ulang begitu user kembali.
    if (!mounted) return;
    context.read<ProcurementListBloc>().add(const ProcurementListRefreshed());
  }

  Future<void> _refresh() async {
    final bloc = context.read<ProcurementListBloc>()
      ..add(const ProcurementListRefreshed());

    await bloc.stream.firstWhere(
      (state) => state.status != ProcurementListStatus.loading,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PortalModulePage(
      title: 'E-Procurement',
      subtitle: 'Track purchase requisitions and their approval progress.',
      illustrationAsset: PortalCategoryPage.laptopIllustration,
      body: BlocBuilder<ProcurementListBloc, ProcurementListState>(
        builder: (context, state) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: AppTextField(
                  controller: _searchController,
                  hint: 'PR Number, requestor, or purpose',
                  icon: Icons.search,
                  onChanged: _onSearchChanged,
                ),
              ),
              PrStatusFilterBar(
                counts: state.summary,
                selected: state.statusCode,
                onChanged: (code) {
                  if (_highlightId != null) setState(() => _highlightId = null);
                  context
                      .read<ProcurementListBloc>()
                      .add(ProcurementListStatusSelected(code));
                },
              ),
              const SizedBox(height: 12),
              Expanded(child: _buildBody(context, state)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, ProcurementListState state) {
    if (state.isFirstLoad) {
      return ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          ShimmerList(
            itemCount: 5,
            itemBuilder: (context) => const _PrCardSkeleton(),
          ),
        ],
      );
    }

    // Galat hanya mengambil alih layar saat belum ada apa pun yang tampil.
    // Kalau daftar sudah ada, kegagalan memuat halaman berikutnya tidak
    // boleh menghapus yang sudah dibaca orang.
    if (state.status == ProcurementListStatus.failure && state.items.isEmpty) {
      return AppErrorView(
        message: state.errorMessage ?? 'Gagal memuat daftar PR.',
        onRetry: () => context
            .read<ProcurementListBloc>()
            .add(const ProcurementListRefreshed()),
      );
    }

    if (state.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: 240,
              child: Center(
                child: Text('Tidak ada data', style: AppTextStyles.bodyMuted),
              ),
            ),
          ],
        ),
      );
    }

    // Dari notifikasi: PR yang dimaksud dinaikkan ke paling atas (daftar
    // ini panjang dan dibangun malas) lalu dikedipkan.
    final items = [...state.items];
    final highlightId = _highlightId;
    if (highlightId != null) {
      final at = items.indexWhere((r) => r.id == highlightId);
      if (at > 0) items.insert(0, items.removeAt(at));
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          // Satu baris tambahan di bawah untuk skeleton halaman berikutnya.
          itemCount: items.length + (state.loadingMore ? 1 : 0),
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            if (i >= items.length) {
              return const _PrCardSkeleton();
            }

            return FlashHighlight(
              key: ValueKey('hl-${items[i].id}'),
              active: items[i].id == highlightId,
              child: PrCard(
                requisition: items[i],
                onTap: () => _openDetail(items[i]),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Skeleton satu [PrCard]: nomor PR + badge status, dua baris keterangan,
/// lalu baris bawah (jumlah item / tanggal).
class _PrCardSkeleton extends StatelessWidget {
  const _PrCardSkeleton();

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
                  child: ShimmerLine(width: 130, height: 14),
                ),
              ),
              SizedBox(width: 8),
              ShimmerBox(width: 64, height: 20, borderRadius: 20),
            ],
          ),
          SizedBox(height: 10),
          ShimmerLine(height: 11),
          SizedBox(height: 6),
          ShimmerLine(width: 170, height: 11),
          SizedBox(height: 12),
          Row(
            children: [
              ShimmerBox(width: 60, height: 18, borderRadius: 20),
              Spacer(),
              ShimmerLine(width: 70, height: 10),
            ],
          ),
        ],
      ),
    );
  }
}
