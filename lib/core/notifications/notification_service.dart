import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../logging/app_logger.dart';

/// Handler pesan FCM yang diterima saat app di background/terminated.
///
/// WAJIB top-level function (bukan method di class) dan diberi anotasi
/// `vm:entry-point` supaya Android bisa memanggilnya lewat isolate terpisah
/// ketika app tidak sedang berjalan. Jangan pindahkan ke dalam class.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase.initializeApp() dipanggil lagi di sini karena handler ini bisa
  // jalan di isolate baru yang belum pernah menjalankan main().
  AppLogger.info('FCM background message: ${message.messageId}');
}

/// Satu pintu untuk semua urusan push notification: minta izin, ambil FCM
/// token, dan tampilkan notifikasi saat app di foreground (FCM tidak
/// menampilkan notifikasi otomatis selagi app terbuka, beda dengan saat
/// background/terminated).
class NotificationService {
  NotificationService({
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _localNotifications =
            localNotifications ?? FlutterLocalNotificationsPlugin();

  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications;

  static const _androidChannel = AndroidNotificationChannel(
    'high_importance_channel',
    'Notifikasi Penting',
    description: 'Dipakai untuk notifikasi approval, pengumuman, dan reminder.',
    importance: Importance.high,
  );

  /// Dipanggil sekali saat startup (lih. `main.dart`), setelah
  /// `Firebase.initializeApp()`. Urutannya:
  /// 1. Minta izin notifikasi (wajib di iOS; wajib di Android 13+/API 33).
  /// 2. Siapkan local notifications plugin + channel Android, supaya pesan
  ///    yang datang selagi app di foreground tetap muncul sebagai notifikasi.
  /// 3. Pasang listener untuk pesan foreground & saat notifikasi di-tap.
  Future<void> init() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    AppLogger.info(
      'Izin notifikasi: ${settings.authorizationStatus.name}',
    );

    await _initLocalNotifications();

    // iOS: pastikan notifikasi tetap tampil (banner/sound) selagi app
    // dibuka, bukan cuma masuk notification center diam-diam.
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen((message) {
      _foregroundMessages.add(message);
      _showForegroundNotification(message);
    });
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // App dibuka dari keadaan mati lewat tap notifikasi: onMessageOpenedApp
    // tidak terpanggil untuk kasus ini, pesannya harus diminta sendiri.
    final initial = await _messaging.getInitialMessage();
    if (initial != null) _handleNotificationTap(initial);
  }

  /// FCM token perangkat ini, dikirim ke backend supaya server tahu ke mana
  /// push notification harus dialamatkan. Null kalau izin ditolak atau token
  /// belum siap.
  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e, stack) {
      AppLogger.error('Gagal mengambil FCM token', e, stack);
      return null;
    }
  }

  /// Dipanggil tiap kali FCM merotasi token (reinstall, clear data, dsb.)
  /// supaya token terbaru bisa langsung dikirim ulang ke backend.
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _localNotifications.initialize(
      settings: const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _handleLocalNotificationTap,
    );

    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_androidChannel);
    }
  }

  void _showForegroundNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      // Dibawa supaya tap pada notifikasi lokal ini bisa diarahkan ke layar
      // yang sama dengan tap pada push dari system tray.
      payload: jsonEncode(message.data),
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    AppLogger.info('Notifikasi di-tap, data: ${message.data}');
    _emitTap(message.data);
  }

  void _handleLocalNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    try {
      final data = jsonDecode(payload);
      if (data is Map<String, dynamic>) _emitTap(data);
    } catch (e, stack) {
      AppLogger.error('Payload notifikasi lokal tidak terbaca', e, stack);
    }
  }

  /// Tap pada notifikasi — dari system tray (app di background/terminated)
  /// maupun dari notifikasi lokal saat app di foreground — berupa data
  /// payload FCM-nya. Beranda yang mendengarkan dan membuka layar terkait.
  ///
  /// Static karena NotificationService dibuat lebih dari sekali (main.dart,
  /// LoginBloc), sementara listener FCM-nya hanya dipasang sekali di init().
  static final _taps = StreamController<Map<String, dynamic>>.broadcast();
  static Stream<Map<String, dynamic>> get taps => _taps.stream;

  /// Tap yang datang saat belum ada yang mendengarkan — mis. app dibuka dari
  /// notifikasi dan user masih di splash/login. Diambil sekali oleh Beranda
  /// lewat [takePendingTap] begitu ia tampil.
  static Map<String, dynamic>? _pendingTap;

  static Map<String, dynamic>? takePendingTap() {
    final tap = _pendingTap;
    _pendingTap = null;
    return tap;
  }

  /// Pesan FCM yang datang selagi app terbuka, supaya Beranda bisa memuat
  /// ulang isi tab Notifications tanpa menunggu ditarik manual.
  static final _foregroundMessages = StreamController<RemoteMessage>.broadcast();
  static Stream<RemoteMessage> get foregroundMessages =>
      _foregroundMessages.stream;

  static void _emitTap(Map<String, dynamic> data) {
    if (_taps.hasListener) {
      _taps.add(data);
    } else {
      _pendingTap = data;
    }
  }

  @visibleForTesting
  AndroidNotificationChannel get androidChannel => _androidChannel;
}
