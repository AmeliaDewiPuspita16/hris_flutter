import '../../../domain/executive_dashboard.dart';

sealed class ExecutiveDashboardState {
  const ExecutiveDashboardState();
}

class ExecutiveDashboardInitial extends ExecutiveDashboardState {
  const ExecutiveDashboardInitial();
}

class ExecutiveDashboardLoading extends ExecutiveDashboardState {
  const ExecutiveDashboardLoading();
}

class ExecutiveDashboardLoaded extends ExecutiveDashboardState {
  const ExecutiveDashboardLoaded(this.data);

  final ExecutiveDashboardModel data;
}

class ExecutiveDashboardError extends ExecutiveDashboardState {
  const ExecutiveDashboardError(this.message);

  final String message;
}

/// Akun tidak berhak atas EST Project Monitoring (API membalas 401/403).
class ExecutiveDashboardNoAccess extends ExecutiveDashboardState {
  const ExecutiveDashboardNoAccess();
}

/// Dipancarkan selama panggilan buka/tutup sesi berjalan.
class ExecutiveSessionLoading extends ExecutiveDashboardState {
  const ExecutiveSessionLoading(this.currentData);

  final ExecutiveDashboardModel currentData;
}

/// Dipancarkan saat buka/tutup sesi berhasil.
class ExecutiveSessionSuccess extends ExecutiveDashboardState {
  const ExecutiveSessionSuccess(this.message);

  final String message;
}

/// Dipancarkan saat buka/tutup sesi gagal.
class ExecutiveSessionError extends ExecutiveDashboardState {
  const ExecutiveSessionError(this.message, this.currentData);

  final String message;
  final ExecutiveDashboardModel currentData;
}
