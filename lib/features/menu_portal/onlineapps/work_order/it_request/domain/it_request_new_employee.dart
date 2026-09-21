import '../../../../../../core/utils/json_value.dart';

/// Data sub-form "New employee account creation", dari `new_employee` di
/// respons detail — null di semua contoh yang pernah terlihat.
///
/// Nama key JSON di sini adalah tebakan berdasarkan field form yang sama di
/// [NewEmployeeData] lokal (`full_name`, `employee_number`, dst) — API belum
/// pernah mengirim contoh isinya. Semua field sengaja nullable dan dibaca
/// defensif: kalau tebakan key-nya meleset, bagian ini cuma tidak
/// menampilkan apa-apa (bukan crash).
class ItRequestNewEmployee {
  const ItRequestNewEmployee({
    this.fullName,
    this.preferredName,
    this.employeeNumber,
    this.executiveType,
    this.department,
    this.section,
    this.equipmentNeeded = const [],
  });

  final String? fullName;
  final String? preferredName;
  final String? employeeNumber;
  final String? executiveType;
  final String? department;
  final String? section;
  final List<String> equipmentNeeded;

  /// Null bila `new_employee` sendiri null di respons.
  static ItRequestNewEmployee? fromJsonOrNull(dynamic json) {
    if (json is! Map<String, dynamic>) return null;

    return ItRequestNewEmployee(
      fullName: textOrNull(json['full_name']),
      preferredName: textOrNull(json['preferred_name']),
      employeeNumber: textOrNull(json['employee_number']),
      executiveType: textOrNull(json['executive_type']),
      department: textOrNull(json['department']),
      section: textOrNull(json['section']),
      equipmentNeeded: (json['equipment_needed'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(growable: false),
    );
  }
}
