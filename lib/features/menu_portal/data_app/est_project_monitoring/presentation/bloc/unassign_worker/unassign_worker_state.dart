sealed class UnassignWorkerState {
  const UnassignWorkerState();
}

class UnassignWorkerInitial extends UnassignWorkerState {
  const UnassignWorkerInitial();
}

class UnassignWorkerLoading extends UnassignWorkerState {
  const UnassignWorkerLoading();
}

class UnassignWorkerSuccess extends UnassignWorkerState {
  const UnassignWorkerSuccess(this.message);

  final String message;
}

class UnassignWorkerFailure extends UnassignWorkerState {
  const UnassignWorkerFailure(this.message);

  final String message;
}
