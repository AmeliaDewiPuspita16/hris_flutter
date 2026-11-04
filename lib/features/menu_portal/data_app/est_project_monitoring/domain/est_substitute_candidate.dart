/// Kandidat pengganti di sheet substitusi. Dibaca longgar seperti DW: id dari
/// `id`, `user_id`, atau `worker_id`; nama jatuh ke '-' bila kosong.
class EstSubstituteCandidate {
  final int id;
  final String name;

  const EstSubstituteCandidate({required this.id, required this.name});

  factory EstSubstituteCandidate.fromJson(Map<String, dynamic> json) =>
      EstSubstituteCandidate(
        id: (json['id'] ?? json['user_id'] ?? json['worker_id']) as int,
        name: json['name'] as String? ?? '-',
      );
}
