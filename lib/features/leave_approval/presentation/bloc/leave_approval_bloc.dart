import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/logging/app_logger.dart';
import '../../../../../../core/network/api_exception.dart';
import '../../data/leave_approval_repository.dart';
import '../../domain/leave_approval_status.dart';
import 'leave_approval_event.dart';
import 'leave_approval_state.dart';

/// Memuat daftar pengajuan yang masuk ke HOD dan memproses keputusan
/// approve/reject.
class LeaveApprovalBloc extends Bloc<LeaveApprovalEvent, LeaveApprovalState> {
  LeaveApprovalBloc({required LeaveApprovalRepository repository})
      : _repository = repository,
        super(const LeaveApprovalState()) {
    on<LeaveApprovalStarted>(_onLoad);
    on<LeaveApprovalRefreshed>(_onLoad);
    on<LeaveApprovalDecided>(_onDecided);
  }

  final LeaveApprovalRepository _repository;

  Future<void> _onLoad(
    LeaveApprovalEvent event,
    Emitter<LeaveApprovalState> emit,
  ) async {
    emit(state.copyWith(status: LeaveApprovalLoadStatus.loading));

    try {
      final items = await _repository.fetchRequests();

      emit(state.copyWith(
        status: LeaveApprovalLoadStatus.success,
        items: items,
      ));
    } catch (e, stack) {
      AppLogger.error('Daftar leave approval gagal dimuat', e, stack);

      const message = 'Failed to load approvals. Try again.';
      emit(state.copyWith(
        status: LeaveApprovalLoadStatus.failure,
        errorMessage: message,
        // Kalau daftar lama masih ada, layar tetap menampilkannya —
        // kegagalan cukup diberitahukan lewat SnackBar.
        feedback: state.items.isEmpty
            ? null
            : const LeaveApprovalFeedback(message, isError: true),
      ));
    }
  }

  Future<void> _onDecided(
    LeaveApprovalDecided event,
    Emitter<LeaveApprovalState> emit,
  ) async {
    if (state.processingIds.contains(event.id)) return;

    emit(state.copyWith(processingIds: {...state.processingIds, event.id}));

    try {
      final updated = await _repository.decide(
        event.id,
        decision: event.decision,
        note: event.note,
      );

      final verb = event.decision == LeaveApprovalDecision.approve
          ? 'approved'
          : 'rejected';

      emit(state.copyWith(
        items: [
          for (final item in state.items) item.id == updated.id ? updated : item,
        ],
        processingIds: {...state.processingIds}..remove(event.id),
        feedback: LeaveApprovalFeedback(
          "${updated.requesterName}'s request $verb",
          decided: updated,
        ),
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        processingIds: {...state.processingIds}..remove(event.id),
        feedback: LeaveApprovalFeedback(e.message, isError: true),
      ));
    } catch (e, stack) {
      AppLogger.error('Keputusan leave approval gagal dikirim', e, stack);

      emit(state.copyWith(
        processingIds: {...state.processingIds}..remove(event.id),
        feedback: const LeaveApprovalFeedback(
          'Failed to submit your decision. Try again.',
          isError: true,
        ),
      ));
    }
  }
}
