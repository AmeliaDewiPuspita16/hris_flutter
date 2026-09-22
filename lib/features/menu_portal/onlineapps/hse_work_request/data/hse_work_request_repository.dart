import '../domain/hse_request_category.dart';
import '../domain/hse_request_status.dart';
import '../domain/hse_work_request.dart';

/// repository ini untuk sementara mengembalikan data demo statis sebelum tersambung API.
///
/// Begitu endpoint-nya siap, cukup ganti isi method di bawah ini dengan
/// pemanggilan `ApiClient` — signature method & model [HseWorkRequest] tidak perlu berubah,
/// jadi layar-layar yang sudah memakai repository ini tidak perlu disentuh.
class HseWorkRequestRepository {
  HseWorkRequestRepository();

  Future<List<HseWorkRequest>> fetchRequests({HseRequestStatus? status}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (status == null) return List.unmodifiable(_demoData);
    return _demoData.where((r) => r.status == status).toList(growable: false);
  }

  Future<HseWorkRequest> fetchDetail(int id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _demoData.firstWhere(
      (r) => r.id == id,
      orElse: () => throw StateError('Permit HSE #$id tidak ditemukan.'),
    );
  }

  /// Mengirim permit baru. Selama belum ada API, cuma menandai draft
  /// sebagai "terkirim" (status On Waiting) supaya alur form bisa dicoba
  /// end-to-end di layar.
  Future<HseWorkRequest> submit(HseWorkRequest draft) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return draft.copyWith(
      id: DateTime.now().millisecondsSinceEpoch,
      idRegister: 'HSE/REG/DRAFT/${DateTime.now().millisecondsSinceEpoch}',
      status: HseRequestStatus.onWaiting,
    );
  }

  static final List<HseWorkRequest> _demoData = [
    HseWorkRequest(
      id: 1017,
      idRegister: 'HSE/REG/2026/09/017',
      pic: 'Diko Despabera Rosdianto',
      department: 'EST',
      category: HseRequestCategory.nonRutin,
      location: 'Jalan Lot 20 PT BIIE',
      materials: 'Genset, kabel las, alat las',
      totalWorkers: 4,
      dateStart: DateTime(2026, 9, 11),
      dateEnd: DateTime(2026, 9, 11),
      generalChecklist: const [
        'Timeline pekerjaan tersedia',
        'Melakukan briefing kerja',
      ],
      typeOfWorks: const [
        'Hot work',
        'Heavy equipment operation',
        'Shut down & start up engine generator',
      ],
      ppe: const ['Helm safety', 'Sepatu safety', 'Ear plug'],
      acknowledgeBy: 'Mulyadi',
      approvalBy: 'Habib Twindy Lubis',
      status: HseRequestStatus.onProgress,
    ),
    HseWorkRequest(
      id: 1093,
      idRegister: 'HSE/REG/2026/08/093',
      pic: 'Alen Pepa',
      department: 'EST',
      category: HseRequestCategory.rutin,
      location: 'STP 1, STP 2, Dorm Kawasan BIE',
      materials: 'Tabung gas, blower',
      totalWorkers: 2,
      dateStart: DateTime(2026, 8, 20),
      dateEnd: DateTime(2026, 8, 20),
      generalChecklist: const ['Alat pendeteksi gas dan berfungsi dengan baik'],
      typeOfWorks: const ['Confined space'],
      ppe: const ['Full body harness', 'Respirator protection'],
      acknowledgeBy: 'Habib Twindy Lubis',
      approvalBy: 'Mulyadi',
      status: HseRequestStatus.onProgress,
    ),
    HseWorkRequest(
      id: 7,
      idRegister: 'HSE/REG/2026/08/007',
      pic: 'Reynold Pandiangan',
      department: 'FIN',
      category: HseRequestCategory.rutin,
      location: 'PH 2 & RWPS',
      materials: '-',
      totalWorkers: 1,
      dateStart: DateTime(2026, 8, 18),
      dateEnd: DateTime(2026, 8, 18),
      generalChecklist: const [],
      typeOfWorks: const [],
      ppe: const [],
      approvalBy: 'Habib Twindy Lubis',
      status: HseRequestStatus.onWaiting,
    ),
    HseWorkRequest(
      id: 16,
      idRegister: 'HSE/REG/2026/09/016',
      pic: 'Reza Zulfiansyah',
      department: 'EVD',
      category: HseRequestCategory.rutin,
      location: 'BIEV depan pos security',
      materials: 'Gerinda potong, APAR',
      totalWorkers: 3,
      dateStart: DateTime(2026, 9, 2),
      dateEnd: DateTime(2026, 9, 2),
      generalChecklist: const [
        'Peralatan kerja dalam kondisi baik dan tidak ada tools yang rusak',
      ],
      typeOfWorks: const ['Hot work'],
      otherTypeOfWork: 'Trimming bafia',
      ppe: const ['Helm safety', 'Kacamata safety', 'Sarung tangan / sarung tangan las'],
      acknowledgeBy: 'Habib Twindy Lubis',
      approvalBy: 'Kiki Mulyadi',
      status: HseRequestStatus.done,
    ),
    HseWorkRequest(
      id: 2025903,
      idRegister: 'HSE/REG/2025/09/003',
      pic: 'Anastacia Febriyanti Sibarani',
      department: 'EST',
      category: HseRequestCategory.nonRutin,
      location: 'WTP 03',
      materials: 'Tangga, tali pengaman',
      totalWorkers: 2,
      dateStart: DateTime(2025, 9, 22),
      dateEnd: DateTime(2025, 9, 22),
      generalChecklist: const [],
      typeOfWorks: const ['Working at height', 'Hot work'],
      ppe: const [],
      status: HseRequestStatus.reject,
    ),
  ];
}
