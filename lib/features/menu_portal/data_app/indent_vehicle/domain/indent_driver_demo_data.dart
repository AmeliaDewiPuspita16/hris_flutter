import 'indent_assigned_item.dart';

/// Data contoh untuk pratinjau tab My Assignments
/// (`FeatureFlags.previewIndentDriverTab`). Bukan data dari server.
///
/// Tanggalnya dibuat relatif terhadap hari ini supaya semua penanda
/// (Overdue, Today, Tomorrow, dan tanggal biasa) ikut terlihat, dan sengaja
/// tidak berurutan untuk memperlihatkan pengurutan.
class IndentDriverDemoData {
  IndentDriverDemoData._();

  static List<IndentAssignedItem> items([DateTime? now]) {
    final t = now ?? DateTime.now();
    final today = DateTime(t.year, t.month, t.day);

    IndentAssignedItem trip({
      required int id,
      required int dayOffset,
      required String name,
      required String destination,
      required String timeRange,
      required String remark,
      required String vehicle,
      required int startHour,
      int startMinute = 0,
    }) {
      final d = DateTime(today.year, today.month, today.day + dayOffset);
      return IndentAssignedItem(
        id: '$id',
        name: name,
        destination: destination,
        date: '${_two(d.day)}-${_two(d.month)}-${d.year}',
        timeRange: timeRange,
        remark: remark,
        vehicle: vehicle,
        day: d,
        startsAt: DateTime(d.year, d.month, d.day, startHour, startMinute),
      );
    }

    return [
      trip(
        id: 9003,
        dayOffset: 3,
        name: 'Rudi Hartono',
        destination: 'Pelabuhan Batu Ampar',
        timeRange: '13:00 to 16:30',
        remark: 'Pengambilan sparepart di pelabuhan, bawa surat jalan dan '
            'form penerimaan barang',
        vehicle: 'BP 9012 ZZ',
        startHour: 13,
      ),
      trip(
        id: 9001,
        dayOffset: 0,
        name: 'Ari Putra',
        destination: 'Kantor Pusat BIIE',
        timeRange: '08:00 to 17:00',
        remark: 'Antar dokumen ke client',
        vehicle: 'BP 1234 XX',
        startHour: 8,
      ),
      trip(
        id: 9004,
        dayOffset: -1,
        name: 'Maya Sari',
        destination: 'Rumah Sakit Awal Bros',
        timeRange: '09:00 to 11:00',
        remark: 'Antar karyawan kontrol kesehatan',
        vehicle: 'BP 3456 AB',
        startHour: 9,
      ),
      trip(
        id: 9002,
        dayOffset: 1,
        name: 'Dewi Lestari',
        destination: 'Bandara RHF',
        timeRange: '06:30 to 10:00',
        remark: 'Jemput tamu dari Jakarta',
        vehicle: 'BP 5678 YY',
        startHour: 6,
        startMinute: 30,
      ),
    ];
  }

  static String _two(int n) => n.toString().padLeft(2, '0');
}
