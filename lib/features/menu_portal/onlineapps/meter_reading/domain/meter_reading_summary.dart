import 'meter_approval_status.dart';
import 'meter_period.dart';
import 'meter_reading_state.dart';
import 'meter_record_action.dart';
import 'meter_type.dart';

/// Satu baris di daftar Meter Reading = satu record = SATU meter pada satu
/// periode. Lokasi yang punya listrik dan air muncul sebagai dua record.
///
/// `id` berubah setiap kali dibuat bacaan baru untuk periode berikutnya.
class MeterReadingSummary {
  const MeterReadingSummary({
    required this.id,
    required this.company,
    required this.location,
    required this.type,
    required this.serialNumber,
    required this.period,
    required this.recordedInActivePeriod,
    required this.approval,
    required this.action,
    this.categoryLabel,
    this.previousValue,
    this.currentValue,
    this.lastValue,
    this.notes,
    this.imageProofUrl,
    this.recordedBy,
    this.recordedAt,
  });

  final int id;

  /// Ex: "PT CONTOH JAYA".
  final String company;

  /// Ex: "Block A-12".
  final String location;

  final MeterType type;

  /// Nomor seri meter, ex: "KWH-001". Pembeda dua record di lokasi yang sama.
  final String serialNumber;

  final MeterPeriod period;

  /// True bila record ini sudah berisi bacaan di periode AKTIF.
  final bool recordedInActivePeriod;

  /// Nasib bacaan setelah dicatat: pending / approved / rejected.
  final MeterApprovalStatus approval;

  /// Aksi yang boleh dilakukan user — sumber kebenaran untuk tombol.
  final MeterRecordAction action;

  /// Kategori lokasi dari server. null bisa server tidak mengirimnya
  final String? categoryLabel;

  /// Angka sebelumnya.
  final num? previousValue;

  /// Angka periode ini. Null bila belum dicatat.
  final num? currentValue;

  /// Angka terakhir yang tercatat. Ini yang jadi fokus kartu.
  final num? lastValue;

  final String? notes;
  final String? imageProofUrl;

  /// Nama pencatat (`recorded_by.name`) dan waktunya. Null selama belum dicatat.
  final String? recordedBy;
  final DateTime? recordedAt;

  /// Sudah / belum dicatat di periode aktif — dipakai badge dan chip filter.
  MeterReadingState get state => recordedInActivePeriod
      ? MeterReadingState.recorded
      : MeterReadingState.pending;

  /// Pemakaian periode ini: selisih mentah [currentValue] - [previousValue].
  /// Belum dikalikan `multiplier` karena fungsinya belum dikonfirmasi backend.
  num? get consumption {
    final current = currentValue;
    final previous = previousValue;
    return current == null || previous == null ? null : current - previous;
  }

  /// Dipertahankan sementara supaya widget lama tetap kompilasi; widget
  /// baru memakai [action] langsung.
  bool get canRecord => action.isAvailable;

  /// Foto bukti sebagai daftar, untuk `MeterPhotoGrid`.
  List<String> get photoUrls =>
      imageProofUrl == null ? const [] : [imageProofUrl!];
}
