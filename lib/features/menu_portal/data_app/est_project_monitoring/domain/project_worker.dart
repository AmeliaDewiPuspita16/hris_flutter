class ProjectWorkerModel {
  final int workerId;
  final String name;
  final String? nik;
  final String? photo;
  final String? clockIn;
  final String? clockOut;
  final bool isClockedIn;
  final double hoursToday;
  final int attendanceCondition;
  final bool isSubstitute;
  final String? substituteForName; // nama worker asli yang digantikan
  final int? assignmentId; // untuk DELETE endSubstitute

  const ProjectWorkerModel({
    required this.workerId,
    required this.name,
    this.nik,
    this.photo,
    this.clockIn,
    this.clockOut,
    required this.isClockedIn,
    required this.hoursToday,
    required this.attendanceCondition,
    this.isSubstitute = false,
    this.substituteForName,
    this.assignmentId,
  });

  factory ProjectWorkerModel.fromJson(Map<String, dynamic> json) {
    final subFor = json['substitute_for'] as Map<String, dynamic>?;
    return ProjectWorkerModel(
      workerId: json['worker_id'] as int,
      name: json['name'] as String? ?? '-',
      nik: json['nik'] as String?,
      photo: json['photo'] as String?,
      clockIn: json['clock_in'] as String?,
      clockOut: json['clock_out'] as String?,
      isClockedIn: json['is_clocked_in'] as bool? ?? false,
      hoursToday: (json['hours_today'] as num?)?.toDouble() ?? 0.0,
      attendanceCondition: json['attendance_condition'] as int? ?? 1,
      isSubstitute: json['is_substitute'] as bool? ?? false,
      substituteForName: subFor?['name'] as String?,
      assignmentId: json['assignment_id'] as int?,
    );
  }

  String get initials {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts.isNotEmpty ? parts[0][0].toUpperCase() : '?';
  }
}
