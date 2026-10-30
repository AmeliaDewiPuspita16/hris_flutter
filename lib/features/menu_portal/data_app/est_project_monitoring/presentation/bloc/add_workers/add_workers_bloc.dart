import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../core/network/api_exception.dart';
import '../../../data/est_project_repository.dart';
import 'add_workers_event.dart';
import 'add_workers_state.dart';

class AddWorkersBloc extends Bloc<AddWorkersEvent, AddWorkersState> {
  AddWorkersBloc({required EstProjectRepository repository})
      : _repository = repository,
        super(const AddWorkersInitial()) {
    on<SubmitAddWorkers>(_onSubmit);
  }

  final EstProjectRepository _repository;

  Future<void> _onSubmit(
    SubmitAddWorkers event,
    Emitter<AddWorkersState> emit,
  ) async {
    emit(const AddWorkersLoading());
    try {
      final json =
          await _repository.assignWorkers(event.projectId, event.workerIds);
      emit(AddWorkersSuccess(
        json['message'] as String? ?? 'Worker berhasil ditambahkan',
      ));
    } on ApiException catch (e) {
      emit(AddWorkersFailure(e.message));
    } catch (_) {
      emit(const AddWorkersFailure('Gagal menambahkan worker'));
    }
  }
}
