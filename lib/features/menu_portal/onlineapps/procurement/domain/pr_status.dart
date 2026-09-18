import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

/// Kode status PR yang dikenal aplikasi.
///
/// Dipakai untuk dua hal yang tidak dikirim server: label pendek buat chip
/// filter (server hanya punya label panjang seperti "Pending Finance
/// Manager", terlalu lebar untuk deret chip) dan urutan tampilnya.
enum PrStatusCode {
  pendingHod('pending_hod', 'HOD'),
  pendingReview('pending_review', 'Under Review'),
  pendingDgm('pending_dgm', 'DGM'),
  pendingFinance('pending_finance', 'Finance'),
  pendingGm('pending_gm', 'GM'),
  draft('draft', 'Draft'),
  underRevision('under_revision', 'Revisi'),
  approved('approved', 'Approved'),
  rejected('rejected', 'Rejected'),
  poCreated('po_created', 'PO Created');

  const PrStatusCode(this.code, this.shortLabel);

  final String code;
  final String shortLabel;

  /// Null bila server mengirim kode yang belum dikenal — bukan galat.
  /// Pemanggil jatuh ke label dan warna netral, tidak menggugurkan PR-nya.
  static PrStatusCode? fromCode(String code) => switch (code) {
        'pending_hod' => PrStatusCode.pendingHod,
        'pending_review' => PrStatusCode.pendingReview,
        'pending_dgm' => PrStatusCode.pendingDgm,
        'pending_finance' => PrStatusCode.pendingFinance,
        'pending_gm' => PrStatusCode.pendingGm,
        'draft' => PrStatusCode.draft,
        'under_revision' => PrStatusCode.underRevision,
        'approved' => PrStatusCode.approved,
        'rejected' => PrStatusCode.rejected,
        'po_created' => PrStatusCode.poCreated,
        _ => null,
      };

  Color get color => switch (this) {
        PrStatusCode.approved => AppColors.present,
        PrStatusCode.rejected => AppColors.rejected,
        PrStatusCode.poCreated => AppColors.teal,
        PrStatusCode.underRevision => AppColors.accent,
        PrStatusCode.draft => AppColors.neutral,
        _ => AppColors.pending,
      };

  Color get background => switch (this) {
        PrStatusCode.approved => AppColors.presentBg,
        PrStatusCode.rejected => AppColors.rejectedBg,
        PrStatusCode.poCreated => AppColors.tealBg,
        PrStatusCode.underRevision => AppColors.accentBg,
        PrStatusCode.draft => AppColors.neutralBg,
        _ => AppColors.pendingBg,
      };
}

/// Status satu PR seperti dikirim server: `{code, label, level}`.
///
/// Sengaja bukan enum. Label yang tampil selalu milik server, jadi kode baru
/// yang ditambahkan backend tetap terbaca di layar tanpa aplikasi perlu
/// dirilis ulang; [PrStatusCode] hanya menambahkan warna dan label pendek
/// untuk kode yang sudah dikenal.
class PrStatus {
  const PrStatus({required this.code, required this.label, this.level});

  final String code;

  /// Label siap tampil, mis. "Pending Finance Manager".
  final String label;

  /// Urutan tahap approval yang sedang berjalan. Null di respons detail.
  final int? level;

  factory PrStatus.fromJson(Map<String, dynamic>? json) {
    final code = '${json?['code'] ?? ''}';
    final serverLabel = json?['label'];
    final level = json?['level'];

    final label = serverLabel is String && serverLabel.isNotEmpty
        ? serverLabel
        : PrStatusCode.fromCode(code)?.shortLabel ??
            (code.isEmpty ? 'Tidak diketahui' : code);

    return PrStatus(
      code: code,
      label: label,
      level: level is int ? level : null,
    );
  }

  PrStatusCode? get known => PrStatusCode.fromCode(code);

  /// True selama PR masih berjalan di rantai approval.
  bool get isPending => code.startsWith('pending_');

  /// Label pendek untuk chip filter; kode tak dikenal memakai label server.
  String get shortLabel => known?.shortLabel ?? label;

  Color get color => known?.color ?? AppColors.neutral;

  Color get background => known?.background ?? AppColors.neutralBg;
}
