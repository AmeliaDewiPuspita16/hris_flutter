import 'package:flutter/foundation.dart';

import '../../../../../shared/domain/department.dart';

/// Dropdown "Executive / Non-Executive" pada sub-form New employee account
/// creation.
enum ExecutiveType {
  executive,
  nonExecutive;

  /// Sekaligus nilai yang dikirim ke `new_employee_level` — server memakai
  /// string ini apa adanya.
  String get label => switch (this) {
        ExecutiveType.executive => 'Executive',
        ExecutiveType.nonExecutive => 'Non-Executive',
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

  /// Nama field multipart untuk tiap label, dikirim ke
  /// `POST /api/portal/apps/it_request` saat kategorinya `new_employee_req`.
  static const fieldCodes = {
    laptop: 'new_employee_need_laptop',
    email: 'new_employee_need_email',
    biiePortal: 'new_employee_need_portal',
    synologyDrive: 'new_employee_need_synology',
  };
}

/// Data sub-form "New employee account creation" — satu-satunya opsi "What
/// do you need?" dengan struktur field sendiri (bukan checkbox/text field
/// generik seperti opsi lain), sesuai form pendaftaran karyawan baru di
/// versi web.
///
/// [department] memakai [Department] dari `features/shared` (id + name dari
/// `GET /api/data/department`) — sama seperti dropdown Department di form
/// pengumuman — karena `new_employee_department` di
/// `POST /api/portal/apps/it_request` butuh ID numerik departemen
/// sungguhan, bukan label yang ditebak.
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
