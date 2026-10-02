import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/logging/app_logger.dart';
import '../../../../../core/network/api_exception.dart';
import '../../../data/photo_picker_service.dart';
import '../../../data/profil_repository.dart';
import '../../../domain/photo_pick_exception.dart';
import 'profil_photo_event.dart';
import 'profil_photo_state.dart';

/// Mengganti foto profil: memilih + crop (lewat [PhotoPickerService]) lalu
/// mengunggah (lewat [ProfilRepository]).
///
/// Berumur pendek — hidup bersama layar Profil. Bloc ini TIDAK mengubah
/// sesi; saat sukses ia hanya menyiarkan user terbaru, dan layar
/// meneruskannya ke `AuthBloc` yang memegang sesi.
class ProfilPhotoBloc extends Bloc<ProfilPhotoEvent, ProfilPhotoState> {
  ProfilPhotoBloc({
    required ProfilRepository repository,
    required PhotoPickerService picker,
  })  : _repository = repository,
        _picker = picker,
        super(const ProfilPhotoState()) {
    on<ProfilPhotoPickRequested>(_onPickRequested);
  }

  final ProfilRepository _repository;
  final PhotoPickerService _picker;

  Future<void> _onPickRequested(
    ProfilPhotoPickRequested event,
    Emitter<ProfilPhotoState> emit,
  ) async {
    if (state.isBusy) return;

    // Foto sebelumnya dibawa terus, supaya kegagalan/pembatalan tidak
    // mengosongkan avatar.
    final previous = state.photo;
    emit(ProfilPhotoState(status: ProfilPhotoStatus.picking, photo: previous));

    final File? file;
    try {
      file = await _picker.pick(event.source);
    } on PhotoPickException catch (e) {
      emit(ProfilPhotoState(
        status: ProfilPhotoStatus.failure,
        photo: previous,
        errorMessage: e.message,
      ));
      return;
    } catch (e, stack) {
      AppLogger.error('Foto profil gagal dipilih karena galat tak terduga', e, stack);
      emit(ProfilPhotoState(
        status: ProfilPhotoStatus.failure,
        photo: previous,
        errorMessage: 'Terjadi kesalahan tak terduga. Coba lagi.',
      ));
      return;
    }

    // User membatalkan di pemilih atau di layar crop — bukan galat.
    if (file == null) {
      emit(ProfilPhotoState(photo: previous));
      return;
    }

    // Foto langsung tampil secara lokal selama upload berjalan.
    emit(ProfilPhotoState(status: ProfilPhotoStatus.uploading, photo: file));

    try {
      final user = await _repository.uploadPhoto(file);
      emit(ProfilPhotoState(status: ProfilPhotoStatus.success, photo: file, user: user));
    } on ApiException catch (e) {
      AppLogger.info('Foto profil gagal diunggah: ${e.kind.name} — ${e.message}');
      emit(ProfilPhotoState(
        status: ProfilPhotoStatus.failure,
        photo: previous,
        errorMessage: e.message,
      ));
    } catch (e, stack) {
      AppLogger.error('Foto profil gagal diunggah karena galat tak terduga', e, stack);
      emit(ProfilPhotoState(
        status: ProfilPhotoStatus.failure,
        photo: previous,
        errorMessage: 'Terjadi kesalahan tak terduga. Coba lagi.',
      ));
    }
  }
}
