import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/date_formatter.dart';
import '../../../../../../core/widgets/app_attachment_field.dart';
import '../../../../../../core/widgets/app_button.dart';
import '../../../../../../core/widgets/app_card.dart';
import '../../../../../../core/widgets/app_dropdown.dart';
import '../../../../../../core/widgets/app_text_field.dart';
import '../../../../../../core/widgets/back_header.dart';
import '../../domain/it_request_item.dart';
import '../../domain/it_request_status.dart';
import '../../domain/need_option.dart';
import '../../domain/new_employee_data.dart';
import '../../domain/request_category.dart';
import '../../domain/support_type.dart';
import '../widgets/need_checkbox_group.dart';
import '../widgets/need_option_tile.dart';
import '../widgets/new_employee_subform.dart';

/// Layar "+ Ajukan Request" (Add Request) — dibuka dari [ItRequestScreen].
///
/// Sengaja dibuat sebagai halaman penuh, bukan bottom sheet, karena
/// field-nya dinamis dan bisa jadi cukup panjang (terutama sub-form "New
/// employee account creation") — akan sulit dipakai kalau harus scroll di
/// dalam sheet yang berbagi layar dengan latar belakang.
///
/// Mengembalikan [ItRequestItem] baru lewat Navigator.pop kalau berhasil
/// disubmit, atau null kalau ditutup tanpa submit. Belum terhubung ke API —
/// sesuai pola fitur ini sekarang (lihat [ItRequestDemoData]), item baru
/// murni disusun dari isian form di sini.
class AddItRequestScreen extends StatefulWidget {
  const AddItRequestScreen({super.key});

  @override
  State<AddItRequestScreen> createState() => _AddItRequestScreenState();
}

class _AddItRequestScreenState extends State<AddItRequestScreen> {
  RequestCategory? _category;
  SupportType? _supportType;
  String? _selectedNeedId;

  final Map<String, Set<String>> _checkboxSelections = {};
  final Map<String, TextEditingController> _specifyControllers = {};
  NewEmployeeData _newEmployeeData = const NewEmployeeData();

  final _descriptionController = TextEditingController();
  String? _attachmentFileName;

