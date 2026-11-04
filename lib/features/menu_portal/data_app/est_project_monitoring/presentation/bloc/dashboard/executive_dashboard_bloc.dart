import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../core/network/api_exception.dart';
import '../../../data/est_project_repository.dart';
import '../../../domain/executive_dashboard.dart';
import 'executive_dashboard_event.dart';
import 'executive_dashboard_state.dart';

class ExecutiveDashboardBloc
    extends Bloc<ExecutiveDashboardEvent, ExecutiveDashboardState> {
  ExecutiveDashboardBloc({required EstProjectRepository repository})
      : _repository = repository,
        super(const ExecutiveDashboardInitial()) {
    on<LoadExecutiveDashboard>(_onLoad);
    on<OpenExecutiveSession>(_onOpenSession);
    on<CloseExecutiveSession>(_onCloseSession);
  }

  final EstProjectRepository _repository;

  Future<void> _onLoad(
    LoadExecutiveDashboard event,
    Emitter<ExecutiveDashboardState> emit,
  ) async {
    emit(const ExecutiveDashboardLoading());
    try {
      final data = await _repository.fetchExecutiveDashboard();
      emit(ExecutiveDashboardLoaded(data));
    } on ApiException catch (e) {
      // 401/403: akun ini bukan executive EST.
      if (e.kind == ApiErrorKind.unauthorized) {
        emit(const ExecutiveDashboardNoAccess());
      } else {
        emit(ExecutiveDashboardError(e.message));
      }
    } catch (_) {
      emit(const ExecutiveDashboardError('Gagal memuat data dashboard'));
    }
  }

  ExecutiveDashboardModel? get _currentData => switch (state) {
        ExecutiveDashboardLoaded s => s.data,
        ExecutiveSessionError s => s.currentData,
        _ => null,
      };

  Future<void> _onOpenSession(
    OpenExecutiveSession event,
    Emitter<ExecutiveDashboardState> emit,
  ) async {
    final data = _currentData;
    if (data == null) return;

    emit(ExecutiveSessionLoading(data));
    try {
      await _repository.openSession(event.projectId);
      emit(const ExecutiveSessionSuccess('Sesi berhasil dibuka'));
    } on ApiException catch (e) {
      emit(ExecutiveSessionError(e.message, data));
    } catch (_) {
      emit(ExecutiveSessionError('Gagal membuka sesi', data));
    }
  }

  Future<void> _onCloseSession(
    CloseExecutiveSession event,
    Emitter<ExecutiveDashboardState> emit,
  ) async {
    final data = _currentData;
    if (data == null) return;

    emit(ExecutiveSessionLoading(data));
    try {
      await _repository.closeSession(
        event.projectId,
        description: event.description,
        autoClockOut: event.autoClockOut,
        photoPaths: event.photoPaths,
      );
      emit(const ExecutiveSessionSuccess('Sesi berhasil ditutup'));
    } on ApiException catch (e) {
      emit(ExecutiveSessionError(e.message, data));
    } catch (_) {
      emit(ExecutiveSessionError('Gagal menutup sesi', data));
    }
  }
}
