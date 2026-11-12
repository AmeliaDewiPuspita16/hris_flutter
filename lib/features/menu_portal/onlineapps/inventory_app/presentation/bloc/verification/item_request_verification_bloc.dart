import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../core/logging/app_logger.dart';
import '../../../../../../../core/network/api_exception.dart';
import '../../../data/inventory_item_request_demo_repository.dart';
import 'item_request_verification_event.dart';
import 'item_request_verification_state.dart';

/// Tab "Verification": memuat antrean request pending dan mengirim
/// keputusan Approve/Reject. Polanya sama dengan `EstApprovalBloc`.
///
/// Dimulai untuk SEMUA user karena aplikasi belum tahu siapa verifier —
/// server yang menentukan. Bila server menolak (401/403) maka
/// [ItemRequestVerificationState.denied] jadi true dan layar menyembunyikan
/// tabnya.
class ItemRequestVerificationBloc
    extends Bloc<ItemRequestVerificationEvent, ItemRequestVerificationState> {
  ItemRequestVerificationBloc({required InventoryItemRequestDemoRepository repository})
      : _repository = repository,
        super(const ItemRequestVerificationState()) {
    on<ItemRequestVerificationStarted>(_onLoad);
    on<ItemRequestVerificationRefreshed>(_onLoad);
    on<ItemRequestVerificationDecided>(_onDecided);
  }

  final InventoryItemRequestDemoRepository _repository;

  int _requestToken = 0;

  Future<void> _onLoad(
    ItemRequestVerificationEvent event,
    Emitter<ItemRequestVerificationState> emit,
  ) async {
    final token = ++_requestToken;

    emit(state.copyWith(
      status: ItemRequestVerificationStatus.loading,
      errorMessage: null,
    ));

    try {
      final page = await _repository.fetchVerifications();
      if (token != _requestToken) return;

      emit(state.copyWith(
        status: ItemRequestVerificationStatus.success,
        items: page.items,
        pending: page.pending,
        denied: false,
        resolved: true,
      ));
    } on ApiException catch (e) {
      if (token != _requestToken) return;

      AppLogger.info(
          'Antrean verifikasi item request gagal: ${e.kind.name} — ${e.message}');
      emit(state.copyWith(
        status: ItemRequestVerificationStatus.failure,
        items: const [],
        pending: 0,
        errorMessage: e.message,
        // 401/403: akun ini memang bukan verifier, bukan sekadar gagal muat.
        denied: e.kind == ApiErrorKind.unauthorized,
        resolved: true,
      ));
    } catch (e, stack) {
      if (token != _requestToken) return;

      AppLogger.error(
          'Antrean verifikasi item request gagal tak terduga', e, stack);
      emit(state.copyWith(
        status: ItemRequestVerificationStatus.failure,
        items: const [],
        pending: 0,
        errorMessage: 'An unexpected error occurred. Please try again.',
        resolved: true,
      ));
    }
  }

  /// Kirim keputusan dulu, baru keluarkan request dari antrean — kalau server
  /// gagal, request tetap ada supaya verifier bisa mencoba lagi.
  Future<void> _onDecided(
    ItemRequestVerificationDecided event,
    Emitter<ItemRequestVerificationState> emit,
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
        notice: ItemRequestVerificationNotice(
          message: event.approved
              ? '${item.code} approved'
              : '${item.code} rejected',
          isError: false,
        ),
      ));
    } on ApiException catch (e) {
      AppLogger.info(
          'Keputusan item request gagal: ${e.kind.name} — ${e.message}');
      emit(state.copyWith(
        busyIds: Set.of(state.busyIds)..remove(item.id),
        notice: ItemRequestVerificationNotice(message: e.message, isError: true),
      ));
    } catch (e, stack) {
      AppLogger.error('Keputusan item request gagal tak terduga', e, stack);
      emit(state.copyWith(
        busyIds: Set.of(state.busyIds)..remove(item.id),
        notice: const ItemRequestVerificationNotice(
          message: 'An unexpected error occurred. Please try again.',
          isError: true,
        ),
      ));
    }
  }
}
