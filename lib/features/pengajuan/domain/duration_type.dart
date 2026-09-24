/// pilihan durasi pada form Ajukan (Izin & Lembur)
enum DurationType { full, half }

extension DurationTypeX on DurationType {
  String get label {
    switch (this) {
      case DurationType.full:
        return 'Full Day';

      case DurationType.half:
        return 'Half Day';
    }
  }
}
