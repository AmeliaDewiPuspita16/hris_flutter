/// Daftar pilihan tetap yang dipakai form HSE Work Request.
///
///(General Checklist, Type of Works, Personal Protective Equipment, Department)
library;

class HseChecklistCatalog {
  HseChecklistCatalog._();

  /// Checklist umum (wajib diisi minimal satu). Opsi terakhir "Lainnya"
  /// ditangani terpisah oleh [HseChecklistGroup] lewat field teks manual,
  /// jadi sengaja tidak diikutkan di sini.
  static const generalChecklist = <String>[
    'Terdapat soft drawing',
    'Timeline pekerjaan tersedia',
    'Tempat kerja bersih dari minyak, gas, dan bahan mudah terbakar',
    'Alat pendeteksi gas dan berfungsi dengan baik',
    'Jika di sekitar area kerja terdapat valve untuk mengisolir '
        'hydrocarbon, sudah ditutup dan diberikan tag',
    'Jika terdapat pekerjaan listrik, sudah diisolasi / diberikan '
        'Lock Out Tag Out (LOTO)',
    'Jika pekerjaan berpotensi menimbulkan kebakaran atau hot work, '
        'terdapat APAR di sekitar area kerja tersebut',
    'Peralatan kerja dalam kondisi baik dan tidak ada tools yang rusak',
    'Melakukan briefing kerja',
    'Tidak melanjutkan pekerjaan ketika cuaca buruk (pekerjaan outdoor)',
    'Rambu di sekitar area kerja dan pembatas area (barrier, safety '
        'perimeter) sudah terpasang',
    'ROA',
  ];

  /// Jenis pekerjaan. Menentukan risiko HSE apa saja yang berlaku untuk
  /// permit ini.
  static const typeOfWorks = <String>[
    'Working at height',
    'Hot work',
    'Heavy equipment operation',
    'Shut down & start up engine generator',
    'Confined space',
    'Maintenance equipment at sea',
    'Electrical',
    'Lifting',
  ];

  /// Alat pelindung diri yang wajib dipakai selama pekerjaan.
  static const personalProtectiveEquipment = <String>[
    'Helm safety',
    'Sepatu safety',
    'Full body harness',
    'Ear plug',
    'Ear muff',
    'Dust mask',
    'Respirator protection',
    'Kacamata safety',
    'Safety shield',
    'Sarung tangan / sarung tangan las',
    'Kedok las',
    'Apron',
  ];

  /// Departemen pemohon, sesuai dropdown "Department" di form web.
  static const departments = <String>[
    'AML',
    'GMO',
    'EST',
    'ENV',
    'SSD',
    'IMS',
    'CDD',
    'HR & GA',
    'POD',
    'BDD',
    'FIN',
    'CRS',
    'HSE',
    'LPK',
    'Others',
  ];
}
