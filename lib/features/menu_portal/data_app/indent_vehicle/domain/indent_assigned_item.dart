import '../../../../../core/utils/json_value.dart';
import 'indent_json.dart';

/// Posisi tanggal perjalanan terhadap hari ini — untuk penanda di kartu
/// driver dan peringatan saat Finish.
enum IndentDayState { overdue, today, tomorrow, upcoming, unknown }

/// Satu perjalanan yang ditugaskan ke driver yang sedang login — baris di
/// tab "My Assignments".
///
/// Berasal dari `GET /api/indent/admin/list`, yang untuk role `driver`
/// berisi indent yang sudah di-approve HOD dan ditugaskan ke dirinya
/// (`status = 1`). Server yang menyaring per driver, bukan aplikasi.
class IndentAssignedItem {
  const IndentAssignedItem({
    required this.id,
    required this.name,
    required this.destination,
    required this.date,
    required this.timeRange,
    required this.remark,
    this.vehicle,
    this.day,
    this.startsAt,
  });

  final String id;

  /// Nama peminta (penumpang), BUKAN nama driver.
  final String name;
  final String destination;

  /// Tanggal pemakaian untuk ditampilkan, mis. '20-10-2026'.
  final String date;

  /// Rentang jam, mis. '08:00 to 17:00'.
  final String timeRange;
  final String remark;

  /// Plat kendaraan. Seharusnya selalu ada: perjalanan di daftar driver pasti
  /// request "With driver", dan plat wajib diisi admin saat Assign. (Request
  /// tanpa driver — menyetir sendiri — tidak pernah masuk daftar driver.)
  ///
  /// Tetap nullable karena contoh respons di dokumentasi API tidak memuat
  /// `kendaraan` di baris admin/list; kalau server ternyata tidak
  /// mengirimnya, kartu menyembunyikan chip plat alih-alih gagal dimuat.
  final String? vehicle;

  /// Tanggal pemakaian (tanpa jam) untuk penanda dan pengurutan. Null bila
  /// server mengirim format yang tidak dikenali.
  final DateTime? day;

  /// [day] ditambah jam pergi, untuk mengurutkan perjalanan di hari yang
  /// sama. Null bila jam pergi tidak terbaca.
  final DateTime? startsAt;

  /// Posisi [day] terhadap hari ini. [now] hanya untuk test.
  IndentDayState dayState([DateTime? now]) {
    final d = day;
    if (d == null) return IndentDayState.unknown;

    final n = now ?? DateTime.now();
    final gap = DateTime.utc(d.year, d.month, d.day)
        .difference(DateTime.utc(n.year, n.month, n.day))
        .inDays;

    if (gap < 0) return IndentDayState.overdue;
    if (gap == 0) return IndentDayState.today;
    if (gap == 1) return IndentDayState.tomorrow;
    return IndentDayState.upcoming;
  }

  /// Urutan daftar driver: perjalanan paling awal di atas, jadi yang
  /// terlewat (belum ditutup) dan yang hari ini terlihat lebih dulu. Yang
  /// tanggalnya tidak terbaca di paling bawah.
  static int bySchedule(IndentAssignedItem a, IndentAssignedItem b) {
    final x = a.startsAt ?? a.day;
    final y = b.startsAt ?? b.day;

    if (x == null && y == null) return _byId(a, b);
    if (x == null) return 1;
    if (y == null) return -1;

    final c = x.compareTo(y);
    return c != 0 ? c : _byId(a, b);
  }

  static int _byId(IndentAssignedItem a, IndentAssignedItem b) =>
      (int.tryParse(a.id) ?? 0).compareTo(int.tryParse(b.id) ?? 0);

  /// Melempar [FormatException] bila `id` tidak ada.
  factory IndentAssignedItem.fromJson(Map<String, dynamic> json) {
    final id = indentInt(json['id']);
    if (id == null) throw const FormatException('Indent tanpa id');

    final userId = indentInt(json['id_user']);
    final day = _parseDay(json['tanggal_pemakaian']);

    return IndentAssignedItem(
      id: '$id',
      name: textOrNull(json['name']) ??
          (userId == null ? '-' : 'User #$userId'),
      destination: textOrNull(json['tujuan']) ?? '-',
      date: indentDate(json['tanggal_pemakaian']),
      timeRange: indentTimeRange(json),
      remark: textOrNull(json['keperluan']) ?? '-',
      vehicle: textOrNull(json['kendaraan']),
      day: day,
      startsAt: _withTime(day, json['jam_pergi']),
    );
  }

  /// 'YYYY-MM-DD' (format admin/list menurut dokumentasi), boleh diikuti
  /// jam. Format lain -> null.
  static DateTime? _parseDay(dynamic raw) {
    final text = textOrNull(raw);
    if (text == null) return null;

    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(text);
    if (m == null) return null;
    return DateTime(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
  }

  static DateTime? _withTime(DateTime? day, dynamic raw) {
    final text = textOrNull(raw);
    if (day == null || text == null) return null;

    final m = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(text);
    if (m == null) return null;
    return DateTime(
      day.year,
      day.month,
      day.day,
      int.parse(m[1]!),
      int.parse(m[2]!),
    );
  }
}
