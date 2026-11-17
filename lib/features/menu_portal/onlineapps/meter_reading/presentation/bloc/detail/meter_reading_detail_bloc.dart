import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../core/logging/app_logger.dart';
import '../../../../../../../core/network/api_exception.dart';
import '../../../data/meter_reading_repository.dart';
import 'meter_reading_detail_event.dart';
import 'meter_reading_detail_state.dart';

/// Mengambil rincian satu meter, dan menerima hasil pencatatan dari form.
///
/// Berumur pendek — hidup bersama layar detailnya, satu meter per layar.
class MeterReadingDetailBloc
    extends Bloc<MeterReadingDetailEvent, MeterReadingDetailState> {
  MeterReadingDetailBloc({required MeterReadingRepository repository})
      : _repository = repository,
        super(const MeterReadingDetailState()) {
    on<MeterReadingDetailRequested>(_onRequested);
    on<MeterReadingDetailUpdated>(_onUpdated);
  }

  final MeterReadingRepository _repository;

  Future<void> _onRequested(
    MeterReadingDetailRequested event,
    Emitter<MeterReadingDetailState> emit,
  ) async {
    if (state.status == MeterReadingDetailStatus.loading) return;

    emit(const MeterReadingDetailState(status: MeterReadingDetailStatus.loading));

    try {
      final detail = await _repository.fetchDetail(event.id);
      emit(MeterReadingDetailState(
        status: MeterReadingDetailStatus.success,
        detail: detail,
      ));
    } on ApiException catch (e) {
      AppLogger.info('Detail Meter Reading gagal dimuat: ${e.kind.name} — ${e.message}');
      emit(MeterReadingDetailState(
        status: MeterReadingDetailStatus.failure,
        errorMessage: e.message,
      ));
    } catch (e, stack) {
      AppLogger.error('Detail Meter Reading gagal karena galat tak terduga', e, stack);
      emit(const MeterReadingDetailState(
        status: MeterReadingDetailStatus.failure,
        errorMessage: 'An unexpected error occurred. Please try again.',
      ));
    }
  }

  void _onUpdated(
    MeterReadingDetailUpdated event,
    Emitter<MeterReadingDetailState> emit,
  ) {
    emit(MeterReadingDetailState(
      status: MeterReadingDetailStatus.success,
      detail: event.detail,
    ));
  }
}
