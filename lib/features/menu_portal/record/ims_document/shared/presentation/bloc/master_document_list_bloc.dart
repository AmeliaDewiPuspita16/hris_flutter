import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../core/logging/app_logger.dart';
import '../../../../../../../core/network/api_exception.dart';
import '../../domain/master_document.dart';
import '../../domain/master_document_page.dart';
import 'master_document_list_event.dart';
import 'master_document_list_state.dart';

/// Memuat daftar dokumen master untuk satu tab (Manual, SOP, dst): halaman
/// pertama, halaman berikutnya, dan pencarian.
///
/// Sengaja tidak terikat ke satu kategori atau sumber — [fetcher] disuntik
/// lewat konstruktor, jadi bloc yang sama dipakai untuk tab mana pun, baik
/// dari API (Master Document File) maupun data demo (Master Edited File).
class MasterDocumentListBloc
    extends Bloc<MasterDocumentListEvent, MasterDocumentListState> {
  MasterDocumentListBloc({required MasterDocumentFetcher fetcher, String search = ''})
      : _fetcher = fetcher,
        super(MasterDocumentListState(search: search)) {
    on<MasterDocumentListStarted>((_, emit) => _reload(state.search, emit));
    on<MasterDocumentListRefreshed>((_, emit) => _reload(state.search, emit));
    on<MasterDocumentListSearched>((event, emit) => _reload(event.query, emit));
    on<MasterDocumentListNextPageRequested>(_onNextPage);
  }

  final MasterDocumentFetcher _fetcher;

  /// Pencarian yang diketik cepat bisa membalas dengan urutan terbalik —
  /// hasil yang bukan permintaan terakhir dibuang. Pola sama dengan
  /// `ItRequestListBloc`.
  int _requestToken = 0;

  Future<void> _reload(String search, Emitter<MasterDocumentListState> emit) async {
    final token = ++_requestToken;

    emit(state.copyWith(
      status: MasterDocumentListStatus.loading,
      search: search,
      loadingMore: false,
      errorMessage: null,
    ));

    try {
      final page = await _fetcher(page: 1, search: search);
      if (token != _requestToken) return;

      emit(state.copyWith(
        status: MasterDocumentListStatus.success,
        documents: page.items,
        meta: page.meta,
      ));
    } catch (e, stack) {
      if (token != _requestToken) return;

      AppLogger.error('Daftar dokumen master gagal dimuat', e, stack);
      emit(state.copyWith(
        status: MasterDocumentListStatus.failure,
        documents: const [],
        errorMessage: e is ApiException ? e.message : 'Failed to load documents. Please try again.',
      ));
    }
  }

  Future<void> _onNextPage(
    MasterDocumentListNextPageRequested event,
    Emitter<MasterDocumentListState> emit,
  ) async {
    if (state.loadingMore || !state.meta.hasMore) return;
    if (state.status != MasterDocumentListStatus.success) return;

    final token = _requestToken;
    emit(state.copyWith(loadingMore: true));

    try {
      final page = await _fetcher(page: state.meta.currentPage + 1, search: state.search);
      if (token != _requestToken) return;

      emit(state.copyWith(
        documents: _appendWithoutDuplicates(state.documents, page.items),
        meta: page.meta,
        loadingMore: false,
      ));
    } catch (e, stack) {
      if (token != _requestToken) return;

      AppLogger.error('Halaman dokumen master berikutnya gagal', e, stack);
      emit(state.copyWith(loadingMore: false));
    }
  }

  /// Dokumen tanpa id (data demo) tidak pernah dipaginasi, jadi cukup dedup
  /// berdasarkan id.
  List<MasterDocument> _appendWithoutDuplicates(
    List<MasterDocument> existing,
    List<MasterDocument> incoming,
  ) {
    final seenIds = existing.map((doc) => doc.id).whereType<int>().toSet();
    return [
      ...existing,
      ...incoming.where((doc) => doc.id == null || seenIds.add(doc.id!)),
    ];
  }
}
