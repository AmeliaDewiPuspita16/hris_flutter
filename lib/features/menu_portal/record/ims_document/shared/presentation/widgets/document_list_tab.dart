import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../../core/widgets/app_error_view.dart';
import '../../../../../../../core/widgets/app_shimmer.dart';
import '../../domain/master_document.dart';
import '../../domain/master_document_page.dart';
import '../bloc/master_document_list_bloc.dart';
import '../bloc/master_document_list_event.dart';
import '../bloc/master_document_list_state.dart';
import '../screens/document_viewer_screen.dart';
import 'master_document_tile.dart';

/// Isi satu tab dokumen (Manual, SOP, dst) — daftar dokumen dari [fetcher]
/// yang mana pun, dipaginasi dan dicari lewat [fetcher] juga.
///
/// Dipakai ulang oleh Master Document File (API) dan Master Edited File
/// (data demo), tinggal beda [fetcher]-nya — sama seperti
/// `MasterDocumentListBloc` yang didesain generik per kategori.
class DocumentListTab extends StatelessWidget {
  const DocumentListTab({
    super.key,
    required this.fetcher,
    required this.searchQuery,
    this.pdfHeaders = const {},
  });

  final MasterDocumentFetcher fetcher;
  final String searchQuery;

  /// Header untuk memuat PDF di viewer (mis. `Authorization`).
  final Map<String, String> pdfHeaders;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MasterDocumentListBloc(fetcher: fetcher, search: searchQuery)
        ..add(const MasterDocumentListStarted()),
      child: _DocumentListView(searchQuery: searchQuery, pdfHeaders: pdfHeaders),
    );
  }
}

class _DocumentListView extends StatefulWidget {
  const _DocumentListView({required this.searchQuery, required this.pdfHeaders});

  final String searchQuery;
  final Map<String, String> pdfHeaders;

  @override
  State<_DocumentListView> createState() => _DocumentListViewState();
}

class _DocumentListViewState extends State<_DocumentListView> {
  /// Jeda sebelum ketikan dikirim ke server — pola sama dengan
  /// `ProcurementPage`.
  static const _searchDebounce = Duration(milliseconds: 400);

  /// Sisa ruang gulir yang memicu pemuatan halaman berikutnya.
  static const _loadMoreThreshold = 320.0;

  final _scrollController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant _DocumentListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery == widget.searchQuery) return;

    _debounce?.cancel();
    _debounce = Timer(_searchDebounce, () {
      if (!mounted) return;
      context.read<MasterDocumentListBloc>().add(MasterDocumentListSearched(widget.searchQuery));
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final remaining = _scrollController.position.maxScrollExtent - _scrollController.position.pixels;
    if (remaining > _loadMoreThreshold) return;

    context.read<MasterDocumentListBloc>().add(const MasterDocumentListNextPageRequested());
  }

  Future<void> _refresh() async {
    final bloc = context.read<MasterDocumentListBloc>()..add(const MasterDocumentListRefreshed());
    await bloc.stream.firstWhere((state) => state.status != MasterDocumentListStatus.loading);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MasterDocumentListBloc, MasterDocumentListState>(
      builder: (context, state) {
        if (state.status == MasterDocumentListStatus.loading ||
            state.status == MasterDocumentListStatus.initial) {
          return const _DocumentListSkeleton();
        }

        if (state.status == MasterDocumentListStatus.failure) {
          return AppErrorView(
            message: state.errorMessage ?? 'Failed to load documents.',
            onRetry: () => context.read<MasterDocumentListBloc>().add(const MasterDocumentListRefreshed()),
          );
        }

        final documents = state.documents;

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _refresh,
          child: documents.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(32),
                  children: [
                    Text(
                      state.search.trim().isEmpty
                          ? 'No documents in this category yet.'
                          : 'No documents match your search.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMuted,
                    ),
                  ],
                )
              : ListView.separated(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  // Baris pertama: jumlah dokumen; terakhir: spinner halaman
                  // berikutnya.
                  itemCount: documents.length + 1 + (state.loadingMore ? 1 : 0),
                  separatorBuilder: (_, index) => SizedBox(height: index == 0 ? 8 : 10),
                  itemBuilder: (context, index) {
                    if (index == 0) return _ResultCount(total: state.meta.total);

                    if (index > documents.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Center(
                          child: SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.primary),
                          ),
                        ),
                      );
                    }

                    return MasterDocumentTile(
                      document: documents[index - 1],
                      onView: (doc) => _view(context, doc),
                    );
                  },
                ),
        );
      },
    );
  }

  /// Baca PDF di aplikasi, tanpa opsi simpan — lihat [DocumentViewerScreen].
  void _view(BuildContext context, MasterDocument doc) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DocumentViewerScreen(document: doc, headers: widget.pdfHeaders),
      ),
    );
  }
}

/// "18 documents" di atas daftar — total dari server, bukan yang termuat.
class _ResultCount extends StatelessWidget {
  const _ResultCount({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    return Text(
      total == 1 ? '1 document' : '$total documents',
      style: AppTextStyles.caption.copyWith(
        color: AppColors.textMuted,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// Skeleton daftar dokumen selagi tab dimuat. Meniru [MasterDocumentTile]:
/// kotak ikon di kiri, nomor dokumen + judul + badge di kanan.
class _DocumentListSkeleton extends StatelessWidget {
  const _DocumentListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        ShimmerList(
          itemCount: 5,
          itemBuilder: (context) => const ShimmerCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: 42, height: 42, borderRadius: 12),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerLine(width: 150, height: 13),
                      SizedBox(height: 8),
                      ShimmerLine(height: 10),
                      SizedBox(height: 12),
                      ShimmerLine(width: 110, height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
