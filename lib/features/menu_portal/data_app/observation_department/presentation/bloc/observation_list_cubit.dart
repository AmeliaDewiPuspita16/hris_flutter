import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/logging/app_logger.dart';
import '../../../../../../core/network/api_exception.dart';
import '../../data/observation_repository.dart';
import '../../domain/observation_filter.dart';
import '../../domain/observation_page.dart';
import 'observation_list_state.dart';

/// Memuat dua daftar Observation (To Close dan All Observations), masing-
/// masing per halaman dari server. Pencarian dan filter dikirim ke server;
/// halaman berikutnya dimuat saat daftar digulir ([loadMoreMyOpen],
/// [loadMoreAll]). [load] dipanggil ulang setelah Add / Edit / Delete / Close.
class ObservationListCubit extends Cubit<ObservationListState> {
  ObservationListCubit({required ObservationRepository repository})
      : _repository = repository,
        super(const ObservationListState());

  final ObservationRepository _repository;

  /// Jeda sejak ketukan terakhir sebelum pencarian dikirim ke server.
  static const _searchDebounce = Duration(milliseconds: 400);

  Timer? _debounce;

  /// Satu penanda per tab. Permintaan yang tumpang tindih (refresh dua kali,
  /// ganti filter saat masih memuat) bisa membalas dengan urutan terbalik;
  /// hasil yang bukan permintaan terakhir dibuang.
  int _myOpenToken = 0;
  int _allToken = 0;

  void _emit(ObservationListState next) {
    if (!isClosed) emit(next);
  }

  void _setTab({required bool all, required ObservationTabData tab}) =>
      _emit(all ? state.copyWith(all: tab) : state.copyWith(myOpen: tab));

  /// Memuat ulang halaman pertama kedua tab (daftar lama tetap tampil selama
  /// memuat). [ensureId]: id temuan dari notifikasi; bila tidak ikut di
  /// halaman pertama, diambil terpisah lalu ditaruh di atas.
  Future<void> load({String? ensureId}) async {
    unawaited(_loadDepartments());
    await Future.wait([_reloadMyOpen(), _reloadAll()]);
    if (ensureId != null) await _ensurePresent(ensureId);
  }

  void setQuery(String query) {
    final changed = query.trim() != state.query.trim();
    _emit(state.copyWith(query: query));
    if (!changed) return;

    _debounce?.cancel();
    _debounce = Timer(_searchDebounce, () {
      _reloadMyOpen(clear: true);
      _reloadAll(clear: true);
    });
  }

  void setFilter(ObservationFilter filter) {
    _emit(state.copyWith(filter: filter));
    _reloadAll(clear: true);
  }

  Future<void> loadMoreMyOpen() => _loadMore(all: false);
  Future<void> loadMoreAll() => _loadMore(all: true);

  // ---------------------------------------------------------------------------

  /// [clear] = buang daftar lama dulu (skeleton tampil), dipakai saat
  /// pencarian/filter berganti supaya hasil lama tidak terlihat seolah cocok.
  Future<void> _reloadMyOpen({bool clear = false}) async {
    final token = ++_myOpenToken;
    final base = clear ? const ObservationTabData() : state.myOpen;
    _setTab(
      all: false,
      tab: base.copyWith(loading: true, loadingMore: false, error: null),
    );

    try {
      final page = await _repository.fetchOpenFromMyDept(search: state.query);
      if (token != _myOpenToken) return;
      _emit(state.copyWith(
        myOpen: ObservationTabData.fromPage(page),
        // Badge hanya mengikuti total tanpa pencarian.
        waitingCount: state.searchingMyOpen ? null : page.meta.total,
      ));
    } catch (e, stack) {
      if (token != _myOpenToken) return;
      _setTab(
        all: false,
        tab: state.myOpen.copyWith(
          loading: false,
          error: _describe(e, stack, 'To Close'),
        ),
      );
    }
  }

