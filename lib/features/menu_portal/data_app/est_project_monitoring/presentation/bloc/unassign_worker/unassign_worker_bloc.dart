import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../core/network/api_exception.dart';
import '../../../data/est_project_repository.dart';
import 'unassign_worker_event.dart';
import 'unassign_worker_state.dart';

/// Melepas (remove) worker dari proyek lewat
/// `DELETE /api/est/projects/{project}/workers/unassign`.
class UnassignWorkerBloc
    extends Bloc<UnassignWorkerEvent, UnassignWorkerState> {
  UnassignWorkerBloc({required EstProjectRepository repository})
      : _repository = repository,
        super(const UnassignWorkerInitial()) {
    on<SubmitUnassignWorker>(_onSubmit);
  }

  final EstProjectRepository _repository;

  Future<void> _onSubmit(
    SubmitUnassignWorker event,
    Emitter<UnassignWorkerState> emit,
  ) async {
    emit(const UnassignWorkerLoading());
    try {
      final json =
          await _repository.unassignWorker(event.projectId, event.workerId);
      emit(UnassignWorkerSuccess(
        json['message'] as String? ?? 'Worker berhasil dilepas dari proyek',
      ));
    } on ApiException catch (e) {
      emit(UnassignWorkerFailure(e.message));
    } catch (_) {
      emit(const UnassignWorkerFailure('Gagal menghapus worker'));
    }
  }
}
