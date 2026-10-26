import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/back_header.dart';
import '../../../../core/widgets/profile_ui.dart';
import '../../data/profil_repository.dart';

/// Form ganti password, meniru menu "Update Password" di web portal:
/// password lama, password baru, dan konfirmasinya.
///
/// Memanggil [ProfilRepository.updatePassword] sendiri lalu kembali ke
/// Profil dengan `true` lewat Navigator.pop kalau berhasil.
class UpdatePasswordScreen extends StatefulWidget {
  const UpdatePasswordScreen({super.key, this.repository});

  /// Minimal panjang password baru — sama dengan aturan server.
  static const minLength = 8;

  /// Diisi test; di aplikasi diambil dari [RepositoryProvider].
  final ProfilRepository? repository;

  @override
  State<UpdatePasswordScreen> createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends State<UpdatePasswordScreen> {
  late final ProfilRepository _repository;

  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;

  /// Pesan validasi baru tampil setelah tombol pertama kali ditekan.
  bool _submitted = false;
  bool _submitting = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? context.read<ProfilRepository>();
  }

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String? get _currentError =>
      _currentCtrl.text.isEmpty ? 'Current password is required' : null;

  String? get _newError {
    final value = _newCtrl.text;
    if (value.isEmpty) return 'New password is required';
    if (value.length < UpdatePasswordScreen.minLength) {
      return 'New password must be at least ${UpdatePasswordScreen.minLength} characters';
    }
    if (value == _currentCtrl.text) {
      return 'New password must be different from the current one';
    }
    return null;
  }

  String? get _confirmError {
    if (_confirmCtrl.text.isEmpty) return 'Please confirm the new password';
    if (_confirmCtrl.text != _newCtrl.text) return 'Passwords do not match';
    return null;
  }

  bool get _isValid =>
      _currentError == null && _newError == null && _confirmError == null;

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _submitted = true;
      _submitError = null;
    });
    if (!_isValid || _submitting) return;

    setState(() => _submitting = true);
    try {
      await _repository.updatePassword(
        currentPassword: _currentCtrl.text,
        newPassword: _newCtrl.text,
        confirmation: _confirmCtrl.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitError = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: BackHeader(
        title: 'Update Password',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _passwordField(
                    label: 'Current Password',
                    controller: _currentCtrl,
                    visible: _showCurrent,
                    onToggle: () =>
                        setState(() => _showCurrent = !_showCurrent),
                    error: _currentError,
                  ),
                  const SizedBox(height: 14),
                  _passwordField(
                    label: 'New Password',
                    controller: _newCtrl,
                    visible: _showNew,
                    onToggle: () => setState(() => _showNew = !_showNew),
                    error: _newError,
                  ),
                  const SizedBox(height: 14),
                  _passwordField(
                    label: 'Confirm New Password',
                    controller: _confirmCtrl,
                    visible: _showConfirm,
                    onToggle: () =>
                        setState(() => _showConfirm = !_showConfirm),
                    error: _confirmError,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const InfoNote(
              'Use at least ${UpdatePasswordScreen.minLength} characters. '
              'You will stay signed in on this device.',
            ),
            if (_submitError != null) ...[
              const SizedBox(height: 12),
              Text(
                _submitError!,
                style:
                    const TextStyle(fontSize: 12.5, color: AppColors.rejected),
              ),
            ],
            const SizedBox(height: 20),
            AppButton(
              label: 'Update Password',
              variant: AppButtonVariant.primaryGradient,
              isLoading: _submitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _passwordField({
    required String label,
    required TextEditingController controller,
    required bool visible,
    required VoidCallback onToggle,
    required String? error,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          label: label,
          controller: controller,
          hint: label,
          obscureText: !visible,
          // Rebuild supaya pesan validasi ikut berubah saat mengetik.
          onChanged: (_) => setState(() {}),
          suffixIcon: IconButton(
            onPressed: onToggle,
            tooltip: visible ? 'Hide password' : 'Show password',
            icon: Icon(
              visible
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 20,
              color: AppColors.textMuted,
            ),
          ),
        ),
        if (_submitted && error != null) ...[
          const SizedBox(height: 4),
          Text(error,
              style:
                  const TextStyle(fontSize: 11.5, color: AppColors.rejected)),
        ],
      ],
    );
  }
}
