import 'list_request_item.dart';
import 'list_request_status.dart';

/// Data contoh untuk tab "List Request" tim IT.
class ListRequestDemoData {
  ListRequestDemoData._();

  static List<ListRequestItem> items() => [
        const ListRequestItem(
          id: 'list-1',
          requesterName: 'Fadel Satriawan',
          department: 'BDD',
          description:
              'Design kebutuhan Tropical Night Run, detail terlampir di WA',
          status: ListRequestStatus.onWaiting,
          date: '16 Sep 2026',
        ),
        const ListRequestItem(
          id: 'list-2',
          requesterName: 'Erick Demiska Perwira',
          department: 'CRS',
          description: 'Menyediakan clipon untuk konten media sosial hari Kamis',
          status: ListRequestStatus.onWaiting,
          date: '16 Sep 2026',
        ),
        const ListRequestItem(
          id: 'list-3',
          requesterName: 'Agnes Bellyntiarini Wijayanti',
          department: 'CRS',
          description:
              'Undangan acara Ground Breaking Port A1, 22 Sep jam 10.00 WIB',
          status: ListRequestStatus.onWaiting,
          date: '15 Sep 2026',
        ),
        const ListRequestItem(
          id: 'list-4',
          requesterName: 'Frida Khaerani',
          department: 'HR & GA',
          description:
              'Sound system, proyektor, 2 mic & 1 pointer untuk kegiatan KISS',
          status: ListRequestStatus.onProgress,
          date: '08 Sep 2026',
        ),
        const ListRequestItem(
          id: 'list-5',
          requesterName: 'Irma Hardianti',
          department: 'EVD',
          description:
              'Design banner Orchid Meeting Room di Simpang Harapan Baru',
          status: ListRequestStatus.onProgress,
          date: '18 Aug 2026',
        ),
      ];
}
