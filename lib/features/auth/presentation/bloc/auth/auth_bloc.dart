import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/logging/app_logger.dart';
import '../../../data/auth_repository.dart';
import '../../../domain/auth_session.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// Pemegang status sesi aplikasi, hidup selama aplikasi berjalan.
///
/// Dipisah dari LoginBloc karena logout dan sesi kedaluwarsa bisa terjadi
/// dari layar mana pun, jauh setelah LoginScreen ditutup.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required AuthRepository repository})
      : _repository = repository,
        super(const AuthState.unknown()) {
    on<AuthStarted>(_onStarted);
    on<AuthSessionGranted>(_onSessionGranted);
    on<AuthUserRefreshed>(_onUserRefreshed);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthSessionExpired>(_onSessionExpired);
  }

  final AuthRepository _repository;

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    AuthSession? session;
    try {
      session = await _repository.restoreSession();
    } catch (e, stack) {
      // Penyimpanan yang tidak bisa dibaca bukan alasan untuk gagal membuka
      // aplikasi — perlakukan saja seperti belum pernah login, tapi catat
      // penyebabnya supaya tidak hilang diam-diam.
      AppLogger.error('Gagal memulihkan sesi tersimpan', e, stack);
      session = null;
    }

    emit(
      session == null
          ? const AuthState.unauthenticated()
          : AuthState.authenticated(session),
    );
  }

  void _onSessionGranted(AuthSessionGranted event, Emitter<AuthState> emit) {
    emit(AuthState.authenticated(event.session));
  }

  /// Mengganti user pada sesi yang berlaku. Tampilan diperbarui lebih dulu;
  /// gagal menyimpan ke penyimpanan tidak membatalkannya (paling buruk foto
  /// lama muncul lagi setelah aplikasi dibuka ulang), tapi dicatat.
  Future<void> _onUserRefreshed(
    AuthUserRefreshed event,
    Emitter<AuthState> emit,
  ) async {
    final current = state.session;
    if (current == null) return;

    final updated = AuthSession(
      token: current.token,
      tokenType: current.tokenType,
      user: event.user,
    );
    emit(AuthState.authenticated(updated));

    try {
      await _repository.saveSession(updated);
    } catch (e, stack) {
      AppLogger.error('Gagal menyimpan data user terbaru ke sesi', e, stack);
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _clearSession(emit);
  }

  Future<void> _onSessionExpired(
    AuthSessionExpired event,
    Emitter<AuthState> emit,
  ) async {
    await _clearSession(emit);
  }

  /// Pengguna harus tetap sampai ke layar login walaupun pembersihan
  /// penyimpanan gagal.
  Future<void> _clearSession(Emitter<AuthState> emit) async {
    try {
      await _repository.logout();
    } finally {
      emit(const AuthState.unauthenticated());
    }
  }
}
