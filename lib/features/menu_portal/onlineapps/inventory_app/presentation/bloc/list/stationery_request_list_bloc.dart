import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../core/logging/app_logger.dart';
import '../../../../../../../core/network/api_exception.dart';
import '../../../data/inventory_stationery_repository.dart';
import 'stationery_request_list_event.dart';
import 'stationery_request_list_state.dart';

/// Memuat daftar "Request Items" stationery halaman demi halaman (infinite
/// scroll). Polanya sama dengan `EstRequestListBloc`.
///
/// Tidak butuh id user: server sudah menandai request milik sendiri lewat
/// `is_mine`, dan hak edit/cancel lewat `can_edit` / `can_cancel`.
class StationeryRequestListBloc
    extends Bloc<StationeryRequestListEvent, StationeryRequestListState> {
  StationeryRequestListBloc({required InventoryStationeryRepository repository})
      : _repository = repository,
        super(const StationeryRequestListState()) {
    on<StationeryRequestListStarted>(_onLoad);
    on<StationeryRequestListRefreshed>(_onLoad);
    on<StationeryRequestListNextPageRequested>(_onNextPage);
  }

  final InventoryStationeryRepository _repository;

  /// Permintaan yang tumpang tindih bisa membalas dengan urutan terbalik;
  /// hasil yang bukan permintaan terakhir dibuang.
  int _requestToken = 0;

  Future<void> _onLoad(
    StationeryRequestListEvent event,
    Emitter<StationeryRequestListState> emit,
  ) async {
    final token = ++_requestToken;

    emit(state.copyWith(
      status: StationeryRequestListStatus.loading,
      loadingMore: false,
      errorMessage: null,
    ));

    try {
      final page = await _repository.fetchRequests(page: 1);
      if (token != _requestToken) return;

      emit(state.copyWith(
        status: StationeryRequestListStatus.success,
        items: page.items,
        meta: page.meta,
        counts: page.counts,
      ));
    } on ApiException catch (e) {
      if (token != _requestToken) return;

      AppLogger.info('List stationery gagal dimuat: ${e.kind.name} — ${e.message}');
      emit(state.copyWith(
        status: StationeryRequestListStatus.failure,
        items: const [],
        errorMessage: e.message,
      ));
    } catch (e, stack) {
      if (token != _requestToken) return;

      AppLogger.error('List stationery gagal karena galat tak terduga', e, stack);
      emit(state.copyWith(
        status: StationeryRequestListStatus.failure,
        items: const [],
        errorMessage: 'An unexpected error occurred. Please try again.',
      ));
    }
  }

  /// Halaman berikutnya ditambahkan di bawah daftar yang ada. Bila gagal,
  /// daftar yang sudah tampil dibiarkan utuh — menggulir lagi mencoba lagi.
  Future<void> _onNextPage(
    StationeryRequestListNextPageRequested event,
    Emitter<StationeryRequestListState> emit,
  ) async {
    if (state.loadingMore ||
        !state.meta.hasMore ||
        state.status != StationeryRequestListStatus.success) {
      return;
    }

    final token = _requestToken;
    emit(state.copyWith(loadingMore: true));

    try {
      final page =
          await _repository.fetchRequests(page: state.meta.currentPage + 1);
      if (token != _requestToken) return;

      // Request baru yang masuk di sela-sela halaman mendorong item lama ke
      // halaman berikutnya, sehingga bisa muncul dua kali. Buang duplikatnya.
      final known = {for (final item in state.items) item.id};
      final fresh = page.items.where((item) => !known.contains(item.id));

      emit(state.copyWith(
        items: [...state.items, ...fresh],
        meta: page.meta,
        loadingMore: false,
      ));
    } on ApiException catch (e) {
      if (token != _requestToken) return;

      AppLogger.info('Halaman berikutnya gagal: ${e.kind.name} — ${e.message}');
      emit(state.copyWith(loadingMore: false));
    } catch (e, stack) {
      if (token != _requestToken) return;

      AppLogger.error('Halaman berikutnya gagal tak terduga', e, stack);
      emit(state.copyWith(loadingMore: false));
    }
  }
}
