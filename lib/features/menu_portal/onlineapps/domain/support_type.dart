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
}