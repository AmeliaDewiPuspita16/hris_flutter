import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/widgets/app_error_view.dart';
import '../../../../../../core/widgets/app_shimmer.dart';
import '../../../../../../core/widgets/app_text_field.dart';
import '../../../../shared/presentation/widgets/portal_category_page.dart';
import '../../data/meter_reading_repository.dart';
import '../../domain/meter_reading_state.dart';
import '../../domain/meter_reading_summary.dart';
import '../bloc/list/meter_reading_list_bloc.dart';
import '../bloc/list/meter_reading_list_event.dart';
import '../bloc/list/meter_reading_list_state.dart';
import 'meter_reading_detail_screen.dart';
import '../widgets/meter_category_filter.dart';
import '../widgets/meter_load_more_retry.dart';
import '../widgets/meter_progress_summary.dart';
import '../widgets/meter_reading_card.dart';
import '../widgets/meter_reading_empty_view.dart';
import '../widgets/meter_state_filter_bar.dart';

/// Halaman Meter Reading — daftar meter yang harus dicatat petugas.
///
/// Versi mobile dari tabel di web, dirancang ulang untuk kerja lapangan:
/// kartu per meter dengan angka terakhir sebagai fokus, filter status
/// pencatatan (terutama "Not recorded"), kategori lewat bottom sheet, dan
/// pencarian. Filter, pencarian, dan paginasi dikerjakan sisi server.
class MeterReadingScreen extends StatelessWidget {
  const MeterReadingScreen({
    super.key,
    this.repository,
    this.initialStateCode,
  });

  /// Diisi test; di aplikasi diambil dari [RepositoryProvider].
  final MeterReadingRepository? repository;

  /// `MeterReadingState.code` yang langsung aktif saat halaman dibuka, mis.
  /// `pending`. Null = chip "All".
  final String? initialStateCode;

  @override
  Widget build(BuildContext context) {
    final meterReading = repository ?? context.read<MeterReadingRepository>();

    return BlocProvider(
      create: (_) => MeterReadingListBloc(
        repository: meterReading,
        initialStateCode: initialStateCode,
      )..add(const MeterReadingListStarted()),
      child: _MeterReadingView(repository: meterReading),
    );
  }
}

class _MeterReadingView extends StatefulWidget {
  const _MeterReadingView({required this.repository});

  /// Diteruskan ke layar detail saat sebuah kartu dibuka — detail punya
  /// bloc-nya sendiri, bukan berbagi dengan daftar.
  final MeterReadingRepository repository;

  @override
  State<_MeterReadingView> createState() => _MeterReadingViewState();
}

class _MeterReadingViewState extends State<_MeterReadingView> {
  /// Jeda sebelum ketikan dikirim ke server.
  static const _searchDebounce = Duration(milliseconds: 400);

  /// Sisa ruang gulir yang memicu pemuatan halaman berikutnya.
  static const _loadMoreThreshold = 320.0;

  final _searchController = TextEditingController();
  Timer? _debounce;

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

