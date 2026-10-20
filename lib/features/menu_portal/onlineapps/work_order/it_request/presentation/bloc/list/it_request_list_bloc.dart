import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../../core/logging/app_logger.dart';
import '../../../../../../../../core/network/api_exception.dart';
import '../../../data/it_request_repository.dart';
import '../../../domain/it_request_item.dart';
import '../../../domain/it_request_summary.dart';
import 'it_request_list_event.dart';
import 'it_request_list_state.dart';

/// Mengurus riwayat IT/Media Request: memuat halaman, menambah halaman
/// berikutnya, dan menyisipkan hasil aksi yang sudah dieksekusi layar/sheet
/// pemanggil sendiri (tambah request, beri feedback) — bloc ini cuma
/// menyatukan hasilnya ke state, bukan yang memanggil API-nya.
class ItRequestListBloc extends Bloc<ItRequestListEvent, ItRequestListState> {
  ItRequestListBloc({
    required ItRequestRepository repository,
    this.loadAllPages = false,
  })  : _repository = repository,
        super(const ItRequestListState()) {
    on<ItRequestListStarted>(_onReload);
    on<ItRequestListRefreshed>(_onReload);
    on<ItRequestListNextPageRequested>(_onNextPage);
    on<ItRequestLocalItemAdded>(_onLocalItemAdded);
    on<ItRequestLocalItemUpdated>(_onLocalItemUpdated);
    on<ItRequestFeedbackGiven>(_onFeedbackGiven);
  }

  final ItRequestRepository _repository;

  /// True untuk `ListRequestTab`, yang menghitung counter On Waiting/On
  /// Progress dari `items` — tanpa menarik SEMUA halaman di awal, counter
  /// itu akan terus bertambah tiap kali scroll memuat halaman berikutnya
  /// (bukan total sebenarnya, cuma "sejauh yang sudah termuat"). Server
  /// tidak punya endpoint hitung/filter per status, jadi inilah satu-satunya
  /// cara mendapat angka yang akurat dan stabil.
  ///
  /// False untuk `ItFormAndMediaTab` (nilai default) — riwayat perusahaan
  /// bisa sangat panjang dan tab itu tidak butuh total apa pun, jadi tetap
  /// lazy-load per scroll seperti biasa supaya tidak boros network di awal.
  final bool loadAllPages;

  /// Sama alasannya dengan `ProcurementListBloc`: dua permintaan halaman
  /// pertama yang tumpang tindih (mis. refresh ditekan dua kali) bisa
  /// membalas dengan urutan terbalik. Hasil yang bukan permintaan terakhir
  /// dibuang.
  int _requestToken = 0;

  Future<void> _onReload(
    ItRequestListEvent event,
    Emitter<ItRequestListState> emit,
  ) async {
    final token = ++_requestToken;

    emit(state.copyWith(
      status: ItRequestListStatus.loading,
      errorMessage: null,
    ));

    try {
      final page = await _repository.fetchList(page: 1);
      if (token != _requestToken) return;

      emit(state.copyWith(
        status: ItRequestListStatus.success,
        items: page.items,
        summary: page.summary,
        meta: page.meta,
        loadingMore: false,
      ));

      await _huntForOwnAwaitingItem(token, emit);
      if (loadAllPages) await _loadRemainingPages(token, emit);
    } on ApiException catch (e) {
      if (token != _requestToken) return;

      AppLogger.info('Riwayat IT Request gagal dimuat: ${e.kind.name} — ${e.message}');
      emit(state.copyWith(
        status: ItRequestListStatus.failure,
        items: const [],
        errorMessage: e.message,
        loadingMore: false,
      ));
    } catch (e, stack) {
      if (token != _requestToken) return;

      AppLogger.error('Riwayat IT Request gagal karena galat tak terduga', e, stack);
      emit(state.copyWith(
        status: ItRequestListStatus.failure,
        items: const [],
        errorMessage: 'Terjadi kesalahan tak terduga. Coba lagi.',
        loadingMore: false,
      ));
    }
  }

  /// Daftar di tab ini berisi permintaan SELURUH perusahaan (bukan cuma
  /// milik user login), diurut terbaru dulu — sementara `summary.
  /// awaitingRating` dari server dihitung khusus dari permintaan MILIK USER
  /// SENDIRI. Kalau permintaan user yang butuh rating itu bukan yang
  /// terbaru (tertimbun permintaan user lain yang lebih baru), halaman
  /// pertama saja bisa jadi tidak memuatnya sama sekali — banner "Beri
  /// Feedback" pun tidak pernah muncul walau tombol "+ Add Request" sudah
  /// terkunci.
  ///
  /// Jadi begitu halaman pertama termuat, kalau server masih bilang ada
  /// yang menunggu rating tapi belum ada satu pun item `isMine && canRate`
  /// yang termuat, bloc ini otomatis lanjut memuat halaman-halaman
  /// berikutnya sampai ketemu atau sampai server bilang sudah halaman
  /// terakhir (`meta.hasMore` false) — supaya banner-nya benar-benar bisa
  /// muncul tanpa user harus menggulir manual entah sampai halaman keberapa.
  Future<void> _huntForOwnAwaitingItem(
    int token,
    Emitter<ItRequestListState> emit,
  ) async {
    while (state.summary.awaitingRating > 0 &&
        !_hasOwnAwaitingItem(state.items) &&
        state.meta.hasMore) {
      if (token != _requestToken) return;

      try {
        final page = await _repository.fetchList(page: state.meta.currentPage + 1);
        if (token != _requestToken) return;

        emit(state.copyWith(
          items: _appendWithoutDuplicates(state.items, page.items),
          summary: page.summary,
          meta: page.meta,
        ));
      } on ApiException catch (e) {
        // Perburuan ini cuma penyempurnaan tampilan — kegagalan di
        // tengahnya tidak boleh menimpa daftar yang sudah berhasil dimuat
        // dengan layar galat.
        AppLogger.info(
          'Perburuan halaman IT Request untuk item yang butuh rating '
          'berhenti karena galat: ${e.message}',
        );
        return;
      }
    }
  }

