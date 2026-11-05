import '../../domain/observation_filter.dart';
import '../../domain/observation_item.dart';

enum ObservationListStatus { initial, loading, success, failure }

/// Penanda "tidak diisi" untuk [ObservationListState.copyWith], supaya
/// `errorMessage: null` berarti "hapus pesan galat" — pola sama dengan
/// `IndentRequestListState`.
const _unset = Object();

/// Keadaan layar Observation: dua daftar dari server (milik dept sendiri
/// yang masih open, dan semua observasi) plus pencarian & filter lokal.
class ObservationListState {
  const ObservationListState({
    this.status = ObservationListStatus.initial,
    this.myOpen = const [],
    this.all = const [],
    this.query = '',
    this.filter = ObservationFilter.none,
    this.errorMessage,
  });

  final ObservationListStatus status;

  /// Tab "My Dept Open".
  final List<ObservationItem> myOpen;

  /// Tab "All Observations" (belum disaring).
  final List<ObservationItem> all;

  final String query;
  final ObservationFilter filter;
  final String? errorMessage;

  /// Muat pertama kali: belum ada yang bisa ditampilkan, jadi layar
  /// menampilkan skeleton. Saat refresh, daftar lama tetap tampil.
  bool get isFirstLoad =>
      status == ObservationListStatus.loading && all.isEmpty && myOpen.isEmpty;

  /// Pencarian berlaku di kedua tab; filter hanya di "All Observations"
  /// (sama dengan web).
  List<ObservationItem> get visibleMyOpen => _search(myOpen);
  List<ObservationItem> get visibleAll =>
      _search(all).where(filter.matches).toList();

  /// Bulan-bulan yang ada di data (terbaru dulu) untuk pilihan filter Month.
  List<DateTime> get monthOptions {
    final months = {
      for (final i in all) DateTime(i.createdDate.year, i.createdDate.month),
    }.toList()
      ..sort((a, b) => b.compareTo(a));
    return months;
  }

  /// Departemen tujuan yang ada di data (urut abjad) untuk pilihan filter
  /// Relevant Dept. — diambil dari data server, bukan daftar hardcode.
  List<String> get departmentOptions {
    final depts = {
      for (final i in all)
        if (i.relevantDept != '-') i.relevantDept,
    }.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return depts;
  }

  List<ObservationItem> _search(List<ObservationItem> source) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return source;
    return source.where((i) {
      return i.location.toLowerCase().contains(q) ||
          i.description.toLowerCase().contains(q) ||
          i.reporter.toLowerCase().contains(q) ||
          i.categoryLabel.toLowerCase().contains(q) ||
          i.relevantDept.toLowerCase().contains(q);
    }).toList();
  }

  ObservationListState copyWith({
    ObservationListStatus? status,
    List<ObservationItem>? myOpen,
    List<ObservationItem>? all,
    String? query,
    ObservationFilter? filter,
    Object? errorMessage = _unset,
  }) {
    return ObservationListState(
      status: status ?? this.status,
      myOpen: myOpen ?? this.myOpen,
      all: all ?? this.all,
      query: query ?? this.query,
      filter: filter ?? this.filter,
      errorMessage:
          errorMessage == _unset ? this.errorMessage : errorMessage as String?,
    );
  }
}
