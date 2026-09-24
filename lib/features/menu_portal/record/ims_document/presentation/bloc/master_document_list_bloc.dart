import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/logging/app_logger.dart';
import '../../domain/master_document.dart';
import 'master_document_list_event.dart';
import 'master_document_list_state.dart';

/// Memuat daftar dokumen master untuk satu tab (Manual, SOP, dst).
///
/// Sengaja tidak terikat ke satu kategori — [fetcher] disuntik lewat
/// konstruktor, jadi bloc yang sama dipakai ulang untuk tiap tab, tinggal
/// beri method repository yang berbeda (mis.
/// `repository.fetchManualDocuments`, nanti `repository.fetchSopDocuments`,
/// dst) tanpa perlu bikin bloc baru per kategori.
class MasterDocumentListBloc
    extends Bloc<MasterDocumentListEvent, MasterDocumentListState> {
  MasterDocumentListBloc({
    required Future<List<MasterDocument>> Function() fetcher,
  })  : _fetcher = fetcher,
        super(const MasterDocumentListState()) {
    on<MasterDocumentListStarted>(_onLoad);
    on<MasterDocumentListRefreshed>(_onLoad);
  }

  final Future<List<MasterDocument>> Function() _fetcher;

  Future<void> _onLoad(
    MasterDocumentListEvent event,
    Emitter<MasterDocumentListState> emit,
  ) async {
    emit(state.copyWith(
      status: MasterDocumentListStatus.loading,
      errorMessage: null,
    ));

    try {
      final documents = await _fetcher();

      emit(state.copyWith(
        status: MasterDocumentListStatus.success,
        documents: documents,
      ));
    } catch (e, stack) {
      AppLogger.error('Daftar dokumen master gagal dimuat', e, stack);

      emit(state.copyWith(
        status: MasterDocumentListStatus.failure,
        errorMessage: 'Gagal memuat daftar dokumen. Coba lagi.',
      ));
    }
  }
}
