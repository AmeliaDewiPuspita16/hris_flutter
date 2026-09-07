import '../../shared/domain/role.dart';

class Dependent {
  const Dependent({required this.name, required this.relation, required this.birthDate});
  final String name;
  final String relation;
  final String birthDate;
}

// (tab Contract, Bank Account, Address, Dependent)
class EmployeeProfile {
  const EmployeeProfile({
    required this.name,
    required this.title,
    required this.dept,
    required this.nip,
    required this.join,
    required this.phone,
    required this.email,
    required this.address,
    required this.employeeCategory,
    required this.birthPlace,
    required this.birthDate,
    required this.religion,
    required this.maritalStatus,
    required this.degree,
    required this.contractNo,
    required this.bankName,
    required this.bankAccountNo,
    required this.bankAccountName,
    required this.dependents,
  });

  final String name;
  final String title;
  final String dept;
  final String nip;
  final String join;
  final String phone;
  final String email;
  final String address;

  // Data Diri — field tambahan dari web (read-only, HR-managed).
  final String employeeCategory; // "Non Executive" / "Executive"
  final String birthPlace;
  final String birthDate;
  final String religion;
  final String maritalStatus;
  final String degree;

  // Kontrak
  final String contractNo;

  // Rekening
  final String bankName;
  final String bankAccountNo;
  final String bankAccountName;

  // Tanggungan
  final List<Dependent> dependents;

  String get initials => name.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join();

  /// Data dummy per role — nanti diganti fetch API (Employee Information).
  static const _map = <Role, EmployeeProfile>{
    Role.nonExecutive: EmployeeProfile(
      name: 'Amelia Dewi',
      title: 'Intern Programming',
      dept: 'IT & Media',
      nip: 'N/A',
      join: '10 Agu 2026',
      phone: '+62 812-3456-7890',
      email: 'amelia@gmail.com',
      address: 'Teluk Sasah',
      employeeCategory: 'Non Executive',
      birthPlace: 'Tanjung Uban',
      birthDate: '16-01-2003',
      religion: 'Islam',
      maritalStatus: 'Belum Kawin',
      degree: 'SMA',
      contractNo: '-',
      bankName: 'BRI',
      bankAccountNo: '1090019664473',
      bankAccountName: 'Amelia Dewi',
      dependents: [
        Dependent(name: 'Syarief', relation: 'Ayah', birthDate: '03-08-1959'),
        Dependent(name: 'Maya', relation: 'Ibu', birthDate: '20-01-1969'),
      ],
    ),
    Role.executive: EmployeeProfile(
      name: 'Arif Wijaya',
      title: 'Senior Manager Keuangan',
      dept: 'Finance & Accounting',
      nip: '2015-03-0018',
      join: '1 Mar 2015',
      phone: '+62 811-2233-4455',
      email: 'arif.wijaya@nusantara.co.id',
      address: 'Jl. Sudirman Kav. 52, Jakarta 12190',
      employeeCategory: 'Executive',
      birthPlace: 'Jakarta',
      birthDate: '05-11-1985',
      religion: 'Islam',
      maritalStatus: 'Kawin',
      degree: 'S1',
      contractNo: 'CT-2015-0018',
      bankName: 'BCA',
      bankAccountNo: '2200198765',
      bankAccountName: 'Arif Wijaya',
      dependents: [
        Dependent(name: 'Ratna Sari', relation: 'Istri', birthDate: '14-02-1987'),
      ],
    ),
    Role.hod: EmployeeProfile(
      name: 'Dewi Kusuma',
      title: 'Head of Engineering',
      dept: 'Engineering & Maintenance',
      nip: '2012-08-0009',
      join: '10 Agu 2012',
      phone: '+62 813-5678-9012',
      email: 'dewi.kusuma@nusantara.co.id',
      address: 'Jl. Gatot Subroto No. 88, Karawang 41361',
      employeeCategory: 'Executive',
      birthPlace: 'Karawang',
      birthDate: '22-06-1982',
      religion: 'Islam',
      maritalStatus: 'Kawin',
      degree: 'S1',
      contractNo: 'CT-2012-0009',
      bankName: 'BNI',
      bankAccountNo: '0334455667',
      bankAccountName: 'Dewi Kusuma',
      dependents: [
        Dependent(name: 'Bagus Kusuma', relation: 'Suami', birthDate: '10-09-1980'),
        Dependent(name: 'Kirana Kusuma', relation: 'Anak', birthDate: '02-05-2015'),
      ],
    ),
    Role.admin: EmployeeProfile(
      name: 'Rini Astuti',
      title: 'HR Admin Officer',
      dept: 'Human Resources',
      nip: '2020-01-0055',
      join: '6 Jan 2020',
      phone: '+62 812-9988-7766',
      email: 'rini.astuti@nusantara.co.id',
      address: 'Jl. Pahlawan No. 34, Cikarang 17530',
      employeeCategory: 'Non Executive',
      birthPlace: 'Cikarang',
      birthDate: '30-03-1993',
      religion: 'Islam',
      maritalStatus: 'Belum Kawin',
      degree: 'S1',
      contractNo: 'CT-2020-0055',
      bankName: 'BRI',
      bankAccountNo: '445566778899',
      bankAccountName: 'Rini Astuti',
      dependents: [],
    ),
  };

  static EmployeeProfile of(Role role) => _map[role]!;
}