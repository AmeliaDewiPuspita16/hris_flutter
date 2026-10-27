import '../../../shared/domain/master_document.dart';

/// Data demo statis untuk tab "Manual" pada Master Edited File.
/// Catatan: baris yang tampil di sini adalah baris yang terlihat pada screenshot web "Edited File"; sisanya menyusul saat endpoint API tersedia.
const editedManualDocumentsSeed = <MasterDocument>[
  MasterDocument(
    docNo: 'BIIE-IM-001 Rev 4',
    title: 'Manual Sistem Manajemen Terpadu ISO 9001:2015 & 14001:2015',
    hierarchy: 'IMS',
  ),
  MasterDocument(
    docNo: 'BIIE-IM-001/Annex 1-1',
    title: 'Kebijakan Sistem Manajemen Terpadu',
    hierarchy: 'IMS',
  ),
  MasterDocument(
    docNo: 'BIIE-IM-001/Annex 2-1',
    title: 'Sasaran Sistem Manajemen Terpadu',
    hierarchy: 'IMS',
  ),
  MasterDocument(
    docNo: 'BIIE-IM-001/Annex 4-5',
    title: 'Isu Internal dan Eksternal',
    hierarchy: 'IMS',
  ),
  MasterDocument(
    docNo: 'BIIE-IM-001/Annex 5-4',
    title: 'Kebutuhan dan Harapan Pihak-Pihak Berkepentingan',
    hierarchy: 'IMS',
  ),
  MasterDocument(
    docNo: 'BIIE-HM-001 Rev 4',
    title: 'Sistem Jaminan Produk Halal',
    hierarchy: 'IMS',
  ),
  MasterDocument(
    docNo: 'BIIE-HM-001/Annex 1-3',
    title: 'Surat Keputusan Tim Manajemen Halal',
    hierarchy: 'IMS',
  ),
  MasterDocument(
    docNo: 'BIIE-HM-001/Annex 2-2',
    title: 'Struktur Organisasi Tim Manajemen Halal',
    hierarchy: 'IMS',
  ),
];
