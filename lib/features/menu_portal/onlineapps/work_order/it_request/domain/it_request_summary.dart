import '../../../../../../core/utils/json_value.dart';

/// Ringkasan dari `summary` di amplop daftar.
///
/// [awaitingRating] dihitung server atas SELURUH request milik user (bukan
/// cuma halaman yang termuat) — satu-satunya sumber kebenaran untuk
/// mengunci tombol "+ Add Request" sampai user menilai request yang sudah
/// selesai dikerjakan.
class ItRequestSummary {
  const ItRequestSummary({required this.awaitingRating});

  final int awaitingRating;

  factory ItRequestSummary.fromJson(Map<String, dynamic> json) {
    return ItRequestSummary(awaitingRating: intOr(json['awaiting_rating'], 0));
  }
}
