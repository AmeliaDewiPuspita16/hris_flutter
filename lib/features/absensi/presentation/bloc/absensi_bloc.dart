import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/logging/app_logger.dart';
import '../../data/absensi_repository.dart';
import '../../domain/attendance_day.dart';
import 'absensi_event.dart';
import 'absensi_state.dart';

/// Memuat & menyimpan Log Absensi (jadwal + realisasi harian) per bulan,
/// beserta tanggal yang sedang dipilih user di kalender.
class AbsensiBloc extends Bloc<AbsensiEvent, AbsensiState> {
  AbsensiBloc({required AbsensiRepository repository, DateTime? initialMonth})
      : _repository = repository,
        super(AbsensiState(selectedMonth: initialMonth ?? _currentMonth())) {
    on<AbsensiStarted>(_onStarted);
    on<AbsensiMonthChanged>(_onMonthChanged);
    on<AbsensiDateSelected>(_onDateSelected);
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

  void _onDateSelected(
    AbsensiDateSelected event,
    Emitter<AbsensiState> emit,
  ) {
    emit(state.copyWith(selectedDate: event.date));
  }

  Future<void> _load(DateTime month, Emitter<AbsensiState> emit) async {
    emit(state.copyWith(status: AbsensiStatus.loading, errorMessage: null));

    try {
      final result = await _repository.fetchMonth(month);

      emit(state.copyWith(
        status: AbsensiStatus.success,
        days: result.days,
        summary: result.summary,
        selectedDate: _defaultSelectedDate(month, result.days),
      ));
    } catch (e, stack) {
      AppLogger.error('Log absensi gagal dimuat', e, stack);

      emit(state.copyWith(
        status: AbsensiStatus.failure,
        errorMessage: 'Gagal memuat absensi. Coba lagi.',
      ));
    }
  }

  /// Tanggal yang otomatis dipilih saat bulan baru dimuat: hari ini bila
  /// bulan yang dilihat adalah bulan berjalan, kalau tidak — tanggal
  /// terakhir yang sudah punya realisasi (bukan sekadar jadwal), atau
  /// tanggal 1 bila belum ada realisasi sama sekali.
  DateTime _defaultSelectedDate(DateTime month, List<AttendanceDay> days) {
    final now = DateTime.now();
    if (now.year == month.year && now.month == month.month) {
      return DateTime(now.year, now.month, now.day);
    }
    if (days.isEmpty) return month;

    for (final day in days.reversed) {
      if (day.status != AttendanceDayStatus.terjadwal) return day.date;
    }
    return days.first.date;
  }
}
