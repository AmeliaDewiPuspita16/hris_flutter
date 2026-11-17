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
/// Approve goes to HRIS through the portal
/// (`POST .../leave/approvals/{id}/decision`, ERP Document Routing). Reject
/// is refused by the portal for now: HRIS has no rejection action yet, and
/// the portal's message says so.
class LeaveApprovalRepository {
  LeaveApprovalRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// `category` (leave|overtime) of each loaded request, which the decision
  /// endpoint needs to pick the HRIS service.
  final Map<String, String> _categories = {};

  /// Pending requests plus the decided ones of the last 90 days. The
  /// screen splits them into the Pending and History tabs.
  Future<List<LeaveApprovalRequest>> fetchRequests() async {
    final envelope = await _apiClient.getEnvelope(ApiConfig.leaveApprovals);
    final rows = envelope['data'];
    if (rows is! List) throw const ApiException.server();

    final items = <LeaveApprovalRequest>[];
    for (final row in rows) {
      if (row is! Map<String, dynamic>) continue;
      final item = LeaveApprovalRequest.fromJson(row);
      _categories[item.id] = (row['category'] as String?) ?? 'leave';
      items.add(item);
    }
    return List.unmodifiable(items);
  }

  /// Pending count for the Home banner and the HRIS menu badge.
  Future<int> fetchPendingCount() async {
    final envelope = await _apiClient.getEnvelope(ApiConfig.leaveApprovals);
    final meta = envelope['meta'];
    final count = meta is Map<String, dynamic> ? meta['pending_count'] : null;
    return count is num ? count.toInt() : 0;
  }

  /// Approve or reject one request and return its new version from HRIS.
  ///
  /// Throws [ApiException] with the portal's message when it is refused
  /// (already processed, own request, reject not available, HRIS down).
  Future<LeaveApprovalRequest> decide(
    String id, {
    required LeaveApprovalDecision decision,
    String? note,
  }) async {
    final trimmed = note?.trim();
    final data = await _apiClient.post(
      ApiConfig.leaveApprovalDecision(id),
      body: {
        'category': _categories[id] ?? 'leave',
        'decision':
            decision == LeaveApprovalDecision.approve ? 'approve' : 'reject',
        if (trimmed != null && trimmed.isNotEmpty) 'note': trimmed,
      },
    );

    return LeaveApprovalRequest.fromJson(data);
  }
}
