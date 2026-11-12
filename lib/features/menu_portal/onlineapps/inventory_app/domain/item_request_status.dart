import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/json_value.dart';

/// Status satu item request, dibaca dari objek `status` server:
///
/// ```json
/// "status": { "code": "pending", "label": "Pending" }
/// ```
///
/// | code       | arti                                   |
/// |------------|----------------------------------------|
/// | `pending`  | menunggu verifikasi                    |
/// | `approved` | disetujui                              |
/// | `rejected` | ditolak                                |
///
/// Warna: pending = emas (`accent`, sama seperti "menunggu persetujuan" di
/// Procurement dan badge kuning di web), approved = hijau, rejected = merah.
/// Pending sengaja TIDAK memakai `AppColors.pending` (oranye-kemerahan) karena
/// terlihat mirip Rejected.
///
/// Sengaja BUKAN enum (sama seperti `EstRequestStatus`): teks yang tampil
/// selalu [label] dari server, aplikasi hanya menentukan warna. Kode baru
/// dari server tidak membuat aplikasi error — badge-nya netral.
class ItemRequestStatus {
  const ItemRequestStatus({required this.code, required this.label});

  static const codePending = 'pending';
  static const codeApproved = 'approved';
  static const codeRejected = 'rejected';

  final String code;
  final String label;

  factory ItemRequestStatus.fromJson(Object? raw) {
    // Server boleh mengirim objek {code,label} ATAU teks biasa.
    if (raw is String && raw.trim().isNotEmpty) {
      return ItemRequestStatus(
        code: raw.trim().toLowerCase(),
        label: _capitalize(raw.trim()),
      );
    }
    if (raw is! Map<String, dynamic>) {
      return const ItemRequestStatus(code: '', label: '-');
    }

    final code = (textOrNull(raw['code']) ?? '').toLowerCase();
    return ItemRequestStatus(
      code: code,
      label: textOrNull(raw['label']) ??
          (code.isEmpty ? '-' : _capitalize(code)),
    );
  }

  bool get isPending => code == codePending;

  Color get color => switch (code) {
        codePending => AppColors.accent,
        codeApproved => AppColors.present,
        codeRejected => AppColors.rejected,
        _ => AppColors.textMuted,
      };

  Color get background => switch (code) {
        codePending => AppColors.accentBg,
        codeApproved => AppColors.presentBg,
        codeRejected => AppColors.rejectedBg,
        _ => AppColors.neutralBg,
      };

  static String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  @override
  bool operator ==(Object other) =>
      other is ItemRequestStatus &&
      other.code == code &&
      other.label == label;

  @override
  int get hashCode => Object.hash(code, label);
}
