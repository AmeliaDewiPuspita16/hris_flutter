/// Worker dari `GET /api/est/resources/workers/available` (bottom sheet
/// tambah worker di detail project).
class EstAvailableWorker {
  final int id;
  final String name;
  final String nik;
  final String skills;
  final String? placement;

  const EstAvailableWorker({
    required this.id,
    required this.name,
    required this.nik,
    required this.skills,
    this.placement,
  });

  factory EstAvailableWorker.fromJson(Map<String, dynamic> json) =>
      EstAvailableWorker(
        id: json['id'] as int,
        name: json['name'] as String? ?? '-',
        nik: json['nik'] as String? ?? '-',
        skills: json['skills'] as String? ?? '-',
        placement: json['placement'] as String?,
      );
}
