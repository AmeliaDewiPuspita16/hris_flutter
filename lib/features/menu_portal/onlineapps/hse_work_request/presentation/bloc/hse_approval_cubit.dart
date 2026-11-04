import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/logging/app_logger.dart';
import '../../../../../../core/network/api_exception.dart';
import '../../data/hse_work_request_repository.dart';
import '../../domain/hse_work_request.dart';

enum HseApprovalStatus { initial, loading, success, failure }

/// Hasil approve/reject untuk snackbar.
class HseApprovalNotice {
  const HseApprovalNotice(this.message, {this.isError = false});

  final String message;
  final bool isError;
}

class HseApprovalState {
  const HseApprovalState({
    this.status = HseApprovalStatus.initial,
    this.items = const [],
    this.summary = const {},
    this.stage,
    this.denied = false,
    this.confirmed = false,
    this.busyIds = const {},
    this.errorMessage,
    this.notice,
  });

  final HseApprovalStatus status;
  final List<HseWorkRequest> items;

  /// Jumlah antrean per stage (`hod`, `hse`) — key-nya sekaligus stage yang
  /// dimiliki user.
  final Map<String, int> summary;

  /// Stage yang sedang disaring; null = semua stage milik user.
  final String? stage;

  /// Server membalas 403: akun ini bukan approver, tab disembunyikan.
  final bool denied;

  /// Server pernah membalas antrean dengan sukses: akun ini approver.
  /// Bertahan selama refresh supaya tab tidak berkedip.
  final bool confirmed;

  /// Permit yang sedang diproses approve/reject (tombolnya loading).
  final Set<int> busyIds;
  final String? errorMessage;
  final HseApprovalNotice? notice;

  int get pending => summary.values.fold(0, (sum, n) => sum + n);

  bool get isFirstLoad =>
      (status == HseApprovalStatus.initial ||
          status == HseApprovalStatus.loading) &&
      items.isEmpty;

  HseApprovalState copyWith({
    HseApprovalStatus? status,
    List<HseWorkRequest>? items,
    Map<String, int>? summary,
    bool? denied,
    bool? confirmed,
    Set<int>? busyIds,
    String? errorMessage,
    HseApprovalNotice? notice,
  }) {
    return HseApprovalState(
      status: status ?? this.status,
      items: items ?? this.items,
      summary: summary ?? this.summary,
      stage: stage,
      denied: denied ?? this.denied,
      confirmed: confirmed ?? this.confirmed,
      busyIds: busyIds ?? this.busyIds,
      errorMessage: errorMessage,
      notice: notice,
    );
  }
}

/// Antrean approval HOD/HSE dari `GET /hse_permit/approvals`, plus aksi
/// approve & reject.
class HseApprovalCubit extends Cubit<HseApprovalState> {
  HseApprovalCubit({required HseWorkRequestRepository repository})
      : _repository = repository,
        super(const HseApprovalState());

  final HseWorkRequestRepository _repository;
  int _token = 0;

  Future<void> load({String? stage}) async {
    emit(HseApprovalState(
      status: HseApprovalStatus.loading,
      items: stage == state.stage ? state.items : const [],
      summary: state.summary,
      stage: stage,
      denied: state.denied,
      confirmed: state.confirmed,
    ));
    await _fetch();
  }

  Future<void> refresh() => load(stage: state.stage);

  Future<void> _fetch() async {
    final token = ++_token;
    try {
      final page = await _repository.fetchApprovals(stage: state.stage);
      if (token != _token || isClosed) return;
      emit(state.copyWith(
        status: HseApprovalStatus.success,
        confirmed: true,
        items: page.items,
        // Saat disaring per stage, summary tetap memuat semua stage.
        summary: page.summary,
      ));
    } on ApiException catch (e) {
      if (token != _token || isClosed) return;
      AppLogger.info('Approval HSE gagal: ${e.kind.name} — ${e.message}');
      emit(state.copyWith(
        status: HseApprovalStatus.failure,
        items: const [],
        denied: e.kind == ApiErrorKind.unauthorized,
        errorMessage: e.message,
      ));
    } catch (e, stack) {
      if (token != _token || isClosed) return;
      AppLogger.error('Approval HSE gagal tak terduga', e, stack);
      emit(state.copyWith(
        status: HseApprovalStatus.failure,
        items: const [],
        errorMessage: 'An unexpected error occurred. Please try again.',
      ));
    }
  }

  /// Approve ([approved] true) atau reject permit, lalu muat ulang antrean.
  /// Mengembalikan true bila berhasil.
  Future<bool> decide(HseWorkRequest item, {required bool approved}) async {
    if (state.busyIds.contains(item.id)) return false;
    emit(state.copyWith(busyIds: {...state.busyIds, item.id}));

    try {
      final result = approved
          ? await _repository.approve(item.id)
          : await _repository.reject(item.id);
      if (isClosed) return true;
      emit(state.copyWith(
        busyIds: {...state.busyIds}..remove(item.id),
        notice: HseApprovalNotice(result.message),
      ));
      await _fetch();
      return true;
    } catch (e, stack) {
      if (isClosed) return false;
      final message = e is ApiException
          ? e.message
          : 'An unexpected error occurred. Please try again.';
      if (e is! ApiException) {
        AppLogger.error('Keputusan HSE gagal tak terduga', e, stack);
      }
      emit(state.copyWith(
        busyIds: {...state.busyIds}..remove(item.id),
        notice: HseApprovalNotice(message, isError: true),
      ));
      return false;
    }
  }
}
