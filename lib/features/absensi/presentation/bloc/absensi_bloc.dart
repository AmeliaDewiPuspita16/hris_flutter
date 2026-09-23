import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/logging/app_logger.dart';
import '../../data/absensi_repository.dart';
import 'absensi_event.dart';
import 'absensi_state.dart';

/// Memuat & menyimpan Log Absensi (entri harian + ringkasan) per bulan.
class AbsensiBloc extends Bloc<AbsensiEvent, AbsensiState> {
  AbsensiBloc({required AbsensiRepository repository, DateTime? initialMonth})
      : _repository = repository,
        super(AbsensiState(selectedMonth: initialMonth ?? _currentMonth())) {
    on<AbsensiStarted>(_onStarted);
    on<AbsensiMonthChanged>(_onMonthChanged);
  }

  final AbsensiRepository _repository;

  static DateTime _currentMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  Future<void> _onStarted(
    AbsensiStarted event,
    Emitter<AbsensiState> emit,
  ) async {
    await _load(state.selectedMonth, emit);
  }

  Future<void> _onMonthChanged(
    AbsensiMonthChanged event,
    Emitter<AbsensiState> emit,
  ) async {
    emit(state.copyWith(selectedMonth: event.month));
    await _load(event.month, emit);
  }

  Future<void> _load(DateTime month, Emitter<AbsensiState> emit) async {
    emit(state.copyWith(status: AbsensiStatus.loading, errorMessage: null));

    try {
      final result = await _repository.fetchMonth(month);

      emit(state.copyWith(
        status: AbsensiStatus.success,
        entries: result.entries,
        summary: result.summary,
      ));
    } catch (e, stack) {
      AppLogger.error('Log absensi gagal dimuat', e, stack);

      emit(state.copyWith(
        status: AbsensiStatus.failure,
        errorMessage: 'Gagal memuat absensi. Coba lagi.',
      ));
    }
  }
}
