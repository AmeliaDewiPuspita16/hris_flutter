/// pilihan durasi pada form Ajukan (Izin & Lembur)
enum DurationType { full, half, hourly }

extension DurationTypeX on DurationType {
  String get label {
    switch (this) {
      case DurationType.full:
        return 'Seharian';

      case DurationType.half:
        return 'Setengah Hari';

      case DurationType.hourly:
        return 'Per Jam';
    }
  }
}
