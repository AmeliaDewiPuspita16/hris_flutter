import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../core/network/api_exception.dart';
import '../../../data/est_project_repository.dart';
import 'project_workers_event.dart';
import 'project_workers_state.dart';

class ProjectWorkersBloc
    extends Bloc<ProjectWorkersEvent, ProjectWorkersState> {
  ProjectWorkersBloc({required EstProjectRepository repository})
      : _repository = repository,
        super(const ProjectWorkersInitial()) {
    on<LoadProjectWorkers>(_onLoad);
  }

  final EstProjectRepository _repository;

  Future<void> _onLoad(
    LoadProjectWorkers event,
    Emitter<ProjectWorkersState> emit,
  ) async {
    emit(const ProjectWorkersLoading());
    try {
      final workers = await _repository.fetchProjectWorkers(event.projectId);
      emit(ProjectWorkersLoaded(workers));
    } on ApiException catch (e) {
      emit(ProjectWorkersError(e.message));
    } catch (_) {
      emit(const ProjectWorkersError('Gagal memuat daftar tim'));
    }
  }
}