  @override
  void dispose() {
    _descriptionController.dispose();
    for (final controller in _specifyControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  List<NeedOption> get _needOptions =>
      _category == null ? const [] : NeedOptionCatalog.optionsFor(_category!);

  NeedOption? get _selectedOption {
    for (final option in _needOptions) {
      if (option.id == _selectedNeedId) return option;
    }
    return null;
  }

  TextEditingController _specifyController(String optionId) =>
      _specifyControllers.putIfAbsent(optionId, () => TextEditingController());

  void _onCategoryChanged(RequestCategory? category) {
    setState(() {
      _category = category;
      // Daftar "What do you need?" total berbeda antara IT & Media, jadi
      // pilihan dan sub-field sebelumnya sudah tidak relevan lagi.
      _selectedNeedId = null;
      _checkboxSelections.clear();
      _newEmployeeData = const NewEmployeeData();
      for (final controller in _specifyControllers.values) {
        controller.dispose();
      }
      _specifyControllers.clear();
    });
  }

  String? _validate() {
    if (_category == null) return 'Pilih Type request dulu ya.';
    if (_supportType == null) return 'Pilih Support type dulu ya.';

    final option = _selectedOption;
    if (option == null) return 'Pilih salah satu di "What do you need?" dulu ya.';

    switch (option.fieldKind) {
      case NeedFieldKind.textField:
        if (_specifyController(option.id).text.trim().isEmpty) {
          return 'Isi kolom "${option.textHint}" dulu ya.';
        }
      case NeedFieldKind.newEmployeeForm:
        if (!_newEmployeeData.isComplete) {
          return 'Lengkapi dulu data karyawan baru (nama, nomor karyawan, '
              'tipe, dan department).';
        }
      case NeedFieldKind.none:
      case NeedFieldKind.checkboxGroup:
        break;
    }

    if (_descriptionController.text.trim().isEmpty) {
      return 'Isi Description dulu ya.';
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
    final item = ItRequestItem(
      id: 'req-${now.microsecondsSinceEpoch}',
      description: _descriptionController.text.trim(),
      date: DateFormatter.shortDate(now),
      status: ItRequestStatus.waitingHod,
    );

    Navigator.of(context).pop(item);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: BackHeader(
        title: 'Ajukan Request',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _sectionLabel('REQUEST CATEGORY'),
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppDropdown<RequestCategory?>(
                          label: 'Type request',
                          required: true,
                          value: _category,
                          items: [
                            (value: null, label: '-- Select --'),
                            for (final c in RequestCategory.values) (value: c, label: c.label),
                          ],
                          onChanged: _onCategoryChanged,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppDropdown<SupportType?>(
                          label: 'Support type',
                          required: true,
                          value: _supportType,
                          items: [
                            (value: null, label: '-- Select --'),
                            for (final s in SupportType.values) (value: s, label: s.label),
                          ],
                          onChanged: (v) => setState(() => _supportType = v),
                        ),
                      ),
                    ],
                  ),
                  if (_category != null) ...[
                    const SizedBox(height: 22),
                    _sectionLabel('WHAT DO YOU NEED?', required: true),
                    const SizedBox(height: 10),
                    for (var i = 0; i < _needOptions.length; i++) ...[
                      if (i > 0) const SizedBox(height: 10),
                      NeedOptionTile(
                        option: _needOptions[i],
                        selected: _selectedNeedId == _needOptions[i].id,
                        onSelect: () => setState(() => _selectedNeedId = _needOptions[i].id),
                        expandedChild: _buildExpandedField(_needOptions[i]),
                      ),
                    ],
                  ],
                  if (_selectedOption != null) ...[
                    const SizedBox(height: 22),
                    AppTextField(
                      label: 'Description',
                      controller: _descriptionController,
                      hint: 'Describe your request / repair / return in detail',
                      required: true,
                      maxLines: 5,
                      minLines: 4,
                    ),
                    const SizedBox(height: 22),
                    AppAttachmentField(
                      label: 'Attachment (optional)',
                      fileName: _attachmentFileName,
                      onTap: () {
                        setState(() {
                          _attachmentFileName =
                              _attachmentFileName == null ? 'lampiran.jpg' : null;
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            AppButton(
              label: 'Submit',
              variant: AppButtonVariant.primary,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildExpandedField(NeedOption option) {
    switch (option.fieldKind) {
      case NeedFieldKind.none:
        return null;

      case NeedFieldKind.checkboxGroup:
        return NeedCheckboxGroup(
          labels: option.checkboxLabels,
          selected: _checkboxSelections[option.id] ?? const {},
          onChanged: (v) => setState(() => _checkboxSelections[option.id] = v),
        );

      case NeedFieldKind.textField:
        return TextField(
          controller: _specifyController(option.id),
          style: AppTextStyles.body,
          decoration: InputDecoration(
            hintText: option.textHint,
            hintStyle: AppTextStyles.body.copyWith(color: AppColors.textMuted),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
        );

      case NeedFieldKind.newEmployeeForm:
        return NewEmployeeSubform(
          data: _newEmployeeData,
          onChanged: (v) => setState(() => _newEmployeeData = v),
        );
    }
  }

  Widget _sectionLabel(String text, {bool required = false}) {
    return RichText(
      text: TextSpan(
        style: AppTextStyles.sectionTitle.copyWith(
          fontSize: 11,
          letterSpacing: 0.3,
          color: AppColors.textMuted,
        ),
        children: [
          TextSpan(text: text),
          if (required) const TextSpan(text: ' *', style: TextStyle(color: AppColors.rejected)),
        ],
      ),
    );
  }
}