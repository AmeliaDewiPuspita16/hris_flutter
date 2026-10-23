import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../../core/logging/app_logger.dart';
import '../../../../../../../../core/network/api_exception.dart';
import '../../../data/it_request_repository.dart';
import 'it_request_approval_event.dart';
import 'it_request_approval_state.dart';

/// Tab "Approve Request": memuat antrean HOD
/// (`GET /api/portal/apps/it_request/approvals`) dan mengirim keputusan
/// Approve/Reject.
///
/// Hanya dimulai untuk akun berperan `hod` — antrean ini milik HOD
/// department, akun lain tidak punya apa-apa untuk diputuskan.
class ItRequestApprovalBloc
    extends Bloc<ItRequestApprovalEvent, ItRequestApprovalState> {
  ItRequestApprovalBloc({required ItRequestRepository repository})
      : _repository = repository,
        super(const ItRequestApprovalState()) {
    on<ItRequestApprovalStarted>(_onLoad);
    on<ItRequestApprovalRefreshed>(_onLoad);
    on<ItRequestApprovalDecided>(_onDecided);
  }

  final ItRequestRepository _repository;

  /// Muat ulang yang tumpang tindih bisa membalas dengan urutan terbalik;
  /// hasil yang bukan permintaan terakhir dibuang.
  int _requestToken = 0;

  Future<void> _onLoad(
    ItRequestApprovalEvent event,
    Emitter<ItRequestApprovalState> emit,
  ) async {
    final token = ++_requestToken;

    emit(state.copyWith(
      status: ItRequestApprovalStatus.loading,
      errorMessage: null,
    ));

    try {
      final page = await _repository.fetchApprovals();
      if (token != _requestToken) return;

      emit(state.copyWith(
        status: ItRequestApprovalStatus.success,
        items: page.items,
        pending: page.pending,
      ));
    } on ApiException catch (e) {
      if (token != _requestToken) return;

      AppLogger.info(
          'Antrean approval IT gagal dimuat: ${e.kind.name} — ${e.message}');
      emit(state.copyWith(
        status: ItRequestApprovalStatus.failure,
        items: const [],
        pending: 0,
        errorMessage: e.message,
      ));
    } catch (e, stack) {
      if (token != _requestToken) return;

      AppLogger.error(
          'Antrean approval IT gagal karena galat tak terduga', e, stack);
      emit(state.copyWith(
        status: ItRequestApprovalStatus.failure,
        items: const [],
        pending: 0,
        errorMessage: 'An unexpected error occurred. Please try again.',
      ));
    }
  }

  /// Kirim keputusan dulu, baru keluarkan request dari daftar — kalau
  /// server gagal, request tetap ada supaya HOD bisa mencoba lagi.
  Future<void> _onDecided(
    ItRequestApprovalDecided event,
    Emitter<ItRequestApprovalState> emit,
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
        notice: ItRequestApprovalNotice(
          message: event.approved
              ? 'Request from ${item.requesterName} approved'
              : 'Request from ${item.requesterName} rejected',
          isError: false,
        ),
      ));
    } on ApiException catch (e) {
      AppLogger.info(
          'Keputusan approval IT gagal: ${e.kind.name} — ${e.message}');
      emit(state.copyWith(
        busyIds: Set.of(state.busyIds)..remove(item.id),
        notice: ItRequestApprovalNotice(message: e.message, isError: true),
      ));
    } catch (e, stack) {
      AppLogger.error('Keputusan approval IT gagal tak terduga', e, stack);
      emit(state.copyWith(
        busyIds: Set.of(state.busyIds)..remove(item.id),
        notice: const ItRequestApprovalNotice(
          message: 'An unexpected error occurred. Please try again.',
          isError: true,
        ),
      ));
    }
  }
}
