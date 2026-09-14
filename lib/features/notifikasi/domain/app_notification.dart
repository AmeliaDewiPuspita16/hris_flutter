import 'notification_category.dart';

/// Keputusan atas notifikasi yang menuntut tindakan.
enum NotificationDecision { approved, rejected }

/// Satu notifikasi.
///
/// Yang membedakan halaman ini dari daftar biasa: notifikasi yang
/// [needsAction] naik ke blok "Needs your action" di paling atas. Begitu
/// diputuskan, ia turun jadi baris biasa — jadi blok itu selalu berisi
/// pekerjaan yang benar-benar masih menggantung.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.category,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
    this.requiresDecision = false,
    this.decision,
  });

  final String id;
  final NotificationCategory category;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;

  /// True kalau notifikasi ini menunggu Approve/Reject dari pengguna.
  final bool requiresDecision;

  /// Null selama belum diputuskan.
  final NotificationDecision? decision;

  bool get needsAction => requiresDecision && decision == null;

  /// Ringkasan hasil keputusan, dipakai sebagai pengganti body setelah
  /// tombol ditekan.
  String? get decisionLabel => switch (decision) {
        NotificationDecision.approved => 'You approved this request',
        NotificationDecision.rejected => 'You rejected this request',
        null => null,
      };

  AppNotification copyWith({bool? isRead, NotificationDecision? decision}) {
    return AppNotification(
      id: id,
      category: category,
      title: title,
      body: body,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      requiresDecision: requiresDecision,
      decision: decision ?? this.decision,
    );
  }
}
