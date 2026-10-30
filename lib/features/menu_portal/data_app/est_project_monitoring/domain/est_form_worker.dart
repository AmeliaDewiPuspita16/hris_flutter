/// Worker dari `GET /api/est/resources/workers/available` dalam bentuk
/// lengkap untuk daftar pilih di form project (parsing ketat seperti DW).
class EstFormWorker {
  final int id;
  final String name;
  final String nik;
  final String? phone;
  final String skills;
  final String? photo;
  final bool isWorker;
  final String workerType;
  final String? placement;

  /// Status centang di daftar pencarian form; berubah oleh form.
  bool isSelected;

  EstFormWorker({
    required this.id,
    required this.name,
    required this.nik,
    this.phone,
    required this.skills,
    this.photo,
    required this.isWorker,
    required this.workerType,
    this.placement,
    this.isSelected = false,
  });

  factory EstFormWorker.fromJson(Map<String, dynamic> json) => EstFormWorker(
        id: json['id'] as int,
        name: json['name'] as String,
        nik: json['nik'] as String,
        phone: json['phone'] as String?,
        skills: json['skills'] as String,
        photo: json['photo'] as String?,
        isWorker: json['is_worker'] as bool,
        workerType: json['worker_type'] as String,
        placement: json['placement'] as String?,
      );
}
