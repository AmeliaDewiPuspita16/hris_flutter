import 'package:flutter/foundation.dart';

/// Dropdown "Executive / Non-Executive" pada sub-form New employee account
/// creation.
enum ExecutiveType {
  executive,
  nonExecutive;

  String get label => switch (this) {
        ExecutiveType.executive => 'Executive',
        ExecutiveType.nonExecutive => 'Non-Executive',
      };
}

/// Dropdown "Department" pada sub-form New employee account creation —
/// sesuai daftar departemen di versi web.
enum Department {
  aml,
  bdd,
  cdd,
  crs,
  est,
  evd,
  fin,
  gmo,
  hrGa,
  hse,
  ims,
  itm,
  pod,
  ssd;

  String get label => switch (this) {
        Department.aml => 'AML',
        Department.bdd => 'BDD',
        Department.cdd => 'CDD',
        Department.crs => 'CRS',
        Department.est => 'EST',
        Department.evd => 'EVD',
        Department.fin => 'FIN',
        Department.gmo => 'GMO',
        Department.hrGa => 'HR & GA',
        Department.hse => 'HSE',
        Department.ims => 'IMS',
        Department.itm => 'ITM',
        Department.pod => 'POD',
        Department.ssd => 'SSD',
      };
}

// Label checkbox "Equipment / Access Needed (optional)" pada sub-form New
/// employee account creation.
class NewEmployeeEquipment {
  NewEmployeeEquipment._();

  static const laptop = 'Laptop/Computer';
  static const email = 'Email account';
  static const biiePortal = 'BIIE Portal account';
  static const synologyDrive = 'Synology Drive account';

  static const all = [laptop, email, biiePortal, synologyDrive];
}

/// Data sub-form "New employee account creation" — satu-satunya opsi "What
/// do you need?" dengan struktur field sendiri (bukan checkbox/text field
/// generik seperti opsi lain), sesuai form pendaftaran karyawan baru di
/// versi web.
@immutable
class NewEmployeeData {
  const NewEmployeeData({
    this.fullName = '',
    this.preferredName = '',
    this.employeeNumber = '',
    this.executiveType,
    this.department,
    this.section = '',
    this.equipmentNeeded = const <String>{},
  });

  final String fullName;
  final String preferredName;
  final String employeeNumber;
  final ExecutiveType? executiveType;
  final Department? department;
  final String section;
  final Set<String> equipmentNeeded;

  /// Field wajib (Full name, Employee number, Executive/Non-Executive,
  /// Department) sudah terisi — Preferred name, Section, dan Equipment
  /// memang opsional di form ini.
  bool get isComplete =>
      fullName.trim().isNotEmpty &&
      employeeNumber.trim().isNotEmpty &&
      executiveType != null &&
      department != null;

  NewEmployeeData copyWith({
    String? fullName,
    String? preferredName,
    String? employeeNumber,
    ExecutiveType? executiveType,
    Department? department,
    String? section,
    Set<String>? equipmentNeeded,
  }) {
    return NewEmployeeData(
      fullName: fullName ?? this.fullName,
      preferredName: preferredName ?? this.preferredName,
      employeeNumber: employeeNumber ?? this.employeeNumber,
      executiveType: executiveType ?? this.executiveType,
      department: department ?? this.department,
      section: section ?? this.section,
      equipmentNeeded: equipmentNeeded ?? this.equipmentNeeded,
    );
  }
}