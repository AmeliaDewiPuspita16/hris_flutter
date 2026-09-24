import '../domain/master_document.dart';

/// Repository ini untuk sementara mengembalikan data demo statis sebelum
/// tersambung API. Karena itu constructor-nya sengaja tanpa `ApiClient`
///  dan screen-nya membuat sendiri instance-nya (tidak lewat `RepositoryProvider`
/// di `main.dart`).
///
/// Begitu endpoint-nya siap: tambahkan lagi `ApiClient` ke constructor,
/// daftarkan lewat `RepositoryProvider` di `main.dart`, dan ganti isi method di
/// bawah ini dengan pemanggilan `ApiClient` — signature method & model
/// [MasterDocument] tidak perlu berubah.
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

  /// Dokumen pada tab "Standart Operational Procedure".
  ///
  /// Beda dengan Manual (semua "IMS"), di sini `hierarchy` bermacam-macam
  /// departemen (HSE, EST, CDD, AML, POD, SSD, HR & GA, GMO) — lihat
  /// `MasterDocumentTile` untuk pemetaan warna badge-nya. Sebagian dokumen
  /// tidak punya `obsoleteUrl` (baris "Obsolete" tidak tampil), sama seperti
  /// di web.
  Future<List<MasterDocument>> fetchSopDocuments() async {
    await Future.delayed(_simulatedLatency);

    return const [
      MasterDocument(
        docNo: 'HSE-01-004 Rev 1',
        title: 'Duty Officer',
        hierarchy: 'HSE',
        downloadUrl: 'dummy://hse-01-004-rev-1',
        obsoleteUrl: 'dummy://hse-01-004-rev-1-obsolete',
      ),
      MasterDocument(
        docNo: 'EST-01-004 Rev 3',
        title: 'ESTATE ROUTINE INSPECTION',
        hierarchy: 'EST',
        downloadUrl: 'dummy://est-01-004-rev-3',
        obsoleteUrl: 'dummy://est-01-004-rev-3-obsolete',
      ),
      MasterDocument(
        docNo: 'EST-01-005 Rev 3',
        title: 'ESTATE REPAIRE & MAINTENANCE',
        hierarchy: 'EST',
        downloadUrl: 'dummy://est-01-005-rev-3',
        obsoleteUrl: 'dummy://est-01-005-rev-3-obsolete',
      ),
      MasterDocument(
        docNo: 'EST-04-001 Rev 3',
        title: 'Waste Water Treatment Plant Operation',
        hierarchy: 'EST',
        downloadUrl: 'dummy://est-04-001-rev-3',
        obsoleteUrl: 'dummy://est-04-001-rev-3-obsolete',
      ),
      MasterDocument(
        docNo: 'EST-04-002 Rev 3',
        title: 'Sewage Treatment Plant Operation',
        hierarchy: 'EST',
        downloadUrl: 'dummy://est-04-002-rev-3',
        obsoleteUrl: 'dummy://est-04-002-rev-3-obsolete',
      ),
      MasterDocument(
        docNo: 'CDD-01-001 Rev 2',
        title: 'Company Social Responsibility (CSR) Program',
        hierarchy: 'CDD',
        downloadUrl: 'dummy://cdd-01-001-rev-2',
      ),
      MasterDocument(
        docNo: 'CDD-02-001 Rev 1',
        title: 'Social Business Engagement',
        hierarchy: 'CDD',
        downloadUrl: 'dummy://cdd-02-001-rev-1',
      ),
      MasterDocument(
        docNo: 'AML-01-001 Rev 3',
        title: 'Pelayanan Perizinan',
        hierarchy: 'AML',
        downloadUrl: 'dummy://aml-01-001-rev-3',
        obsoleteUrl: 'dummy://aml-01-001-rev-3-obsolete',
      ),
      MasterDocument(
        docNo: 'AML-01-003 Rev 1',
        title: 'Prosedur Pengeluaran Data dan Informasi',
        hierarchy: 'AML',
        downloadUrl: 'dummy://aml-01-003-rev-1',
        obsoleteUrl: 'dummy://aml-01-003-rev-1-obsolete',
      ),
      MasterDocument(
        docNo: 'AML-01-002 Rev 1',
        title: 'Layanan Ekspor Impor',
        hierarchy: 'AML',
        downloadUrl: 'dummy://aml-01-002-rev-1',
        obsoleteUrl: 'dummy://aml-01-002-rev-1-obsolete',
      ),
      MasterDocument(
        docNo: 'POD-01-001 Rev 5',
        title: 'Fasilitas Pelabuhan',
        hierarchy: 'POD',
        downloadUrl: 'dummy://pod-01-001-rev-5',
        obsoleteUrl: 'dummy://pod-01-001-rev-5-obsolete',
      ),
      MasterDocument(
        docNo: 'SSD-01-001 Rev 3',
        title: 'Security Procedure and Policies',
        hierarchy: 'SSD',
        downloadUrl: 'dummy://ssd-01-001-rev-3',
        obsoleteUrl: 'dummy://ssd-01-001-rev-3-obsolete',
      ),
      MasterDocument(
        docNo: 'SSD-01-002 Rev 4',
        title: 'Security Patrol',
        hierarchy: 'SSD',
        downloadUrl: 'dummy://ssd-01-002-rev-4',
        obsoleteUrl: 'dummy://ssd-01-002-rev-4-obsolete',
      ),
      MasterDocument(
        docNo: 'SSD-01-003 Rev 3',
        title: 'Prosedur Keluar Masuk Kawasan',
        hierarchy: 'SSD',
        downloadUrl: 'dummy://ssd-01-003-rev-3',
        obsoleteUrl: 'dummy://ssd-01-003-rev-3-obsolete',
      ),
      MasterDocument(
        docNo: 'SSD-01-004 Rev 1',
        title: 'Tindakan pertama tempat kejadian perkara (TPTKP)',
        hierarchy: 'SSD',
        downloadUrl: 'dummy://ssd-01-004-rev-1',
      ),
      MasterDocument(
        docNo: 'SSD-01-005 Rev 3',
        title: 'SAMAPTA',
        hierarchy: 'SSD',
        downloadUrl: 'dummy://ssd-01-005-rev-3',
      ),
      MasterDocument(
        docNo: 'HRD-01-004 Rev 1',
        title: 'Training & Development',
        hierarchy: 'HR & GA',
        downloadUrl: 'dummy://hrd-01-004-rev-1',
      ),
      MasterDocument(
        docNo: 'HRD-01-010 Rev 1',
        title: 'Kode Etik',
        hierarchy: 'HR & GA',
        downloadUrl: 'dummy://hrd-01-010-rev-1',
      ),
      MasterDocument(
        docNo: 'HRD-02-001 Rev 2',
        title: 'Transportation & Vehicle Arrangement',
        hierarchy: 'HR & GA',
        downloadUrl: 'dummy://hrd-02-001-rev-2',
        obsoleteUrl: 'dummy://hrd-02-001-rev-2-obsolete',
      ),
      MasterDocument(
        docNo: 'HRD-02-006 Rev 1',
        title: 'Office Supply Management',
        hierarchy: 'HR & GA',
        downloadUrl: 'dummy://hrd-02-006-rev-1',
      ),
      MasterDocument(
        docNo: 'GMO-01-001 Rev 0',
        title: 'Entertainment',
        hierarchy: 'GMO',
        downloadUrl: 'dummy://gmo-01-001-rev-0',
      ),
      MasterDocument(
        docNo: 'HSE-01-001 Rev 1',
        title: 'Pencegahan & Penanganan Wabah Penyakit Menular',
        hierarchy: 'HSE',
        downloadUrl: 'dummy://hse-01-001-rev-1',
        obsoleteUrl: 'dummy://hse-01-001-rev-1-obsolete',
      ),
      MasterDocument(
        docNo: 'SSD-02-002 Rev 1',
        title: 'Kebijakan Umum Fire Safety',
        hierarchy: 'SSD',
        downloadUrl: 'dummy://ssd-02-002-rev-1',
        obsoleteUrl: 'dummy://ssd-02-002-rev-1-obsolete',
      ),
      MasterDocument(
        docNo: 'SSD-02-003 Rev 5',
        title: 'Prosedur Inspeksi Dan Perawatan Mesin',
        hierarchy: 'SSD',
        downloadUrl: 'dummy://ssd-02-003-rev-5',
        obsoleteUrl: 'dummy://ssd-02-003-rev-5-obsolete',
      ),
      MasterDocument(
        docNo: 'HRD-01-005 Rev 1',
        title: 'Penilaian Kinerja',
        hierarchy: 'HR & GA',
        downloadUrl: 'dummy://hrd-01-005-rev-1',
        obsoleteUrl: 'dummy://hrd-01-005-rev-1-obsolete',
      ),
      MasterDocument(
        docNo: 'HRD-01-007 Rev 1',
        title: 'Employment Termination',
        hierarchy: 'HR & GA',
        downloadUrl: 'dummy://hrd-01-007-rev-1',
        obsoleteUrl: 'dummy://hrd-01-007-rev-1-obsolete',
      ),
      MasterDocument(
        docNo: 'HRD-01-008 Rev 2',
        title: 'Internship',
        hierarchy: 'HR & GA',
        downloadUrl: 'dummy://hrd-01-008-rev-2',
        obsoleteUrl: 'dummy://hrd-01-008-rev-2-obsolete',
      ),
    ];
  }
}
