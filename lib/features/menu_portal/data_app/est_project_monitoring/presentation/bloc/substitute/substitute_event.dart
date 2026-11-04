sealed class SubstituteEvent {
  const SubstituteEvent();
}

class AssignSubstitute extends SubstituteEvent {
  const AssignSubstitute({
    required this.projectId,
    required this.role,
    required this.substituteFor,
    required this.replacementId,
    this.reason,
  });

  final int projectId;

  /// 'mandor' | 'worker'.
  final String role;

  /// user_id (mandor) atau worker_id (worker) yang digantikan.
  final int substituteFor;

  /// user_id (mandor) atau worker_id (worker) pengganti.
  final int replacementId;
  final String? reason;
}

class EndSubstitute extends SubstituteEvent {
  const EndSubstitute({required this.projectId, required this.assignmentId});

  final int projectId;
  final int assignmentId;
}
