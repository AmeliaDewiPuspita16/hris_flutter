import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../core/network/api_exception.dart';
import '../../../data/est_project_repository.dart';
import 'exec_project_detail_event.dart';
import 'exec_project_detail_state.dart';

class ExecProjectDetailBloc
    extends Bloc<ExecProjectDetailEvent, ExecProjectDetailState> {
  ExecProjectDetailBloc({required EstProjectRepository repository})
      : _repository = repository,
        super(const ExecProjectDetailInitial()) {
    on<LoadExecProjectDetail>(_onLoad);
  }

  final EstProjectRepository _repository;

  Future<void> _onLoad(
    LoadExecProjectDetail event,
    Emitter<ExecProjectDetailState> emit,
  ) async {
    emit(const ExecProjectDetailLoading());
    try {
      final data = await _repository.fetchProjectDetail(event.projectId);
      emit(ExecProjectDetailLoaded(data));
    } on ApiException catch (e) {
      emit(ExecProjectDetailError(e.message));
    } catch (_) {
      emit(const ExecProjectDetailError('Gagal memuat detail proyek'));
    }
  }
}
