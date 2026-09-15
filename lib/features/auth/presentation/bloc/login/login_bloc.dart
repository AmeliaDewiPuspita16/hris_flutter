import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/logging/app_logger.dart';
import '../../../../../core/network/api_exception.dart';
import '../../../data/auth_repository.dart';
import 'login_event.dart';
import 'login_state.dart';

/// Mengurus satu kali proses masuk: submit, menunggu, lalu berhasil/gagal.
///
/// Berumur pendek — hidup bersama LoginScreen. Status sesi jangka panjang
/// dipegang AuthBloc.
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc({required AuthRepository repository})
      : _repository = repository,
        super(const LoginState()) {
    on<LoginSubmitted>(_onSubmitted);
    on<LoginReset>(_onReset);
  }

  final AuthRepository _repository;

  Future<void> _onSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    // Bloc memproses event secara bersamaan, jadi ketukan kedua pada tombol
    // Sign in harus ditolak di sini supaya tidak ada dua request login.
    if (state.status == LoginStatus.loading) return;

    emit(const LoginState(status: LoginStatus.loading));

    try {
      final session = await _repository.login(
        email: event.email,
        password: event.password,
      );
      emit(LoginState(status: LoginStatus.success, session: session));
    } on ApiException catch (e) {
      AppLogger.info('Login ditolak: ${e.kind.name} — ${e.message}');
      emit(LoginState(status: LoginStatus.failure, errorMessage: e.message));
    } catch (e, stack) {
      // Apa pun yang tidak terduga tetap tidak boleh bocor ke layar, tapi
      // wajib lengkap di console supaya bisa dilacak.
      AppLogger.error('Login gagal karena galat tak terduga', e, stack);
      emit(
        const LoginState(
          status: LoginStatus.failure,
          errorMessage: 'Terjadi kesalahan tak terduga. Coba lagi.',
        ),
      );
    }
  }

  void _onReset(LoginReset event, Emitter<LoginState> emit) {
    emit(const LoginState());
  }
}
