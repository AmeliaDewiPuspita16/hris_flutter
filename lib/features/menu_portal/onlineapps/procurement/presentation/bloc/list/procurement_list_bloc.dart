import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../core/logging/app_logger.dart';
import '../../../../../../../core/network/api_exception.dart';
import '../../../data/procurement_repository.dart';
import 'procurement_list_event.dart';
import 'procurement_list_state.dart';

/// Mengurus daftar Procurement Monitoring: memuat halaman, mengganti filter
/// status, mencari, dan menambah halaman berikutnya.
///
/// Filter, pencarian, dan paginasi semuanya dikerjakan server — chip memakai
/// `summary` dari respons, jadi angkanya tetap benar untuk seluruh PR meski
/// baru satu halaman yang termuat.
class ProcurementListBloc
    extends Bloc<ProcurementListEvent, ProcurementListState> {
  ProcurementListBloc({required ProcurementRepository repository})
      : _repository = repository,
        super(const ProcurementListState()) {
    on<ProcurementListStarted>(_onReload);
    on<ProcurementListRefreshed>(_onReload);
    on<ProcurementListStatusSelected>(_onStatusSelected);
    on<ProcurementListSearched>(_onSearched);
    on<ProcurementListNextPageRequested>(_onNextPage);
  }

  final ProcurementRepository _repository;

  /// Nomor urut permintaan terakhir.
  ///
  /// Bloc memproses event secara bersamaan, jadi dua ketikan beruntun bisa
  /// menghasilkan dua request yang balasannya datang terbalik. Tiap
  /// permintaan mengambil nomor, lalu hasilnya dibuang bila nomornya sudah
  /// bukan yang terbaru — tanpa ini, hasil ketikan lama bisa menimpa hasil
  /// ketikan terakhir.
  int _requestToken = 0;

  Future<void> _onReload(
    ProcurementListEvent event,
    Emitter<ProcurementListState> emit,
  ) =>
      _loadFirstPage(emit);

  Future<void> _onStatusSelected(
    ProcurementListStatusSelected event,
    Emitter<ProcurementListState> emit,
  ) {
    emit(state.copyWith(statusCode: event.statusCode));
    return _loadFirstPage(emit);
  }

  Future<void> _onSearched(
    ProcurementListSearched event,
    Emitter<ProcurementListState> emit,
  ) {
    emit(state.copyWith(query: event.query));
    return _loadFirstPage(emit);
  }

  Future<void> _loadFirstPage(Emitter<ProcurementListState> emit) async {
    final token = ++_requestToken;

    // items sengaja dipertahankan: layar menampilkan spinner sepenuh layar
    // hanya saat belum ada apa pun (lihat ProcurementListState.isFirstLoad),
    // jadi daftar lama tidak berkedip hilang saat memuat ulang.
    emit(state.copyWith(
      status: ProcurementListStatus.loading,
      errorMessage: null,
    ));

    try {
      final page = await _repository.fetchList(
        page: 1,
        statusCode: state.statusCode,
        search: state.query,
      );

      if (token != _requestToken) return;

      emit(state.copyWith(
        status: ProcurementListStatus.success,
        items: page.items,
        summary: page.summary,
        meta: page.meta,
        loadingMore: false,
      ));
    } on ApiException catch (e) {
      if (token != _requestToken) return;

      AppLogger.info('Daftar PR gagal dimuat: ${e.kind.name} — ${e.message}');
      emit(state.copyWith(
        status: ProcurementListStatus.failure,
        items: const [],
        errorMessage: e.message,
        loadingMore: false,
      ));
    } catch (e, stack) {
      if (token != _requestToken) return;

      AppLogger.error('Daftar PR gagal karena galat tak terduga', e, stack);
      emit(state.copyWith(
        status: ProcurementListStatus.failure,
        items: const [],
        errorMessage: 'Terjadi kesalahan tak terduga. Coba lagi.',
        loadingMore: false,
      ));
    }
  }

  Future<void> _onNextPage(
    ProcurementListNextPageRequested event,
    Emitter<ProcurementListState> emit,
  ) async {
    // Gulir bisa memicu event ini berkali-kali dalam sekejap; satu permintaan
    // halaman berikutnya pada satu waktu sudah cukup.
    if (state.loadingMore || !state.meta.hasMore) return;
    if (state.status != ProcurementListStatus.success) return;

    final token = _requestToken;
    emit(state.copyWith(loadingMore: true));

    try {
      final page = await _repository.fetchList(
        page: state.meta.currentPage + 1,
        statusCode: state.statusCode,
        search: state.query,
      );

      // Filter atau kata kunci berubah selagi halaman ini diambil — hasilnya
      // sudah tidak nyambung dengan daftar yang sekarang.
      if (token != _requestToken) return;

      emit(state.copyWith(
        items: [...state.items, ...page.items],
        summary: page.summary,
        meta: page.meta,
        loadingMore: false,
      ));
    } on ApiException catch (e) {
      if (token != _requestToken) return;

      // Halaman berikutnya gagal bukan alasan mengosongkan yang sudah tampil.
      AppLogger.info('Halaman PR berikutnya gagal: ${e.message}');
      emit(state.copyWith(loadingMore: false, errorMessage: e.message));
    }
  }
}
