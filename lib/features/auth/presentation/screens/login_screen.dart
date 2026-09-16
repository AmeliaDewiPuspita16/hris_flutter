import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../data/auth_repository.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_event.dart';
import '../bloc/login/login_bloc.dart';
import '../bloc/login/login_event.dart';
import '../bloc/login/login_state.dart';
import '../controllers/login_form_controller.dart';
import '../widgets/keep_signed_in_row.dart';
import '../widgets/login_alt_button.dart';
import '../widgets/login_field.dart';
import '../widgets/login_footer.dart';
import '../widgets/login_header.dart';
import '../widgets/or_divider.dart';

/// Halaman login BIIE Portal.
///
/// Menyediakan [LoginBloc] yang umurnya seumur layar ini saja; status sesi
/// jangka panjang dipegang AuthBloc di atasnya.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LoginBloc(
        repository: context.read<AuthRepository>(),
      ),
      child: const _LoginView(),
    );
  }
}

/// Isi layar login: merangkai widget, memegang state form lewat
/// [LoginFormController], dan meneruskan hasil login ke AuthBloc.
class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final _form = LoginFormController();

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  void _handleSignIn() {
    if (!_form.submit()) return;

    final credentials = _form.credentials;
    context.read<LoginBloc>().add(
          LoginSubmitted(
            email: credentials.email,
            password: credentials.password,
          ),
        );
  }

  /// Navigasi tidak dilakukan dari sini — AuthGate yang mengganti layar
  /// begitu AuthBloc tahu sesinya sudah sah.
  void _handleLoginState(BuildContext context, LoginState state) {
    final session = state.session;
    if (state.status == LoginStatus.success && session != null) {
      context.read<AuthBloc>().add(AuthSessionGranted(session));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginBloc, LoginState>(
      listener: _handleLoginState,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        // LayoutBuilder dipakai karena Scaffold memberi body batasan yang
        // longgar: tanpa tinggi eksplisit, latar ikut menyusut setinggi
        // konten dan menyisakan blok polos di bawah halaman.
        body: LayoutBuilder(
          builder: (context, constraints) => Container(
            height: constraints.maxHeight,
            width: constraints.maxWidth,
            decoration: const BoxDecoration(
              gradient: AppColors.pageGradient,
              image: DecorationImage(
                image: AssetImage('assets/images/bg_login.png'),
                fit: BoxFit.cover,
                // Teksturnya cuma penghias. Pada kepekatan penuh, garis-
                // garisnya menutupi teks di atasnya sampai sulit dibaca.
                opacity: 0.1,
              ),
            ),
            child: SingleChildScrollView(
              child: ConstrainedBox(
                // Kolom minimal setinggi layar supaya Spacer di bawah punya
                // ruang untuk mendorong footer ke dasar halaman.
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const LoginHeader(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                        child: AnimatedBuilder(
                          animation: _form,
                          builder: (context, _) =>
                              BlocBuilder<LoginBloc, LoginState>(
                            builder: (context, state) => _LoginForm(
                              form: _form,
                              state: state,
                              onSignIn: _handleSignIn,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(20, 16, 20, 24),
                        child: LoginFooter(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.form,
    required this.state,
    required this.onSignIn,
  });

  final LoginFormController form;
  final LoginState state;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoginField(
          label: 'Email',
          controller: form.emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          errorText: form.emailError,
        ),
        const SizedBox(height: 12),
        LoginField(
          label: 'Password',
          controller: form.passwordController,
          obscureText: form.obscurePassword,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSignIn(),
          errorText: form.passwordError,
          trailing: TextButton(
            onPressed: form.togglePasswordVisibility,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              form.obscurePassword ? 'Show' : 'Hide',
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryMid,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        KeepSignedInRow(
          value: form.keepSignedIn,
          onChanged: form.toggleKeepSignedIn,
          onForgotPressed: () {},
        ),
        if (state.errorMessage != null) ...[
          const SizedBox(height: 16),
          _ServerErrorMessage(message: state.errorMessage!),
        ],
        const SizedBox(height: 20),
        AppButton(
          label: 'Sign in',
          variant: AppButtonVariant.primaryGradient,
          onPressed: onSignIn,
          isLoading: state.isLoading,
        ),
        const SizedBox(height: 20),
        const OrDivider(),
        const SizedBox(height: 20),
        LoginAltButton(label: 'Use Face ID', onPressed: () {}),
      ],
    );
  }
}

/// Galat yang datang dari server — bukan milik satu field tertentu, jadi
/// ditaruh tepat di atas tombol Sign in dan bukan sebagai SnackBar yang
/// keburu hilang saat pengguna mengetik ulang.
class _ServerErrorMessage extends StatelessWidget {
  const _ServerErrorMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.rejectedBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.rejected, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline,
            size: 18,
            color: AppColors.rejected,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.rejected,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
