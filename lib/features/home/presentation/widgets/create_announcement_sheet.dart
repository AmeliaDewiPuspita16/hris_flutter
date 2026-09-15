import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/announcement.dart';

/// Modal untuk HR Publisher membuat pengumuman baru.
///
/// Sengaja dibikin sebagai bottom sheet, bukan halaman terpisah, biar nggak
/// nambah satu route baru cuma untuk form singkat begini.
///
/// Cara pakai:
/// ```dart
/// final result = await showModalBottomSheet<Announcement>(
///   context: context,
///   isScrollControlled: true,
///   backgroundColor: Colors.transparent,
///   builder: (_) => const CreateAnnouncementSheet(),
/// );
/// if (result != null) {
///   setState(() => _announcements = [result, ..._announcements]);
/// }
/// ```
class CreateAnnouncementSheet extends StatefulWidget {
  const CreateAnnouncementSheet({super.key});

  @override
  State<CreateAnnouncementSheet> createState() => _CreateAnnouncementSheetState();
}

class _CreateAnnouncementSheetState extends State<CreateAnnouncementSheet> {
  static const _tagOptions = [
    (value: AnnouncementTag.hr, label: 'HR'),
    (value: AnnouncementTag.ga, label: 'GA'),
    (value: AnnouncementTag.it, label: 'IT'),
  ];

  AnnouncementTag _tag = AnnouncementTag.hr;
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  String? _titleError;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = 'Title is required');
      return;
    }

    final body = _bodyCtrl.text.trim();
    Navigator.of(context).pop(
      Announcement(
        tag: _tag,
        time: 'Just now',
        title: title,
        body: body.isEmpty ? null : body,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    const Expanded(
                      child: Text('New Announcement', style: AppTextStyles.h2),
                    ),
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(16),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.close, size: 20, color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                AppDropdown<AnnouncementTag>(
                  label: 'Department',
                  value: _tag,
                  required: true,
                  items: _tagOptions,
                  onChanged: (v) => setState(() => _tag = v),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Title',
                  controller: _titleCtrl,
                  hint: 'e.g. Office closed for public holiday',
                  required: true,
                  onChanged: _titleError == null
                      ? null
                      : (_) => setState(() => _titleError = null),
                ),
                if (_titleError != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _titleError!,
                    style: const TextStyle(fontSize: 11, color: AppColors.rejected),
                  ),
                ],
                const SizedBox(height: 16),
                Text('Details (optional)', style: AppTextStyles.label),
                const SizedBox(height: 6),
                TextField(
                  controller: _bodyCtrl,
                  maxLines: 3,
                  style: AppTextStyles.body,
                  decoration: InputDecoration(
                    hintText: 'Add more context for employees...',
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
                  ),
                ),
                const SizedBox(height: 20),
                AppButton(
                  label: 'Post Announcement',
                  variant: AppButtonVariant.green,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
