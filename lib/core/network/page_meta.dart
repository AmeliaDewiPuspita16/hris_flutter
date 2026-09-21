import '../utils/json_value.dart';

/// Keterangan paginasi dari `meta` — dipakai endpoint mana pun yang membalas
/// `{data, meta}` dengan bentuk `current_page`/`last_page`/`per_page`/`total`
/// (EProcurement, IT Request, dan seterusnya).
class PageMeta {
  const PageMeta({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  bool get hasMore => currentPage < lastPage;

  PageMeta copyWith({int? currentPage, int? lastPage, int? perPage, int? total}) {
    return PageMeta(
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      perPage: perPage ?? this.perPage,
      total: total ?? this.total,
    );
  }

  /// Amplop tanpa `meta` dianggap satu halaman penuh — lebih aman daripada
  /// terus meminta halaman berikutnya yang tidak ada.
  factory PageMeta.fromJson(Map<String, dynamic> json) {
    return PageMeta(
      currentPage: intOr(json['current_page'], 1),
      lastPage: intOr(json['last_page'], 1),
      perPage: intOr(json['per_page'], 20),
      total: intOr(json['total'], 0),
    );
  }
}
