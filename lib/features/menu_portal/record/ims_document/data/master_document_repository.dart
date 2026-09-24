import '../domain/master_document.dart';
import 'seeds/annex_documents_seed.dart';
import 'seeds/form_documents_seed.dart';
import 'seeds/form_template_documents_seed.dart';
import 'seeds/manual_documents_seed.dart';
import 'seeds/sop_documents_seed.dart';
import 'seeds/wi_documents_seed.dart';

/// Repository ini untuk sementara mengembalikan data demo statis sebelum
/// tersambung API. Karena itu constructor-nya sengaja tanpa `ApiClient`
///  dan screen-nya membuat sendiri instance-nya (tidak lewat `RepositoryProvider`
/// di `main.dart`).
///
/// Begitu endpoint-nya siap: tambahkan lagi `ApiClient` ke constructor,
/// daftarkan lewat `RepositoryProvider` di `main.dart`, dan ganti isi method di
/// bawah ini dengan pemanggilan `ApiClient` — signature method & model
/// [MasterDocument] tidak perlu berubah.
///
/// Data mentah tiap kategori (yang jumlahnya ratusan baris) sudah dipindah ke
/// `seeds/*_documents_seed.dart` supaya file ini tetap pendek dan gampang
/// dibaca — kalau mau tambah/ubah/hapus dokumen, buka file seed kategori
/// terkait, bukan file ini.
class MasterDocumentRepository {
  MasterDocumentRepository();

  static const _simulatedLatency = Duration(milliseconds: 500);

  /// Dokumen pada tab "Manual". Data: [manualDocumentsSeed].
  Future<List<MasterDocument>> fetchManualDocuments() async {
    await Future.delayed(_simulatedLatency);
    return manualDocumentsSeed;
  }

  /// Dokumen pada tab "Standart Operational Procedure". Data: [sopDocumentsSeed].
  Future<List<MasterDocument>> fetchSopDocuments() async {
    await Future.delayed(_simulatedLatency);
    return sopDocumentsSeed;
  }

  /// Dokumen pada tab "Work Instruction". Data: [wiDocumentsSeed].
  Future<List<MasterDocument>> fetchWiDocuments() async {
    await Future.delayed(_simulatedLatency);
    return wiDocumentsSeed;
  }

  /// Dokumen pada tab "Form". Data: [formDocumentsSeed].
  Future<List<MasterDocument>> fetchFormDocuments() async {
    await Future.delayed(_simulatedLatency);
    return formDocumentsSeed;
  }

  /// Dokumen pada tab "ANNEX". Data: [annexDocumentsSeed].
  Future<List<MasterDocument>> fetchAnnexDocuments() async {
    await Future.delayed(_simulatedLatency);
    return annexDocumentsSeed;
  }

  /// Dokumen pada tab "Form Template". Data: [formTemplateDocumentsSeed].
  Future<List<MasterDocument>> fetchFormTemplateDocuments() async {
    await Future.delayed(_simulatedLatency);
    return formTemplateDocumentsSeed;
  }
}
