import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../../core/logging/app_logger.dart';
import '../../../../../../../../core/network/api_exception.dart';
import '../../../data/est_request_repository.dart';
import 'est_approval_event.dart';
import 'est_approval_state.dart';

/// Tab "Approve HOD": memuat antrean HOD
/// (`GET /api/portal/apps/est_work_order/approvals`) dan mengirim keputusan
/// Approve/Reject.
///
/// Hanya dimulai untuk akun berperan `hod` — antrean ini milik HOD
/// department, akun lain tidak punya apa-apa untuk diputuskan.
/// Kalau server tetap menolak ([EstApprovalState.denied]), layar menyembunyikan
/// tabnya.
class EstApprovalBloc
    extends Bloc<EstApprovalEvent, EstApprovalState> {
  EstApprovalBloc({required EstRequestRepository repository})
      : _repository = repository,
        super(const EstApprovalState()) {
    on<EstApprovalStarted>(_onLoad);
    on<EstApprovalRefreshed>(_onLoad);
    on<EstApprovalDecided>(_onDecided);
  }

  final EstRequestRepository _repository;

  /// Muat ulang yang tumpang tindih bisa membalas dengan urutan terbalik;
  /// hasil yang bukan permintaan terakhir dibuang.
  int _requestToken = 0;

  Future<void> _onLoad(
    EstApprovalEvent event,
    Emitter<EstApprovalState> emit,
  ) async {
    final token = ++_requestToken;

    emit(state.copyWith(
      status: EstApprovalStatus.loading,
      errorMessage: null,
    ));

    try {
      final page = await _repository.fetchApprovals();
      if (token != _requestToken) return;

      emit(state.copyWith(
        status: EstApprovalStatus.success,
        items: page.items,
        pending: page.pending,
        denied: false,
      ));
    } on ApiException catch (e) {
      if (token != _requestToken) return;

      AppLogger.info(
          'Antrean approval EST gagal dimuat: ${e.kind.name} — ${e.message}');
      emit(state.copyWith(
        status: EstApprovalStatus.failure,
        items: const [],
        pending: 0,
        errorMessage: e.message,
        // 401/403: akun ini memang tidak berhak, bukan sekadar gagal muat.
        denied: e.kind == ApiErrorKind.unauthorized,
      ));
    } catch (e, stack) {
      if (token != _requestToken) return;

      AppLogger.error(
          'Antrean approval EST gagal karena galat tak terduga', e, stack);
      emit(state.copyWith(
        status: EstApprovalStatus.failure,
        items: const [],
        pending: 0,
        errorMessage: 'An unexpected error occurred. Please try again.',
      ));
    }
  }

  /// Kirim keputusan dulu, baru keluarkan request dari daftar — kalau
  /// server gagal, request tetap ada supaya HOD bisa mencoba lagi.
  Future<void> _onDecided(
    EstApprovalDecided event,
    Emitter<EstApprovalState> emit,
  ) async {
    final item = event.item;
    if (state.busyIds.contains(item.id)) return;

    emit(state.copyWith(busyIds: {...state.busyIds, item.id}));

    try {
      if (event.approved) {
        await _repository.approve(item.id);
      } else {
        await _repository.reject(item.id, reason: event.reason);
      }

      emit(state.copyWith(
        items: state.items.where((r) => r.id != item.id).toList(),
        pending: state.pending > 0 ? state.pending - 1 : 0,
        busyIds: Set.of(state.busyIds)..remove(item.id),
        notice: EstApprovalNotice(
          message: event.approved
              ? 'Request from ${item.requesterName} approved'
              : 'Request from ${item.requesterName} rejected',
          isError: false,
        ),
      ));
    } on ApiException catch (e) {
      AppLogger.info(
          'Keputusan approval EST gagal: ${e.kind.name} — ${e.message}');
      emit(state.copyWith(
        busyIds: Set.of(state.busyIds)..remove(item.id),
        notice: EstApprovalNotice(message: e.message, isError: true),
      ));
    } catch (e, stack) {
      AppLogger.error('Keputusan approval EST gagal tak terduga', e, stack);
      emit(state.copyWith(
        busyIds: Set.of(state.busyIds)..remove(item.id),
        notice: const EstApprovalNotice(
          message: 'An unexpected error occurred. Please try again.',
          isError: true,
        ),
      ));
    }
  }
}
