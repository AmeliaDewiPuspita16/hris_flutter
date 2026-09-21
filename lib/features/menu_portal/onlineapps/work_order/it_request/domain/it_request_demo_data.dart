import 'it_request_item.dart';
import 'it_request_status.dart';
import 'request_category.dart';
import 'support_type.dart';

/// Data contoh SEMUA permintaan IT/Media — bukan cuma milik satu staff,
/// mengikuti tabel "Form IT & Media" di versi web yang menampilkan semua
/// requestor.
///
/// Ada satu item [ItRequestStatus.completed] dengan `awaitingFeedback: true`
/// supaya perilaku tombol "+ Add Request" (tersembunyi sampai feedback
/// diberikan) langsung kelihatan begitu halaman ini dibuka.
class ItRequestDemoData {
  ItRequestDemoData._();

  static List<ItRequestItem> items() => [
        const ItRequestItem(
          id: 'req-1',
          requesterName: 'Karmin',
          department: 'GA',
          category: RequestCategory.media,
          supportType: SupportType.repair,
          description:
              'Dear Team Media, mohon untuk cetak ulang, karena gambar '
              'sudah pudar, gambar terlampir terimakasih.',
          date: '17 Sep 2026',
          status: ItRequestStatus.waitingHod,
        ),
        const ItRequestItem(
          id: 'req-2',
          requesterName: 'Diko Despabera Rosdianto',
          department: 'ENG',
          category: RequestCategory.it,
          supportType: SupportType.request,
          description:
              'Dear Team IT, mohon untuk pemasangan kabel DP untuk '
              'pemakaian dua monitor di PC-nya Khairul untuk keperluan '
              'Design & Perencanaan. Terima Kasih',
          date: '17 Sep 2026',
          status: ItRequestStatus.waitingHod,
        ),
        const ItRequestItem(
          id: 'req-3',
          requesterName: 'Prisilia Cahya Putri Sarena',
          department: 'Procurement',
          category: RequestCategory.it,
          supportType: SupportType.request,
          description:
              'Dear tim IT mohon bantuannya untuk dapat memberikan akses '
              '(Penambahan Role E-Procurement) untuk mempermudah '
              'verifikasi trial E-Procurement selama masa trial sampai '
              'bulan Oktober 2026. Terima Kasih atas bantuannya tim IT',
          date: '16 Sep 2026',
          status: ItRequestStatus.approved,
        ),
        const ItRequestItem(
          id: 'req-4',
          requesterName: 'Anda',
          department: '-',
          category: RequestCategory.it,
          supportType: SupportType.repair,
          description: 'Perbaikan print WWTP, warna merah tidak keluar',
          date: '15 Sep 2026',
          status: ItRequestStatus.onProgress,
        ),
        const ItRequestItem(
          id: 'req-5',
          requesterName: 'Fadel Satriawan',
          department: 'BDD',
          category: RequestCategory.media,
          supportType: SupportType.request,
          description:
              'Dear Team IT Media, Mohon Bantuan utk Design kebutuhan '
              'Tropical Night Run, sesuai detail terlampir di WA '
              'Terimakasih',
          date: '14 Sep 2026',
          status: ItRequestStatus.approved,
        ),
        const ItRequestItem(
          id: 'req-6',
          requesterName: 'Erick Demiska Perwira',
          department: 'CRS',
          category: RequestCategory.it,
          supportType: SupportType.request,
          description:
              'Dear Tim ITM, Mohon bantuannya untuk menyediakan clipon '
              'untuk keperluan konten media sosial yang akan dilakukan '
              'pada hari Kamis, 17 September 2026. Terimakasih.',
          date: '13 Sep 2026',
          status: ItRequestStatus.rejected,
        ),
        const ItRequestItem(
          id: 'req-7',
          requesterName: 'Putri Afifah Yasmine',
          department: 'HR & GA',
          category: RequestCategory.it,
          supportType: SupportType.return_,
          description:
              'Dear IT Team, mohon bantuannya untuk dinonaktifkan akun '
              'portal a.n. Nursiwan, terima kasih.',
          date: '11 Sep 2026',
          status: ItRequestStatus.completed,
        ),
        const ItRequestItem(
          id: 'req-8',
          requesterName: 'Anda',
          department: '-',
          category: RequestCategory.it,
          supportType: SupportType.request,
          description:
              'Setting sound system, proyektor & 2 mic untuk kegiatan KISS',
          date: '10 Sep 2026',
          status: ItRequestStatus.completed,
          awaitingFeedback: true,
        ),
      ];
}
