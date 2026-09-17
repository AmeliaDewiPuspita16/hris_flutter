import 'it_request_item.dart';
import 'it_request_status.dart';

/// Data contoh riwayat permintaan IT/Media milik staff yang sedang login.
///
/// Ada satu item [ItRequestStatus.completed] dengan `awaitingFeedback: true`
/// supaya perilaku tombol "+ Ajukan Request" (tersembunyi sampai feedback
/// diberikan) langsung kelihatan begitu halaman ini dibuka.
class ItRequestDemoData {
  ItRequestDemoData._();

  static List<ItRequestItem> myRequests() => [
        const ItRequestItem(
          id: 'req-1',
          description: 'Zoom untuk meeting kickoff PLTS',
          date: '16 Sep 2026',
          status: ItRequestStatus.waitingHod,
        ),
        const ItRequestItem(
          id: 'req-2',
          description: 'Perbaikan print WWTP, warna merah tidak keluar',
          date: '15 Sep 2026',
          status: ItRequestStatus.onProgress,
        ),
        const ItRequestItem(
          id: 'req-3',
          description:
              'Setting sound system, proyektor & 2 mic untuk kegiatan KISS',
          date: '10 Sep 2026',
          status: ItRequestStatus.completed,
          awaitingFeedback: true,
        ),
      ];
}