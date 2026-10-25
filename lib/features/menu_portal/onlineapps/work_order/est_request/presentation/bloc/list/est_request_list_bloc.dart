import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../../core/logging/app_logger.dart';
import '../../../../../../../../core/network/api_exception.dart';
import '../../../data/est_request_repository.dart';
import 'est_request_list_event.dart';
import 'est_request_list_state.dart';

/// Memuat daftar "All Request" dari `GET /api/portal/apps/est_work_order`,
/// halaman demi halaman (infinite scroll).
///
/// Tidak butuh id user: server sudah menandai request milik sendiri lewat
/// `is_mine`, dan hak edit/hapus/rating lewat `can_*`.
class EstRequestListBloc
    extends Bloc<EstRequestListEvent, EstRequestListState> {
  EstRequestListBloc({required EstRequestRepository repository})
      : _repository = repository,
        super(const EstRequestListState()) {
    on<EstRequestListStarted>(_onLoad);
    on<EstRequestListRefreshed>(_onLoad);
    on<EstRequestListNextPageRequested>(_onNextPage);
  }

  final EstRequestRepository _repository;

  /// Permintaan yang tumpang tindih (mis. refresh ditekan dua kali, atau
  /// refresh saat halaman berikutnya masih dimuat) bisa membalas dengan
  /// urutan terbalik. Hasil yang bukan permintaan terakhir dibuang.
  int _requestToken = 0;

  /// Muat awal / refresh: selalu mulai lagi dari halaman 1.
  Future<void> _onLoad(
    EstRequestListEvent event,
    Emitter<EstRequestListState> emit,
  ) async {
    final token = ++_requestToken;

    emit(state.copyWith(
      status: EstRequestListStatus.loading,
      loadingMore: false,
      errorMessage: null,
    ));

    try {
      final page = await _repository.fetchRequests(page: 1);
      if (token != _requestToken) return;

      emit(state.copyWith(
        status: EstRequestListStatus.success,
        items: page.items,
        meta: page.meta,
        awaitingVerification: page.awaitingVerification,
      ));
    } on ApiException catch (e) {
      if (token != _requestToken) return;

      AppLogger.info('List EST gagal dimuat: ${e.kind.name} — ${e.message}');
      emit(state.copyWith(
        status: EstRequestListStatus.failure,
        items: const [],
        errorMessage: e.message,
      ));
    } catch (e, stack) {
      if (token != _requestToken) return;

      AppLogger.error('List EST gagal karena galat tak terduga', e, stack);
      emit(state.copyWith(
        status: EstRequestListStatus.failure,
        items: const [],
        errorMessage: 'An unexpected error occurred. Please try again.',
      ));
    }
  }

  /// Halaman berikutnya ditambahkan di bawah daftar yang sudah ada. Bila
  /// gagal, daftar yang sudah tampil dibiarkan utuh (tidak diganti layar
  /// galat) — menggulir lagi akan mencoba sekali lagi.
  Future<void> _onNextPage(
    EstRequestListNextPageRequested event,
    Emitter<EstRequestListState> emit,
  ) async {
    if (state.loadingMore ||
        !state.meta.hasMore ||
        state.status != EstRequestListStatus.success) {
      return;
    }

    final token = _requestToken;
    emit(state.copyWith(loadingMore: true));

    try {
      final page =
          await _repository.fetchRequests(page: state.meta.currentPage + 1);
      if (token != _requestToken) return;

      // Request baru yang masuk di sela-sela halaman mendorong item lama
      // ke halaman berikutnya, sehingga bisa muncul dua kali. Buang yang
      // sudah ada.
      final known = {for (final item in state.items) item.id};
      final fresh = page.items.where((item) => !known.contains(item.id));

      emit(state.copyWith(
        items: [...state.items, ...fresh],
        meta: page.meta,
        awaitingVerification: page.awaitingVerification,
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
