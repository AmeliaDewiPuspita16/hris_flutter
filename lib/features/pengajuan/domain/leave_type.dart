import '../../shared/domain/role.dart';

enum LeaveType { cutiTahunan, cutiSakit, izin, lembur, cutiPengganti, cekKesehatan }

extension LeaveTypeX on LeaveType {
  String get label {
    switch (this) {
      case LeaveType.cutiTahunan:
        return '🌴 Cuti Tahunan';
      case LeaveType.cutiSakit:
        return '🏥 Cuti Sakit';
      case LeaveType.izin:
        return '📝 Izin';
      case LeaveType.lembur:
        return '⏱️ Lembur';
      case LeaveType.cutiPengganti:
        return '🔄 Cuti Pengganti (Off in Lieu)';
      case LeaveType.cekKesehatan:
        return '🩺 Cek Kesehatan';
    }
  }


  /// "Lembur" (saldo & pengajuan pribadi) hanya utk Non-Executive, karena web
  /// mencatat Overtime sebagai "Non Executive (personal), HOD & Admin Dep [VIEW]".
  /// HOD & Admin sementara diperlakukan setara Executive → dapat "Cuti Pengganti"
  /// pribadi. View lembur tim/departemen utk HOD & Admin belum dibangun

  static bool showPersonalLembur(Role role) => role == Role.nonExecutive;

  /// array (bergantung role: lembur hanya utk non-exec,
  /// dan pakai cuti-pengganti).
  static List<LeaveType> optionsFor(Role role) {
    return [
      LeaveType.cutiTahunan,
      LeaveType.cutiSakit,
      LeaveType.izin,
      if (showPersonalLembur(role)) LeaveType.lembur else LeaveType.cutiPengganti,
      LeaveType.cekKesehatan,
    ];
  }
}

/// Padanan "Leave Category" di modul web "Leave Permission" (Requirement
/// Tracking No.7) — dipakai sebagai sub-pilihan saat LeaveType == izin,
/// supaya kategori spesifik dari web tetap muncul di mobile.
enum LeaveCategory { mcSakit, oil, menikahkanAnak, dukaCita, kelebihanJamKerja, lainnya }

extension LeaveCategoryX on LeaveCategory {
  String get label {
    switch (this) {
      case LeaveCategory.mcSakit:
        return 'MC / Sakit';
      case LeaveCategory.oil:
        return 'OIL (Off in Lieu)';
      case LeaveCategory.menikahkanAnak:
        return 'Menikahkan Anak';
      case LeaveCategory.dukaCita:
        return 'Duka Cita';
      case LeaveCategory.kelebihanJamKerja:
        return 'Kelebihan Jam Kerja';
      case LeaveCategory.lainnya:
        return 'Lainnya';
    }
  }
}