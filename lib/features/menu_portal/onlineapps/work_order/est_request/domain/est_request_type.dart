/// Pilihan dropdown "Type of Request" pada form Add Request EST.

enum EstRequestType {
  repair,
  project;

  String get label => switch (this) {
        EstRequestType.repair => 'Repair',
        EstRequestType.project => 'Project',
      };
}
