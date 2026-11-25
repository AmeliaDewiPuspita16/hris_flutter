import '../../../../../core/network/page_meta.dart';
import 'observation_item.dart';

/// Satu halaman hasil daftar Observation: isi halaman itu beserta
/// keterangan paginasinya ([PageMeta]: halaman keberapa, masih ada lanjutan
/// atau tidak, total seluruh data). Pola yang sama dengan `IndentRequestPage`.
class ObservationPage {
  const ObservationPage({required this.items, required this.meta});

  final List<ObservationItem> items;
  final PageMeta meta;
}
