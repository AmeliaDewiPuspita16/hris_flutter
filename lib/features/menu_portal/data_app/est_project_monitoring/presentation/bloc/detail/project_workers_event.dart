sealed class ProjectWorkersEvent {
  const ProjectWorkersEvent();
}

class LoadProjectWorkers extends ProjectWorkersEvent {
  const LoadProjectWorkers(this.projectId);

  final int projectId;
}
