import '../../../../../core/network/api_exception.dart';
import '../domain/observation_category.dart';
import '../domain/observation_item.dart';
import '../domain/observation_status.dart';

/// Repository Observation Department yang masih memakai DATA DEMO di memori
/// karena endpoint-nya belum ada. Polanya sama dengan
/// `InventoryStationeryRepository`: konstruktor tanpa `ApiClient`, dan layar
/// membuat sendiri instance-nya. Layar Add / Detail harus memakai instance
/// yang SAMA dengan layar daftar (dioper lewat parameter `repository`).
///
/// Perubahan (add, close) tersimpan selama instance ini hidup. Begitu
/// endpoint siap: tambahkan `ApiClient` ke konstruktor, daftarkan di
/// `RepositoryProvider`, lalu ganti isi tiap method — signature-nya tidak
/// perlu berubah.
class ObservationRepository {
  ObservationRepository() {
    _items.addAll(_seed());
  }

  /// Jeda buatan supaya skeleton dan loading state tampak seperti API sungguhan.
  static const _latency = Duration(milliseconds: 450);

  /// User & departemen "milik sendiri" pada data demo (sama dengan user di web).
  static const _meName = 'Aditya Yudha Pratama';
  static const _meDept = 'ITM';

  /// Pilihan "Relevant Dept." (form Add & filter). Diambil dari data di
  /// screenshot web; ganti dengan daftar dari server.
  static const departments = <String>[
    'CDD',
    'ENV',
    'EST',
    'HR & GA',
    'HSE',
    'ITM',
  ];

  final List<ObservationItem> _items = [];
  int _nextId = 100;

  /// Tabel "Request Table - OPEN Observations from Your Department".
  Future<List<ObservationItem>> fetchOpenFromMyDept() async {
    await Future<void>.delayed(_latency);
    return _sorted(_items.where((i) => i.canClose));
  }

  /// Tabel "All Observations": semua observasi, terbaru di atas.
  Future<List<ObservationItem>> fetchAll() async {
    await Future<void>.delayed(_latency);
    return _sorted(_items);
  }

  /// Form "Add Observation". [imagePath] opsional (png/jpg/jpeg, maks 2 MB —
  /// divalidasi di layar).
  Future<ObservationItem> add({
    required ObservationCategory category,
    String? subCategory,
    required DateTime dateFinding,
    required String relevantDept,
    required String location,
    required String description,
    String? imagePath,
  }) async {
    await Future<void>.delayed(_latency);

    final item = ObservationItem(
      id: '${_nextId++}',
      createdDate: dateFinding,
      reporterName: _meName,
      reporterDept: _meDept,
      category: category,
      subCategory: subCategory,
      location: location,
      relevantDept: relevantDept,
      description: description,
      status: ObservationStatus.open,
      isFromMyDept: true,
      isMine: true,
      findingImage: imagePath,
    );
    _items.add(item);
    return item;
  }

  /// Form "Edit Observation": field sama dengan Add. Hanya milik sendiri
  /// yang masih open ([ObservationItem.canModify]).
  Future<ObservationItem> update(
    String id, {
    required ObservationCategory category,
    String? subCategory,
    required DateTime dateFinding,
    required String relevantDept,
    required String location,
    required String description,
    String? imagePath,
  }) async {
    await Future<void>.delayed(_latency);

    final index = _indexOfModifiable(id);
    final current = _items[index];
    final updated = ObservationItem(
      id: current.id,
      createdDate: dateFinding,
      reporterName: current.reporterName,
      reporterDept: current.reporterDept,
      category: category,
      subCategory: subCategory,
      location: location,
      relevantDept: relevantDept,
      description: description,
      status: current.status,
      isFromMyDept: current.isFromMyDept,
      isMine: current.isMine,
      findingImage: imagePath,
    );
    _items[index] = updated;
    return updated;
  }

  /// Hapus observasi milik sendiri yang masih open
  Future<void> delete(String id) async {
    await Future<void>.delayed(_latency);
    _items.removeAt(_indexOfModifiable(id));
  }

  int _indexOfModifiable(String id) {
    final index = _items.indexWhere((i) => i.id == id);
    if (index < 0) {
      throw const ApiException.server('This observation no longer exists.');
    }
    if (!_items[index].canModify) {
      throw const ApiException.server(
        'You can only change your own open observations.',
      );
    }
    return index;
  }

