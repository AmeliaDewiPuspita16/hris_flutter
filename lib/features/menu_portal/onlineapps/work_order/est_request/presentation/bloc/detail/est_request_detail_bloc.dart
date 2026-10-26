import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../../core/logging/app_logger.dart';
import '../../../../../../../../core/network/api_exception.dart';
import '../../../data/est_request_repository.dart';
import 'est_request_detail_event.dart';
import 'est_request_detail_state.dart';

/// Memuat detail satu Work Order dari
/// `GET /api/portal/apps/est_work_order/{id}`.
///
/// Satu bloc untuk satu layar detail: [id] ditetapkan saat dibuat.
class EstRequestDetailBloc
    extends Bloc<EstRequestDetailEvent, EstRequestDetailState> {
  EstRequestDetailBloc({
    required EstRequestRepository repository,
    required int id,
  })  : _repository = repository,
        _id = id,
        super(const EstRequestDetailState()) {
    on<EstRequestDetailStarted>(_onLoad);
    on<EstRequestDetailRefreshed>(_onLoad);
  }

  final EstRequestRepository _repository;
  final int _id;

  /// Muat ulang yang tumpang tindih bisa membalas dengan urutan terbalik;
  /// hasil yang bukan permintaan terakhir dibuang.
  int _requestToken = 0;

  Future<void> _onLoad(
    EstRequestDetailEvent event,
    Emitter<EstRequestDetailState> emit,
  ) async {
    final token = ++_requestToken;

    emit(state.copyWith(
      status: EstRequestDetailStatus.loading,
      errorMessage: null,
    ));

    try {
      final detail = await _repository.fetchDetail(_id);
      if (token != _requestToken) return;

      emit(state.copyWith(
        status: EstRequestDetailStatus.success,
        detail: detail,
      ));
    } on ApiException catch (e) {
      if (token != _requestToken) return;

      AppLogger.info('Detail EST $_id gagal dimuat: ${e.kind.name} — ${e.message}');
      emit(state.copyWith(
        status: EstRequestDetailStatus.failure,
        errorMessage: e.message,
      ));
    } catch (e, stack) {
      if (token != _requestToken) return;

      AppLogger.error('Detail EST $_id gagal karena galat tak terduga', e, stack);
      emit(state.copyWith(
        status: EstRequestDetailStatus.failure,
        errorMessage: 'An unexpected error occurred. Please try again.',
      ));
    }
  }
}
