sealed class WorkerTransferState {
  const WorkerTransferState();
}

class WorkerTransferInitial extends WorkerTransferState {
  const WorkerTransferInitial();
}

class WorkerTransferLoading extends WorkerTransferState {
  const WorkerTransferLoading();
}

class WorkerTransferSuccess extends WorkerTransferState {
  const WorkerTransferSuccess(this.message);

  final String message;
}

class WorkerTransferFailure extends WorkerTransferState {
  const WorkerTransferFailure(this.message);

  final String message;
}