  bool _hasOwnAwaitingItem(List<ItRequestItem> items) =>
      items.any((item) => item.isMine && item.canRate);

  /// Menambahkan [incoming] ke [existing] tanpa duplikat id.
  ///
  /// WAJIB dipakai setiap kali menyambung hasil halaman baru — daftar ini
  /// diurut "terbaru dulu" dari data SELURUH perusahaan yang terus berubah
  /// (request baru bisa masuk kapan saja). Paginasi offset seperti ini
  /// rentan "bergeser": kalau ada request baru masuk di antara dua
  /// permintaan halaman, request yang tadinya di halaman N bisa ikut
  /// terdorong dan muncul lagi di halaman N+1 — tanpa dedup, request yang
  /// sama terhitung dua kali dan bikin counter On Waiting/On Progress
  /// membengkak jauh dari angka sebenarnya di server.
  List<ItRequestItem> _appendWithoutDuplicates(
    List<ItRequestItem> existing,
    List<ItRequestItem> incoming,
  ) {
    final seenIds = existing.map((item) => item.id).toSet();
    final newOnly = incoming.where((item) => seenIds.add(item.id));
    return [...existing, ...newOnly];
  }

  /// Menarik semua halaman tersisa sekaligus, berurutan, sampai server
  /// bilang `meta.hasMore` false — dipakai [loadAllPages]. `loadingMore`
  /// dipasang untuk seluruh proses (bukan per halaman) supaya tidak
  /// berkedip nyala-mati tiap kali satu halaman selesai.
  Future<void> _loadRemainingPages(
    int token,
    Emitter<ItRequestListState> emit,
  ) async {
    if (!state.meta.hasMore) return;

    emit(state.copyWith(loadingMore: true));

    while (state.meta.hasMore) {
      if (token != _requestToken) return;

      try {
        final page = await _repository.fetchList(page: state.meta.currentPage + 1);
        if (token != _requestToken) return;

        emit(state.copyWith(
          items: _appendWithoutDuplicates(state.items, page.items),
          summary: page.summary,
          meta: page.meta,
        ));
      } on ApiException catch (e) {
        // Sama seperti _huntForOwnAwaitingItem: kegagalan di tengah proses
        // ini tidak boleh menimpa daftar yang sudah berhasil dimuat dengan
        // layar galat — counter cukup dihitung dari sebagian yang berhasil.
        AppLogger.info(
          'Memuat seluruh halaman IT Request untuk counter berhenti karena '
          'galat: ${e.message}',
        );
        break;
      }
    }

    if (token != _requestToken) return;
    emit(state.copyWith(loadingMore: false));
  }

  Future<void> _onNextPage(
    ItRequestListNextPageRequested event,
    Emitter<ItRequestListState> emit,
  ) async {
    if (state.loadingMore || !state.meta.hasMore) return;
    if (state.status != ItRequestListStatus.success) return;

    final token = _requestToken;
    emit(state.copyWith(loadingMore: true));

    try {
      final page = await _repository.fetchList(page: state.meta.currentPage + 1);
      if (token != _requestToken) return;

      emit(state.copyWith(
        items: _appendWithoutDuplicates(state.items, page.items),
        summary: page.summary,
        meta: page.meta,
        loadingMore: false,
      ));
    } on ApiException catch (e) {
      if (token != _requestToken) return;

      AppLogger.info('Halaman IT Request berikutnya gagal: ${e.message}');
      emit(state.copyWith(loadingMore: false, errorMessage: e.message));
    }
  }

  void _onLocalItemAdded(
    ItRequestLocalItemAdded event,
    Emitter<ItRequestListState> emit,
  ) {
    emit(state.copyWith(
      items: [event.item, ...state.items],
      meta: state.meta.copyWith(total: state.meta.total + 1),
    ));
  }

  void _onLocalItemUpdated(
    ItRequestLocalItemUpdated event,
    Emitter<ItRequestListState> emit,
  ) {
    emit(state.copyWith(
      items: [
        for (final item in state.items)
          if (item.id == event.detail.id) event.detail else item,
      ],
    ));
  }

  void _onFeedbackGiven(
    ItRequestFeedbackGiven event,
    Emitter<ItRequestListState> emit,
  ) {
    emit(state.copyWith(
      items: [
        for (final item in state.items)
          if (item.id == event.detail.id) event.detail else item,
      ],
      summary: ItRequestSummary(
        awaitingRating:
            state.summary.awaitingRating > 0 ? state.summary.awaitingRating - 1 : 0,
      ),
    ));
  }
}
