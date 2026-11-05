import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../core/logging/app_logger.dart';
import '../../../../../../../core/network/api_exception.dart';
import '../../../data/indent_vehicle_repository.dart';
import '../../../domain/indent_completed_item.dart';

enum IndentCompletedStatus { initial, loading, success, failure }

/// Keadaan tab "Completed".
class IndentCompletedState {
  const IndentCompletedState({
    this.status = IndentCompletedStatus.initial,
    this.items = const [],
    this.currentPage = 0,
    this.hasMore = false,
    this.loadingMore = false,
    this.errorMessage,
  });

  final IndentCompletedStatus status;
  final List<IndentCompletedItem> items;
  final int currentPage;
  final bool hasMore;
  final bool loadingMore;
  final String? errorMessage;

  /// Saat refresh, daftar lama tetap tampil.
  bool get isFirstLoad =>
      status == IndentCompletedStatus.loading && items.isEmpty;
}

/// Memuat riwayat driver (`GET /api/indent/driver/history`) halaman demi
/// halaman. Hanya dijalankan untuk akun role `driver`.
class IndentCompletedCubit extends Cubit<IndentCompletedState> {
  IndentCompletedCubit({required IndentVehicleRepository repository})
      : _repository = repository,
        super(const IndentCompletedState());

  final IndentVehicleRepository _repository;

  /// Hasil yang bukan permintaan terakhir dibuang.
  int _token = 0;

  /// Muat awal / refresh: selalu mulai lagi dari halaman 1.
  Future<void> load() async {
    final token = ++_token;

    emit(IndentCompletedState(
      status: IndentCompletedStatus.loading,
      items: state.items,
    ));

    try {
      final page = await _repository.fetchDriverHistory();
      if (token != _token || isClosed) return;

      emit(IndentCompletedState(
        status: IndentCompletedStatus.success,
        items: page.items,
        currentPage: page.meta.currentPage,
        hasMore: page.meta.hasMore,
      ));
    } on ApiException catch (e) {
      if (token != _token || isClosed) return;

      AppLogger.info('Riwayat driver gagal dimuat: ${e.kind.name} — ${e.message}');
      emit(IndentCompletedState(
        status: IndentCompletedStatus.failure,
        errorMessage: e.message,
      ));
    } catch (e, stack) {
      if (token != _token || isClosed) return;

      AppLogger.error('Riwayat driver gagal karena galat tak terduga', e, stack);
      emit(const IndentCompletedState(
        status: IndentCompletedStatus.failure,
        errorMessage: 'An unexpected error occurred. Please try again.',
      ));
    }
  }

  /// Halaman berikutnya. Bila gagal, daftar yang sudah tampil dibiarkan utuh —
  /// menggulir lagi akan mencoba sekali lagi.
  Future<void> loadMore() async {
    if (state.loadingMore ||
        !state.hasMore ||
        state.status != IndentCompletedStatus.success) {
      return;
    }

    final token = _token;
    emit(_copy(loadingMore: true));

    try {
      final page =
          await _repository.fetchDriverHistory(page: state.currentPage + 1);
      if (token != _token || isClosed) return;

      // Perjalanan baru bisa mendorong item lama ke halaman berikutnya.
      final known = {for (final item in state.items) item.id};

      emit(_copy(
        items: [
          ...state.items,
          ...page.items.where((item) => !known.contains(item.id)),
        ],
        currentPage: page.meta.currentPage,
        hasMore: page.meta.hasMore,
        loadingMore: false,
      ));
    } on ApiException catch (e) {
      if (token != _token || isClosed) return;

      AppLogger.info('Halaman riwayat driver gagal: ${e.message}');
      emit(_copy(loadingMore: false));
    } catch (e, stack) {
      if (token != _token || isClosed) return;

      AppLogger.error('Halaman riwayat driver gagal tak terduga', e, stack);
      emit(_copy(loadingMore: false));
    }
  }

  IndentCompletedState _copy({
    List<IndentCompletedItem>? items,
    int? currentPage,
    bool? hasMore,
    required bool loadingMore,
  }) {
    return IndentCompletedState(
      status: state.status,
      items: items ?? state.items,
      currentPage: currentPage ?? state.currentPage,
      hasMore: hasMore ?? state.hasMore,
      loadingMore: loadingMore,
    );
  }
}
