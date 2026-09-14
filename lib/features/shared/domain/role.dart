/// type Role = 'non-executive' | 'executive' | 'hod' | 'admin' | 'HR'`
enum Role { nonExecutive, executive, hod, admin }

extension RoleX on Role {
  String get demoUserName {
    switch (this) {
      case Role.nonExecutive:
        return 'Amelia Dewi';
      case Role.executive:
        return 'Anita';
      case Role.hod:
        return 'Dewi Puspita';
      case Role.admin:
        return 'Rini Astuti';
      // case Role:
      //   return 'Lastri';
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
        return 'Admin Department';
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
