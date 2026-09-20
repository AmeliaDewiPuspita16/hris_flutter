import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../../core/utils/date_formatter.dart';
import '../../../../../../../core/widgets/app_attachment_field.dart';
import '../../../../../../../core/widgets/app_dropdown.dart';
import '../../../../../../../core/widgets/app_text_field.dart';
import '../../../../../../../core/widgets/back_header.dart';
import '../../domain/est_request_item.dart';
import '../../domain/est_request_status.dart';
import '../../domain/est_request_type.dart';

/// Layar "+ Add Request"
///
/// Mengembalikan [EstRequestItem] baru lewat Navigator.pop kalau berhasil
/// disubmit, atau null kalau ditutup tanpa submit. Belum terhubung ke API —
/// Nama & departemen requester untuk sementara di-hardcode ke user yang sedang
/// login belum tersedia di sini — tinggal disambungkan ke sesi auth nanti.
class AddEstRequestScreen extends StatefulWidget {
  const AddEstRequestScreen({super.key});

  @override
  State<AddEstRequestScreen> createState() => _AddEstRequestScreenState();
}

class _AddEstRequestScreenState extends State<AddEstRequestScreen> {
  EstRequestType? _type;
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

    final now = DateTime.now();
    final item = EstRequestItem(
      id: 'est-${now.microsecondsSinceEpoch}',
      // TODO: ambil dari sesi auth begitu tersambung — lihat catatan role
      // serupa di ItRequestScreen/auth_gate.dart.
      requesterName: 'Anda',
      department: '-',
      type: _type!,
      location: _locationController.text.trim(),
      description: _descriptionController.text.trim(),
      date: DateFormatter.shortDate(now),
      status: EstRequestStatus.onWaiting,
      imageFileName: _imageFileName,
    );

    Navigator.of(context).pop(item);
  }

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
          AppDropdown<EstRequestType>(
            label: 'Type of Request',
            required: true,
            value: _type ?? EstRequestType.repair,
            items: [
              for (final t in EstRequestType.values) (value: t, label: t.label),
            ],
            onChanged: (v) => setState(() => _type = v),
          ),
          const SizedBox(height: 18),
          AppAttachmentField(
            label: 'Image',
            hint: '*.png / *.jpg / *.jpeg — max 2MB',
            fileName: _imageFileName,
            onTap: () {
              setState(() {
                _imageFileName = _imageFileName == null ? 'photo.jpg' : null;
              });
            },
          ),
          const SizedBox(height: 18),
          AppTextField(
            label: 'Location',
            required: true,
            controller: _locationController,
            hint: 'Contoh: Blok 3 unit 8',
          ),
          const SizedBox(height: 18),
          AppTextField(
            label: 'Description',
            required: true,
            controller: _descriptionController,
            hint: 'Jelaskan detail permintaan Anda',
            minLines: 4,
            maxLines: null,
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
                'Submit',
                style: AppTextStyles.buttonText.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
