import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../core/logging/app_logger.dart';
import '../../../../../../../core/network/api_exception.dart';
import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/widgets/app_error_view.dart';
import '../../../../../../../core/widgets/back_header.dart';
import '../../data/master_document_repository.dart';
import '../../../shared/domain/document_category.dart';
import '../../../shared/presentation/widgets/document_tabbed_view.dart';

/// Halaman "Document File" — tab kategori dokumen master IMS dari
/// `GET /api/record/ims/documents/categories`, dibuka dari opsi "Master
/// Document File" di bottom sheet `ImsDocumentMenuSheet`.
///
/// [MasterDocumentRepository] diambil dari `RepositoryProvider` di
/// `main.dart` (berbagi `ApiClient` yang sudah memegang token login).
///
/// Search, chip tab, dan daftar dokumennya ada di [DocumentTabbedView]
/// (dipakai bersama `MasterEditedFileScreen`).
class MasterDocumentFileScreen extends StatefulWidget {
  const MasterDocumentFileScreen({super.key});

  @override
  State<MasterDocumentFileScreen> createState() => _MasterDocumentFileScreenState();
}

class _MasterDocumentFileScreenState extends State<MasterDocumentFileScreen> {
  late final MasterDocumentRepository _repository = context.read<MasterDocumentRepository>();
  late Future<List<DocumentCategory>> _categories = _repository.fetchCategories();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: BackHeader(
        title: 'Document File',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: FutureBuilder<List<DocumentCategory>>(
        future: _categories,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            final error = snapshot.error!;
            if (error is! ApiException) {
              AppLogger.error('Kategori dokumen IMS gagal dimuat', error, snapshot.stackTrace);
            }
            return AppErrorView(
              message: error is ApiException ? error.message : 'Gagal memuat kategori dokumen.',
              onRetry: () => setState(() => _categories = _repository.fetchCategories()),
            );
          }

          final categories = snapshot.data;
          if (categories == null) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (categories.isEmpty) {
            return AppErrorView(
              message: 'Belum ada kategori dokumen.',
              onRetry: () => setState(() => _categories = _repository.fetchCategories()),
            );
          }

          return DocumentTabbedView(
            // Server hanya mencari di nomor dokumen dan judul.
            searchHint: 'Nomor dokumen atau judul',
            pdfHeaders: _repository.pdfHeaders,
            tabs: [
              for (final category in categories)
                DocumentTabSpec(
                  label: category.count == null ? category.label : '${category.label} (${category.count})',
                  fetcher: ({required page, required search}) => _repository.fetchDocuments(
                    category: category.key,
                    page: page,
                    search: search,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
