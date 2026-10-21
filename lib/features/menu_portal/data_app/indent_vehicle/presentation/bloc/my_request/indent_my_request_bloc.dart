import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../core/logging/app_logger.dart';
import '../../../../../../../core/network/api_exception.dart';
import '../../../data/indent_vehicle_repository.dart';
import 'indent_my_request_event.dart';
import 'indent_my_request_state.dart';

/// Tab "My Request": memuat request milik user yang login dari
/// `GET /api/indent/list`. Endpoint ini tidak berpaginasi (array polos),
/// jadi tidak ada muat halaman berikutnya.
class IndentMyRequestBloc
    extends Bloc<IndentMyRequestEvent, IndentMyRequestState> {
  IndentMyRequestBloc({required IndentVehicleRepository repository})
      : _repository = repository,
        super(const IndentMyRequestState()) {
    on<IndentMyRequestStarted>(_onLoad);
    on<IndentMyRequestRefreshed>(_onLoad);
  }

  final IndentVehicleRepository _repository;

  /// Muat ulang yang tumpang tindih bisa membalas dengan urutan terbalik;
  /// hasil yang bukan permintaan terakhir dibuang.
  int _requestToken = 0;

  Future<void> _onLoad(
    IndentMyRequestEvent event,
    Emitter<IndentMyRequestState> emit,
  ) async {
    final token = ++_requestToken;

    emit(state.copyWith(
      status: IndentMyRequestStatus.loading,
      errorMessage: null,
    ));

    try {
      final items = await _repository.fetchMyRequests();
      if (token != _requestToken) return;

      emit(state.copyWith(status: IndentMyRequestStatus.success, items: items));
    } on ApiException catch (e) {
      if (token != _requestToken) return;

      AppLogger.info('My Request gagal dimuat: ${e.kind.name} — ${e.message}');
      emit(state.copyWith(
        status: IndentMyRequestStatus.failure,
        items: const [],
        errorMessage: e.message,
      ));
    } catch (e, stack) {
      if (token != _requestToken) return;

      AppLogger.error('My Request gagal karena galat tak terduga', e, stack);
      emit(state.copyWith(
        status: IndentMyRequestStatus.failure,
        items: const [],
        errorMessage: 'An unexpected error occurred. Please try again.',
      ));
    }
  }
}
