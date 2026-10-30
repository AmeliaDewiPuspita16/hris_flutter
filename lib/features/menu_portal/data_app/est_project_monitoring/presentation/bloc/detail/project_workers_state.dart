import '../../../domain/project_worker.dart';

sealed class ProjectWorkersState {
  const ProjectWorkersState();
}

class ProjectWorkersInitial extends ProjectWorkersState {
  const ProjectWorkersInitial();
}

class ProjectWorkersLoading extends ProjectWorkersState {
  const ProjectWorkersLoading();
}

class ProjectWorkersLoaded extends ProjectWorkersState {
  const ProjectWorkersLoaded(this.workers);

  final List<ProjectWorkerModel> workers;
}

class ProjectWorkersError extends ProjectWorkersState {
  const ProjectWorkersError(this.message);

  final String message;
}
