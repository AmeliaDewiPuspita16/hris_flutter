import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../../core/logging/app_logger.dart';
import '../../../../../../../../core/network/api_exception.dart';
import '../../../data/it_request_repository.dart';
import '../../../domain/it_request_summary.dart';
import 'it_request_list_event.dart';
import 'it_request_list_state.dart';

/// Mengurus riwayat IT/Media Request: memuat halaman, menambah halaman
/// berikutnya, dan dua penyesuaian lokal (tambah request, beri feedback)
/// yang belum punya endpoint submit di server.
class ItRequestListBloc extends Bloc<ItRequestListEvent, ItRequestListState> {
  ItRequestListBloc({required ItRequestRepository repository})
      : _repository = repository,
        super(const ItRequestListState()) {
    on<ItRequestListStarted>(_onReload);
    on<ItRequestListRefreshed>(_onReload);
    on<ItRequestListNextPageRequested>(_onNextPage);
    on<ItRequestLocalItemAdded>(_onLocalItemAdded);
    on<ItRequestLocalFeedbackGiven>(_onLocalFeedbackGiven);
  }

  final ItRequestRepository _repository;

  /// Sama alasannya dengan `ProcurementListBloc`: dua permintaan halaman
  /// pertama yang tumpang tindih (mis. refresh ditekan dua kali) bisa
  /// membalas dengan urutan terbalik. Hasil yang bukan permintaan terakhir
  /// dibuang.
  int _requestToken = 0;

  Future<void> _onReload(
    ItRequestListEvent event,
    Emitter<ItRequestListState> emit,
  ) async {
    final token = ++_requestToken;

    emit(state.copyWith(
      status: ItRequestListStatus.loading,
      errorMessage: null,
    ));

    try {
      final page = await _repository.fetchList(page: 1);
      if (token != _requestToken) return;

      emit(state.copyWith(
        status: ItRequestListStatus.success,
        items: page.items,
        summary: page.summary,
        meta: page.meta,
        loadingMore: false,
      ));
    } on ApiException catch (e) {
      if (token != _requestToken) return;

      AppLogger.info('Riwayat IT Request gagal dimuat: ${e.kind.name} — ${e.message}');
      emit(state.copyWith(
        status: ItRequestListStatus.failure,
        items: const [],
        errorMessage: e.message,
        loadingMore: false,
      ));
    } catch (e, stack) {
      if (token != _requestToken) return;

      AppLogger.error('Riwayat IT Request gagal karena galat tak terduga', e, stack);
      emit(state.copyWith(
        status: ItRequestListStatus.failure,
        items: const [],
        errorMessage: 'Terjadi kesalahan tak terduga. Coba lagi.',
        loadingMore: false,
      ));
    }
  }

  Future<void> _onNextPage(
    ItRequestListNextPageRequested event,
    Emitter<ItRequestListState> emit,
  ) async {
    if (state.loadingMore || !state.meta.hasMore) return;
    if (state.status != ItRequestListStatus.success) return;

    final token = _requestToken;
    emit(state.copyWith(loadingMore: true));

    try {
      final page = await _repository.fetchList(page: state.meta.currentPage + 1);
      if (token != _requestToken) return;

      emit(state.copyWith(
        items: [...state.items, ...page.items],
        summary: page.summary,
        meta: page.meta,
        loadingMore: false,
      ));
    } on ApiException catch (e) {
      if (token != _requestToken) return;

      AppLogger.info('Halaman IT Request berikutnya gagal: ${e.message}');
      emit(state.copyWith(loadingMore: false, errorMessage: e.message));
    }
  }

  void _onLocalItemAdded(
    ItRequestLocalItemAdded event,
    Emitter<ItRequestListState> emit,
  ) {
    emit(state.copyWith(
      items: [event.item, ...state.items],
      meta: state.meta.copyWith(total: state.meta.total + 1),
    ));
  }

  void _onLocalFeedbackGiven(
    ItRequestLocalFeedbackGiven event,
    Emitter<ItRequestListState> emit,
  ) {
    emit(state.copyWith(
      items: [
        for (final item in state.items)
          if (item.id == event.id)
            item.copyWith(rating: event.rating, canRate: false)
          else
            item,
      ],
      summary: ItRequestSummary(
        awaitingRating:
            state.summary.awaitingRating > 0 ? state.summary.awaitingRating - 1 : 0,
      ),
    ));
  }
}
