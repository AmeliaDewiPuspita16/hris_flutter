import '../../shared/domain/master_document_page.dart';
import 'seeds/edited_annex_documents_seed.dart';
import 'seeds/edited_manual_documents_seed.dart';
import 'seeds/edited_sop_documents_seed.dart';
import 'seeds/edited_wi_documents_seed.dart';

/// Repository untuk halaman "Master Edited File". Untuk sementara
/// mengembalikan data demo statis karena endpoint-nya belum tersedia
/// (Master Document File sudah tersambung ke API). Karena itu constructor-nya tanpa
/// `ApiClient` dan screen-nya membuat sendiri instance-nya, tidak lewat
/// `RepositoryProvider` di `main.dart`.
///
/// Begitu endpoint-nya siap: tambahkan `ApiClient` ke constructor, daftarkan
/// lewat `RepositoryProvider` di `main.dart`, lalu ganti isi method di bawah
/// dengan pemanggilan `ApiClient` (lihat `MasterDocumentRepository`) — signature
/// method tidak perlu berubah. Selama masih demo, pencarian dilakukan lokal
/// lewat [MasterDocumentPage.local].
///
/// Master Edited File hanya punya 4 kategori (Manual, SOP, WI, ANNEX) dan
/// tidak punya Form/Form Template. Model yang dipakai sama dengan Master
/// Document File.
class MasterEditedDocumentRepository {
  MasterEditedDocumentRepository();

  static const _simulatedLatency = Duration(milliseconds: 500);

  /// Jumlah dokumen per kategori untuk angka di chip tab — dihitung dari
  /// data demo yang sama dengan daftarnya, jadi tidak bisa selisih. Begitu
  /// endpoint siap, ganti dengan `count` dari server (seperti
  /// `MasterDocumentRepository.fetchCategories`).
  int get manualCount => editedManualDocumentsSeed.length;
  int get sopCount => editedSopDocumentsSeed.length;
  int get wiCount => editedWiDocumentsSeed.length;
  int get annexCount => editedAnnexDocumentsSeed.length;

  /// Dokumen pada tab "Manual". Data: [editedManualDocumentsSeed].
  Future<MasterDocumentPage> fetchManualDocuments({required int page, required String search}) async {
    await Future.delayed(_simulatedLatency);
    return MasterDocumentPage.local(editedManualDocumentsSeed, search);
  }

  /// Dokumen pada tab "Standart Operational Procedure". Data:
  /// [editedSopDocumentsSeed].
  Future<MasterDocumentPage> fetchSopDocuments({required int page, required String search}) async {
    await Future.delayed(_simulatedLatency);
    return MasterDocumentPage.local(editedSopDocumentsSeed, search);
  }

  /// Dokumen pada tab "Work Instruction". Data: [editedWiDocumentsSeed].
  Future<MasterDocumentPage> fetchWiDocuments({required int page, required String search}) async {
    await Future.delayed(_simulatedLatency);
    return MasterDocumentPage.local(editedWiDocumentsSeed, search);
  }

  /// Dokumen pada tab "ANNEX". Data: [editedAnnexDocumentsSeed].
  Future<MasterDocumentPage> fetchAnnexDocuments({required int page, required String search}) async {
    await Future.delayed(_simulatedLatency);
    return MasterDocumentPage.local(editedAnnexDocumentsSeed, search);
  }
}
