import '../domain/master_document.dart';

/// Sumber data dokumen master IMS Document (Manual, SOP, WI, Form, ANNEX,
/// Form Template — satu method per tab di [MasterDocumentFileScreen]).
///
/// Repository ini untuk sementara mengembalikan data demo statis sebelum
/// tersambung API — pola sama dengan `HseWorkRequestRepository`. Karena itu
/// constructor-nya sengaja tanpa `ApiClient` dan screen-nya membuat sendiri
/// instance-nya (tidak lewat `RepositoryProvider` di `main.dart`).
///
/// Begitu endpoint-nya siap: tambahkan lagi `ApiClient` ke constructor,
/// daftarkan lewat `RepositoryProvider` di `main.dart` (sama seperti
/// `ProcurementRepository`/`ItRequestRepository`), dan ganti isi method di
/// bawah ini dengan pemanggilan `ApiClient` — signature method & model
/// [MasterDocument] tidak perlu berubah.
///
/// Tab selain Manual (SOP, WI, Form, ANNEX, Form Template) sengaja belum
/// dibuatkan method-nya — [MasterDocumentFileScreen] menampilkan
/// placeholder "Segera hadir" untuk tab-tab itu sampai giliran masing-
/// masing dikerjakan.
class MasterDocumentRepository {
  MasterDocumentRepository();

  static const _simulatedLatency = Duration(milliseconds: 500);

  /// Dokumen pada tab "Manual".
  Future<List<MasterDocument>> fetchManualDocuments() async {
    await Future.delayed(_simulatedLatency);

    return const [
      MasterDocument(
        docNo: 'BIIE-IM-001/Annex 2-1',
        title: 'SASARAN SISTEM MANAJEMEN TERPADU',
        hierarchy: 'IMS',
        downloadUrl: 'dummy://biie-im-001-annex-2-1',
      ),
      MasterDocument(
        docNo: 'BIIE-IM-001 Rev 4',
        title: 'Manual Sistem Manajemen Terpadu ISO 9001:2015 & 14001:2015',
        hierarchy: 'IMS',
        downloadUrl: 'dummy://biie-im-001-rev-4',
      ),
      MasterDocument(
        docNo: 'BIIE-IM-001/Annex 1-1',
        title: 'Kebijakan Sistem Manajemen Terpadu',
        hierarchy: 'IMS',
        downloadUrl: 'dummy://biie-im-001-annex-1-1',
      ),
      MasterDocument(
        docNo: 'BIIE-IM-001/Annex 3-3',
        title: 'Business Process',
        hierarchy: 'IMS',
        downloadUrl: 'dummy://biie-im-001-annex-3-3',
      ),
      MasterDocument(
        docNo: 'BIIE-IM-001/Annex 4-6',
        title: 'Isu Internal dan Eksternal',
        hierarchy: 'IMS',
        downloadUrl: 'dummy://biie-im-001-annex-4-6',
      ),
      MasterDocument(
        docNo: 'BIIE-IM-001/Annex 5-5',
        title: 'Kebutuhan dan Harapan Pihak-Pihak Berkepentingan',
        hierarchy: 'IMS',
        downloadUrl: 'dummy://biie-im-001-annex-5-5',
      ),
      MasterDocument(
        docNo: 'BIIE-HM-001 Rev 4',
        title: 'Sistem Jaminan Produk Halal',
        hierarchy: 'IMS',
        downloadUrl: 'dummy://biie-hm-001-rev-4',
      ),
      MasterDocument(
        docNo: 'BIIE-HM-001/Annex 1-4',
        title: 'Surat Keputusan Tim Manajemen Halal',
        hierarchy: 'IMS',
        downloadUrl: 'dummy://biie-hm-001-annex-1-4',
      ),
      MasterDocument(
        docNo: 'BIIE-HM-001/Annex 2-4',
        title: 'Struktur Organisasi Tim Manajemen Halal',
        hierarchy: 'IMS',
        downloadUrl: 'dummy://biie-hm-001-annex-2-4',
      ),
      MasterDocument(
        docNo: 'BIIE-HM-001/Annex 3-1',
        title: 'Daftar Bahan yang digunakan untuk Produk Air Bersih',
        hierarchy: 'IMS',
        downloadUrl: 'dummy://biie-hm-001-annex-3-1',
      ),
      MasterDocument(
        docNo: 'BIIE-HM-001/Annex 4-1',
        title: 'Daftar Bahan yang digunakan untuk Kawasan Industri Halal',
        hierarchy: 'IMS',
        downloadUrl: 'dummy://biie-hm-001-annex-4-1',
      ),
    ];
  }
}
