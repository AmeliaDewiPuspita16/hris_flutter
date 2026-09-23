import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/logging/app_logger.dart';
import '../../../../shared/domain/role.dart';
import '../../../data/pengajuan_repository.dart';
import '../../../domain/leave_type.dart';
import 'leave_balance_event.dart';
import 'leave_balance_state.dart';

/// Memuat saldo cuti/izin/lembur untuk tab Ringkasan.
class LeaveBalanceBloc extends Bloc<LeaveBalanceEvent, LeaveBalanceState> {
  LeaveBalanceBloc({
    required PengajuanRepository repository,
    required Role role,
  })  : _repository = repository,
        _role = role,
        super(const LeaveBalanceState()) {
    on<LeaveBalanceStarted>(_onLoad);
    on<LeaveBalanceRefreshed>(_onLoad);
  }

  final PengajuanRepository _repository;
  final Role _role;

  Future<void> _onLoad(
    LeaveBalanceEvent event,
    Emitter<LeaveBalanceState> emit,
  ) async {
    emit(state.copyWith(
      status: LeaveBalanceStatus.loading,
      errorMessage: null,
    ));

    try {
      final balances = await _repository.fetchBalances(
        showPersonalLembur: LeaveTypeX.showPersonalLembur(_role),
      );

      emit(state.copyWith(
        status: LeaveBalanceStatus.success,
        balances: balances,
      ));
    } catch (e, stack) {
      AppLogger.error('Saldo cuti/izin gagal dimuat', e, stack);

      emit(state.copyWith(
        status: LeaveBalanceStatus.failure,
        errorMessage: 'Gagal memuat saldo. Coba lagi.',
      ));
    }
  }
}
