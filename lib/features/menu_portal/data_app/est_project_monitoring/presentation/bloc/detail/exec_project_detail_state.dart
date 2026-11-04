import '../../../domain/exec_project_full.dart';

sealed class ExecProjectDetailState {
  const ExecProjectDetailState();
}

class ExecProjectDetailInitial extends ExecProjectDetailState {
  const ExecProjectDetailInitial();
}

class ExecProjectDetailLoading extends ExecProjectDetailState {
  const ExecProjectDetailLoading();
}

class ExecProjectDetailLoaded extends ExecProjectDetailState {
  const ExecProjectDetailLoaded(this.data);

  final ExecProjectFullModel data;
}

class ExecProjectDetailError extends ExecProjectDetailState {
  const ExecProjectDetailError(this.message);

  final String message;
}
