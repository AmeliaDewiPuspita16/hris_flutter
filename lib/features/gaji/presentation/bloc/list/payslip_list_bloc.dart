import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/logging/app_logger.dart';
import '../../../../../core/network/api_exception.dart';
import '../../../domain/payslip_repository.dart';
import 'payslip_list_event.dart';
import 'payslip_list_state.dart';

/// Memuat daftar slip gaji per tahun.
class PayslipListBloc extends Bloc<PayslipListEvent, PayslipListState> {
  PayslipListBloc({required PayslipRepository repository, DateTime? now})
      : _repository = repository,
        super(_initialState(now ?? DateTime.now())) {
    on<PayslipListStarted>((event, emit) => _load(state.year, emit));
    on<PayslipYearSelected>(_onYearSelected);
    on<PayslipListRetried>((event, emit) => _load(state.year, emit));
  }

  final PayslipRepository _repository;

  /// Tahun ini dan dua tahun sebelumnya.
  static PayslipListState _initialState(DateTime now) {
    return PayslipListState(
      year: now.year,
      years: List.generate(3, (i) => now.year - i),
    );
  }

  Future<void> _onYearSelected(
    PayslipYearSelected event,
    Emitter<PayslipListState> emit,
  ) async {
    if (event.year == state.year && state.status == PayslipListStatus.success) return;
    await _load(event.year, emit);
  }

  Future<void> _load(int year, Emitter<PayslipListState> emit) async {
    emit(state.copyWith(year: year, status: PayslipListStatus.loading, payslips: const []));

    try {
      final payslips = await _repository.getPayslips(year: year);
      // User sudah pindah ke tahun lain selagi menunggu: hasil ini basi.
      if (state.year != year) return;
      emit(state.copyWith(status: PayslipListStatus.success, payslips: payslips));
    } on ApiException catch (e) {
      if (state.year != year) return;
      AppLogger.info('Slip gaji $year gagal dimuat: ${e.kind.name} — ${e.message}');
      emit(state.copyWith(status: PayslipListStatus.failure, errorMessage: e.message));
    } catch (e, stack) {
      if (state.year != year) return;
      AppLogger.error('Slip gaji $year gagal dimuat karena galat tak terduga', e, stack);
      emit(state.copyWith(
        status: PayslipListStatus.failure,
        errorMessage: 'Terjadi kesalahan tak terduga. Coba lagi.',
      ));
    }
  }
}
