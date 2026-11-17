import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../../core/network/api_exception.dart';
import '../domain/leave_approval_request.dart';
import '../domain/leave_approval_status.dart';

/// Data source of the Leave Approvals screen: the leave requests of the
/// HOD's department, read from HRIS through the portal
/// (`GET /api/portal/apps/hris/leave/approvals`).
///
/// One instance is shared (held by `BerandaScreen`) so the Home badge and
/// the menu show the same count as the screen.
///
/// Approve/reject is NOT available yet: the HRIS vendor has not delivered the
/// endpoint that changes a leave request's status. [decide] says so instead
/// of pretending, so nothing looks approved in the app while HRIS still has
/// it pending.
class LeaveApprovalRepository {
  LeaveApprovalRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Pending requests plus the decided ones of the last 90 days. The
  /// screen splits them into the Pending and History tabs.
  Future<List<LeaveApprovalRequest>> fetchRequests() async {
    final envelope = await _apiClient.getEnvelope(ApiConfig.leaveApprovals);
    final rows = envelope['data'];
    if (rows is! List) throw const ApiException.server();

    return List.unmodifiable([
      for (final row in rows)
        if (row is Map<String, dynamic>) LeaveApprovalRequest.fromJson(row),
    ]);
  }

  /// Pending count for the Home banner and the HRIS menu badge.
  Future<int> fetchPendingCount() async {
    final envelope = await _apiClient.getEnvelope(ApiConfig.leaveApprovals);
    final meta = envelope['meta'];
    final count = meta is Map<String, dynamic> ? meta['pending_count'] : null;
    return count is num ? count.toInt() : 0;
  }

  /// Approve or reject one request. Always throws for now (see class doc).
  Future<LeaveApprovalRequest> decide(
    String id, {
    required LeaveApprovalDecision decision,
    String? note,
  }) async {
    throw const ApiException.server(
      'Approving or rejecting from the app is not available yet. '
      'Please use HRIS for now.',
    );
  }
}
