import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../../core/logging/app_logger.dart';
import '../../../../../../../../core/network/api_exception.dart';
import '../../../data/it_request_repository.dart';
import 'it_request_detail_event.dart';
import 'it_request_detail_state.dart';

/// Mengambil rincian satu request IT/Media.
///
/// Berumur pendek — hidup bersama layar detailnya, satu request per layar.
class ItRequestDetailBloc extends Bloc<ItRequestDetailEvent, ItRequestDetailState> {
  ItRequestDetailBloc({required ItRequestRepository repository})
      : _repository = repository,
        super(const ItRequestDetailState()) {
    on<ItRequestDetailRequested>(_onRequested);
  }

  final ItRequestRepository _repository;

  Future<void> _onRequested(
    ItRequestDetailRequested event,
    Emitter<ItRequestDetailState> emit,
  ) async {
    if (state.status == ItRequestDetailStatus.loading) return;

    emit(const ItRequestDetailState(status: ItRequestDetailStatus.loading));

    try {
      final detail = await _repository.fetchDetail(event.id);
      emit(ItRequestDetailState(status: ItRequestDetailStatus.success, detail: detail));
    } on ApiException catch (e) {
      AppLogger.info('Detail IT Request gagal dimuat: ${e.kind.name} — ${e.message}');
      emit(ItRequestDetailState(status: ItRequestDetailStatus.failure, errorMessage: e.message));
    } catch (e, stack) {
      AppLogger.error('Detail IT Request gagal karena galat tak terduga', e, stack);
      emit(
        const ItRequestDetailState(
          status: ItRequestDetailStatus.failure,
          errorMessage: 'Terjadi kesalahan tak terduga. Coba lagi.',
        ),
      );
    }
  }
}
