sealed class AddWorkersEvent {
  const AddWorkersEvent();
}

class SubmitAddWorkers extends AddWorkersEvent {
  const SubmitAddWorkers({required this.projectId, required this.workerIds});

  final int projectId;
  final List<int> workerIds;
}
