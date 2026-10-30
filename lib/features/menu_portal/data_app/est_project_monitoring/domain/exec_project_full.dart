class MandorModel {
  final int id;
  final String name;
  final bool isSubstitute;
  final MandorModel? substituteFor; // orang asli yang digantikan
  final int? assignmentId; // untuk DELETE endSubstitute

  const MandorModel({
    required this.id,
    required this.name,
    this.isSubstitute = false,
    this.substituteFor,
    this.assignmentId,
  });

  factory MandorModel.fromJson(Map<String, dynamic> json) {
    final subForRaw = json['substitute_for'] as Map<String, dynamic>?;
    return MandorModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '-',
      isSubstitute: json['is_substitute'] as bool? ?? false,
      substituteFor: subForRaw != null ? MandorModel.fromJson(subForRaw) : null,
      assignmentId: json['assignment_id'] as int?,
    );
  }

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

class ExecProjectFullModel {
  final int id;
  final List<MandorModel> mandors;
  final double avgHoursPerDay;
  final int estimatedDaysLeft;
  final String? closedAt;

  const ExecProjectFullModel({
    required this.id,
    required this.mandors,
    required this.avgHoursPerDay,
    required this.estimatedDaysLeft,
    this.closedAt,
  });

  factory ExecProjectFullModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final mandorsRaw = data['mandors'] as List? ?? [];
    return ExecProjectFullModel(
      id: data['id'] as int,
      mandors: mandorsRaw
          .map((e) => MandorModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      avgHoursPerDay: (data['avg_hours_per_day'] as num?)?.toDouble() ?? 0.0,
      estimatedDaysLeft: data['estimated_days_left'] as int? ?? 0,
      closedAt: data['closed_at'] as String?,
    );
  }
}
