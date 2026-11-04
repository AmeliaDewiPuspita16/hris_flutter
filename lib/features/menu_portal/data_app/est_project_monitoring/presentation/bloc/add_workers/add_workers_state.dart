sealed class AddWorkersState {
  const AddWorkersState();
}

class AddWorkersInitial extends AddWorkersState {
  const AddWorkersInitial();
}

class AddWorkersLoading extends AddWorkersState {
  const AddWorkersLoading();
}

class AddWorkersSuccess extends AddWorkersState {
  const AddWorkersSuccess(this.message);

  final String message;
}

class AddWorkersFailure extends AddWorkersState {
  const AddWorkersFailure(this.message);

  final String message;
}
