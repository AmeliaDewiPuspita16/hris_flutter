sealed class CloseProjectEvent {
  const CloseProjectEvent();
}

class SubmitCloseProject extends CloseProjectEvent {
  const SubmitCloseProject(this.projectId);

  final int projectId;
}
