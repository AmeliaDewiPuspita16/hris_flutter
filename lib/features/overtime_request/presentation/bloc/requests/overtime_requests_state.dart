import '../../../domain/overtime_request_entry.dart';

enum OvertimeRequestsStatus { initial, loading, success, failure }

/// Keadaan tab Status: riwayat pengajuan lembur.
class OvertimeRequestsState {
  const OvertimeRequestsState({
    this.status = OvertimeRequestsStatus.initial,
    this.requests = const [],
    this.errorMessage,
  });

  final OvertimeRequestsStatus status;
  final List<OvertimeRequestEntry> requests;
  final String? errorMessage;
}
