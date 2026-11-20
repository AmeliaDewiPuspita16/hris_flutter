import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../core/logging/app_logger.dart';
import '../../../../../../../core/network/api_exception.dart';
import '../../../data/meter_reading_repository.dart';
import '../../../domain/meter_reading_summary.dart';
import 'meter_reading_list_event.dart';
import 'meter_reading_list_state.dart';

/// Mengurus daftar Meter Reading: memuat halaman, mengganti filter jenis
/// meter, kategori, dan status pencatatan, mencari, dan menambah halaman berikutnya.
///
/// Filter, pencarian, dan paginasi semuanya dikerjakan sisi server. Chip dan
/// progress bar memakai `summary` dari respons, jadi angkanya benar untuk
/// seluruh meter walau baru satu halaman yang termuat.
///
/// Setelah petugas mencatat pembacaan, layar menutup detail lalu mengirim
/// [MeterReadingListRefreshed]: angka chip dan status baris ikut benar tanpa
/// bloc ini menebak-nebak perubahannya.
class MeterReadingListBloc
    extends Bloc<MeterReadingListEvent, MeterReadingListState> {
  /// [initialStateCode] membuka daftar langsung dengan chip status itu aktif
  /// (mis. `pending` dari banner "Belum dicatat"). Null = Semua.
  MeterReadingListBloc({
    required MeterReadingRepository repository,
    String? initialStateCode,
  })  : _repository = repository,
        super(MeterReadingListState(stateCode: initialStateCode)) {
    on<MeterReadingListStarted>(_onStarted);
    on<MeterReadingListRefreshed>(_onRefreshed);
    on<MeterReadingListStateSelected>(_onStateSelected);
    on<MeterReadingListTypeSelected>(_onTypeSelected);
    on<MeterReadingListCategorySelected>(_onCategorySelected);
    on<MeterReadingListFiltersApplied>(_onFiltersApplied);
    on<MeterReadingListSearched>(_onSearched);
    on<MeterReadingListFiltersCleared>(_onFiltersCleared);
    on<MeterReadingListNextPageRequested>(_onNextPage);
    on<MeterReadingListNextPageRetried>(_onNextPageRetried);
  }

  final MeterReadingRepository _repository;

  /// Nomor urut permintaan halaman pertama terakhir.
  ///
  /// Bloc memproses event secara bersamaan, jadi dua perubahan filter
  /// beruntun bisa menghasilkan dua request yang balasannya datang
  /// terbalik. Tiap permintaan mengambil nomor, lalu hasilnya dibuang bila
  /// nomornya sudah bukan yang terbaru.
  int _requestToken = 0;

  Future<void> _onStarted(
    MeterReadingListStarted event,
    Emitter<MeterReadingListState> emit,
  ) =>
      _loadFirstPage(emit);

  Future<void> _onRefreshed(
    MeterReadingListRefreshed event,
    Emitter<MeterReadingListState> emit,
  ) =>
      _loadFirstPage(emit);

  Future<void> _onStateSelected(
    MeterReadingListStateSelected event,
    Emitter<MeterReadingListState> emit,
  ) {
    emit(state.copyWith(stateCode: event.stateCode));
    return _loadFirstPage(emit);
  }

  Future<void> _onTypeSelected(
    MeterReadingListTypeSelected event,
    Emitter<MeterReadingListState> emit,
  ) {
    emit(state.copyWith(typeCode: event.typeCode));
    return _loadFirstPage(emit);
  }

  Future<void> _onCategorySelected(
    MeterReadingListCategorySelected event,
    Emitter<MeterReadingListState> emit,
  ) {
    emit(state.copyWith(category: event.category));
    return _loadFirstPage(emit);
  }

  Future<void> _onFiltersApplied(
    MeterReadingListFiltersApplied event,
    Emitter<MeterReadingListState> emit,
  ) {
    // Tanpa perubahan, tidak ada yang perlu dimuat ulang.
    if (event.typeCode == state.typeCode && event.category == state.category) {
      return Future.value();
    }

    emit(state.copyWith(typeCode: event.typeCode, category: event.category));
    return _loadFirstPage(emit);
  }

  Future<void> _onSearched(
    MeterReadingListSearched event,
    Emitter<MeterReadingListState> emit,
  ) {
    emit(state.copyWith(query: event.query));
    return _loadFirstPage(emit);
  }

  Future<void> _onFiltersCleared(
    MeterReadingListFiltersCleared event,
    Emitter<MeterReadingListState> emit,
  ) {
    emit(state.copyWith(
      typeCode: null,
      category: null,
      stateCode: null,
      query: '',
    ));
    return _loadFirstPage(emit);
  }

  Future<void> _loadFirstPage(Emitter<MeterReadingListState> emit) async {
    final token = ++_requestToken;

    // items sengaja dipertahankan: layar menampilkan skeleton sepenuh layar
    // hanya saat belum ada apa pun (lihat MeterReadingListState.isFirstLoad),
    // jadi daftar lama tidak berkedip hilang saat memuat ulang.
    emit(state.copyWith(
      status: MeterReadingListStatus.loading,
      errorMessage: null,
      loadMoreError: null,
    ));

    try {
      final page = await _repository.fetchList(
        page: 1,
        typeCode: state.typeCode,
        category: state.category,
        stateCode: state.stateCode,
        search: state.query,
      );

      if (token != _requestToken) return;

      emit(state.copyWith(
        status: MeterReadingListStatus.success,
        items: page.items,
        counts: page.counts,
        meta: page.meta,
        activePeriod: page.activePeriod,
        canWrite: page.canWrite,
        // Daftar kategori ikut di tiap respons; hanya diperbarui saat tidak
        // ada filter kategori, supaya pilihannya tidak ikut menyempit.
        categories: state.category == null && page.categories.isNotEmpty
            ? page.categories
            : state.categories,
        loadingMore: false,
      ));
    } on ApiException catch (e) {
      if (token != _requestToken) return;

      AppLogger.info(
        'Daftar Meter Reading gagal dimuat: ${e.kind.name} — ${e.message}',
      );
      emit(state.copyWith(
        status: MeterReadingListStatus.failure,
        items: const [],
        errorMessage: e.message,
        loadingMore: false,
      ));
    } catch (e, stack) {
      if (token != _requestToken) return;

      AppLogger.error('Daftar Meter Reading gagal karena galat tak terduga', e, stack);
      emit(state.copyWith(
        status: MeterReadingListStatus.failure,
        items: const [],
        errorMessage: 'An unexpected error occurred. Please try again.',
        loadingMore: false,
      ));
    }
  }

  Future<void> _onNextPage(
    MeterReadingListNextPageRequested event,
    Emitter<MeterReadingListState> emit,
  ) {
    // Gulir bisa memicu event ini berkali-kali dalam sekejap; satu permintaan
    // halaman berikutnya pada satu waktu sudah cukup. Selama galat halaman
    // sebelumnya belum dicoba ulang lewat tombol, gulir tidak mengulangnya.
    if (state.loadingMore || state.loadMoreError != null) {
      return Future.value();
    }
    return _loadNextPage(emit);
  }

  Future<void> _onNextPageRetried(
    MeterReadingListNextPageRetried event,
    Emitter<MeterReadingListState> emit,
  ) {
    if (state.loadingMore) return Future.value();

    emit(state.copyWith(loadMoreError: null));
    return _loadNextPage(emit);
  }

  Future<void> _loadNextPage(Emitter<MeterReadingListState> emit) async {
    if (!state.meta.hasMore) return;
    if (state.status != MeterReadingListStatus.success) return;

    final token = _requestToken;
    emit(state.copyWith(loadingMore: true));

    try {
      final page = await _repository.fetchList(
        page: state.meta.currentPage + 1,
        typeCode: state.typeCode,
        category: state.category,
        stateCode: state.stateCode,
        search: state.query,
      );

      // Filter atau kata kunci berubah selagi halaman ini diambil — hasilnya
      // sudah tidak nyambung dengan daftar yang sekarang.
      if (token != _requestToken) return;

      emit(state.copyWith(
        items: _appendWithoutDuplicates(state.items, page.items),
        counts: page.counts,
        meta: page.meta,
        loadingMore: false,
      ));
    } on ApiException catch (e) {
      if (token != _requestToken) return;

      // Halaman berikutnya gagal bukan alasan mengosongkan yang sudah tampil.
      AppLogger.info('Halaman Meter Reading berikutnya gagal: ${e.message}');
      emit(state.copyWith(loadingMore: false, loadMoreError: e.message));
    } catch (e, stack) {
      if (token != _requestToken) return;

      AppLogger.error('Halaman Meter Reading berikutnya gagal tak terduga', e, stack);
      emit(state.copyWith(
        loadingMore: false,
        loadMoreError: 'An unexpected error occurred. Please try again.',
      ));
    }
  }

  /// Menambahkan [incoming] ke [existing] tanpa duplikat id.
  ///
  /// Paginasi offset bisa "bergeser" bila data di server berubah di antara
  /// dua permintaan halaman — mis. petugas lain baru mencatat sebuah meter
  /// sementara daftar disaring "Belum dicatat". Tanpa dedup, meter yang sama
  /// bisa tampil dua kali.
  List<MeterReadingSummary> _appendWithoutDuplicates(
    List<MeterReadingSummary> existing,
    List<MeterReadingSummary> incoming,
  ) {
    final seenIds = existing.map((item) => item.id).toSet();
    final newOnly = incoming.where((item) => seenIds.add(item.id));
    return [...existing, ...newOnly];
  }
}
