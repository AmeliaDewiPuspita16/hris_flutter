/// Padanan `type Role = 'non-executive' | 'executive' | 'hod' | 'admin'`
enum Role { nonExecutive, executive, hod, admin }

extension RoleX on Role {
  /// Nama pegawai demo per role (sementara — nanti diganti data user asli).
  String get demoUserName {
    switch (this) {
      case Role.nonExecutive:
        return 'Amelia Dewi';
      case Role.executive:
        return 'Sasqia';
      case Role.hod:
        return 'Dewi Puspita';
      case Role.admin:
        return 'Rini Astuti';
    }
  }

  String get firstName => demoUserName.split(' ').first;

  /// Jabatan demo per role — ditampilkan di header Beranda & Profil.
  String get demoUserTitle {
    switch (this) {
      case Role.nonExecutive:
        return 'Staff';
      case Role.executive:
        return 'Manager';
      case Role.hod:
        return 'Head of Department';
      case Role.admin:
        return 'HR Admin';
    }
  }

  /// Inisial 2 huruf dari nama, dipakai di avatar bulat header.
  String get initials {
    final parts = demoUserName.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}