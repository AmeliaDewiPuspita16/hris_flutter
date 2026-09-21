import '../../../../../../core/utils/json_value.dart';

/// Progres pengerjaan tim IT, dari `handling` di respons detail.
class ItRequestHandling {
  const ItRequestHandling({
    this.workBy,
    this.note,
    this.dateStart,
    this.dateEnd,
    this.dateDone,
    this.resultImageUrl,
  });

  /// Nama staff IT yang mengerjakan.
  final String? workBy;

  final String? note;
  final DateTime? dateStart;
  final DateTime? dateEnd;

  /// Terisi begitu pengerjaan benar-benar selesai — beda dari [dateEnd]
  /// (target/estimasi selesai).
  final DateTime? dateDone;

  final String? resultImageUrl;

  /// Null bila `handling` sendiri tidak ada di respons (request belum mulai
  /// dikerjakan) — dibedakan dari objek kosong supaya bagian "Pengerjaan"
  /// di layar detail bisa disembunyikan sepenuhnya.
  static ItRequestHandling? fromJsonOrNull(dynamic json) {
    if (json is! Map<String, dynamic>) return null;

    return ItRequestHandling(
      workBy: textOrNull(json['work_by']),
      note: textOrNull(json['note']),
      dateStart: dateOrNull(json['date_start']),
      dateEnd: dateOrNull(json['date_end']),
      dateDone: dateOrNull(json['date_done']),
      resultImageUrl: textOrNull(json['result_image_url']),
    );
  }
}
