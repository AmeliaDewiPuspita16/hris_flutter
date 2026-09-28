import '../../../shared/domain/master_document.dart';

/// Data demo statis untuk tab "Work Instruction" pada Master Edited File.
/// Catatan: baris yang tampil di sini adalah baris yang terlihat pada screenshot web "Edited File"; sisanya menyusul saat endpoint API tersedia.
/// EST-04-001/WI-4 dan WI-5 tidak terlihat di screenshot; judulnya diambil dari
/// seed Master Document File.
const editedWiDocumentsSeed = <MasterDocument>[
  MasterDocument(
    docNo: 'AML-01-001/WI-1 Rev 0',
    title: 'Pengurusan Izin Stasiun Radio (ISR)',
    hierarchy: 'AML',
    downloadUrl: 'dummy://edited-aml-01-001-wi-1-rev-0',
  ),
  MasterDocument(
    docNo: 'AML-01-001/WI-2 Rev 0',
    title: 'Pengurusan Sertifikat Laik Sehat Restoran',
    hierarchy: 'AML',
    downloadUrl: 'dummy://edited-aml-01-001-wi-2-rev-0',
  ),
  MasterDocument(
    docNo: 'AML-01-001/WI-3 Rev 0',
    title: 'Pengurusan Izin Tempat Usaha Minuman Beralkohol',
    hierarchy: 'AML',
    downloadUrl: 'dummy://edited-aml-01-001-wi-3-rev-0',
  ),
  MasterDocument(
    docNo: 'AML-01-001/WI-4 Rev 0',
    title: 'Pengurusan Surat Izin Usaha Minuman Beralkohol (SIUP-MB)',
    hierarchy: 'AML',
    downloadUrl: 'dummy://edited-aml-01-001-wi-4-rev-0',
  ),
  MasterDocument(
    docNo: 'AML-01-001/WI-5 Rev 0',
    title: 'Pengurusan Nomor Pokok Penjual Barang Kena Cukai (NPPBKC)',
    hierarchy: 'AML',
    downloadUrl: 'dummy://edited-aml-01-001-wi-5-rev-0',
  ),
  MasterDocument(
    docNo: 'AML-01-002/WI-1 Rev 0',
    title: 'Instruksi Kerja Pengerjaan dan Penyelesaian Dokumen Ekspor Impor',
    hierarchy: 'AML',
    downloadUrl: 'dummy://edited-aml-01-002-wi-1-rev-0',
  ),
  MasterDocument(
    docNo: 'EST-04-001/WI-1 Rev 3',
    title: 'Operational Monitoring',
    hierarchy: 'EST',
    downloadUrl: 'dummy://edited-est-04-001-wi-1-rev-3',
  ),
  MasterDocument(
    docNo: 'EST-04-001/WI-2 Rev 4',
    title: 'Pengoperasian Tangki Bahan Kimia',
    hierarchy: 'EST',
    downloadUrl: 'dummy://edited-est-04-001-wi-2-rev-4',
  ),
  MasterDocument(
    docNo: 'EST-04-001/WI-3 Rev 2',
    title: 'Operational of DAF Unit',
    hierarchy: 'EST',
    downloadUrl: 'dummy://edited-est-04-001-wi-3-rev-2',
  ),
  MasterDocument(
    docNo: 'EST-04-001/WI-4 Rev 2',
    title: 'Operational of UASB Unit',
    hierarchy: 'EST',
    downloadUrl: 'dummy://edited-est-04-001-wi-4-rev-2',
  ),
  MasterDocument(
    docNo: 'EST-04-001/WI-5 Rev 2',
    title: 'Operational of Flare Unit',
    hierarchy: 'EST',
    downloadUrl: 'dummy://edited-est-04-001-wi-5-rev-2',
  ),
  MasterDocument(
    docNo: 'EST-04-001/WI-6 Rev 3',
    title: 'Operational of Aerobic Unit',
    hierarchy: 'EST',
    downloadUrl: 'dummy://edited-est-04-001-wi-6-rev-3',
  ),
  MasterDocument(
    docNo: 'EST-04-001/WI-7 Rev 2',
    title: 'Operational of Screw Press Unit',
    hierarchy: 'EST',
    downloadUrl: 'dummy://edited-est-04-001-wi-7-rev-2',
  ),
  MasterDocument(
    docNo: 'EST-04-002/WI-3 Rev 1',
    title: 'Cleaning Inspection Chamber Screen Chamber',
    hierarchy: 'EST',
    downloadUrl: 'dummy://edited-est-04-002-wi-3-rev-1',
  ),
  MasterDocument(
    docNo: 'EST-04-002/WI-2 Rev 1',
    title: 'Cleaning STP',
    hierarchy: 'EST',
    downloadUrl: 'dummy://edited-est-04-002-wi-2-rev-1',
  ),
  MasterDocument(
    docNo: 'EST-04-002/WI-1 Rev 1',
    title: 'STP 2 Operational Monitoring',
    hierarchy: 'EST',
    downloadUrl: 'dummy://edited-est-04-002-wi-1-rev-1',
  ),
  MasterDocument(
    docNo: 'EST-04-003/WI-1',
    title: 'WTP Operation',
    hierarchy: 'EST',
    downloadUrl: 'dummy://edited-est-04-003-wi-1',
  ),
  MasterDocument(
    docNo: 'EST-04-003/WI-2 Rev 1',
    title: 'DOSING PUMP',
    hierarchy: 'EST',
    downloadUrl: 'dummy://edited-est-04-003-wi-2-rev-1',
  ),
  MasterDocument(
    docNo: 'EST-04-003/WI-3 Rev 2',
    title: 'TOP UP CHEMICALS',
    hierarchy: 'EST',
    downloadUrl: 'dummy://edited-est-04-003-wi-3-rev-2',
  ),
  MasterDocument(
    docNo: 'EST-04-003/WI-4 Rev 1',
    title: 'SAND WASH',
    hierarchy: 'EST',
    downloadUrl: 'dummy://edited-est-04-003-wi-4-rev-1',
  ),
  MasterDocument(
    docNo: 'EST-04-003/WI-5 Rev 1',
    title: 'WATER REJECT CHECK',
    hierarchy: 'EST',
    downloadUrl: 'dummy://edited-est-04-003-wi-5-rev-1',
  ),
  MasterDocument(
    docNo: 'EST-04-003/WI-6 Rev 1',
    title: 'TREATED BOOSTER PUMP',
    hierarchy: 'EST',
    downloadUrl: 'dummy://edited-est-04-003-wi-6-rev-1',
  ),
  MasterDocument(
    docNo: 'EST-04-003/WI-7 Rev 1',
    title: 'PROCESS SWITCHING',
    hierarchy: 'EST',
    downloadUrl: 'dummy://edited-est-04-003-wi-7-rev-1',
  ),
  MasterDocument(
    docNo: 'SSD-01-001/WI-1 Rev 0',
    title: 'Penjagaan Security Kawasan BIIE',
    hierarchy: 'SSD',
    downloadUrl: 'dummy://edited-ssd-01-001-wi-1-rev-0',
  ),
  MasterDocument(
    docNo: 'SSD-01-004/WI-1 Rev 0',
    title: 'Kehilangan barang, pencurian, keributan dan perkelahian',
    hierarchy: 'SSD',
    downloadUrl: 'dummy://edited-ssd-01-004-wi-1-rev-0',
  ),
];
