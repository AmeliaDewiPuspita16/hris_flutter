import '../../../shared/domain/master_document.dart';

/// Data demo statis untuk tab "ANNEX" pada Master Edited File.
/// Catatan: baris yang tampil di sini adalah baris yang terlihat pada screenshot web "Edited File"; sisanya menyusul saat endpoint API tersedia.
const editedAnnexDocumentsSeed = <MasterDocument>[
  MasterDocument(
    docNo: 'AML-01-002/Annex 1-0',
    title: 'Daftar Tarif Pengerjaan Dokumen Ekspor Impor',
    hierarchy: 'AML',
    downloadUrl: 'dummy://edited-aml-01-002-annex-1-0',
  ),
  MasterDocument(
    docNo: 'SSD-01-001/Annex 1-1',
    title: 'Tugas dan Tanggung Jawab Petugas Security',
    hierarchy: 'SSD',
    downloadUrl: 'dummy://edited-ssd-01-001-annex-1-1',
  ),
  MasterDocument(
    docNo: 'SSD-01-001/Annex 2-1',
    title: 'Standar Seragam Satpam BIE',
    hierarchy: 'SSD',
    downloadUrl: 'dummy://edited-ssd-01-001-annex-2-1',
  ),
  MasterDocument(
    docNo: 'SSD-01-001/Annex 3-1',
    title: 'Peta Kawasan Bintan Industrial Estate',
    hierarchy: 'SSD',
    downloadUrl: 'dummy://edited-ssd-01-001-annex-3-1',
  ),
  MasterDocument(
    docNo: 'SSD-01-005/Annex 1-0',
    title: 'Tabel Nilai Ujian Kesamaptaan Jasmani Security PT. Bintan Inti Industrial Estate (Pria) Golongan I (Usia 18 - 30 Th)',
    hierarchy: 'SSD',
    downloadUrl: 'dummy://edited-ssd-01-005-annex-1-0',
  ),
  MasterDocument(
    docNo: 'SSD-01-005/Annex 2-0',
    title: 'Tabel Nilai Ujian Kesamaptaan Jasmani Security PT. Bintan Inti Industrial Estate (Pria) Golongan II (Usia 31 - 40 Th)',
    hierarchy: 'SSD',
    downloadUrl: 'dummy://edited-ssd-01-005-annex-2-0',
  ),
  MasterDocument(
    docNo: 'SSD-01-005/Annex 3-0',
    title: 'Tabel Nilai Ujian Kesamaptaan Jasmani Security PT. Bintan Inti Industrial Estate (Pria) Golongan III (Usia 41 - 50 Th)',
    hierarchy: 'SSD',
    downloadUrl: 'dummy://edited-ssd-01-005-annex-3-0',
  ),
];