    context.read<MeterReadingListBloc>().add(
          const MeterReadingListNextPageRequested(),
        );
    return false;
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(_searchDebounce, () {
      if (!mounted) return;
      context.read<MeterReadingListBloc>().add(MeterReadingListSearched(value));
    });
  }

  Future<void> _pickCategory(MeterReadingListState state) async {
    final picked = await showMeterCategorySheet(
      context,
      categories: state.categories,
      selectedCode: state.categoryCode,
    );
    if (picked == null || !mounted) return;

    context
        .read<MeterReadingListBloc>()
        .add(MeterReadingListCategorySelected(picked.code));
  }

  void _resetFilters() {
    _debounce?.cancel();
    _searchController.clear();
    context.read<MeterReadingListBloc>().add(const MeterReadingListFiltersCleared());
  }

  /// Membuka detail, lalu mengambil ulang daftar begitu user kembali:
  /// mencatat pembacaan mengubah status baris dan angka di chip, dan daftar
  /// tidak perlu menebak-nebak perubahannya.
  ///
  /// [startRecording] true bila datang dari jalan pintas "Record reading" —
  /// detail langsung membuka form begitu rinciannya termuat.
  Future<void> _openDetail(
    MeterReadingSummary reading, {
    bool startRecording = false,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MeterReadingDetailScreen(
          summary: reading,
          repository: widget.repository,
          startRecording: startRecording,
        ),
      ),
    );
    if (!mounted) return;

    context.read<MeterReadingListBloc>().add(const MeterReadingListRefreshed());
  }

  Future<void> _refresh() async {
    final bloc = context.read<MeterReadingListBloc>()
      ..add(const MeterReadingListRefreshed());

    await bloc.stream.firstWhere(
      (state) => state.status != MeterReadingListStatus.loading,
    );
  }

  String _categoryLabel(MeterReadingListState state) {
    for (final category in state.categories) {
      if (category.code == state.categoryCode) return category.label;
    }
    return state.categoryCode ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return PortalModulePage(
      title: 'Meter Reading',
      subtitle: 'Record utility meter readings and manage their billing.',
      illustrationAsset: PortalCategoryPage.meterIllustration,
      body: BlocBuilder<MeterReadingListBloc, MeterReadingListState>(
        builder: (context, state) {
          return Column(
            children: [
              MeterProgressSummary(counts: state.counts),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _searchController,
                        hint: 'Search company or location',
                        icon: Icons.search,
                        onChanged: _onSearchChanged,
                      ),
                    ),
                    if (state.categories.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      MeterCategoryButton(
                        active: state.categoryCode != null,
                        onTap: () => _pickCategory(state),
                      ),
                    ],
                  ],
                ),
              ),
              MeterStateFilterBar(
                counts: state.counts,
                selected: state.stateCode,
                onChanged: (code) => context
                    .read<MeterReadingListBloc>()
                    .add(MeterReadingListStateSelected(code)),
              ),
              if (state.categoryCode != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: MeterActiveCategoryChip(
                      label: _categoryLabel(state),
                      onClear: () => context
                          .read<MeterReadingListBloc>()
                          .add(const MeterReadingListCategorySelected(null)),
                    ),
                  ),
                ),
              const SizedBox(height: 14),
              Expanded(child: _buildBody(context, state)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, MeterReadingListState state) {
    // `initial` sebentar saja: bloc baru menerima event Started.
    if (state.isFirstLoad || state.status == MeterReadingListStatus.initial) {
      return ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          ShimmerList(
            itemCount: 5,
            itemBuilder: (context) => const MeterReadingCardSkeleton(),
          ),
        ],
      );
    }

    // Galat hanya mengambil alih layar saat belum ada apa pun yang tampil.
    if (state.status == MeterReadingListStatus.failure && state.items.isEmpty) {
      return AppErrorView(
        message: state.errorMessage ?? 'Failed to load meter readings.',
        onRetry: () => context
            .read<MeterReadingListBloc>()
            .add(const MeterReadingListRefreshed()),
      );
    }

    if (state.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            MeterReadingEmptyView(
              hasActiveFilter: state.hasActiveFilter,
              allRecorded: state.stateCode == MeterReadingState.pending.code &&
                  state.query.trim().isEmpty &&
                  state.categoryCode == null,
              onReset: _resetFilters,
            ),
          ],
        ),
      );
    }

    // Satu baris tambahan di bawah: skeleton saat memuat halaman berikutnya,
    // atau tombol "Retry" bila gagal.
    final hasFooter = state.loadingMore || state.loadMoreError != null;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          itemCount: state.items.length + (hasFooter ? 1 : 0),
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            if (i >= state.items.length) {
              if (state.loadingMore) return const MeterReadingCardSkeleton();

              return MeterLoadMoreRetry(
                message: state.loadMoreError ?? 'Could not load more.',
                onRetry: () => context
                    .read<MeterReadingListBloc>()
                    .add(const MeterReadingListNextPageRetried()),
              );
            }

            final reading = state.items[i];
            return MeterReadingCard(
              reading: reading,
              onTap: () => _openDetail(reading),
              onRecord: () => _openDetail(reading, startRecording: true),
            );
          },
        ),
      ),
    );
  }
}
