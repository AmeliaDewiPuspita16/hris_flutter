import 'notification_category.dart';
import 'notification_link.dart';

/// Keputusan atas notifikasi yang menuntut tindakan.
enum NotificationDecision { approved, rejected }

/// Jenis tindakan yang diminta notifikasi: [decision] = Approve/Reject,
/// [assign] = admin driver menetapkan kendaraan (satu tombol "Assign").
enum NotificationActionType { decision, assign }

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
    this.awaitsApproval = false,
    this.decision,
    this.actionType = NotificationActionType.decision,
    this.refId,
    this.serverId,
    this.link,
  });

  final String id;
  final NotificationCategory category;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;

  /// True kalau notifikasi ini menunggu Approve/Reject dari pengguna.
  final bool requiresDecision;

  /// Notifikasi server "butuh approval" yang request-nya masih menunggu
  /// keputusan user (dicek ke antrean approval modulnya, lihat
  /// `PendingApprovalChecker`). Beda dari [requiresDecision]: tidak ada
  /// tombol Approve/Reject di baris ini — tap membuka antrean modulnya.
  final bool awaitsApproval;

  /// Null selama belum diputuskan.
  final NotificationDecision? decision;

  /// Bentuk tombol yang ditampilkan bila [needsAction].
  final NotificationActionType actionType;

  /// id request di modul asalnya (mis. id indent untuk [assign]), supaya
  /// pemanggil bisa membuka request yang dimaksud. Null untuk yang lain.
  final String? refId;

  /// id di tabel notifikasi server (`GET /api/portal/apps/notifications`).
  /// Null untuk notifikasi yang dibangun di app sendiri (Leave, Assign) —
  /// dibaca/dihapus hanya di lokal.
  final int? serverId;

  /// Tujuan saat di-tap. Null = tap hanya menandai sudah dibaca.
  final NotificationLink? link;

  bool get isFromServer => serverId != null;

  bool get needsAction => requiresDecision && decision == null;

  /// Masuk tab Action dan kelompok "Action needed": menunggu tombol di
  /// baris ini ([needsAction]) atau approval di modulnya ([awaitsApproval]).
  bool get isAction => needsAction || awaitsApproval;

  /// Ringkasan hasil keputusan, dipakai sebagai pengganti body setelah
  /// tombol ditekan.
  String? get decisionLabel {
    if (decision == null) return null;
    if (actionType == NotificationActionType.assign) return 'Vehicle assigned';
    return switch (decision) {
      NotificationDecision.approved => 'You approved this request',
      NotificationDecision.rejected => 'You rejected this request',
      null => null,
    };
  }

  AppNotification copyWith({
    bool? isRead,
    NotificationDecision? decision,
    bool? awaitsApproval,
  }) {
    return AppNotification(
      id: id,
      category: category,
      title: title,
      body: body,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      requiresDecision: requiresDecision,
      awaitsApproval: awaitsApproval ?? this.awaitsApproval,
      decision: decision ?? this.decision,
      actionType: actionType,
      refId: refId,
      serverId: serverId,
      link: link,
    );
  }
}
