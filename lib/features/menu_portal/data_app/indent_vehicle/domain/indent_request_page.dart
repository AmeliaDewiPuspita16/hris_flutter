import '../../../../../core/network/page_meta.dart';
import 'indent_request_item.dart';

/// Satu halaman hasil `GET /api/indent`: isi halaman itu beserta
/// keterangan paginasinya (halaman keberapa, masih ada lanjutan atau tidak).
class IndentRequestPage {
  const IndentRequestPage({required this.items, required this.meta});

  final List<IndentRequestItem> items;
  final PageMeta meta;
}
