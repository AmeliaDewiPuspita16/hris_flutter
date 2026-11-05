import 'dart:async';

import 'package:flutter/material.dart';
import 'package:no_screenshot/no_screenshot.dart';
import 'package:no_screenshot/screenshot_snapshot.dart';

import '../logging/app_logger.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Melindungi [child] dari screenshot dan rekam layar selama widget ini tampil.
///
/// - Android: `FLAG_SECURE`, screenshot ditolak dan rekaman menjadi hitam.
/// - iOS: tidak ada API resmi; plugin memakai lapisan secure text field
///   sehingga layar tampil hitam di hasil tangkapan. Selama layar direkam,
///   [child] juga diganti pesan, sebagai lapisan kedua.
///
/// [child] baru dibangun setelah proteksi terpasang. Kalau plugin gagal,
/// kegagalannya dicatat dan [child] tetap ditampilkan supaya dokumen masih
/// bisa dibaca.
class ScreenCaptureGuard extends StatefulWidget {
  const ScreenCaptureGuard({super.key, required this.child});

  final Widget child;

  /// Status proteksi disimpan plugin di disk. Kalau app mati saat guard aktif,
  /// proteksi akan ikut aktif di seluruh app pada peluncuran berikutnya, jadi
  /// harus dibersihkan saat app mulai.
  static Future<void> clearLeftoverProtection() async {
    try {
      await NoScreenshot.instance.screenshotOn();
    } on Exception catch (error, stackTrace) {
      AppLogger.error('Gagal membersihkan proteksi layar', error, stackTrace);
    }
  }

  /// Sengaja satu untuk seumur app dan tidak pernah dibatalkan: di iOS setiap
  /// listen baru memulai loop polling plugin yang tidak ikut berhenti.
  static StreamSubscription<ScreenshotSnapshot>? _recordingSubscription;
  static final _isRecording = ValueNotifier<bool>(false);

  @override
  State<ScreenCaptureGuard> createState() => _ScreenCaptureGuardState();
}

class _ScreenCaptureGuardState extends State<ScreenCaptureGuard> {
  bool _protectionSettled = false;

  @override
  void initState() {
    super.initState();
    _enable();
  }

  Future<void> _enable() async {
    final plugin = NoScreenshot.instance;
    try {
      ScreenCaptureGuard._recordingSubscription ??= plugin.screenshotStream
          .listen(
            (snapshot) =>
                ScreenCaptureGuard._isRecording.value =
                    snapshot.isScreenRecording,
            onError: (Object error, StackTrace stackTrace) => AppLogger.error(
              'Gagal memantau rekam layar',
              error,
              stackTrace,
            ),
          );
      await plugin.screenshotOff();
      await plugin.startScreenRecordingListening();
    } on Exception catch (error, stackTrace) {
      AppLogger.error('Gagal memasang proteksi layar', error, stackTrace);
    }
    if (mounted) setState(() => _protectionSettled = true);
  }

  Future<void> _disable() async {
    final plugin = NoScreenshot.instance;
    try {
      await plugin.stopScreenRecordingListening();
      await plugin.screenshotOn();
    } on Exception catch (error, stackTrace) {
      AppLogger.error('Gagal melepas proteksi layar', error, stackTrace);
    }
  }

  @override
  void dispose() {
    unawaited(_disable());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_protectionSettled) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.primaryText),
      );
    }

    return ValueListenableBuilder<bool>(
      valueListenable: ScreenCaptureGuard._isRecording,
      builder: (context, isRecording, child) {
        if (!isRecording) return child!;

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'This document is hidden during screen recording.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMuted,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}
