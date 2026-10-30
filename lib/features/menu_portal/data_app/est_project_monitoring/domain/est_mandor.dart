/// Mandor dari `GET /api/est/resources/mandors` (dipakai form project).
class EstMandor {
  final int id;
  final String name;
  final String email;
  final String? phone;

  const EstMandor({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
  });

  factory EstMandor.fromJson(Map<String, dynamic> json) => EstMandor(
        id: json['id'] as int,
        name: json['name'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String?,
      );
}
