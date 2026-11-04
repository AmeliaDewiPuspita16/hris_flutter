import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../core/network/api_exception.dart';
import '../../../data/est_project_repository.dart';
import 'worker_transfer_event.dart';
import 'worker_transfer_state.dart';

class WorkerTransferBloc
    extends Bloc<WorkerTransferEvent, WorkerTransferState> {
  WorkerTransferBloc({required EstProjectRepository repository})
      : _repository = repository,
        super(const WorkerTransferInitial()) {
    on<SubmitWorkerTransfer>(_onSubmit);
  }

  final EstProjectRepository _repository;

  Future<void> _onSubmit(
    SubmitWorkerTransfer event,
    Emitter<WorkerTransferState> emit,
  ) async {
    emit(const WorkerTransferLoading());
    try {
      final json = await _repository.transferWorkers(
        event.fromProjectId,
        targetProjectId: event.targetProjectId,
        workerIds: event.workerIds,
        reason: event.reason,
      );
      emit(WorkerTransferSuccess(
        json['message'] as String? ?? 'Worker berhasil dipindahkan',
      ));
    } on ApiException catch (e) {
      emit(WorkerTransferFailure(e.message));
    } catch (_) {
      emit(const WorkerTransferFailure('Gagal memindahkan worker'));
    }
  }
}
