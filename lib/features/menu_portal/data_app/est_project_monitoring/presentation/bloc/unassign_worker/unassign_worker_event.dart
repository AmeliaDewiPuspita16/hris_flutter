sealed class UnassignWorkerEvent {
  const UnassignWorkerEvent();
}

class SubmitUnassignWorker extends UnassignWorkerEvent {
  const SubmitUnassignWorker({
    required this.projectId,
    required this.workerId,
  });

  final int projectId;
  final int workerId;
}
