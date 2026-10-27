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
import '../../data/ims_web_links.dart';
import '../screens/document_viewer_screen.dart';
import 'ims_web_download_dialog.dart';
import 'master_document_tile.dart';

/// Isi satu tab dokumen (Manual, SOP, dst) — daftar dokumen dari [fetcher]
/// yang mana pun, dipaginasi dan dicari lewat [fetcher] juga.
///
/// Dipakai ulang oleh Master Document File (API) dan Master Edited File
/// (data demo), tinggal beda [fetcher]-nya — sama seperti
/// `MasterDocumentListBloc` yang didesain generik per kategori. Dokumen tanpa
/// `obsoleteUrl` otomatis tidak menampilkan tombol "Obsolete" karena diatur
/// oleh [MasterDocumentTile].
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
            message: state.errorMessage ?? 'Gagal memuat dokumen.',
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
                          ? 'Belum ada dokumen di kategori ini.'
                          : 'Tidak ada dokumen yang cocok dengan pencarian.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMuted,
                    ),
                  ],
                )
              : ListView.separated(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: documents.length + (state.loadingMore ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    if (index >= documents.length) {
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

                    final document = documents[index];

                    return MasterDocumentTile(
                      document: document,
                      onView: (doc) => _view(context, doc),
                      onDownload: (doc) => _download(context, doc),
                      onObsolete: (doc) => _openOnWeb(context, doc.obsoleteUrl ?? doc.downloadUrl),
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

  /// Dokumen tidak diunduh di aplikasi: tampilkan penjelasan dulu, lalu
  /// arahkan ke website IMS kalau user setuju.
  Future<void> _download(BuildContext context, MasterDocument doc) async {
    final confirmed = await showImsWebDownloadDialog(context);
    if (!confirmed || !context.mounted) return;
    await _openOnWeb(context, doc.downloadUrl);
  }

  /// Buka [url] di browser; kasih tahu user kalau gagal.
  ///
  /// TODO(api): API belum mengirim alamat unduh di website, jadi
  /// [MasterDocument.downloadUrl] / `obsoleteUrl` sementara berisi
  /// `ImsWebLinks.documentsPage`.
  Future<void> _openOnWeb(BuildContext context, String url) async {
    final opened = await ImsWebLinks.open(url);
    if (opened || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tidak dapat membuka website IMS.')),
    );
  }
}

/// Skeleton daftar dokumen selagi tab pertama dimuat. Meniru
/// [MasterDocumentTile]: judul + keterangan, lalu baris aksi file
/// (Download / Obsolete) berbentuk kotak memanjang.
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerLine(width: 200, height: 14),
                SizedBox(height: 8),
                ShimmerLine(width: 130, height: 10),
                SizedBox(height: 12),
                ShimmerBox(height: 38, borderRadius: 10),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
