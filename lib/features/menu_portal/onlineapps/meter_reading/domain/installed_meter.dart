import 'meter_type.dart';

/// Satu meter terpasang pada sebuah kontrak/lokasi.
class InstalledMeter {
  const InstalledMeter({
    required this.id,
    required this.serialNumber,
    required this.type,
    this.previousValue,
    this.lastValue,
    this.remark,
    this.photoUrl,
  });

  final int id;

  /// ex: "5388970" = tampil sebagai "S/N" di form.
  final String serialNumber;

  final MeterType type;

  /// Angka sebelum [lastValue]. Null bila meter baru dicatat sekali.
  final num? previousValue;

  /// Angka terakhir yang tercatat. Null bila belum pernah dicatat
  final num? lastValue;

  /// Catatan bebas petugas, ex: "MSB-1".
  final String? remark;

  final String? photoUrl;

  /// Pemakaian periode ini ([lastValue] - [previousValue]); null bila salah
  /// satunya belum ada.
  num? get consumption {
    final last = lastValue;
    final previous = previousValue;
    return last == null || previous == null ? null : last - previous;
  }

  /// "Previous value" di form Record New Data: angka terakhir yang tercatat
  /// menjadi pembanding bagi pembacaan berikutnya.
  num? get baselineForNextReading => lastValue;

  InstalledMeter copyWith({
    num? previousValue,
    num? lastValue,
    String? remark,
    String? photoUrl,
  }) {
    return InstalledMeter(
      id: id,
      serialNumber: serialNumber,
      type: type,
      previousValue: previousValue ?? this.previousValue,
      lastValue: lastValue ?? this.lastValue,
      remark: remark ?? this.remark,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
