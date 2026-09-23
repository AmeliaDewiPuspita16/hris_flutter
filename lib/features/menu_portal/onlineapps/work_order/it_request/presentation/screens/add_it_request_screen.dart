import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart' as picker;

import '../../../../../../../core/logging/app_logger.dart';
import '../../../../../../../core/network/api_exception.dart';
import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../../core/widgets/app_text_field.dart';
import '../../../../../../../core/widgets/back_header.dart';
import '../../../../../../../core/widgets/field_label_row.dart';
import '../../../../../../shared/data/department_repository.dart';
import '../../../../../../shared/domain/department.dart';
import '../../data/it_request_repository.dart';
import '../../domain/it_request_attachment.dart';
import '../../domain/it_request_item.dart';
import '../../domain/it_request_type.dart';
import '../../domain/need_option.dart';
import '../../domain/new_employee_data.dart';
import '../../domain/request_category.dart';
import '../../domain/support_type.dart';
import '../widgets/attachment_row_field.dart';
import '../widgets/need_choice_chips.dart';
import '../widgets/need_option_group.dart';
import '../widgets/new_employee_subform.dart';
import '../widgets/request_category_selector.dart';
import '../widgets/support_type_selector.dart';

/// Membuka galeri dan mengembalikan gambar yang dipilih, atau null kalau
/// dibatalkan.
///
/// Disuntik lewat konstruktor supaya test bisa menggantinya tanpa perlu
/// plugin galeri sungguhan — pola sama dengan `PhotoPicker` di form
/// pengumuman.
typedef AttachmentPicker = Future<ItRequestAttachment?> Function();

/// Layar "+ Add Request" — dibuka dari [ItFormAndMediaTab].
///
/// Sengaja dibuat sebagai halaman penuh, bukan bottom sheet, karena
/// field-nya dinamis dan bisa jadi cukup panjang (terutama sub-form "New
/// employee account creation") — akan sulit dipakai kalau harus scroll di
/// dalam sheet yang berbagi layar dengan latar belakang.
///
/// Mengirim ke `POST /api/portal/apps/it_request` lewat [ItRequestRepository]
/// dan mengembalikan [ItRequestItem] (bentuknya [ItRequestDetail], hasil
/// dari server) lewat Navigator.pop kalau berhasil, atau null kalau ditutup
/// tanpa submit. Galat ditangani dengan setState lokal (bukan bloc) — ini
/// satu aksi sekali-jalan yang terikat ke satu layar, pola sama dengan
/// `CreateAnnouncementSheet`.
///
/// Versi ini mengganti tampilan dropdown/checkbox bawaan web dengan kartu,
/// segmented control, dan grup opsi yang cuma memberi jarak pada baris yang
/// sedang dipilih — lihat [RequestCategorySelector], [SupportTypeSelector],
/// dan [NeedOptionGroup].
class AddItRequestScreen extends StatefulWidget {
  const AddItRequestScreen({
    super.key,
    this.repository,
    this.departmentRepository,
    this.pickAttachment,
  });

  final ItRequestRepository? repository;
  final DepartmentRepository? departmentRepository;

  /// Null berarti memakai galeri sungguhan lewat image_picker.
  final AttachmentPicker? pickAttachment;

  @override
  State<AddItRequestScreen> createState() => _AddItRequestScreenState();
}

class _AddItRequestScreenState extends State<AddItRequestScreen> {
  late final ItRequestRepository _repository;
  late final DepartmentRepository _departmentRepository;

  RequestCategory? _category = RequestCategory.it;
  SupportType? _supportType;
  String? _selectedNeedId;

  final Map<String, Set<String>> _checkboxSelections = {};
  final Map<String, TextEditingController> _specifyControllers = {};
  final _usernameDescController = TextEditingController();
  NewEmployeeData _newEmployeeData = const NewEmployeeData();

  final _descriptionController = TextEditingController();

  ItRequestAttachment? _attachment;
  String? _attachmentError;

