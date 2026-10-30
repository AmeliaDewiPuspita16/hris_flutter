import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../domain/executive_dashboard.dart';
import 'est_photo_source_sheet.dart';

/// Isian sheet "Tutup Sesi Hari Ini".
class EstCloseSessionInput {
  const EstCloseSessionInput({
    required this.description,
    required this.photoPaths,
  });

  final String description;
  final List<String> photoPaths;
}

/// Sheet penutupan sesi: deskripsi wajib (min. 10 karakter) dan foto opsional
/// (maks. 10). Hasil null = dibatalkan.
class EstCloseSessionSheet extends StatefulWidget {
  const EstCloseSessionSheet({
    super.key,
    required this.project,
    required this.autoClockOut,
  });

  final ExecutiveProjectModel project;
  final bool autoClockOut;

  static Future<EstCloseSessionInput?> show(
    BuildContext context,
    ExecutiveProjectModel project, {
    required bool autoClockOut,
  }) {
    return showModalBottomSheet<EstCloseSessionInput>(
      context: context,
      backgroundColor: AppColors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => EstCloseSessionSheet(
        project: project,
        autoClockOut: autoClockOut,
      ),
    );
  }

  @override
  State<EstCloseSessionSheet> createState() => _EstCloseSessionSheetState();
}

class _EstCloseSessionSheetState extends State<EstCloseSessionSheet> {
  static const _maxPhotos = 10;

  final _descController = TextEditingController();
  final _selectedPhotos = <XFile>[];
  final _picker = ImagePicker();

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1920,
    );
    if (picked != null && mounted) setState(() => _selectedPhotos.add(picked));
  }

  Future<void> _pickMultiplePhotos() async {
    final picked = await _picker.pickMultiImage(
      imageQuality: 80,
      maxWidth: 1920,
    );
    if (picked.isEmpty || !mounted) return;
    setState(() {
      for (final img in picked) {
        if (_selectedPhotos.length < _maxPhotos) _selectedPhotos.add(img);
      }
    });
  }

  Future<void> _showPickerOptions() async {
    final source = await EstPhotoSourceSheet.show(context);
    if (source == null) return;
    if (source == ImageSource.gallery) {
      await _pickMultiplePhotos();
    } else {
      await _pickPhoto(source);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.rejected,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _submit() {
    final desc = _descController.text.trim();
    if (desc.isEmpty) {
      _showError('Deskripsi pekerjaan wajib diisi');
      return;
    }
    if (desc.length < 10) {
      _showError('Deskripsi minimal 10 karakter');
      return;
    }
    Navigator.pop(
      context,
      EstCloseSessionInput(
        description: desc,
        photoPaths: _selectedPhotos.map((x) => x.path).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.project;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.presentBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.lock_outline,
                    color: AppColors.primaryText,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tutup Sesi Hari Ini',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                      Text(
                        project.name,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSub,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (widget.autoClockOut) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.orangeBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.orange,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${project.notClockedOut} DW akan otomatis di-clock out dengan waktu sekarang.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.orange,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 20),

            // ── Deskripsi ─────────────────────────────
            Text(
              'Deskripsi Pekerjaan Hari Ini',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Wajib diisi — jelaskan progres pekerjaan hari ini',
              style: TextStyle(fontSize: 12, color: AppColors.textSub),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descController,
              maxLines: 4,
              maxLength: 500,
              style: TextStyle(fontSize: 14, color: AppColors.text),
              decoration: InputDecoration(
                hintText: 'Contoh: Pengecoran lantai 3 selesai 80%...',
                hintStyle: TextStyle(fontSize: 13, color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.bg,
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: AppColors.primaryText, width: 1.5),
                ),
                counterStyle: TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ),

            // ── Upload Foto ───────────────────────────
            const SizedBox(height: 20),
            Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Foto Pekerjaan',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '(opsional)',
                  style: TextStyle(fontSize: 12, color: AppColors.textSub),
                ),
                const Spacer(),
                if (_selectedPhotos.isNotEmpty)
                  Text(
                    '${_selectedPhotos.length}/$_maxPhotos',
                    style: TextStyle(fontSize: 12, color: AppColors.textSub),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < _selectedPhotos.length; i++)
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          File(_selectedPhotos[i].path),
                          width: 76,
                          height: 76,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: -6,
                        right: -6,
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedPhotos.removeAt(i)),
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: AppColors.rejected,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                if (_selectedPhotos.length < _maxPhotos)
                  GestureDetector(
                    onTap: _showPickerOptions,
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: AppColors.presentBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.primaryText.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            color: AppColors.primaryText,
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tambah',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.primaryText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.lock_outline, size: 18),
                label: const Text(
                  'Tutup Sesi & Simpan',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Batal',
                  style: TextStyle(
                    color: AppColors.textSub,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }
}
