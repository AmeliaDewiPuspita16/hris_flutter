import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/logging/app_logger.dart';
import '../../../data/overtime_repository.dart';
import 'overtime_summary_event.dart';
import 'overtime_summary_state.dart';

/// Memuat realisasi lembur per bulan untuk tab Summary.
class OvertimeSummaryBloc
    extends Bloc<OvertimeSummaryEvent, OvertimeSummaryState> {
  OvertimeSummaryBloc({
    required OvertimeRepository repository,
    DateTime? initialMonth,
  })  : _repository = repository,
        super(OvertimeSummaryState(month: initialMonth ?? _currentMonth())) {
    on<OvertimeSummaryStarted>((event, emit) => _load(state.month, emit));
    on<OvertimeSummaryRetried>((event, emit) => _load(state.month, emit));
    on<OvertimeSummaryMonthChanged>(_onMonthChanged);
  }

  final OvertimeRepository _repository;

  static DateTime _currentMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  Future<void> _onMonthChanged(
    OvertimeSummaryMonthChanged event,
    Emitter<OvertimeSummaryState> emit,
  ) async {
    // Data bulan lama dibuang supaya tidak tampil di bawah label bulan baru.
    emit(OvertimeSummaryState(
      month: DateTime(event.month.year, event.month.month),
    ));
    await _load(state.month, emit);
  }

  bool _isSelected(DateTime month) =>
      state.month.year == month.year && state.month.month == month.month;

  Future<void> _load(
    DateTime month,
    Emitter<OvertimeSummaryState> emit,
  ) async {
    emit(state.copyWith(
      status: OvertimeSummaryStatus.loading,
      errorMessage: null,
    ));

    try {
      final result = await _repository.fetchMonth(month);

      // User sudah pindah bulan saat menunggu: buang hasil ini.
      if (!_isSelected(month)) return;

      emit(state.copyWith(
        status: OvertimeSummaryStatus.success,
        data: result,
      ));
    } catch (e, stack) {
      AppLogger.error('Data lembur gagal dimuat', e, stack);

      if (!_isSelected(month)) return;

      emit(state.copyWith(
        status: OvertimeSummaryStatus.failure,
        errorMessage: 'Failed to load overtime. Please try again.',
      ));
    }
  }
}
