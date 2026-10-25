import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../../core/widgets/back_header.dart';
import '../../../../../../../core/widgets/field_label_row.dart';
import '../../domain/est_request_type.dart';
import '../widgets/est_photo_upload_field.dart';
import '../widgets/request_type_selector.dart';

/// Layar "+ Add Request"
///
/// Menutup diri dengan `true` lewat Navigator.pop kalau request tersimpan di
/// server (pemanggil lalu memuat ulang daftar), atau null kalau ditutup tanpa
/// submit.
///
/// Belum terhubung ke API: submit baru memvalidasi isian lalu memberi tahu
/// bahwa belum tersambung. Nama & departemen requester tidak perlu dikirim —
/// server memakai user yang login.
class AddEstRequestScreen extends StatefulWidget {
  const AddEstRequestScreen({super.key});

  @override
  State<AddEstRequestScreen> createState() => _AddEstRequestScreenState();
}

class _AddEstRequestScreenState extends State<AddEstRequestScreen> {
  EstRequestType? _type = EstRequestType.repair;
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _imageFileName;

  @override
  void dispose() {
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String? _validate() {
    if (_type == null) return 'Please select type of request.';
    if (_locationController.text.trim().isEmpty) {
      return 'Please fill in the location.';
    }
    if (_descriptionController.text.trim().isEmpty) {
      return 'Please fill in the description.';
    }
    return null;
  }

  void _submit() {
    final error = _validate();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    // TODO(est): kirim ke POST /est_work_order (multipart, foto opsional),
    // lalu `Navigator.pop(true)` agar daftar dimuat ulang. Sampai itu
    // tersambung, jangan pura-pura berhasil.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add Request is not connected to the server yet.'),
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.textMuted),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primaryMid, width: 1.5),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: BackHeader(
        title: 'Add Request',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const FieldLabelRow(label: 'Type of request'),
                RequestTypeSelector(
                  value: _type,
                  onChanged: (v) => setState(() => _type = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const FieldLabelRow(label: 'Location', required: true),
          TextField(
            controller: _locationController,
            style: AppTextStyles.body,
            decoration: _fieldDecoration('e.g. Block 3, unit 8'),
          ),
          const SizedBox(height: 18),
          const FieldLabelRow(label: 'Description', required: true),
          TextField(
            controller: _descriptionController,
            minLines: 4,
            maxLines: null,
            style: AppTextStyles.body,
            decoration: _fieldDecoration('Describe your request in detail'),
          ),
          const SizedBox(height: 18),
          const FieldLabelRow(label: 'Photo'),
          EstPhotoUploadField(
            fileName: _imageFileName,
            onTap: () {
              setState(() {
                _imageFileName = _imageFileName == null ? 'photo.jpg' : null;
              });
            },
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                'Submit request',
                style: AppTextStyles.buttonText.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
