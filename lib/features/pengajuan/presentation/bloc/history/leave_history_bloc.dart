import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/logging/app_logger.dart';
import '../../../data/pengajuan_repository.dart';
import 'leave_history_event.dart';
import 'leave_history_state.dart';

/// Memuat & menyimpan riwayat pengajuan cuti/izin/lembur untuk tab Status.
class LeaveHistoryBloc extends Bloc<LeaveHistoryEvent, LeaveHistoryState> {
  LeaveHistoryBloc({required PengajuanRepository repository})
      : _repository = repository,
        super(const LeaveHistoryState()) {
    on<LeaveHistoryStarted>(_onLoad);
    on<LeaveHistoryRefreshed>(_onLoad);
    on<LeaveHistoryLocalItemAdded>(_onLocalItemAdded);
  }

  final PengajuanRepository _repository;

  Future<void> _onLoad(
    LeaveHistoryEvent event,
    Emitter<LeaveHistoryState> emit,
  ) async {
    emit(state.copyWith(
      status: LeaveHistoryStatus.loading,
      errorMessage: null,
    ));

    try {
      final items = await _repository.fetchHistory();

      emit(state.copyWith(
        status: LeaveHistoryStatus.success,
        items: items,
      ));
    } catch (e, stack) {
      AppLogger.error('Riwayat pengajuan gagal dimuat', e, stack);

      emit(state.copyWith(
        status: LeaveHistoryStatus.failure,
        errorMessage: 'Gagal memuat riwayat. Coba lagi.',
      ));
    }
  }

  void _onLocalItemAdded(
    LeaveHistoryLocalItemAdded event,
    Emitter<LeaveHistoryState> emit,
  ) {
    emit(state.copyWith(items: [event.entry, ...state.items]));
  }
}
