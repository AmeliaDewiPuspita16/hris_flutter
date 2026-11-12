import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../core/logging/app_logger.dart';
import '../../../../../../../core/network/api_exception.dart';
import '../../../data/inventory_item_request_repository.dart';
import 'item_request_verification_event.dart';
import 'item_request_verification_state.dart';

/// Tab "Verification": memuat antrean LINE pending halaman demi halaman dan
/// mengirim keputusan Approve/Reject.
///
/// Layar sebaiknya memulai bloc ini hanya bila `options.permissions`
/// mengizinkan (`canOpenVerification`). Bila server tetap menolak (401/403)
/// maka [ItemRequestVerificationState.denied] jadi true dan layar
/// menyembunyikan tabnya.
class ItemRequestVerificationBloc
    extends Bloc<ItemRequestVerificationEvent, ItemRequestVerificationState> {
  ItemRequestVerificationBloc(
      {required InventoryItemRequestRepository repository})
      : _repository = repository,
        super(const ItemRequestVerificationState()) {
    on<ItemRequestVerificationStarted>(_onLoad);
    on<ItemRequestVerificationRefreshed>(_onLoad);
    on<ItemRequestVerificationSearchChanged>(_onSearchChanged);
    on<ItemRequestVerificationDecided>(_onDecided);
  }

  final InventoryItemRequestRepository _repository;

  static const _perPage = 20;
  static const _unexpected = 'An unexpected error occurred. Please try again';

  /// Permintaan yang tumpang tindih bisa membalas dengan urutan terbalik;
  /// hasil yang bukan permintaan terakhir dibuang.
  int _requestToken = 0;

  /// Kata kunci yang sedang berlaku; dipakai juga untuk refresh dan halaman
  /// berikutnya.
  String _search = '';

  Future<void> _onSearchChanged(
    ItemRequestVerificationSearchChanged event,
    Emitter<ItemRequestVerificationState> emit,
  ) async {
    final search = event.search.trim();
    if (search == _search &&
        state.status != ItemRequestVerificationStatus.initial) {
      return;
    }
    _search = search;

    // Hasil lama tidak berlaku lagi untuk kata kunci baru: kosongkan supaya
    // layar menampilkan skeleton,  ukan daftar yang salah.
    emit(state.copyWith(items: const []));
    await _onLoad(event, emit);
  }

  Future<void> _onLoad(
    ItemRequestVerificationEvent event,
    Emitter<ItemRequestVerificationState> emit,
  ) async {
    final token = ++_requestToken;

    emit(state.copyWith(
      status: ItemRequestVerificationStatus.loading,
      loadingMore: false,
      errorMessage: null,
    ));

    try {
      final page = await _repository.fetchVerifications(
          page: 1, perPage: _perPage, search: _search);
      final pending = await _pendingCount(fallback: page.meta.total);
      if (token != _requestToken) return;

      emit(state.copyWith(
        status: ItemRequestVerificationStatus.success,
        items: page.items,
        meta: page.meta,
        pending: pending,
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
        errorMessage: _unexpected,
        resolved: true,
      ));
    }
  }

  /// ANgka badge dari `pending-count`, yang tidak terpengaruh pencarian.
  /// Gagal bukan masalah besar: saat tidak mencaru, total hasil (`meta.total`)
  /// sama dengan natrean penuh.
  Future<int> _pendingCount({required int fallback}) async {
    try {
      return await _repository.fetchPendingCount();
    } catch (e) {
      AppLogger.info('pending-count verifikasi gagal dimuat: $e');
      return _search.isEmpty ? fallback : state.pending;
    }
  }

  /// Halaman berikutnya ditambahkan di bawah daftar yang ada. Bila gagal,
  /// daftar yang sudah tampil dibiarkan utuh — menggulir lagi mencoba lagi.
  Future<void> _onNextPage(
    ItemRequestVerificationNextPageRequested event,
    Emitter<ItemRequestVerificationState> emit,
  ) async {
    if (state.loadingMore ||
        !state.meta.hasMore ||
        state.status != ItemRequestVerificationStatus.success) {
      return;
    }

    final token = _requestToken;
    emit(state.copyWith(loadingMore: true));

    try {
      final page = await _repository.fetchVerifications(
        page: state.meta.currentPage + 1,
        perPage: _perPage,
        search: _search,
      );
      if (token != _requestToken) return;

      // Antrean bergeser saat ada yang diputuskan di sela-sela halaman,
      // sehingga satu line bisa muncul dua kali. Buang duplikatnya.
      final known = {for (final item in state.items) item.id};
      final fresh = page.items.where((item) => !known.contains(item.id));

      emit(state.copyWith(
        items: [...state.items, ...fresh],
        meta: page.meta,
        loadingMore: false,
      ));
    } on ApiException catch (e) {
      if (token != _requestToken) return;

      AppLogger.info('Halaman verifikasi berikutnya gagal: ${e.message}');
      emit(state.copyWith(loadingMore: false));
    } catch (e, stack) {
      if (token != _requestToken) return;

      AppLogger.error('Halaman verifikasi berikutnya gagal tak terduga', e, stack);
      emit(state.copyWith(loadingMore: false));
    }
  }

  /// Kirim keputusan dulu, baru keluarkan line dari antrean — kalau server
  /// gagal, line tetap ada supaya verifier bisa mencoba lagi.
  Future<void> _onDecided(
    ItemRequestVerificationDecided event,
    Emitter<ItemRequestVerificationState> emit,
  ) async {
    final item = event.item;
    if (state.busyIds.contains(item.id)) return;

    emit(state.copyWith(busyIds: {...state.busyIds, item.id}));

    try {
      if (event.approved) {
        await _repository.approveLine(item.id);
      } else {
        await _repository.rejectLine(item.id);
      }

      final remaining = state.items.where((r) => r.id != item.id).toList();
      emit(state.copyWith(
        items: remaining,
        pending: state.pending > 0 ? state.pending - 1 : 0,
        busyIds: Set.of(state.busyIds)..remove(item.id),
        notice: ItemRequestVerificationNotice(
          message: event.approved
              ? '${item.code} · ${item.itemName} approved'
              : '${item.code} · ${item.itemName} rejected',
          isError: false,
        ),
      ));

      // Halaman termuat habis tapi antrean masih ada: ambil ulang supaya
      // layar tidak menampilkan "All caught up" padahal belum.
      if (remaining.isEmpty && state.meta.hasMore) {
        add(const ItemRequestVerificationRefreshed());
      }
    } on ApiException catch (e) {
      AppLogger.info(
          'Keputusan item request gagal: ${e.kind.name} — ${e.message}');
      emit(state.copyWith(
        busyIds: Set.of(state.busyIds)..remove(item.id),
        notice: ItemRequestVerificationNotice(message: e.message, isError: true),
      ));

      // Line sudah diputuskan orang lain: antrean di layar sudah basi.
      if (e.message.toLowerCase().contains('no longer pending')) {
        add(const ItemRequestVerificationRefreshed());
      }
    } catch (e, stack) {
      AppLogger.error('Keputusan item request gagal tak terduga', e, stack);
      emit(state.copyWith(
        busyIds: Set.of(state.busyIds)..remove(item.id),
        notice: const ItemRequestVerificationNotice(
          message: _unexpected,
          isError: true,
        ),
      ));
    }
  }
}