  List<Department> _departments = const [];
  String? _departmentsError;

  String? _submitError;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? context.read<ItRequestRepository>();
    _departmentRepository =
        widget.departmentRepository ?? context.read<DepartmentRepository>();
    _loadDepartments();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _usernameDescController.dispose();
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

  Future<void> _loadDepartments() async {
    setState(() => _departmentsError = null);
    try {
      final departments = await _departmentRepository.getActiveDepartments();
      if (!mounted) return;
      setState(() => _departments = departments);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _departmentsError = e.message);
    }
  }

  void _onCategoryChanged(RequestCategory category) {
    setState(() {
      _category = category;
      // Daftar "What do you need?" total berbeda antara IT & Media, jadi
      // pilihan dan sub-field sebelumnya sudah tidak relevan lagi.
      _selectedNeedId = null;
      _checkboxSelections.clear();
      _usernameDescController.clear();
      _newEmployeeData = const NewEmployeeData();
      for (final controller in _specifyControllers.values) {
        controller.dispose();
      }
      _specifyControllers.clear();
    });
  }

  /// True kalau checkbox "New username" pada grup Account management
  /// sedang tercentang — satu-satunya opsi yang butuh field tambahan di
  /// atas checkbox group-nya sendiri (`username_desc` wajib diisi).
  bool _needsUsernameDesc(NeedOption option) =>
      option.id == 'account_mgmt' &&
      (_checkboxSelections[option.id]?.contains('New username') ?? false);

  String? _validate() {
    if (_category == null) return 'Please select a request type.';
    if (_supportType == null) return 'Please select a support type.';

    final option = _selectedOption;
    if (option == null) {
      return 'Please choose one option under "What do you need".';
    }

    switch (option.fieldKind) {
      case NeedFieldKind.textField:
        if (_specifyController(option.id).text.trim().isEmpty) {
          return 'Please fill in "${option.textHint}".';
        }
      case NeedFieldKind.checkboxGroup:
        if ((_checkboxSelections[option.id] ?? const <String>{}).isEmpty) {
          return 'Please select at least one option in "What do you need?".';
        }
        if (_needsUsernameDesc(option) &&
            _usernameDescController.text.trim().isEmpty) {
          return 'Please specify the desired username.';
        }
      case NeedFieldKind.newEmployeeForm:
        if (!_newEmployeeData.isComplete) {
          return 'Please complete the new employee details (name, employee '
              'number, type, and department).';
        }
      case NeedFieldKind.none:
        break;
    }

    if (_descriptionController.text.trim().isEmpty) {
      return 'Please fill in the description.';
    }

    return null;
  }

  /// Field tambahan spesifik kategori, sudah diresolusi ke nama field
  /// server lewat metadata yang menempel di [NeedOption] — lihat
  /// `NeedOptionCatalog`.
  Map<String, String> _categoryFields(NeedOption option) {
    final selected = _checkboxSelections[option.id] ?? const <String>{};

    return {
      for (final label in selected)
        option.checkboxFieldCodes[option.checkboxLabels.indexOf(label)]: '1',
      if (option.textFieldCode != null)
        option.textFieldCode!: _specifyController(option.id).text.trim(),
      if (_needsUsernameDesc(option))
        'username_desc': _usernameDescController.text.trim(),
      if (option.fieldKind == NeedFieldKind.newEmployeeForm) ..._newEmployeeFields(),
    };
  }

  Map<String, String> _newEmployeeFields() {
    final data = _newEmployeeData;
    return {
      'new_employee_name': data.fullName.trim(),
      if (data.preferredName.trim().isNotEmpty)
        'new_employee_preferred_name': data.preferredName.trim(),
      'new_employee_number': data.employeeNumber.trim(),
      'new_employee_level': data.executiveType!.label,
      'new_employee_department': '${data.department!.id}',
      if (data.section.trim().isNotEmpty) 'new_employee_section': data.section.trim(),
      for (final label in data.equipmentNeeded)
        NewEmployeeEquipment.fieldCodes[label]!: '1',
    };
  }

  Future<ItRequestAttachment?> _pickFromGallery() async {
    final file = await picker.ImagePicker().pickImage(source: picker.ImageSource.gallery);
    if (file == null) return null;

    return ItRequestAttachment(
      path: file.path,
      fileName: file.name,
      sizeBytes: await file.length(),
    );
  }

  Future<void> _pickAttachment() async {
    if (_submitting) return;

    if (_attachment != null) {
      setState(() {
        _attachment = null;
        _attachmentError = null;
      });
      return;
    }

    final pick = widget.pickAttachment ?? _pickFromGallery;

    final ItRequestAttachment? picked;
    try {
      picked = await pick();
    } catch (e) {
      if (mounted) setState(() => _attachmentError = 'Tidak bisa membuka galeri.');
      return;
    }

    if (!mounted || picked == null) return;

    final error = picked.validationError;
    setState(() {
      if (error != null) {
        _attachmentError = error;
      } else {
        _attachment = picked;
        _attachmentError = null;
      }
    });
  }

  Future<void> _submit() async {
    final error = _validate();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    if (_submitting) return;

    setState(() {
      _submitting = true;
      _submitError = null;
    });

    final option = _selectedOption!;

    try {
      final detail = await _repository.submit(
        type: _category == RequestCategory.media ? ItRequestType.media : ItRequestType.it,
        supportType: _supportType!,
        requestCategoryCode: option.requestCategoryCode,
        description: _descriptionController.text.trim(),
        categoryFields: _categoryFields(option),
        imagePath: _attachment?.path,
      );

      if (!mounted) return;
      Navigator.of(context).pop(detail);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitError = e.message;
        _submitting = false;
      });
    } catch (e, stack) {
      // Berkas yang sudah terhapus setelah dipilih sampai ke sini sebagai
      // FileSystemException — tidak boleh bocor mentah ke layar.
      AppLogger.error('Gagal mengajukan IT request', e, stack);
      if (!mounted) return;
      setState(() {
        _submitError = 'Gagal mengajukan request. Coba lagi.';
        _submitting = false;
      });
    }
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
                const FieldLabelRow(label: 'Request type'),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border, width: 1.2),
                  ),
                  child: RequestCategorySelector(
                    value: _category,
                    onChanged: _onCategoryChanged,
                  ),
                ),
                const SizedBox(height: 16),
                const FieldLabelRow(label: 'Support type'),
                SupportTypeSelector(
                  value: _supportType,
                  onChanged: (v) => setState(() => _supportType = v),
                ),
              ],
            ),
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
              minLines: 1,
              maxLines: null,
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
              fileName: _attachment?.fileName,
              onTap: _pickAttachment,
            ),
            if (_attachmentError != null) ...[
              const SizedBox(height: 6),
              Text(
                _attachmentError!,
                style: const TextStyle(fontSize: 11, color: AppColors.rejected),
              ),
            ],
            if (_submitError != null) ...[
              const SizedBox(height: 16),
              _FormError(message: _submitError!),
            ],
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Text(
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            NeedChoiceChips(
              labels: option.checkboxLabels,
              selected: _checkboxSelections[option.id] ?? const {},
              onChanged: (v) => setState(() => _checkboxSelections[option.id] = v),
            ),
            if (_needsUsernameDesc(option)) ...[
              const SizedBox(height: 12),
              AppTextField(
                label: 'Desired username',
                controller: _usernameDescController,
                hint: 'e.g. andi.pratama',
                required: true,
              ),
            ],
          ],
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
          departments: _departments,
          departmentsError: _departmentsError,
          onRetryLoadDepartments: _loadDepartments,
        );
    }
  }
}

/// Pesan galat dari server, ditaruh tepat di atas tombol submit.
class _FormError extends StatelessWidget {
  const _FormError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.rejectedBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.rejected),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 16, color: AppColors.rejected),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12, color: AppColors.rejected),
            ),
          ),
        ],
      ),
    );
  }
}
