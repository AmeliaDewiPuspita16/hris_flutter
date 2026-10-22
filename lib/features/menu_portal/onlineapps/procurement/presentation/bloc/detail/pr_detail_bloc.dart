import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../core/logging/app_logger.dart';
import '../../../../../../../core/network/api_exception.dart';
import '../../../data/procurement_repository.dart';
import '../../../domain/pr_action.dart';
import 'pr_detail_event.dart';
import 'pr_detail_state.dart';

/// Mengambil rincian satu PR, dan mengirim keputusan atasan atasnya.
///
/// Berumur pendek — hidup bersama PrDetailScreen, satu PR per layar.
class PrDetailBloc extends Bloc<PrDetailEvent, PrDetailState> {
  PrDetailBloc({required ProcurementRepository repository})
      : _repository = repository,
        super(const PrDetailState()) {
    on<PrDetailRequested>(_onRequested);
    on<PrActionSubmitted>(_onActionSubmitted);
  }

  final ProcurementRepository _repository;

  Future<void> _onRequested(
    PrDetailRequested event,
    Emitter<PrDetailState> emit,
  ) async {
    if (state.status == PrDetailStatus.loading) return;

    emit(const PrDetailState(status: PrDetailStatus.loading));

    try {
      final requisition = await _repository.fetchDetail(event.id);
      emit(PrDetailState(
        status: PrDetailStatus.success,
        requisition: requisition,
      ));
    } on ApiException catch (e) {
      AppLogger.info('Detail PR gagal dimuat: ${e.kind.name} — ${e.message}');
      emit(PrDetailState(
        status: PrDetailStatus.failure,
        errorMessage: e.message,
      ));
    } catch (e, stack) {
      AppLogger.error('Detail PR gagal karena galat tak terduga', e, stack);
      emit(
        const PrDetailState(
          status: PrDetailStatus.failure,
          errorMessage: 'Terjadi kesalahan tak terduga. Coba lagi.',
        ),
      );
    }
  }

  Future<void> _onActionSubmitted(
    PrActionSubmitted event,
    Emitter<PrDetailState> emit,
  ) async {
    final current = state.requisition;

    // Tanpa rincian PR tidak ada yang diputuskan; dan selama satu aksi masih
    // berjalan, ketukan kedua diabaikan supaya tidak terkirim dobel.
    if (current == null || state.isSubmitting) return;

    final comments = event.comments?.trim() ?? '';

    // Server juga memeriksa ini, tapi tidak perlu bolak-balik jaringan untuk
    // kesalahan yang sudah pasti.
    if (event.action.commentRequired && comments.isEmpty) {
      emit(state.copyWith(
        feedback: const PrActionFeedback('Comment is required.', isError: true),
      ));
      return;
    }

    emit(state.copyWith(isSubmitting: true));

    try {
      await _repository.submitAction(
        current.id,
        event.action,
        comments: comments,
      );
    } on ApiException catch (e) {
      AppLogger.info(
        'Aksi ${event.action.path} PR gagal: ${e.kind.name} — ${e.message}',
      );
      emit(state.copyWith(
        isSubmitting: false,
        feedback: PrActionFeedback(e.message, isError: true),
      ));
      // Hasil request yang gagal bisa saja tidak pasti (mis. timeout padahal
      // server sudah memprosesnya). Tidak pernah dikirim ulang otomatis;
      // cukup muat ulang supaya layar mengikuti keadaan sebenarnya di server.
      await _refreshQuietly(current.id, emit);
      return;
    } catch (e, stack) {
      AppLogger.error(
        'Aksi ${event.action.path} PR gagal karena galat tak terduga',
        e,
        stack,
      );
      emit(state.copyWith(
        isSubmitting: false,
        feedback: const PrActionFeedback(
          'Something went wrong. Please try again.',
          isError: true,
        ),
      ));
      await _refreshQuietly(current.id, emit);
      return;
    }

    // Berhasil. Isi respons server tidak dipakai; rincian diambil ulang supaya
    // status dan progress approval yang tampil persis seperti di server.
    final success = PrActionFeedback(_successMessage(event.action));

    try {
      final fresh = await _repository.fetchDetail(current.id);
      emit(PrDetailState(
        status: PrDetailStatus.success,
        requisition: fresh,
        feedback: success,
      ));
    } catch (e, stack) {
      AppLogger.error('Detail PR gagal dimuat ulang setelah aksi', e, stack);
      // Keputusannya sudah tersimpan, tapi layar tidak boleh terus memajang
      // tombol dari data lama. Tampilkan error dengan tombol "Coba lagi".
      emit(PrDetailState(
        status: PrDetailStatus.failure,
        errorMessage:
            'Your decision was saved, but the PR details failed to reload.',
        feedback: success,
      ));
    }
  }

  /// Muat ulang tanpa mengubah apa pun bila gagal.
  Future<void> _refreshQuietly(int id, Emitter<PrDetailState> emit) async {
    try {
      final fresh = await _repository.fetchDetail(id);
      emit(state.copyWith(requisition: fresh));
    } catch (_) {
      // Sengaja diabaikan: pesan error aksi sudah tampil.
    }
  }

  static String _successMessage(PrAction action) => switch (action) {
        PrAction.approve => 'PR approved.',
        PrAction.revision => 'PR sent back for revision.',
        PrAction.reject => 'PR rejected.',
      };
}
