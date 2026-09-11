import 'package:flutter/material.dart';

import '../../shared/domain/role.dart';

enum LeaveType {
  cutiTahunan,
  izin,
  lembur,
  cutiPengganti,
  cekKesehatan,
}

extension LeaveTypeX on LeaveType {
  String get label {
    switch (this) {
      case LeaveType.cutiTahunan:
        return 'Cuti Tahunan';

      case LeaveType.izin:
        return 'Izin';

      case LeaveType.lembur:
        return 'Lembur';

      case LeaveType.cutiPengganti:
        return 'Cuti Pengganti';

      case LeaveType.cekKesehatan:
        return 'Cek Kesehatan';
    }
  }

  IconData get icon {
    switch (this) {
      case LeaveType.cutiTahunan:
        return Icons.beach_access_outlined;

      case LeaveType.izin:
        return Icons.assignment_turned_in_outlined;

      case LeaveType.lembur:
        return Icons.more_time_outlined;

      case LeaveType.cutiPengganti:
        return Icons.event_available_outlined;

      case LeaveType.cekKesehatan:
        return Icons.medical_information_outlined;
    }
  }

  /// Lembur pribadi hanya untuk Non-Executive.
  static bool showPersonalLembur(Role role) {
    return role == Role.nonExecutive;
  }

  /// Pilihan jenis pengajuan berdasarkan role.
  static List<LeaveType> optionsFor(Role role) {
    return [
      LeaveType.cutiTahunan,
      LeaveType.izin,
      if (showPersonalLembur(role))
        LeaveType.lembur
      else
        LeaveType.cutiPengganti,
      LeaveType.cekKesehatan,
    ];
  }
}

/// Padanan "Leave Category" dari HRIS Web.
///
/// Untuk sementara data dibuat statis.
/// Nanti ketika API sudah tersedia, enum ini dapat diganti
/// dengan model dari response API.
enum LeaveCategory {
  dukaCita,
  cutiHaji,
  keluargaDirawat,
  khitanBaptisAnak,
  cutiMelahirkan,
  dinasLuar,
  istriMelahirkan,
  kelebihanJamKerja,
  mcSakit,
  kewajibanNegara,
  menikah,
  menikahkanAnak,
  oil,
  publicHoliday,
  permission,
  unpaidLeave,
}

extension LeaveCategoryX on LeaveCategory {
  /// Kode mengikuti Leave Category pada HRIS Web.
  String get code {
    switch (this) {
      case LeaveCategory.dukaCita:
        return 'CD';

      case LeaveCategory.cutiHaji:
        return 'CH';

      case LeaveCategory.keluargaDirawat:
        return 'CIA';

      case LeaveCategory.khitanBaptisAnak:
        return 'CK';

      case LeaveCategory.cutiMelahirkan:
        return 'CML';

      case LeaveCategory.dinasLuar:
        return 'DL';

      case LeaveCategory.istriMelahirkan:
        return 'IM';

      case LeaveCategory.kelebihanJamKerja:
        return 'KJK';

      case LeaveCategory.mcSakit:
        return 'MC';

      case LeaveCategory.kewajibanNegara:
        return 'MKN';

      case LeaveCategory.menikah:
        return 'MR';

      case LeaveCategory.menikahkanAnak:
        return 'MRA';

      case LeaveCategory.oil:
        return 'OIL';

      case LeaveCategory.publicHoliday:
        return 'PH';

      case LeaveCategory.permission:
        return 'PS';

      case LeaveCategory.unpaidLeave:
        return 'UPL';
    }
  }

  String get label {
    switch (this) {
      case LeaveCategory.dukaCita:
        return 'Duka Cita';

      case LeaveCategory.cutiHaji:
        return 'Cuti Haji';

      case LeaveCategory.keluargaDirawat:
        return 'Istri/Suami/Anak Dirawat';

      case LeaveCategory.khitanBaptisAnak:
        return 'Khitan/Baptis Anak';

      case LeaveCategory.cutiMelahirkan:
        return 'Cuti Melahirkan';

      case LeaveCategory.dinasLuar:
        return 'Dinas Luar';

      case LeaveCategory.istriMelahirkan:
        return 'Istri Melahirkan';

      case LeaveCategory.kelebihanJamKerja:
        return 'Kelebihan Jam Kerja';

      case LeaveCategory.mcSakit:
        return 'MC/Sakit';

      case LeaveCategory.kewajibanNegara:
        return 'Menjalankan Kewajiban Negara';

      case LeaveCategory.menikah:
        return 'Menikah';

      case LeaveCategory.menikahkanAnak:
        return 'Menikahkan Anak';

      case LeaveCategory.oil:
        return 'OIL (Off In Lieu)';

      case LeaveCategory.publicHoliday:
        return 'Public Holiday';

      case LeaveCategory.permission:
        return 'Permission';

      case LeaveCategory.unpaidLeave:
        return 'Unpaid Leave';
    }
  }

  IconData get icon {
    switch (this) {
      case LeaveCategory.dukaCita:
        return Icons.sentiment_dissatisfied_outlined;

      case LeaveCategory.cutiHaji:
        return Icons.mosque_outlined;

      case LeaveCategory.keluargaDirawat:
        return Icons.local_hospital_outlined;

      case LeaveCategory.khitanBaptisAnak:
        return Icons.celebration_outlined;

      case LeaveCategory.cutiMelahirkan:
        return Icons.pregnant_woman_outlined;

      case LeaveCategory.dinasLuar:
        return Icons.business_center_outlined;

      case LeaveCategory.istriMelahirkan:
        return Icons.child_friendly_outlined;

      case LeaveCategory.kelebihanJamKerja:
        return Icons.more_time_outlined;

      case LeaveCategory.mcSakit:
        return Icons.medical_services_outlined;

      case LeaveCategory.kewajibanNegara:
        return Icons.account_balance_outlined;

      case LeaveCategory.menikah:
        return Icons.favorite_border;

      case LeaveCategory.menikahkanAnak:
        return Icons.family_restroom_outlined;

      case LeaveCategory.oil:
        return Icons.event_available_outlined;

      case LeaveCategory.publicHoliday:
        return Icons.calendar_month_outlined;

      case LeaveCategory.permission:
        return Icons.assignment_turned_in_outlined;

      case LeaveCategory.unpaidLeave:
        return Icons.money_off_outlined;
    }
  }

  /// Semua kategori Leave Category untuk sementara.
  static List<LeaveCategory> get all => LeaveCategory.values;
}