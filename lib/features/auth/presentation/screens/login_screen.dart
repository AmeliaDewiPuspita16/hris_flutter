import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../home/presentation/screens/beranda_screen.dart';
import '../../../shared/domain/role.dart';
import '../controllers/login_form_controller.dart';
import '../widgets/keep_signed_in_row.dart';
import '../widgets/login_alt_button.dart';
import '../widgets/login_field.dart';
import '../widgets/login_footer.dart';
import '../widgets/login_header.dart';
import '../widgets/or_divider.dart';

/// Halaman login BIIE Portal.
///
/// Layar ini hanya merangkai widget; state form-nya dipegang
/// [LoginFormController] dan aturan validasinya ada di LoginCredentials.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = LoginFormController();

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  /// Belum ada autentikasi — kalau input valid, langsung ke Beranda.
  void _handleSignIn() {
    if (!_form.submit()) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const BerandaScreen(role: Role.hrPublisher)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgWarm,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const LoginHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: AnimatedBuilder(
                animation: _form,
                builder: (context, _) => _LoginForm(
                  form: _form,
                  onSignIn: _handleSignIn,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({required this.form, required this.onSignIn});

  final LoginFormController form;
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
        const SizedBox(height: 20),
        AppButton(label: 'Sign in', onPressed: onSignIn),
        const SizedBox(height: 20),
        const OrDivider(),
        const SizedBox(height: 20),
        LoginAltButton(label: 'Use Face ID', onPressed: () {}),
        const SizedBox(height: 28),
        const LoginFooter(),
      ],
    );
  }
}
