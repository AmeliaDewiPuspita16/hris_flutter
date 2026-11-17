import 'installed_meter.dart';
import 'meter_period.dart';
import 'meter_reading_state.dart';
import 'meter_reading_summary.dart';

/// Satu kontrak/lokasi lengkap beserta meter-meternya — isi layar detail
/// dan form Record New Data.
///
/// Mewarisi [MeterReadingSummary] supaya layar detail bisa menggambar kepala
/// halaman dari baris daftar sambil menunggu rinciannya. Pola sama dengan
/// `PurchaseRequisition` dan `ItRequestDetail`.
class MeterReading extends MeterReadingSummary {
  const MeterReading({
    required super.id,
    required super.location,
    required super.company,
    required super.category,
    required super.type,
    required super.period,
    required super.state,
    super.lastValue,
    super.canRecord,
    required this.contractNumber,
    this.tenantRepresentative,
    this.recordedBy,
    this.recordedAt,
    this.biieRepresentative,
    this.meters = const [],
  });

  /// Ex: "EST-02-003/RF-I-0". Tampil di subjudul form.
  final String contractNumber;

  final String? tenantRepresentative;

  /// Siapa dan kapan pembacaan terakhir dicatat.
  final String? recordedBy;
  final DateTime? recordedAt;

  /// Ex: "Ari Putra".
  final String? biieRepresentative;

  final List<InstalledMeter> meters;

  /// Foto yang terlampir pada meter-meternya, untuk bagian "Uploaded Photo".
  List<String> get photoUrls => [
        for (final meter in meters)
          if (meter.photoUrl != null) meter.photoUrl!,
      ];

  /// Pemakaian periode ini: jumlah pemakaian meter yang jenisnya sama dengan
  /// [type] (kWh tidak dijumlah dengan m³). Null bila belum bisa dihitung.
  num? get totalConsumption {
    final values = [
      for (final meter in meters)
        if (meter.type == type && meter.consumption != null) meter.consumption!,
    ];
    return values.isEmpty ? null : values.fold<num>(0, (a, b) => a + b);
  }

  /// Versi ringkas, persis seperti yang dikirim endpoint daftar.
  MeterReadingSummary toSummary() => MeterReadingSummary(
        id: id,
        location: location,
        company: company,
        category: category,
        type: type,
        lastValue: lastValue,
        period: period,
        state: state,
        canRecord: canRecord,
      );

  MeterReading copyWith({
    MeterReadingState? state,
    bool? canRecord,
    MeterPeriod? period,
    num? lastValue,
    String? recordedBy,
    DateTime? recordedAt,
    List<InstalledMeter>? meters,
  }) {
    return MeterReading(
      id: id,
      location: location,
      company: company,
      category: category,
      type: type,
      period: period ?? this.period,
      state: state ?? this.state,
      lastValue: lastValue ?? this.lastValue,
      canRecord: canRecord ?? this.canRecord,
      contractNumber: contractNumber,
      tenantRepresentative: tenantRepresentative,
      recordedBy: recordedBy ?? this.recordedBy,
      recordedAt: recordedAt ?? this.recordedAt,
      biieRepresentative: biieRepresentative,
      meters: meters ?? this.meters,
    );
  }
}
