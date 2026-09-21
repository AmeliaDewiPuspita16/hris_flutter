/// Pilihan dropdown "Support type" pada form Ajukan Request

enum SupportType {
  request,
  repair,
  return_;

  String get label => switch (this) {
        SupportType.request => 'Request',
        SupportType.repair => 'Repair',
        SupportType.return_ => 'Return',
      };

  /// Nilai `jenis_dukungan` untuk `POST /api/portal/apps/it_request`.
  String get wireValue => switch (this) {
        SupportType.request => 'PERMINTAAN',
        SupportType.repair => 'PERBAIKAN',
        SupportType.return_ => 'PENGEMBALIAN',
      };
}