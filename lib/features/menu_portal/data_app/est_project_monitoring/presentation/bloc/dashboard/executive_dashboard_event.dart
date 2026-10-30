sealed class ExecutiveDashboardEvent {
  const ExecutiveDashboardEvent();
}

class LoadExecutiveDashboard extends ExecutiveDashboardEvent {
  const LoadExecutiveDashboard();
}

class OpenExecutiveSession extends ExecutiveDashboardEvent {
  const OpenExecutiveSession(this.projectId);

  final int projectId;
}

class CloseExecutiveSession extends ExecutiveDashboardEvent {
  const CloseExecutiveSession(
    this.projectId,
    this.description, {
    this.autoClockOut = false,
    this.photoPaths = const [],
  });

  final int projectId;
  final String description;
  final bool autoClockOut;

  /// Path berkas foto di perangkat; kosong = tanpa foto.
  final List<String> photoPaths;
}
