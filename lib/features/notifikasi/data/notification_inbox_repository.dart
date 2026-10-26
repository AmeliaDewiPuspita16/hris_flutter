import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../../core/utils/json_value.dart';
import '../domain/app_notification.dart';
import '../domain/notification_category.dart';
import '../domain/notification_link.dart';

/// Satu halaman isi tab Notifications dari server, beserta jumlah yang
/// belum dibaca (seluruhnya, bukan hanya di halaman ini) untuk badge
/// lonceng.
class NotificationInboxPage {
  const NotificationInboxPage({required this.items, required this.unread});

  final List<AppNotification> items;
  final int unread;
}

/// Notifikasi IT Request, eProcurement, EST Work Order, dan Indent Vehicle
/// yang dikirim backend (sumber yang sama dengan push FCM-nya). Tidak tahu
/// soal HTTP — itu urusan [ApiClient].
///
/// Semua method melempar [ApiException] bila gagal.
class NotificationInboxRepository {
  NotificationInboxRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// 50 terbaru cukup untuk tab ini; yang lebih lama tetap dihitung di
  /// [NotificationInboxPage.unread].
  Future<NotificationInboxPage> fetchLatest({int perPage = 50}) async {
    final envelope = await _apiClient
        .getEnvelope('${ApiConfig.notifications}?per_page=$perPage');

    final data = envelope['data'];
    final summary = envelope['summary'];

    return NotificationInboxPage(
      items: [
        if (data is List)
          for (final row in data)
            if (row is Map<String, dynamic>) fromJson(row),
      ],
      unread: summary is Map<String, dynamic> ? intOr(summary['unread'], 0) : 0,
    );
  }

  Future<void> markRead(int id) =>
      _apiClient.postAction(ApiConfig.notificationRead(id));

  Future<void> markAllRead() =>
      _apiClient.postAction(ApiConfig.notificationsReadAll);

  Future<void> delete(int id) =>
      _apiClient.delete(ApiConfig.notificationDetail(id));

  /// Satu baris `data[]` dari server menjadi [AppNotification]. Id-nya
  /// diberi awalan supaya tidak pernah bentrok dengan id notifikasi lokal
  /// (Leave, Assign).
  static AppNotification fromJson(Map<String, dynamic> json) {
    final id = intOr(json['id'], 0);
    final payload = json['data'];
    final link = NotificationLink.fromData(
      payload is Map<String, dynamic>
          ? payload
          : {'module': json['module'], 'type': json['type']},
    );

    return AppNotification(
      id: 'srv-$id',
      serverId: id,
      category: categoryFor(json['module']?.toString()),
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      createdAt: dateOrNull(json['created_at'])?.toLocal() ?? DateTime.now(),
      isRead: json['is_read'] == true,
      refId: json['reference_id']?.toString(),
      link: link,
    );
  }

  static NotificationCategory categoryFor(String? module) => switch (module) {
        NotificationLink.moduleItRequest => NotificationCategory.itRequest,
        NotificationLink.moduleEstWorkOrder => NotificationCategory.estRequest,
        NotificationLink.moduleIndentVehicle =>
          NotificationCategory.indentVehicle,
        NotificationLink.moduleEprocurement => NotificationCategory.procurement,
        _ => NotificationCategory.approval,
      };
}
