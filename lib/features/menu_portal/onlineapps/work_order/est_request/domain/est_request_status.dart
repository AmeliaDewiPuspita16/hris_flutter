import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/utils/json_value.dart';

/// Status satu Work Order, dibaca dari objek `status` di respons server:
///
/// ```json
/// "status": { "code": "progress", "label": "On Progress" }
/// ```
///
/// | code          | arti                                              |
/// |---------------|---------------------------------------------------|
/// | `waiting_hod` | menunggu HOD menyetujui request-nya               |
/// | `waiting`     | HOD sudah setuju, tim EST belum mengerjakan       |
/// | `progress`    | sedang dikerjakan                                 |
/// | `finished`    | selesai                                           |
/// | `rejected`    | ditolak HOD                                       |
///
/// Sengaja BUKAN enum: [code] dan [label] disimpan apa adanya dari server.
/// Teks yang tampil selalu [label] dari server, dan hanya warna badge yang
/// ditentukan di sini. Kalau server menambah kode baru, aplikasi tidak error
/// — badge-nya memakai warna netral sampai kita menambahkan warnanya.
class EstRequestStatus {
  const EstRequestStatus({required this.code, required this.label});

  static const codeWaitingHod = 'waiting_hod';
  static const codeWaiting = 'waiting';
  static const codeProgress = 'progress';
  static const codeFinished = 'finished';
  static const codeRejected = 'rejected';

  final String code;
  final String label;

  /// Bila `status` hilang atau bentuknya tidak dikenal, hasilnya status
  /// kosong berlabel `-` supaya satu baris cacat tidak merusak seluruh daftar.
  factory EstRequestStatus.fromJson(Object? raw) {
    if (raw is! Map<String, dynamic>) {
      return const EstRequestStatus(code: '', label: '-');
    }

    final code = textOrNull(raw['code']) ?? '';
    return EstRequestStatus(
      code: code,
      label: textOrNull(raw['label']) ?? (code.isEmpty ? '-' : code),
    );
  }

  bool get isWaitingHod => code == codeWaitingHod;
  bool get isRejected => code == codeRejected;

  Color get color => switch (code) {
        codeWaitingHod => AppColors.accent,
        codeWaiting => AppColors.pending,
        codeProgress => AppColors.inProgress,
        codeFinished => AppColors.primaryMid,
        codeRejected => AppColors.rejected,
        _ => AppColors.textMuted,
      };

  Color get background => switch (code) {
        codeWaitingHod => AppColors.accentBg,
        codeWaiting => AppColors.pendingBg,
        codeProgress => AppColors.inProgressBg,
        codeFinished => AppColors.primaryLight,
        codeRejected => AppColors.rejectedBg,
        _ => AppColors.neutralBg,
      };

  @override
  bool operator ==(Object other) =>
      other is EstRequestStatus && other.code == code && other.label == label;

  @override
  int get hashCode => Object.hash(code, label);
}
