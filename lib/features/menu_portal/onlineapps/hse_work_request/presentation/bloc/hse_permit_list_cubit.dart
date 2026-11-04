import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/logging/app_logger.dart';
import '../../../../../../core/network/api_exception.dart';
import '../../../../../../core/network/page_meta.dart';
import '../../data/hse_work_request_repository.dart';
import '../../domain/hse_permit_page.dart';
import '../../domain/hse_request_status.dart';
import '../../domain/hse_work_request.dart';

enum HseListStatus { initial, loading, success, failure }

class HsePermitListState {
  const HsePermitListState({
    this.status = HseListStatus.initial,
    this.items = const [],
    this.meta = HsePermitPage.emptyMeta,
    this.filter,
    this.mine = false,
    this.loadingMore = false,
    this.errorMessage,
  });

  final HseListStatus status;
  final List<HseWorkRequest> items;
  final PageMeta meta;

  /// Filter status di server; null = semua (server menyembunyikan Reject).
  final HseRequestStatus? filter;

  /// Hanya permit milik user yang login (`?mine=1`).
  final bool mine;
  final bool loadingMore;
  final String? errorMessage;

  bool get isFirstLoad =>
      (status == HseListStatus.initial || status == HseListStatus.loading) &&
      items.isEmpty;

  HsePermitListState copyWith({
    HseListStatus? status,
    List<HseWorkRequest>? items,
    PageMeta? meta,
    bool? loadingMore,
    String? errorMessage,
  }) {
    return HsePermitListState(
      status: status ?? this.status,
      items: items ?? this.items,
      meta: meta ?? this.meta,
      filter: filter,
      mine: mine,
      loadingMore: loadingMore ?? this.loadingMore,
      errorMessage: errorMessage,
    );
  }
}

/// Daftar permit dari `GET /hse_permit`, halaman demi halaman.
class HsePermitListCubit extends Cubit<HsePermitListState> {
  HsePermitListCubit({required HseWorkRequestRepository repository})
      : _repository = repository,
        super(const HsePermitListState());

  final HseWorkRequestRepository _repository;

  /// Permintaan yang tumpang tindih (ganti filter cepat-cepat, refresh
  /// ganda) bisa membalas tidak berurutan; hanya yang terakhir dipakai.
  int _token = 0;

  /// Muat ulang dari halaman 1 dengan [filter] baru.
  Future<void> applyFilter(HseRequestStatus? filter) async {
    emit(HsePermitListState(
      status: HseListStatus.loading,
      filter: filter,
      mine: state.mine,
    ));
    await _load();
  }

  /// Hanya permit milik sendiri ([mine] true) atau semua permit.
  Future<void> setMine(bool mine) async {
    if (mine == state.mine) return;
    emit(HsePermitListState(
      status: HseListStatus.loading,
      filter: state.filter,
      mine: mine,
    ));
    await _load();
  }

  /// Muat ulang dari halaman 1, daftar lama tetap tampil selama memuat.
  Future<void> refresh() async {
    emit(state.copyWith(status: HseListStatus.loading, loadingMore: false));
    await _load();
  }

  Future<void> _load() async {
    final token = ++_token;
    try {
      final page = await _repository.fetchPermits(
        status: state.filter,
        mine: state.mine,
      );
      if (token != _token || isClosed) return;
      emit(state.copyWith(
        status: HseListStatus.success,
        items: page.items,
        meta: page.meta,
      ));
    } catch (e, stack) {
      if (token != _token || isClosed) return;
      emit(state.copyWith(
        status: HseListStatus.failure,
        items: const [],
        errorMessage: _messageOf(e, stack),
      ));
    }
  }

  /// Halaman berikutnya; diabaikan bila sedang memuat / sudah habis.
  Future<void> loadMore() async {
    if (state.loadingMore ||
        !state.meta.hasMore ||
        state.status != HseListStatus.success) {
      return;
    }

    final token = _token;
    emit(state.copyWith(loadingMore: true));
    try {
      final page = await _repository.fetchPermits(
        status: state.filter,
        mine: state.mine,
        page: state.meta.currentPage + 1,
      );
      if (token != _token || isClosed) return;

      // Permit baru di sela-sela halaman bisa mendorong item lama ke
      // halaman berikutnya — buang yang sudah ada.
      final known = {for (final item in state.items) item.id};
      emit(state.copyWith(
        items: [
          ...state.items,
          ...page.items.where((i) => !known.contains(i.id)),
        ],
        meta: page.meta,
        loadingMore: false,
      ));
    } catch (e, stack) {
      if (token != _token || isClosed) return;
      _messageOf(e, stack);
      emit(state.copyWith(loadingMore: false));
    }
  }

  static String _messageOf(Object e, StackTrace stack) {
    if (e is ApiException) {
      AppLogger.info('Daftar HSE gagal: ${e.kind.name} — ${e.message}');
      return e.message;
    }
    AppLogger.error('Daftar HSE gagal karena galat tak terduga', e, stack);
    return 'An unexpected error occurred. Please try again.';
  }
}
