import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../core/logging/app_logger.dart';
import '../../../../../../../core/network/api_exception.dart';
import '../../../data/indent_vehicle_repository.dart';
import 'indent_approval_event.dart';
import 'indent_approval_state.dart';

/// Tab "Supervisor Approval": memuat request yang menunggu keputusan atasan
/// (`GET /api/list_hod_approve`) dan mengirim keputusan Approve/Reject.
///
/// Bloc ini hanya boleh dimulai untuk akun berperan `hod` — server membalas
/// 404 untuk akun lain.
class IndentApprovalBloc
    extends Bloc<IndentApprovalEvent, IndentApprovalState> {
  IndentApprovalBloc({required IndentVehicleRepository repository})
      : _repository = repository,
        super(const IndentApprovalState()) {
    on<IndentApprovalStarted>(_onLoad);
    on<IndentApprovalRefreshed>(_onLoad);
    on<IndentApprovalDecided>(_onDecided);
  }

  final IndentVehicleRepository _repository;

  /// Muat ulang yang tumpang tindih bisa membalas dengan urutan terbalik;
  /// hasil yang bukan permintaan terakhir dibuang.
  int _requestToken = 0;

  Future<void> _onLoad(
    IndentApprovalEvent event,
    Emitter<IndentApprovalState> emit,
  ) async {
    final token = ++_requestToken;

    emit(state.copyWith(
      status: IndentApprovalStatus.loading,
      errorMessage: null,
    ));

    try {
      final items = await _repository.fetchApprovals();
      if (token != _requestToken) return;

      emit(state.copyWith(status: IndentApprovalStatus.success, items: items));
    } on ApiException catch (e) {
      if (token != _requestToken) return;

      AppLogger.info('List approval gagal dimuat: ${e.kind.name} — ${e.message}');
      emit(state.copyWith(
        status: IndentApprovalStatus.failure,
        items: const [],
        errorMessage: e.message,
      ));
    } catch (e, stack) {
      if (token != _requestToken) return;

      AppLogger.error('List approval gagal karena galat tak terduga', e, stack);
      emit(state.copyWith(
        status: IndentApprovalStatus.failure,
        items: const [],
        errorMessage: 'Terjadi kesalahan tak terduga. Coba lagi.',
      ));
    }
  }

  /// Kirim keputusan dulu, baru keluarkan request dari daftar — kalau
  /// server gagal, request tetap ada supaya atasan bisa mencoba lagi.
  Future<void> _onDecided(
    IndentApprovalDecided event,
    Emitter<IndentApprovalState> emit,
  ) async {
    final item = event.item;
    if (state.busyIds.contains(item.id)) return;

    emit(state.copyWith(busyIds: {...state.busyIds, item.id}));

    try {
      if (event.approved) {
        await _repository.approveByHod(item.id);
      } else {
        await _repository.rejectByHod(item.id);
      }

      emit(state.copyWith(
        items: state.items.where((r) => r.id != item.id).toList(),
        busyIds: Set.of(state.busyIds)..remove(item.id),
        notice: IndentApprovalNotice(
          message: event.approved
              ? 'Request ${item.name} disetujui'
              : 'Request ${item.name} ditolak',
          isError: false,
        ),
      ));
    } on ApiException catch (e) {
      AppLogger.info('Keputusan approval gagal: ${e.kind.name} — ${e.message}');
      emit(state.copyWith(
        busyIds: Set.of(state.busyIds)..remove(item.id),
        notice: IndentApprovalNotice(message: e.message, isError: true),
      ));
    } catch (e, stack) {
      AppLogger.error('Keputusan approval gagal tak terduga', e, stack);
      emit(state.copyWith(
        busyIds: Set.of(state.busyIds)..remove(item.id),
        notice: const IndentApprovalNotice(
          message: 'Terjadi kesalahan tak terduga. Coba lagi.',
          isError: true,
        ),
      ));
    }
  }
}
