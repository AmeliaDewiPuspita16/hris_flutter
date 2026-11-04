sealed class WorkerTransferEvent {
  const WorkerTransferEvent();
}

class SubmitWorkerTransfer extends WorkerTransferEvent {
  const SubmitWorkerTransfer({
    required this.fromProjectId,
    required this.workerIds,
    required this.targetProjectId,
    this.reason,
  });

  final int fromProjectId;
  final List<int> workerIds;
  final int targetProjectId;
  final String? reason;
}
