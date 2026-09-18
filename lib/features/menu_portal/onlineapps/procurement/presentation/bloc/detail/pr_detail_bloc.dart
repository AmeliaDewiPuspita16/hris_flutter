import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../core/logging/app_logger.dart';
import '../../../../../../../core/network/api_exception.dart';
import '../../../data/procurement_repository.dart';
import 'pr_detail_event.dart';
import 'pr_detail_state.dart';

/// Mengambil rincian satu PR.
///
/// Berumur pendek — hidup bersama PrDetailScreen, satu PR per layar.
class PrDetailBloc extends Bloc<PrDetailEvent, PrDetailState> {
  PrDetailBloc({required ProcurementRepository repository})
      : _repository = repository,
        super(const PrDetailState()) {
    on<PrDetailRequested>(_onRequested);
  }

  final ProcurementRepository _repository;

  Future<void> _onRequested(
    PrDetailRequested event,
    Emitter<PrDetailState> emit,
  ) async {
    if (state.status == PrDetailStatus.loading) return;

    emit(const PrDetailState(status: PrDetailStatus.loading));

    try {
      final requisition = await _repository.fetchDetail(event.id);
      emit(PrDetailState(
        status: PrDetailStatus.success,
        requisition: requisition,
      ));
    } on ApiException catch (e) {
      AppLogger.info('Detail PR gagal dimuat: ${e.kind.name} — ${e.message}');
      emit(PrDetailState(
        status: PrDetailStatus.failure,
        errorMessage: e.message,
      ));
    } catch (e, stack) {
      AppLogger.error('Detail PR gagal karena galat tak terduga', e, stack);
      emit(
        const PrDetailState(
          status: PrDetailStatus.failure,
          errorMessage: 'Terjadi kesalahan tak terduga. Coba lagi.',
        ),
      );
    }
  }
}
