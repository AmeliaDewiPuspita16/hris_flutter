import '../../../../../core/logging/app_logger.dart';
import '../../../../../core/network/api_config.dart';
import '../../../../../core/network/page_meta.dart';
import '../domain/meter_approval_status.dart';
import '../domain/meter_period.dart';
import '../domain/meter_reading.dart';
import '../domain/meter_reading_page.dart';
import '../domain/meter_reading_summary.dart';
import '../domain/meter_record_action.dart';
import '../domain/meter_type.dart';

/// Parsing JSON Meter Reading -> model domain. Sengaja fungsi biasa di
/// lapisan data (bukan `fromJson` di model) supaya domain tetap murni.
///
/// Toleran terhadap bentuk angka: kolom desimal Laravel sering datang sebagai
/// string ("12450.00"), bukan angka.

final _unknownPeriod = MeterPeriod(
  label: '—',
  start: DateTime.fromMillisecondsSinceEpoch(0),
  end: DateTime.fromMillisecondsSinceEpoch(0),
);

num? _num(Object? v) {
  if (v is num) return v;
  if (v is String) return num.tryParse(v.trim());
  return null;
}

int? _int(Object? v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v.trim());
  return null;
}

String? _str(Object? v) {
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}

DateTime? _date(Object? v) => v is String ? DateTime.tryParse(v) : null;

bool _bool(Object? v) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) return v == '1' || v.toLowerCase() == 'true';
  return false;
}

Map<String, dynamic>? _map(Object? v) => v is Map<String, dynamic> ? v : null;

List<String> _stringList(Object? v) {
  if (v is! List) return const [];
  final result = <String>[];
  for (final element in v) {
    final text = _str(element);
    if (text != null) result.add(text);
  }
  return result;
}

/// Foto dari server bisa berupa URL penuh atau path relatif (`/storage/...`).
/// `MeterPhotoGrid` hanya memuat alamat berawalan `http` dari jaringan.
String? _absoluteUrl(String? url) {
  if (url == null) return null;
  if (url.startsWith('http')) return url;
  return '${ApiConfig.baseUrl}${url.startsWith('/') ? '' : '/'}$url';
}

MeterPeriod? _periodFrom(Map<String, dynamic>? json) {
  if (json == null) return null;
  final start = _date(json['start_date']);
  final end = _date(json['end_date']);
  final label = _str(json['label']);
  if (label == null && start == null && end == null) return null;

  return MeterPeriod(
    id: _int(json['id']),
    label: label ?? '—',
    start: start ?? DateTime.fromMillisecondsSinceEpoch(0),
    end: end ?? DateTime.fromMillisecondsSinceEpoch(0),
    isActive: _str(json['status']) == 'active',
  );
}

/// Satu record dari daftar, atau `data` pada detail / respons POST.
///
/// Melempar [FormatException] bila record tidak punya `id`.
MeterReadingSummary meterSummaryFromJson(Map<String, dynamic> json) {
  final id = _int(json['id']);
  if (id == null) {
    throw const FormatException('Record Meter Reading tanpa id.');
  }

  return MeterReadingSummary(
    id: id,
    company: _str(json['company']) ?? '—',
    location: _str(json['location']) ?? '—',
    type: MeterType.fromCode(_str(json['type'])),
    serialNumber: _str(json['serial_number']) ?? '—',
    period: _periodFrom(_map(json['period'])) ?? _unknownPeriod,
    recordedInActivePeriod: _bool(json['recorded_in_active_period']),
    approval: MeterApprovalStatus.fromCode(_str(json['status'])),
    action: MeterRecordAction.fromCode(_str(json['action'])),
    categoryLabel: _str(json['category']),
    previousValue: _num(json['previous_value']),
    currentValue: _num(json['current_value']),
    lastValue: _num(json['last_value']),
    notes: _str(json['notes']),
    imageProofUrl: _absoluteUrl(_str(json['image_proof_url'])),
    recordedBy: _str(_map(json['recorded_by'])?['name']),
    recordedAt: _date(json['recorded_at']),
  );
}

/// Amplop `GET /records/{id}`: `data` + `active_period` + `can_write`.
///
/// Melempar [FormatException] bila `data` bukan objek atau tanpa `id`.
MeterReading meterDetailFromEnvelope(Map<String, dynamic> envelope) {
  final data = _map(envelope['data']);
  if (data == null) {
    throw const FormatException('Detail Meter Reading: data bukan objek.');
  }

  final s = meterSummaryFromJson(data);
  return MeterReading(
    id: s.id,
    company: s.company,
    location: s.location,
    type: s.type,
    serialNumber: s.serialNumber,
    period: s.period,
    recordedInActivePeriod: s.recordedInActivePeriod,
    approval: s.approval,
    action: s.action,
    previousValue: s.previousValue,
    currentValue: s.currentValue,
    lastValue: s.lastValue,
    notes: s.notes,
    imageProofUrl: s.imageProofUrl,
    recordedBy: s.recordedBy,
    recordedAt: s.recordedAt,
    categoryLabel: s.categoryLabel,
    meterTypeLabel: _str(data['meter_type']),
    buildingType: _str(data['building_type']),
    typeWater: _str(data['type_water']),
    multiplier: _num(data['multiplier']),
    meterDigits: _int(data['meter_digits']),
    nextPreviousValue: _num(data['next_previous_value']),
    meterRecordedInActivePeriod: _bool(data['meter_recorded_in_active_period']),
    activePeriod: _periodFrom(_map(envelope['active_period'])),
    canWrite: _bool(envelope['can_write']),
  );
}

MeterReadingCounts _countsFrom(Map<String, dynamic>? summary) {
  if (summary == null) {
    return const MeterReadingCounts(all: 0, recorded: 0, pending: 0);
  }
  final recorded = _int(summary['recorded']) ?? 0;
  final pending = _int(summary['not_recorded']) ?? 0;
  return MeterReadingCounts(
    all: _int(summary['total']) ?? recorded + pending,
    recorded: recorded,
    pending: pending,
  );
}

/// Amplop `GET /records`: `data` (list), `summary`, `categories`, `meta`, `active_period`,
/// `can_write`. Baris yang rusak dilewati; satu baris jelek tidak boleh
/// menggagalkan seluruh daftar.
///
/// Melempar [FormatException] bila `data` bukan list.
MeterReadingPage meterPageFromEnvelope(
  Map<String, dynamic> envelope, {
  required int page,
  required int perPage,
}) {
  final rows = envelope['data'];
  if (rows is! List) {
    throw const FormatException('Daftar Meter Reading: data bukan list.');
  }

  final items = <MeterReadingSummary>[];
  for (final row in rows) {
    if (row is! Map<String, dynamic>) continue;
    try {
      items.add(meterSummaryFromJson(row));
    } on FormatException catch (e) {
      AppLogger.info('Baris Meter Reading dilewati: ${e.message}');
    }
  }

  final meta = _map(envelope['meta']);
  return MeterReadingPage(
    items: items,
    counts: _countsFrom(_map(envelope['summary'])),
    categories: _stringList(envelope['categories']),
    meta: meta != null
        ? PageMeta.fromJson(meta)
        : PageMeta(
            currentPage: page,
            lastPage: page,
            perPage: perPage,
            total: items.length,
          ),
    activePeriod: _periodFrom(_map(envelope['active_period'])),
    canWrite: _bool(envelope['can_write']),
  );
}
