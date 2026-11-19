import '../../../domain/meter_reading.dart';

/// Hal-hal yang bisa terjadi pada layar detail Meter Reading.
sealed class MeterReadingDetailEvent {
  const MeterReadingDetailEvent();
}

/// Minta rincian meter ber-id [id]. Dipakai juga oleh tombol "Coba lagi".
class MeterReadingDetailRequested extends MeterReadingDetailEvent {
  const MeterReadingDetailRequested(this.id);

  final int id;
}

/// Petugas berhasil mencatat pembacaan lewat form Record New Data.
///
/// Form sudah memanggil `MeterReadingRepository.record` sendiri (satu aksi
/// sekali-jalan yang terikat ke satu layar — pola sama dengan
/// `AddItRequestScreen`), jadi [detail] di sini rincian TERBARU dari server.
/// Layar detail cukup menggambarnya ulang, tanpa fetch ulang.
class MeterReadingDetailUpdated extends MeterReadingDetailEvent {
  const MeterReadingDetailUpdated(this.detail);

  final MeterReading detail;
}
