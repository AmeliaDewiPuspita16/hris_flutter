import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/date_formatter.dart';
import '../../../../../../core/widgets/back_header.dart';
import '../../domain/it_request_item.dart';
import '../../domain/it_request_status.dart';
import '../../domain/need_option.dart';
import '../../domain/new_employee_data.dart';
import '../../domain/request_category.dart';
import '../../domain/support_type.dart';
import '../widgets/attachment_row_field.dart';
import '../widgets/field_label_row.dart';
import '../widgets/need_choice_chips.dart';
import '../widgets/need_option_group.dart';
import '../widgets/new_employee_subform.dart';
import '../widgets/request_category_selector.dart';
import '../widgets/support_type_selector.dart';

/// Layar "+ Add Request" — dibuka dari [ItFormAndMediaTab].
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
///
/// Versi ini mengganti tampilan dropdown/checkbox bawaan web dengan kartu,
/// segmented control, dan grup opsi yang cuma memberi jarak pada baris yang
/// sedang dipilih — lihat [RequestCategorySelector], [SupportTypeSelector],
/// dan [NeedOptionGroup].
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

  void _onCategoryChanged(RequestCategory category) {
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
    if (_category == null) return 'Please select a request type.';
    if (_supportType == null) return 'Please select a support type.';

    final option = _selectedOption;
    if (option == null) return 'Please choose one option under "What do you need".';

    switch (option.fieldKind) {
      case NeedFieldKind.textField:
        if (_specifyController(option.id).text.trim().isEmpty) {
          return 'Please fill in "${option.textHint}".';
        }
      case NeedFieldKind.newEmployeeForm:
        if (!_newEmployeeData.isComplete) {
          return 'Please complete the new employee details (name, employee '
              'number, type, and department).';
        }
      case NeedFieldKind.none:
      case NeedFieldKind.checkboxGroup:
        break;
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
        title: 'New Request',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          const FieldLabelRow(label: 'Request type', required: true),
          RequestCategorySelector(value: _category, onChanged: _onCategoryChanged),
          const SizedBox(height: 18),

          const FieldLabelRow(label: 'Support type', required: true),
          SupportTypeSelector(
            value: _supportType,
            onChanged: (v) => setState(() => _supportType = v),
          ),

          if (_category != null) ...[
            const SizedBox(height: 18),
            const FieldLabelRow(label: 'What do you need', required: true),
            NeedOptionGroup(
              options: _needOptions,
              selectedId: _selectedNeedId,
              onSelect: (id) => setState(() => _selectedNeedId = id),
              expandedChildBuilder: _buildExpandedField,
            ),
          ],

          if (_selectedOption != null) ...[
            const SizedBox(height: 18),
            const FieldLabelRow(label: 'Description', required: true),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              minLines: 4,
              style: AppTextStyles.body,
              decoration: InputDecoration(
                hintText: 'Describe your request in detail',
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
            const SizedBox(height: 18),

            const FieldLabelRow(label: 'Attachment'),
            AttachmentRowField(
              fileName: _attachmentFileName,
              onTap: () {
                setState(() {
                  _attachmentFileName =
                      _attachmentFileName == null ? 'attachment.jpg' : null;
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
        ],
      ),
    );
  }

  Widget? _buildExpandedField(NeedOption option) {
    switch (option.fieldKind) {
      case NeedFieldKind.none:
        return null;

      case NeedFieldKind.checkboxGroup:
        return NeedChoiceChips(
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
}