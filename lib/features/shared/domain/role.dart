enum Role { nonExecutive, executive, hod, admin, hrPublisher }

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
      case Role.hrPublisher:
        return 'Nanda Pratiwi';
    }
  }

  String get firstName => demoUserName.split(' ').first;

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
      case Role.hrPublisher:
        return 'HR Publisher';
    }
  }

  /// Inisial 2 huruf dari nama, dipakai di avatar bulat header.
  String get initials {
    final parts = demoUserName.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  /// Jam check-in demo (dummy) — hasil sync dari mesin
  /// fingerprint kantor lewat HRIS web.
  String get demoCheckIn {
    switch (this) {
      case Role.nonExecutive:
        return '06:52';
      case Role.executive:
        return '07:59';
      case Role.hod:
        return '07:55';
      case Role.admin:
        return '07:50';
      case Role.hrPublisher:
        return '07:47';
    }
  }
}
