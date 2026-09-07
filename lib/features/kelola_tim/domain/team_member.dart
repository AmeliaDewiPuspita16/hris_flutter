/// Padanan baris data di web "Manage Leave Request Department":

class TeamMember {
  const TeamMember({
    required this.id,
    required this.name,
    required this.position,
    required this.department,
    required this.leavePlafond,
    required this.leaveUsed,
  });

  final String id;
  final String name;
  final String position;
  final String department;
  final double leavePlafond;
  final double leaveUsed;

  double get leaveRemaining => leavePlafond - leaveUsed;

  /// adalah data dummy (nanti kalo dah ada API by department, bisa dihapus).

  static const dummyTeam = [
    TeamMember(id: '0774', name: 'Ari Putra', position: 'IT Solution', department: 'ESTATE', leavePlafond: 59, leaveUsed: 42),
    TeamMember(id: '0035', name: 'Aditya Yudha', position: 'IT Solution', department: 'ESTATE', leavePlafond: 55, leaveUsed: 33),
    TeamMember(id: '0047', name: 'Rayhan Putra', position: 'IT Infrastructure', department: 'ESTATE', leavePlafond: 55, leaveUsed: 50),
    TeamMember(id: '0057', name: 'Intan Puspita', position: 'Intern', department: 'ESTATE', leavePlafond: 55, leaveUsed: 15),
    TeamMember(id: '0788', name: 'Noval Sandy Hidayat', position: 'IT Media', department: 'IT & MEDIA', leavePlafond: 49.5, leaveUsed: 37),
  ];

}