import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../core/network/api_exception.dart';
import '../../../data/est_project_repository.dart';
import 'substitute_event.dart';
import 'substitute_state.dart';

class SubstituteBloc extends Bloc<SubstituteEvent, SubstituteState> {
  SubstituteBloc({required EstProjectRepository repository})
      : _repository = repository,
        super(const SubstituteInitial()) {
    on<AssignSubstitute>(_onAssign);
    on<EndSubstitute>(_onEnd);
  }

  final EstProjectRepository _repository;

  Future<void> _onAssign(
    AssignSubstitute event,
    Emitter<SubstituteState> emit,
  ) async {
    emit(const SubstituteLoading());
    try {
      final body = <String, dynamic>{
        'role': event.role,
        'substitute_for': event.substituteFor,
        'substitute_reason': event.reason ?? '',
      };
      if (event.role == 'mandor') {
        body['user_id'] = event.replacementId;
      } else {
        body['worker_id'] = event.replacementId;
      }
      await _repository.assignSubstitute(event.projectId, body);
      emit(const SubstituteSuccess('Pengganti berhasil ditugaskan'));
    } on ApiException catch (e) {
      emit(SubstituteFailure(e.message));
    } catch (_) {
      emit(const SubstituteFailure('Gagal menugaskan pengganti'));
    }
  }

  Future<void> _onEnd(
    EndSubstitute event,
    Emitter<SubstituteState> emit,
  ) async {
    emit(const SubstituteLoading());
    try {
      await _repository.endSubstitute(event.projectId, event.assignmentId);
      emit(const SubstituteSuccess('Substitusi berhasil diakhiri'));
    } on ApiException catch (e) {
      emit(SubstituteFailure(e.message));
    } catch (_) {
      emit(const SubstituteFailure('Gagal mengakhiri substitusi'));
    }
  }
}
