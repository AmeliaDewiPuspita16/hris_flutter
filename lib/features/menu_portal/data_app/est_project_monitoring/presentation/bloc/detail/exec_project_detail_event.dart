sealed class ExecProjectDetailEvent {
  const ExecProjectDetailEvent();
}

class LoadExecProjectDetail extends ExecProjectDetailEvent {
  const LoadExecProjectDetail(this.projectId);

  final int projectId;
}
