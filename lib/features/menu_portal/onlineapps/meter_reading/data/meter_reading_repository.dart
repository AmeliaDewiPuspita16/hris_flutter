import '../../../../../core/logging/app_logger.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_config.dart';
import '../../../../../core/network/api_exception.dart';
import '../domain/meter_reading.dart';
import '../domain/meter_reading_input.dart';
import '../domain/meter_reading_page.dart';
import '../domain/meter_reading_state.dart';
import '../domain/meter_reading_summary.dart';
import '../domain/meter_record_action.dart';
import 'meter_reading_json.dart';

/// Meter Reading lewat API BIIE Portal. Satu record = satu meter pada satu
/// periode; `id` record berubah setiap kali dibuat bacaan baru.
///
/// Melempar [ApiException] untuk semua kegagalan (jaringan, 401/403, 422,
/// respons yang tidak bisa dipahami). Pesan 422 dari server dibiarkan apa
/// adanya.
class MeterReadingRepository {
  MeterReadingRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  /// Satu halaman daftar, lengkap dengan `summary` (angka chip), `meta`,
  /// periode aktif, dan hak tulis.
  ///
  /// [typeCode]: `kwh` / `m3` ([MeterType.code]). [stateCode]: `recorded` /
  /// `pending` ([MeterReadingState.code]), dipetakan ke `recorded=1/0`.
  /// [search] dipotong 100 karakter (batas server).
  Future<MeterReadingPage> fetchList({
    int page = 1,
    int perPage = 20,
    String? typeCode,
    String? stateCode,
    String? search,
  }) async {
    final envelope = await _api.getEnvelope(
      _listPath(
        page: page,
        perPage: perPage,
        typeCode: typeCode,
        recorded: _recordedFlag(stateCode),
        search: _cleanSearch(search),
      ),
    );

    try {
      return meterPageFromEnvelope(envelope, page: page, perPage: perPage);
    } on FormatException catch (e) {
      AppLogger.info('Daftar Meter Reading tidak bisa dibaca: ${e.message}');
      throw const ApiException.server();
    }
  }

  /// Rincian satu record, lengkap dengan `active_period` dan `can_write`.
  Future<MeterReading> fetchDetail(int id) async {
    final envelope = await _api.getEnvelope(ApiConfig.meterReadingRecord(id));
    try {
      return meterDetailFromEnvelope(envelope);
    } on FormatException catch (e) {
      AppLogger.info('Detail Meter Reading tidak bisa dibaca: ${e.message}');
      throw const ApiException.server();
    }
  }

  /// Mencatat, mengedit, atau membuat bacaan baru — endpoint dipilih dari
  /// `target.action`:
  ///
  /// - `record` / `edit`: `POST /records/{id}`
  /// - `new_reading`: `POST /records/{id}/new_reading` (id baris BARU ada di
  ///   `reading.id` hasilnya; pakai itu untuk langkah berikutnya)
  ///
  /// Respons POST tidak membawa field detail, jadi setelah sukses detail
  /// diambil ulang. Bila pengambilan ulang itu yang gagal, bacaan SUDAH
  /// tersimpan — jangan dilaporkan sebagai gagal (pengguna akan mengulang dan
  /// kena 422 "sudah dicatat"); detail dirakit dari respons POST.
  ///
  /// `notes` hanya dikirim untuk catat / edit: belum jelas apakah
  /// `new_reading` menerimanya. Pada edit, catatan kosong tetap dikirim
  /// supaya catatan lama bisa dihapus.
  Future<({MeterReading reading, String? message})> save(
    MeterReading target,
    MeterReadingInput input,
  ) async {
    final action = target.action;
    if (!target.canRecord) {
      throw const ApiException.badRequest(
        'This meter cannot be recorded right now.',
      );
    }

    final isNewReading = action == MeterRecordAction.newReading;
    final path = isNewReading
        ? ApiConfig.meterReadingNewReading(target.id)
        : ApiConfig.meterReadingRecord(target.id);

    final notes = input.notes?.trim() ?? '';
    final photoPath = input.photoPath;

    final body = await _api.postMultipartJson(
      path,
      fields: {
        'current_value': input.currentValue.toString(),
        if (!isNewReading &&
            (notes.isNotEmpty || action == MeterRecordAction.edit))
          'notes': notes,
      },
      files: {
        if (photoPath != null) 'image_proof': [photoPath],
      },
      timeout: photoPath == null ? null : ApiConfig.uploadTimeout,
    );

    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      AppLogger.info('Respons simpan Meter Reading: data bukan objek');
      throw const ApiException.server();
    }

    final MeterReadingSummary saved;
    try {
      saved = meterSummaryFromJson(data);
    } on FormatException catch (e) {
      AppLogger.info(
        'Respons simpan Meter Reading tidak bisa dibaca: ${e.message}',
      );
      throw const ApiException.server();
    }

    final message = body['message'];
    final serverMessage =
        message is String && message.isNotEmpty ? message : null;

    try {
      return (reading: await fetchDetail(saved.id), message: serverMessage);
    } on ApiException catch (e) {
      AppLogger.info('Detail setelah simpan gagal dimuat: ${e.message}');
      return (reading: _detailFromSaved(saved, target), message: serverMessage);
    }
  }

  // ---------------------------------------------------------------------------

  String _listPath({
    required int page,
    required int perPage,
    String? typeCode,
    String? recorded,
    String? search,
  }) {
    final query = <String, String>{
      'page': '$page',
      'per_page': '$perPage',
      if (typeCode != null && typeCode.isNotEmpty) 'type': typeCode,
      if (recorded != null) 'recorded': recorded,
      if (search != null && search.isNotEmpty) 'search': search,
    };
    return Uri(
      path: ApiConfig.meterReadingRecords,
      queryParameters: query,
    ).toString();
  }

  String? _recordedFlag(String? stateCode) {
    if (stateCode == MeterReadingState.recorded.code) return '1';
    if (stateCode == MeterReadingState.pending.code) return '0';
    return null;
  }

  String _cleanSearch(String? search) {
    final keyword = search?.trim() ?? '';
    return keyword.length > 100 ? keyword.substring(0, 100) : keyword;
  }

  /// Detail cadangan dari respons POST + field detail yang sudah diketahui
  /// dari [previous]. `nextPreviousValue` dikosongkan: setelah menyimpan,
  /// nilainya berubah dan hanya server yang tahu.
  MeterReading _detailFromSaved(
    MeterReadingSummary saved,
    MeterReading previous,
  ) {
    return MeterReading(
      id: saved.id,
      company: saved.company,
      location: saved.location,
      type: saved.type,
      serialNumber: saved.serialNumber,
      period: saved.period,
      recordedInActivePeriod: saved.recordedInActivePeriod,
      approval: saved.approval,
      action: saved.action,
      previousValue: saved.previousValue,
      currentValue: saved.currentValue,
      lastValue: saved.lastValue,
      notes: saved.notes,
      imageProofUrl: saved.imageProofUrl,
      recordedBy: saved.recordedBy,
      recordedAt: saved.recordedAt,
      categoryLabel: previous.categoryLabel,
      meterTypeLabel: previous.meterTypeLabel,
      buildingType: previous.buildingType,
      typeWater: previous.typeWater,
      multiplier: previous.multiplier,
      meterDigits: previous.meterDigits,
      meterRecordedInActivePeriod: saved.recordedInActivePeriod,
      activePeriod: previous.activePeriod,
      canWrite: previous.canWrite,
    );
  }
}
