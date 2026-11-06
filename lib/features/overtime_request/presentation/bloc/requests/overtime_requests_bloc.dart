import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/logging/app_logger.dart';
import '../../../data/overtime_repository.dart';
import 'overtime_requests_event.dart';
import 'overtime_requests_state.dart';

/// Memuat riwayat pengajuan lembur untuk tab Status.
class OvertimeRequestsBloc
    extends Bloc<OvertimeRequestsEvent, OvertimeRequestsState> {
  OvertimeRequestsBloc({required OvertimeRepository repository})
      : _repository = repository,
        super(const OvertimeRequestsState()) {
    on<OvertimeRequestsLoaded>(_onLoaded);
  }

  final OvertimeRepository _repository;

  Future<void> _onLoaded(
    OvertimeRequestsLoaded event,
    Emitter<OvertimeRequestsState> emit,
  ) async {
    emit(const OvertimeRequestsState(status: OvertimeRequestsStatus.loading));

    try {
      final requests = await _repository.fetchRequests();

      emit(OvertimeRequestsState(
        status: OvertimeRequestsStatus.success,
        requests: requests,
      ));
    } catch (e, stack) {
      AppLogger.error('Riwayat pengajuan lembur gagal dimuat', e, stack);

      emit(const OvertimeRequestsState(
        status: OvertimeRequestsStatus.failure,
        errorMessage: 'Failed to load overtime requests. Please try again.',
      ));
    }
  }
}
