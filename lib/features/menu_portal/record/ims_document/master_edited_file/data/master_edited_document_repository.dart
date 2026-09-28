import '../../shared/domain/master_document.dart';
import 'seeds/edited_annex_documents_seed.dart';
import 'seeds/edited_manual_documents_seed.dart';
import 'seeds/edited_sop_documents_seed.dart';
import 'seeds/edited_wi_documents_seed.dart';

/// Repository untuk halaman "Master Edited File". Sama seperti
/// [MasterDocumentRepository], untuk sementara mengembalikan data demo
/// statis karena endpoint API modul Record belum tersedia (auth dan menu lain
/// sudah terintegrasi, Record belum). Karena itu constructor-nya tanpa
/// `ApiClient` dan screen-nya membuat sendiri instance-nya, tidak lewat
/// `RepositoryProvider` di `main.dart`.
///
/// Begitu endpoint-nya siap: tambahkan `ApiClient` ke constructor, daftarkan
/// lewat `RepositoryProvider` di `main.dart`, lalu ganti isi method di bawah
/// dengan pemanggilan `ApiClient` — signature method & model [MasterDocument]
/// tidak perlu berubah.
///
/// Master Edited File hanya punya 4 kategori (Manual, SOP, WI, ANNEX) dan
/// tidak punya Form/Form Template. Model yang dipakai sama dengan Master
/// Document File; bedanya `obsoleteUrl` selalu null karena dokumen edited
/// tidak punya versi obsolete.
class MasterEditedDocumentRepository {
  MasterEditedDocumentRepository();

  static const _simulatedLatency = Duration(milliseconds: 500);

  /// Dokumen pada tab "Manual". Data: [editedManualDocumentsSeed].
  Future<List<MasterDocument>> fetchManualDocuments() async {
    await Future.delayed(_simulatedLatency);
    return editedManualDocumentsSeed;
  }

  /// Dokumen pada tab "Standart Operational Procedure". Data:
  /// [editedSopDocumentsSeed].
  Future<List<MasterDocument>> fetchSopDocuments() async {
    await Future.delayed(_simulatedLatency);
    return editedSopDocumentsSeed;
  }

  /// Dokumen pada tab "Work Instruction". Data: [editedWiDocumentsSeed].
  Future<List<MasterDocument>> fetchWiDocuments() async {
    await Future.delayed(_simulatedLatency);
    return editedWiDocumentsSeed;
  }

  /// Dokumen pada tab "ANNEX". Data: [editedAnnexDocumentsSeed].
  Future<List<MasterDocument>> fetchAnnexDocuments() async {
    await Future.delayed(_simulatedLatency);
    return editedAnnexDocumentsSeed;
  }
}
