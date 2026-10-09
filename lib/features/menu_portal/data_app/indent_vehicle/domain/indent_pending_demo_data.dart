import 'indent_pending_item.dart';

/// Data contoh tab "Pending Vehicle Assignment" + daftar driver untuk
/// dropdown (dari screenshot web). Nanti diganti repository + API.
class IndentPendingDemoData {
  IndentPendingDemoData._();

  static List<IndentPendingItem> items() => const [
        IndentPendingItem(
          id: 'pending-1',
          name: 'Marsa Aulia',
          destination: 'Lagoi (Yayasan Bintan Resorts)',
          date: '10-10-2026',
          timeRange: '15:30:00 s/d 16:30:00',
          remark: 'Jemput setelah support dokumentasi SMEX (rangkaian HUT YBR)',
          withDriver: true,
        ),
        IndentPendingItem(
          id: 'pending-2',
          name: 'Singkat Sinaga',
          destination: 'Tanjung Uban',
          date: '07-10-2026',
          timeRange: '14:30:00 s/d 16:00:00',
          remark: 'Order Sign TPS Port',
          withDriver: false,
        ),
        IndentPendingItem(
          id: 'pending-3',
          name: 'Noval',
          destination: 'tanjungpinang',
          date: '07-10-2026',
          timeRange: '11:00:00 s/d 14:00:00',
          remark: 'tanjungpinang',
          withDriver: true,
        ),
        IndentPendingItem(
          id: 'pending-4',
          name: 'Imelda Ayu Kinanti',
          destination: 'Pelabuhan Speed Tanjung Uban',
          date: '07-10-2026',
          timeRange: '07:00:00 s/d 08:00:00',
          remark: 'Anter Bu Nancy & Pak Reynold',
          withDriver: true,
        ),
        IndentPendingItem(
          id: 'pending-5',
          name: 'Nurhafizhah Putri Andini',
          destination: 'PBC - Busung - PBC',
          date: '09-10-2026',
          timeRange: '08:00:00 s/d 16:48:00',
          remark: 'Jemput IC mengabdi Mangrove Planting (6 orang)',
          withDriver: true,
        ),
      ];

  /// Isi dropdown "Driver" di popup Assign Vehicle.
  static const drivers = [
    'Arief Pratama',
    'Moh Yogi',
    'Febri Rivanov',
    'M Saragih',
    'Nizar',
    'Suko',
  ];
}
