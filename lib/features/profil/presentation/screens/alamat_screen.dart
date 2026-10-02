import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/back_header.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/profile_ui.dart';
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
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const TintedIcon(Icons.location_on_outlined),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text('Alamat Domisili', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text)),
                      ),
                      PillButton(
                        label: _editing ? 'Simpan' : 'Ubah',
                        filled: _editing,
                        onPressed: () => setState(() => _editing = !_editing),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Teks alamat sejajar dengan judul (ikon 40 + jarak 14 = 54).
                  Padding(
                    padding: const EdgeInsets.only(left: 54),
                    child: _editing
                        ? TextField(
                            controller: _addressCtrl,
                            maxLines: 3,
                            autofocus: true,
                            keyboardType: TextInputType.streetAddress,
                            style: const TextStyle(fontSize: 14),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.all(10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                            ),
                          )
                        : Text(_addressCtrl.text, style: const TextStyle(fontSize: 14, color: AppColors.text, height: 1.6)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const InfoNote('Perubahan alamat memerlukan verifikasi Admin HR sebelum aktif.'),
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
