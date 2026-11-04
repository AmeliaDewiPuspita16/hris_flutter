import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../core/network/api_exception.dart';
import '../../../data/est_project_repository.dart';
import 'close_project_event.dart';
import 'close_project_state.dart';

class CloseProjectBloc extends Bloc<CloseProjectEvent, CloseProjectState> {
  CloseProjectBloc({required EstProjectRepository repository})
      : _repository = repository,
        super(const CloseProjectInitial()) {
    on<SubmitCloseProject>(_onSubmit);
  }

  final EstProjectRepository _repository;

  Future<void> _onSubmit(
    SubmitCloseProject event,
    Emitter<CloseProjectState> emit,
  ) async {
    emit(const CloseProjectLoading());
    try {
      await _repository.requestCloseProject(event.projectId);
      emit(const CloseProjectSuccess());
    } on ApiException catch (e) {
      emit(CloseProjectFailure(e.message));
    } catch (_) {
      emit(const CloseProjectFailure('Gagal menutup proyek'));
    }
  }
}
