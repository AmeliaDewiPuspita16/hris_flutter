import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/back_header.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/employee_profile.dart';

/// Padanan tab "Address" di web.
class AlamatScreen extends StatefulWidget {
  const AlamatScreen({super.key, required this.profile});

  final EmployeeProfile profile;

  @override
  State<AlamatScreen> createState() => _AlamatScreenState();
}

class _AlamatScreenState extends State<AlamatScreen> {
  bool _editing = false;
  late final _addressCtrl = TextEditingController(text: widget.profile.address);

  @override
  void dispose() {
    _addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: BackHeader(title: 'Alamat', onBack: () => Navigator.of(context).pop()),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Alamat Domisili', style: AppTextStyles.label),
                      TextButton(
                        onPressed: () => setState(() => _editing = !_editing),
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                        child: Text(_editing ? 'Simpan' : 'Ubah', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryMid)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _editing
                      ? TextField(
                          controller: _addressCtrl,
                          maxLines: 3,
                          autofocus: true,
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.all(10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primaryMid, width: 1.5)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primaryMid, width: 1.5)),
                          ),
                        )
                      : Text(_addressCtrl.text, style: const TextStyle(fontSize: 13.5, color: AppColors.text, height: 1.5)),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text('* Perubahan alamat memerlukan verifikasi Admin HR sebelum aktif.', style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontStyle: FontStyle.italic)),
            ),
            if (_editing) ...[
              const SizedBox(height: 16),
              AppButton(label: 'Ajukan Perubahan Alamat', onPressed: () => setState(() => _editing = false)),
            ],
          ],
        ),
      ),
    );
  }
}