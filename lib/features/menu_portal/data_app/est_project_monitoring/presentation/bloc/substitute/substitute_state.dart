sealed class SubstituteState {
  const SubstituteState();
}

class SubstituteInitial extends SubstituteState {
  const SubstituteInitial();
}

class SubstituteLoading extends SubstituteState {
  const SubstituteLoading();
}

class SubstituteSuccess extends SubstituteState {
  const SubstituteSuccess(this.message);

  final String message;
}

class SubstituteFailure extends SubstituteState {
  const SubstituteFailure(this.message);

  final String message;
}
