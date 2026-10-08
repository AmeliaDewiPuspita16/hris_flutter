import 'indent_approve_status.dart';
import 'indent_progress_status.dart';
import 'indent_request_item.dart';

/// Data contoh "List of User Requests" (diambil dari screenshot web).
/// Nanti diganti repository + API.
class IndentRequestDemoData {
  IndentRequestDemoData._();

  static List<IndentRequestItem> items() => const [
        IndentRequestItem(
          id: 'indent-1',
          name: 'Aulia Rahmatul Jannah',
          destination: 'All Tenant',
          date: '08-10-2026',
          timeRange: '01:00:00 s/d 14:30:00',
          remark: 'Antar Invoice',
          approve: IndentApproveStatus.onWaiting,
          status: IndentProgressStatus.onWaiting,
        ),
        IndentRequestItem(
          id: 'indent-2',
          name: 'Erick Demiska Perwira',
          destination: 'Kost kita dan PHS',
          date: '08-10-2026',
          timeRange: '10:00:00 s/d 11:00:00',
          remark: 'Plotting',
          approve: IndentApproveStatus.onWaiting,
          status: IndentProgressStatus.onWaiting,
        ),
        IndentRequestItem(
          id: 'indent-26',
          name: 'Mahyuddin',
          destination: 'Mandiri & BCA Tanjung Uban',
          date: '06-10-2026',
          timeRange: '13:30:00 s/d 14:30:00',
          remark: 'Setoran & TF',
          vehicle: 'BP 1508 FB',
          approve: IndentApproveStatus.approved,
          status: IndentProgressStatus.onProgress,
          driver: 'M Saragih',
        ),
        IndentRequestItem(
          id: 'indent-27',
          name: 'Rindiani',
          destination: 'Pelabuhan Speed Tanjung Uban',
          date: '06-10-2026',
          timeRange: '11:00:00 s/d 12:00:00',
          remark: 'Pengambilan paper cup untuk resto',
          vehicle: 'BP 1730 FB',
          approve: IndentApproveStatus.approved,
          status: IndentProgressStatus.done,
          driver: 'Febri Rivanov',
          rating: 5,
        ),
        IndentRequestItem(
          id: 'indent-28',
          name: 'Nurhafizhah Putri Andini',
          destination: 'Busung',
          date: '06-10-2026',
          timeRange: '10:30:00 s/d 14:00:00',
          remark: 'Cek dan prepare mangrove',
          vehicle: 'BP 1507 FB',
          approve: IndentApproveStatus.approved,
          status: IndentProgressStatus.onProgress,
        ),
        IndentRequestItem(
          id: 'indent-29',
          name: 'Cahyo Jati Nugroho',
          destination: 'Bionesia',
          date: '06-10-2026',
          timeRange: '10:00:00 s/d 13:00:00',
          remark: 'pengecekan legal compliance Bionesia',
          approve: IndentApproveStatus.onWaiting,
          status: IndentProgressStatus.onWaiting,
        ),
        IndentRequestItem(
          id: 'indent-30',
          name: 'Nurhafizhah Putri Andini',
          destination: 'PBC - Busung - PBC',
          date: '09-10-2026',
          timeRange: '08:00:00 s/d 12:00:00',
          remark: 'Jemput IC mengabdi Mangrove Planting',
          approve: IndentApproveStatus.approved,
          status: IndentProgressStatus.onWaiting,
        ),
      ];
}
