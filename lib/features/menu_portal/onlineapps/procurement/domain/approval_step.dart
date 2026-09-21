import 'approval_state.dart';
import '../../../../../core/utils/json_value.dart';

/// Satu tahap di "Approval Progress" — HOD, Under Review, DGM, Finance
/// Manager, GM.
class ApprovalStep {
  const ApprovalStep({
    required this.level,
    required this.label,
    required this.state,
    required this.stateLabel,
    this.subtitle,
    this.approver,
    this.comments,
    this.actedAt,
  });

  /// Urutan tahap, 1..n. Dipakai sebagai nomor di titik timeline.
  final int level;

  /// Ex: "Finance Manager".
  final String label;

  /// Jabatan yang menangani tahap ini, ex: "Deputy General Manager".
  final String? subtitle;

  final ApprovalState state;

  /// Keterangan siap tampil dari server, ex: "Menunggu persetujuan".
  final String stateLabel;

  /// Nama pemberi keputusan. Kosong selama tahapnya belum dijalankan.
  final String? approver;

  final String? comments;
  final DateTime? actedAt;

  factory ApprovalStep.fromJson(Map<String, dynamic> json) {
    final level = json['level'];
    final state = ApprovalState.fromCode('${json['state'] ?? ''}');
    final stateLabel = json['state_label'];

    return ApprovalStep(
      level: level is int ? level : 0,
      label: '${json['label'] ?? ''}',
      subtitle: textOrNull(json['subtitle']),
      state: state,
      stateLabel: stateLabel is String && stateLabel.isNotEmpty
          ? stateLabel
          : _fallbackLabel(state),
      approver: textOrNull(json['approver']),
      comments: textOrNull(json['comments']),
      actedAt: dateOrNull(json['acted_at']),
    );
  }

  /// Dipakai hanya bila server tidak mengirim `state_label`.
  static String _fallbackLabel(ApprovalState state) => switch (state) {
        ApprovalState.approved => 'Disetujui',
        ApprovalState.rejected => 'Ditolak',
        ApprovalState.revision => 'Perlu revisi',
        ApprovalState.waiting => 'Menunggu persetujuan',
        ApprovalState.pending => 'Belum diproses',
      };
}
