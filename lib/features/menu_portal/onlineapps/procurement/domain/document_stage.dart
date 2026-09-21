import 'document_state.dart';

/// Satu tahap di "Progress Dokumen": PR Approval -> Vendor Tally ->
/// Purchase Order -> Goods Receipt.
class DocumentStage {
  const DocumentStage({
    required this.code,
    required this.label,
    required this.state,
    this.count,
    this.numbers = const [],
  });

  /// Ex: "vendor_tally".
  final String code;

  /// Ex: "Vendor Tally".
  final String label;

  final DocumentState state;

  /// Jumlah dokumen yang sudah terbit di tahap ini. Null bila tahapnya
  /// memang tidak menghitung dokumen (PR Approval).
  final int? count;

  /// Nomor dokumen yang sudah terbit, ex: ["BIIE/26-08-003"].
  final List<String> numbers;

  /// Keterangan siap tampil. Server tidak mengirim `state_label` untuk
  /// progress dokumen, jadi disusun di sini.
  String get stateLabel => switch (state) {
        DocumentState.done => 'Selesai',
        DocumentState.inProgress => 'Sedang Berjalan',
        DocumentState.rejected => 'Ditolak',
        DocumentState.notStarted => 'Belum ada',
      };

  factory DocumentStage.fromJson(Map<String, dynamic> json) {
    final count = json['count'];

    return DocumentStage(
      code: '${json['code'] ?? ''}',
      label: '${json['label'] ?? ''}',
      state: DocumentState.fromCode('${json['state'] ?? ''}'),
      count: count is int ? count : null,
      numbers: (json['numbers'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(growable: false),
    );
  }
}