  Future<void> _reloadAll({bool clear = false}) async {
    final token = ++_allToken;
    final base = clear ? const ObservationTabData() : state.all;
    _setTab(
      all: true,
      tab: base.copyWith(loading: true, loadingMore: false, error: null),
    );

    try {
      final page = await _fetchAllPage(1);
      if (token != _allToken) return;
      _setTab(all: true, tab: ObservationTabData.fromPage(page));
    } catch (e, stack) {
      if (token != _allToken) return;
      _setTab(
        all: true,
        tab: state.all.copyWith(
          loading: false,
          error: _describe(e, stack, 'All Observations'),
        ),
      );
    }
  }

  Future<ObservationPage> _fetchAllPage(int page) {
    final filter = state.filter;
    return _repository.fetchAll(
      page: page,
      search: state.query,
      month: filter.month,
      idDept: filter.idDept,
      category: filter.category?.label,
    );
  }

  /// Halaman berikutnya untuk satu tab. Diabaikan bila masih memuat, sudah
  /// habis, atau sedang galat (galat dicoba lagi lewat tombol "retry").
  Future<void> _loadMore({required bool all}) async {
    final tab = all ? state.all : state.myOpen;
    if (tab.loading || tab.loadingMore || !tab.hasMore) return;

    final token = all ? _allToken : _myOpenToken;
    bool stale() => token != (all ? _allToken : _myOpenToken);

    _setTab(all: all, tab: tab.copyWith(loadingMore: true, error: null));

    try {
      final next = tab.meta.currentPage + 1;
      final page = all
          ? await _fetchAllPage(next)
          : await _repository.fetchOpenFromMyDept(page: next, search: state.query);
      if (stale()) return;

      final current = all ? state.all : state.myOpen;
      final known = {for (final i in current.items) i.id};
      _setTab(
        all: all,
        tab: current.copyWith(
          // Dibuang bila sudah ada (mis. temuan dari notifikasi yang
          // ditaruh di atas, atau data bergeser antar-halaman).
          items: [
            ...current.items,
            ...page.items.where((i) => !known.contains(i.id)),
          ],
          meta: page.meta,
          loadingMore: false,
        ),
      );
    } catch (e, stack) {
      if (stale()) return;
      final current = all ? state.all : state.myOpen;
      _setTab(
        all: all,
        tab: current.copyWith(
          loadingMore: false,
          error: _describe(e, stack, all ? 'All Observations' : 'To Close'),
        ),
      );
    }
  }

  /// Daftar departemen untuk filter, sekali saja. Gagal tidak menghalangi
  /// daftar: dropdown departemen saja yang kosong.
  Future<void> _loadDepartments() async {
    if (state.departments.isNotEmpty) return;
    try {
      final options = await _repository.fetchOptions();
      _emit(state.copyWith(departments: options.departments));
    } catch (e) {
      AppLogger.info('Pilihan departemen observation gagal dimuat: $e');
    }
  }

  /// Temuan dari notifikasi mungkin tidak ada di halaman pertama. Ambil
  /// detailnya dan taruh di atas daftar yang relevan; gagal (mis. 404)
  /// diabaikan, layar tetap terbuka seperti biasa.
  Future<void> _ensurePresent(String id) async {
    bool has(ObservationTabData tab) => tab.items.any((i) => i.id == id);
    if (has(state.myOpen) || has(state.all)) return;

    try {
      final item = await _repository.fetchDetail(id);
      final inMyOpen = item.isOpen && (item.isMine || item.isFromMyDept);
      _emit(state.copyWith(
        all: state.all.withPinned(item),
        myOpen: inMyOpen ? state.myOpen.withPinned(item) : state.myOpen,
      ));
    } catch (e) {
      AppLogger.info('Temuan $id dari notifikasi tidak bisa dimuat: $e');
    }
  }

  String _describe(Object e, StackTrace stack, String what) {
    if (e is ApiException) {
      AppLogger.info('Observation ($what) gagal dimuat: ${e.kind.name} — ${e.message}');
      return e.message;
    }
    AppLogger.error('Observation ($what) gagal karena galat tak terduga', e, stack);
    return 'An unexpected error occurred. Please try again.';
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
