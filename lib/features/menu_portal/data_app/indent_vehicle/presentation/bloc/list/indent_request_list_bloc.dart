import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../core/logging/app_logger.dart';
import '../../../../../../../core/network/api_exception.dart';
import '../../../data/indent_vehicle_repository.dart';
import 'indent_request_list_event.dart';
import 'indent_request_list_state.dart';

/// Memuat daftar "List of User Requests" dari `GET /api/indent`, halaman
/// demi halaman (infinite scroll).
///
/// [currentUserId] diambil layar dari sesi login (AuthBloc) dan diteruskan
/// ke repository, supaya request milik sendiri bisa ditandai (hak
/// edit/hapus & banner feedback hanya untuk milik sendiri).
class IndentRequestListBloc
    extends Bloc<IndentRequestListEvent, IndentRequestListState> {
  IndentRequestListBloc({
    required IndentVehicleRepository repository,
    int? currentUserId,
  })  : _repository = repository,
        _currentUserId = currentUserId,
        super(const IndentRequestListState()) {
    on<IndentRequestListStarted>(_onLoad);
    on<IndentRequestListRefreshed>(_onLoad);
    on<IndentRequestListNextPageRequested>(_onNextPage);
    on<IndentRequestLocalAdded>(_onLocalAdded);
    on<IndentRequestLocalUpdated>(_onLocalUpdated);
    on<IndentRequestLocalRemoved>(_onLocalRemoved);
  }

  final IndentVehicleRepository _repository;
  final int? _currentUserId;

  /// Permintaan yang tumpang tindih (mis. refresh ditekan dua kali, atau
  /// refresh saat halaman berikutnya masih dimuat) bisa membalas dengan
  /// urutan terbalik. Hasil yang bukan permintaan terakhir dibuang.
  int _requestToken = 0;

  /// Muat awal / refresh: selalu mulai lagi dari halaman 1.
  Future<void> _onLoad(
    IndentRequestListEvent event,
    Emitter<IndentRequestListState> emit,
  ) async {
    final token = ++_requestToken;

    emit(state.copyWith(
      status: IndentRequestListStatus.loading,
      loadingMore: false,
      errorMessage: null,
    ));

    try {
      final page = await _repository.fetchRequests(
        page: 1,
        currentUserId: _currentUserId,
      );
      if (token != _requestToken) return;

      emit(state.copyWith(
        status: IndentRequestListStatus.success,
        items: page.items,
        meta: page.meta,
      ));
    } on ApiException catch (e) {
      if (token != _requestToken) return;

      AppLogger.info('List Indent gagal dimuat: ${e.kind.name} — ${e.message}');
      emit(state.copyWith(
        status: IndentRequestListStatus.failure,
        items: const [],
        errorMessage: e.message,
      ));
    } catch (e, stack) {
      if (token != _requestToken) return;

      AppLogger.error('List Indent gagal karena galat tak terduga', e, stack);
      emit(state.copyWith(
        status: IndentRequestListStatus.failure,
        items: const [],
        errorMessage: 'Terjadi kesalahan tak terduga. Coba lagi.',
      ));
    }
  }

  /// Halaman berikutnya ditambahkan di bawah daftar yang sudah ada. Bila
  /// gagal, daftar yang sudah tampil dibiarkan utuh (tidak diganti layar
  /// galat) — menggulir lagi akan mencoba sekali lagi.
  Future<void> _onNextPage(
    IndentRequestListNextPageRequested event,
    Emitter<IndentRequestListState> emit,
  ) async {
    if (state.loadingMore ||
        !state.meta.hasMore ||
        state.status != IndentRequestListStatus.success) {
      return;
    }

    final token = _requestToken;
    emit(state.copyWith(loadingMore: true));

    try {
      final page = await _repository.fetchRequests(
        page: state.meta.currentPage + 1,
        currentUserId: _currentUserId,
      );
      if (token != _requestToken) return;

      // Request baru yang masuk di sela-sela halaman mendorong item lama
      // ke halaman berikutnya, sehingga bisa muncul dua kali. Buang yang
      // sudah ada.
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

  void _onLocalAdded(
    IndentRequestLocalAdded event,
    Emitter<IndentRequestListState> emit,
  ) {
    emit(state.copyWith(items: [event.item, ...state.items]));
  }

  void _onLocalUpdated(
    IndentRequestLocalUpdated event,
    Emitter<IndentRequestListState> emit,
  ) {
    emit(state.copyWith(
      items: [
        for (final item in state.items)
          if (item.id == event.item.id) event.item else item,
      ],
    ));
  }

  void _onLocalRemoved(
    IndentRequestLocalRemoved event,
    Emitter<IndentRequestListState> emit,
  ) {
    emit(state.copyWith(
      items: state.items.where((item) => item.id != event.id).toList(),
    ));
  }
}