  /// Form "Close Observation": alasan wajib, foto opsional.
  Future<ObservationItem> close(
    String id, {
    required String reason,
    String? imagePath,
  }) async {
    await Future<void>.delayed(_latency);

    final index = _items.indexWhere((i) => i.id == id);
    if (index < 0) {
      throw const ApiException.server('This observation no longer exists.');
    }
    final current = _items[index];
    if (!current.canClose) {
      throw const ApiException.server(
        'This observation cannot be closed by your department.',
      );
    }

    final closed = current.copyWith(
      status: ObservationStatus.closed,
      closeReason: reason,
      closeDate: DateTime.now(),
      closedBy: _meName,
      closeImage: imagePath,
    );
    _items[index] = closed;
    return closed;
  }

  List<ObservationItem> _sorted(Iterable<ObservationItem> items) {
    final list = items.toList()
      ..sort((a, b) {
        final byDate = b.createdDate.compareTo(a.createdDate);
        if (byDate != 0) return byDate;
        return int.parse(b.id).compareTo(int.parse(a.id));
      });
    return list;
  }

  /// Data awal: baris-baris dari screenshot web.
  List<ObservationItem> _seed() => [
        ObservationItem(
          id: '1',
          createdDate: DateTime(2026, 3, 9),
          reporterName: _meName,
          reporterDept: _meDept,
          category: ObservationCategory.quality,
          location:
              'Area Bionesia, Kost Kita Block 01, atau area yang memiliki plang Parkir',
          relevantDept: 'ENV',
          description:
              'Rambu plang parkiran segera dilepas karena sudah tidak layak lagi',
          status: ObservationStatus.open,
          isFromMyDept: true,
          isMine: true
        ),
        ObservationItem(
          id: '2',
          createdDate: DateTime(2026, 3, 9),
          reporterName: _meName,
          reporterDept: _meDept,
          category: ObservationCategory.quality,
          location: 'Driver Room Wisma BIIE',
          relevantDept: 'HR & GA',
          description:
              'Disarankan memasang label ruangan driver room, agar karyawan/ti mengetahui letak ruangan driver room',
          status: ObservationStatus.open,
          isFromMyDept: true,
          isMine: true
        ),
        ObservationItem(
          id: '3',
          createdDate: DateTime(2024, 4, 29),
          reporterName: 'Setya Budi Prabowo',
          reporterDept: 'CDD',
          category: ObservationCategory.safety,
          subCategory: 'Nearmiss',
          location: 'Tempat parkir dorm blok 5',
          relevantDept: 'EST',
          description:
              'Muatan motor roda tiga Dept Estate (besi) menjulur ke badan jalan saat diparkir di dorm blok 5. Berpotensi bahaya kecelakaan/ kerugian (materil/korban jiwa) bagi pengendara lain.',
          status: ObservationStatus.closed,
          isFromMyDept: false,
          isMine: false,
          closeDate: DateTime(2024, 4, 30),
          closeReason: 'N/A',
          closedBy: 'N/A',
        ),
        ObservationItem(
          id: '4',
          createdDate: DateTime(2024, 5, 7),
          reporterName: 'Ade Tri Septian',
          reporterDept: 'EST',
          category: ObservationCategory.safety,
          subCategory: 'Nearmiss',
          location: 'WISMA BIE',
          relevantDept: 'HR & GA',
          description:
              'Belum ada sign tanda arah panah naik ataupun turun di tangga emergency wisma',
          status: ObservationStatus.closed,
          isFromMyDept: false,
          isMine: false,
        ),
        ObservationItem(
          id: '5',
          createdDate: DateTime(2024, 5, 12),
          reporterName: 'Salsabila Cahyanti',
          reporterDept: 'HSE',
          category: ObservationCategory.safety,
          subCategory: 'Unsafe condition',
          location: 'Pintu samping wisma BIIE',
          relevantDept: 'HSE',
          description:
              'Antislip di pintu samping area absensi karyawan sudah tidak bekerja maksimal perlu adanya penggantian antislip',
          status: ObservationStatus.closed,
          isFromMyDept: false,
          isMine: false,
        ),
        ObservationItem(
          id: '6',
          createdDate: DateTime(2024, 5, 21),
          reporterName: 'Ade Tri Septian',
          reporterDept: 'EST',
          category: ObservationCategory.safety,
          subCategory: 'Nearmiss',
          location: 'Jalan Matahari',
          relevantDept: 'EST',
          description:
              'Terdapat potongan dahan ranting di jalan matahari dari wisma arah PT Majapahit, sehingga membahayakan pengendara yang melintas',
          status: ObservationStatus.closed,
          isFromMyDept: false,
          isMine: false,
        ),
      ];
}
