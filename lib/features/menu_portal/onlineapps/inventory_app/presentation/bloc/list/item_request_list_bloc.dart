import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../core/logging/app_logger.dart';
import '../../../../../../../core/network/api_exception.dart';
import '../../../data/inventory_item_request_repository.dart';
import 'item_request_list_event.dart';
import 'item_request_list_state.dart';

/// Memuat daftar "Request Items" halaman demi halaman (infinite
/// scroll). Polanya sama dengan `EstRequestListBloc`.
///
/// Tidak butuh id user: server sudah menandai request milik sendiri lewat
/// `is_mine`, dan hak edit/cancel lewat `can_edit` / `can_cancel`.
class ItemRequestListBloc
    extends Bloc<ItemRequestListEvent, ItemRequestListState> {
  ItemRequestListBloc({required InventoryItemRequestRepository repository})
      : _repository = repository,
        super(const ItemRequestListState()) {
    on<ItemRequestListStarted>(_onLoad);
    on<ItemRequestListRefreshed>(_onLoad);
    on<ItemRequestListFilterChanged>(_onFilterChanged);
    on<ItemRequestListNextPageRequested>(_onNextPage);
  }

  final InventoryItemRequestRepository _repository;

  /// Permintaan yang tumpang tindih bisa membalas dengan urutan terbalik;
  /// hasil yang bukan permintaan terakhir dibuang.
  int _requestToken = 0;

  /// Penyaring yang sedang berlaku; dipakai juga untuk refresh dan halaman
  /// berikutnya.
  ItemRequestListFilter _filter = ItemRequestListFilter.none;

  Future<void> _onFilterChanged(
    ItemRequestListFilterChanged event,
    Emitter<ItemRequestListState> emit,
  ) async {
    if (event.filter == _filter &&
        state.status != ItemRequestListStatus.initial) {
      return;
    }
    _filter = event.filter;

    // Hasil lama tidak berlaku lagi untuk penyaring baru: kosongkan supaya
    // layar menampilkan skeleton, bukan daftar yang salah.
    emit(state.copyWith(items: const []));
    await _onLoad(event, emit);
  }

  Future<void> _onLoad(
    ItemRequestListEvent event,
    Emitter<ItemRequestListState> emit,
  ) async {
    final token = ++_requestToken;

    emit(state.copyWith(
      status: ItemRequestListStatus.loading,
      loadingMore: false,
      errorMessage: null,
    ));

    try {
      final page = await _repository.fetchRequests(
        page: 1,
        status: _filter.status,
        search: _filter.search,
        mine: _filter.mine,
      );
      if (token != _requestToken) return;

      emit(state.copyWith(
        status: ItemRequestListStatus.success,
        items: page.items,
        meta: page.meta,
      ));
    } on ApiException catch (e) {
      if (token != _requestToken) return;

      AppLogger.info('List item request gagal dimuat: ${e.kind.name} — ${e.message}');
      emit(state.copyWith(
        status: ItemRequestListStatus.failure,
        items: const [],
        errorMessage: e.message,
      ));
    } catch (e, stack) {
      if (token != _requestToken) return;

      AppLogger.error('List item request gagal karena galat tak terduga', e, stack);
      emit(state.copyWith(
        status: ItemRequestListStatus.failure,
        items: const [],
        errorMessage: 'An unexpected error occurred. Please try again.',
      ));
    }
  }

  /// Halaman berikutnya ditambahkan di bawah daftar yang ada. Bila gagal,
  /// daftar yang sudah tampil dibiarkan utuh — menggulir lagi mencoba lagi.
  Future<void> _onNextPage(
    ItemRequestListNextPageRequested event,
    Emitter<ItemRequestListState> emit,
  ) async {
    if (state.loadingMore ||
        !state.meta.hasMore ||
        state.status != ItemRequestListStatus.success) {
      return;
    }

    final token = _requestToken;
    emit(state.copyWith(loadingMore: true));

    try {
      final page = await _repository.fetchRequests(
        page: state.meta.currentPage + 1,
        status: _filter.status,
        search: _filter.search,
        mine: _filter.mine,
      );
      if (token != _requestToken) return;

      // Request baru yang masuk di sela-sela halaman mendorong item lama ke
      // halaman berikutnya, sehingga bisa muncul dua kali. Buang duplikatnya.
      final known = {for (final item in state.items) item.id};
      final fresh = page.items.where((item) => !known.contains(item.id));

      emit(state.copyWith(
        items: [...state.items, ...fresh],
        meta: page.meta,
        loadingMore: false,
      ));
    } on ApiException catch (e) {
      if (token != _requestToken) return;

      AppLogger.info('Halaman berikutnya gagal: ${e.kind.name} — ${e.message}');
      emit(state.copyWith(loadingMore: false));
    } catch (e, stack) {
      if (token != _requestToken) return;

      AppLogger.error('Halaman berikutnya gagal tak terduga', e, stack);
      emit(state.copyWith(loadingMore: false));
    }
  }
}
