import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/widgets/app_text_field.dart';
import '../../../../../../core/widgets/back_header.dart';
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
  const ProcurementPage({super.key, this.repository});

  /// Diisi test; di aplikasi diambil dari [RepositoryProvider].
  final ProcurementRepository? repository;

  @override
  Widget build(BuildContext context) {
    final procurement = repository ?? context.read<ProcurementRepository>();

    return BlocProvider(
      create: (_) => ProcurementListBloc(repository: procurement)
        ..add(const ProcurementListStarted()),
      child: _ProcurementView(repository: procurement),
    );
  }
}

class _ProcurementView extends StatefulWidget {
  const _ProcurementView({required this.repository});

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
  final _scrollController = ScrollController();

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final remaining = _scrollController.position.maxScrollExtent -
        _scrollController.position.pixels;
    if (remaining > _loadMoreThreshold) return;

    context.read<ProcurementListBloc>().add(
          const ProcurementListNextPageRequested(),
        );
  }

  /// Menunda pengiriman kata kunci supaya mengetik satu kalimat tidak jadi
  /// satu request per huruf.
  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(_searchDebounce, () {
      if (!mounted) return;
      context.read<ProcurementListBloc>().add(ProcurementListSearched(value));
    });
  }

  void _openDetail(PurchaseRequisitionSummary requisition) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PrDetailScreen(
          summary: requisition,
          repository: widget.repository,
        ),
      ),
    );
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
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: BackHeader(
        title: 'Procurement Monitoring',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: BlocBuilder<ProcurementListBloc, ProcurementListState>(
        builder: (context, state) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: AppTextField(
                  label: 'Cari',
                  controller: _searchController,
                  hint: 'Nomor PR, requestor, atau purpose',
                  icon: Icons.search,
                  onChanged: _onSearchChanged,
                ),
              ),
              PrStatusFilterBar(
                counts: state.summary,
                selected: state.statusCode,
                onChanged: (code) => context
                    .read<ProcurementListBloc>()
                    .add(ProcurementListStatusSelected(code)),
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
      return const Center(child: CircularProgressIndicator());
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
          controller: _scrollController,
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

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        // Satu baris tambahan di bawah untuk spinner halaman berikutnya.
        itemCount: state.items.length + (state.loadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          if (i >= state.items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          return PrCard(
            requisition: state.items[i],
            onTap: () => _openDetail(state.items[i]),
          );
        },
      ),
    );
  }
}
