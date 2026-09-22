import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/widgets/app_button.dart';
import '../../../../../../core/widgets/app_card.dart';
import '../../../../../../core/widgets/app_date_range_field.dart';
import '../../../../../../core/widgets/app_dropdown.dart';
import '../../../../../../core/widgets/app_text_field.dart';
import '../../../../../../core/widgets/back_header.dart';
import '../../data/hse_work_request_repository.dart';
import '../../domain/hse_checklist_catalog.dart';
import '../../domain/hse_request_category.dart';
import '../../domain/hse_work_request.dart';
import '../widgets/hse_checklist_group.dart';
import '../widgets/hse_choice_chip_group.dart';
import '../widgets/hse_wizard_header.dart';

/// Wizard "Add Permit Request".
///
/// 3 grup checklist (General Checklist, Type of Works, PPE — total 30+ opsi)
/// Di sini dipecah 4 step (Detail Pekerjaan → General Checklist → Jenis Pekerjaan &
/// APD → Review).
class HseWorkRequestFormScreen extends StatefulWidget {
  HseWorkRequestFormScreen({super.key, HseWorkRequestRepository? repository})
      : repository = repository ?? HseWorkRequestRepository();

  final HseWorkRequestRepository repository;

  @override
  State<HseWorkRequestFormScreen> createState() => _HseWorkRequestFormScreenState();
}

class _HseWorkRequestFormScreenState extends State<HseWorkRequestFormScreen> {
  static const _stepTitles = [
    'Detail Pekerjaan',
    'General Checklist',
    'Jenis Pekerjaan & APD',
    'Review & Submit',
  ];

  final _pageController = PageController();
  int _step = 0;
  bool _isSubmitting = false;

  // Step 1 — detail pekerjaan.
  final _picController = TextEditingController();
  final _locationController = TextEditingController();
  final _materialsController = TextEditingController();
  final _vendorController = TextEditingController();
  final _totalWorkersController = TextEditingController();
  String? _department;
  HseRequestCategory _category = HseRequestCategory.rutin;
  DateTime? _dateStart;
  DateTime? _dateEnd;

  // Step 2 — general checklist.
  final _generalChecklist = <String>{};
  final _otherGeneralController = TextEditingController();

  // Step 3 — jenis pekerjaan & APD.
  final _typeOfWorks = <String>{};
  final _otherTypeOfWorkController = TextEditingController();
  final _ppe = <String>{};
  final _otherPpeController = TextEditingController();

  @override
  void dispose() {
    _pageController.dispose();
    _picController.dispose();
    _locationController.dispose();
    _materialsController.dispose();
    _vendorController.dispose();
    _totalWorkersController.dispose();
    _otherGeneralController.dispose();
    _otherTypeOfWorkController.dispose();
    _otherPpeController.dispose();
    super.dispose();
  }

  bool get _step1Valid =>
      _picController.text.trim().isNotEmpty &&
      _department != null &&
      _locationController.text.trim().isNotEmpty &&
      _materialsController.text.trim().isNotEmpty &&
      int.tryParse(_totalWorkersController.text.trim()) != null &&
      _dateStart != null &&
      _dateEnd != null;

  bool get _step2Valid =>
      _generalChecklist.isNotEmpty || _otherGeneralController.text.trim().isNotEmpty;

  void _goTo(int step) {
    setState(() => _step = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  void _next() {
    if (_step == 0 && !_step1Valid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi dulu detail pekerjaan yang wajib diisi.')),
      );
      return;
    }
    if (_step == 1 && !_step2Valid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal satu general checklist.')),
      );
      return;
    }
    if (_step < _stepTitles.length - 1) _goTo(_step + 1);
  }

  void _back() {
    if (_step > 0) {
      _goTo(_step - 1);
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      final draft = HseWorkRequest(
        pic: _picController.text.trim(),
        department: _department!,
        category: _category,
        location: _locationController.text.trim(),
        materials: _materialsController.text.trim(),
        vendor: _vendorController.text.trim().isEmpty ? null : _vendorController.text.trim(),
        totalWorkers: int.tryParse(_totalWorkersController.text.trim()) ?? 0,
        dateStart: _dateStart!,
        dateEnd: _dateEnd!,
        generalChecklist: _generalChecklist.toList(),
        otherGeneralChecklist: _otherGeneralController.text.trim().isEmpty
            ? null
            : _otherGeneralController.text.trim(),
        typeOfWorks: _typeOfWorks.toList(),
        otherTypeOfWork: _otherTypeOfWorkController.text.trim().isEmpty
            ? null
            : _otherTypeOfWorkController.text.trim(),
        ppe: _ppe.toList(),
        otherPpe: _otherPpeController.text.trim().isEmpty ? null : _otherPpeController.text.trim(),
      );

      await widget.repository.submit(draft);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permit HSE berhasil diajukan.')),
      );
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengirim permit. Coba lagi.')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: BackHeader(title: 'Add Permit Request', onBack: _back),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: HseWizardHeader(
                stepIndex: _step,
                stepCount: _stepTitles.length,
                title: _stepTitles[_step],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _StepDetailPekerjaan(
                    picController: _picController,
                    locationController: _locationController,
                    materialsController: _materialsController,
                    vendorController: _vendorController,
                    totalWorkersController: _totalWorkersController,
                    department: _department,
                    onDepartmentChanged: (value) => setState(() => _department = value),
                    category: _category,
                    onCategoryChanged: (value) => setState(() => _category = value),
                    dateStart: _dateStart,
                    dateEnd: _dateEnd,
                    onDateChanged: (start, end) => setState(() {
                      _dateStart = start;
                      _dateEnd = end;
                    }),
                  ),
                  _StepGeneralChecklist(
                    selected: _generalChecklist,
                    otherController: _otherGeneralController,
                    onToggle: (option) => setState(() {
                      if (!_generalChecklist.remove(option)) _generalChecklist.add(option);
                    }),
                  ),
                  _StepTypeAndPpe(
                    selectedTypes: _typeOfWorks,
                    otherTypeController: _otherTypeOfWorkController,
                    onToggleType: (option) => setState(() {
                      if (!_typeOfWorks.remove(option)) _typeOfWorks.add(option);
                    }),
                    selectedPpe: _ppe,
                    otherPpeController: _otherPpeController,
                    onTogglePpe: (option) => setState(() {
                      if (!_ppe.remove(option)) _ppe.add(option);
                    }),
                  ),
                  _StepReview(
                    pic: _picController.text,
                    department: _department ?? '-',
                    category: _category,
                    location: _locationController.text,
                    materials: _materialsController.text,
                    vendor: _vendorController.text,
                    totalWorkers: _totalWorkersController.text,
                    dateStart: _dateStart,
                    dateEnd: _dateEnd,
                    generalChecklist: _generalChecklist,
                    otherGeneral: _otherGeneralController.text,
                    typeOfWorks: _typeOfWorks,
                    otherType: _otherTypeOfWorkController.text,
                    ppe: _ppe,
                    otherPpe: _otherPpeController.text,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: _step == 0 ? 'Batal' : 'Kembali',
                      variant: AppButtonVariant.ghost,
                      onPressed: _isSubmitting ? null : _back,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: AppButton(
                      label: _step == _stepTitles.length - 1 ? 'Submit' : 'Lanjut',
                      isLoading: _isSubmitting,
                      onPressed: _step == _stepTitles.length - 1 ? _submit : _next,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepDetailPekerjaan extends StatelessWidget {
  const _StepDetailPekerjaan({
    required this.picController,
    required this.locationController,
    required this.materialsController,
    required this.vendorController,
    required this.totalWorkersController,
    required this.department,
    required this.onDepartmentChanged,
    required this.category,
    required this.onCategoryChanged,
    required this.dateStart,
    required this.dateEnd,
    required this.onDateChanged,
  });

  final TextEditingController picController;
  final TextEditingController locationController;
  final TextEditingController materialsController;
  final TextEditingController vendorController;
  final TextEditingController totalWorkersController;
  final String? department;
  final ValueChanged<String> onDepartmentChanged;
  final HseRequestCategory category;
  final ValueChanged<HseRequestCategory> onCategoryChanged;
  final DateTime? dateStart;
  final DateTime? dateEnd;
  final void Function(DateTime start, DateTime end) onDateChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        AppTextField(label: 'PIC', controller: picController, required: true, hint: 'Nama PIC'),
        const SizedBox(height: 14),
        AppDropdown<String>(
          label: 'Department',
          value: department ?? '',
          required: true,
          items: [
            const (value: '', label: '-- Pilih --'),
            for (final dept in HseChecklistCatalog.departments) (value: dept, label: dept),
          ],
          onChanged: (value) {
            if (value.isNotEmpty) onDepartmentChanged(value);
          },
        ),
        const SizedBox(height: 14),
        AppDropdown<HseRequestCategory>(
          label: 'Kategori',
          value: category,
          required: true,
          items: [
            for (final value in HseRequestCategory.values) (value: value, label: value.label),
          ],
          onChanged: onCategoryChanged,
        ),
        const SizedBox(height: 14),
        AppTextField(
          label: 'Location',
          controller: locationController,
          required: true,
          hint: 'Lokasi pekerjaan',
        ),
        const SizedBox(height: 14),
        AppTextField(
          label: 'Materials',
          controller: materialsController,
          required: true,
          hint: 'Material / alat kerja yang dipakai',
          maxLines: 3,
          minLines: 2,
        ),
        const SizedBox(height: 14),
        AppTextField(
          label: 'Vendor',
          controller: vendorController,
          hint: 'Nama vendor (opsional)',
        ),
        const SizedBox(height: 14),
        AppTextField(
          label: 'Total Workers',
          controller: totalWorkersController,
          required: true,
          hint: 'Jumlah pekerja',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 14),
        AppDateRangeField(
          label: 'Date of Work',
          required: true,
          startDate: dateStart,
          endDate: dateEnd,
          onChanged: onDateChanged,
        ),
      ],
    );
  }
}

class _StepGeneralChecklist extends StatelessWidget {
  const _StepGeneralChecklist({
    required this.selected,
    required this.otherController,
    required this.onToggle,
  });

  final Set<String> selected;
  final TextEditingController otherController;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          'Pastikan kondisi lapangan sudah memenuhi checklist berikut sebelum pekerjaan dimulai.',
          style: AppTextStyles.bodyMuted,
        ),
        const SizedBox(height: 12),
        HseChecklistGroup(
          title: 'General Checklist',
          required: true,
          options: HseChecklistCatalog.generalChecklist,
          selected: selected,
          onChanged: onToggle,
          otherController: otherController,
        ),
      ],
    );
  }
}

class _StepTypeAndPpe extends StatelessWidget {
  const _StepTypeAndPpe({
    required this.selectedTypes,
    required this.otherTypeController,
    required this.onToggleType,
    required this.selectedPpe,
    required this.otherPpeController,
    required this.onTogglePpe,
  });

  final Set<String> selectedTypes;
  final TextEditingController otherTypeController;
  final ValueChanged<String> onToggleType;
  final Set<String> selectedPpe;
  final TextEditingController otherPpeController;
  final ValueChanged<String> onTogglePpe;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        HseChoiceChipGroup(
          title: 'Type of Works',
          options: HseChecklistCatalog.typeOfWorks,
          selected: selectedTypes,
          onChanged: onToggleType,
          otherController: otherTypeController,
        ),
        HseChoiceChipGroup(
          title: 'Personal Protective Equipment',
          options: HseChecklistCatalog.personalProtectiveEquipment,
          selected: selectedPpe,
          onChanged: onTogglePpe,
          otherController: otherPpeController,
        ),
      ],
    );
  }
}

class _StepReview extends StatelessWidget {
  const _StepReview({
    required this.pic,
    required this.department,
    required this.category,
    required this.location,
    required this.materials,
    required this.vendor,
    required this.totalWorkers,
    required this.dateStart,
    required this.dateEnd,
    required this.generalChecklist,
    required this.otherGeneral,
    required this.typeOfWorks,
    required this.otherType,
    required this.ppe,
    required this.otherPpe,
  });

  final String pic;
  final String department;
  final HseRequestCategory category;
  final String location;
  final String materials;
  final String vendor;
  final String totalWorkers;
  final DateTime? dateStart;
  final DateTime? dateEnd;
  final Set<String> generalChecklist;
  final String otherGeneral;
  final Set<String> typeOfWorks;
  final String otherType;
  final Set<String> ppe;
  final String otherPpe;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          'Periksa lagi sebelum dikirim — permit yang sudah masuk perlu acknowledge HOD dan approval untuk bisa diubah.',
          style: AppTextStyles.bodyMuted,
        ),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              _ReviewRow(label: 'PIC', value: pic),
              _ReviewRow(label: 'Department', value: department),
              _ReviewRow(label: 'Kategori', value: category.shortLabel),
              _ReviewRow(label: 'Location', value: location),
              _ReviewRow(label: 'Materials', value: materials),
              _ReviewRow(label: 'Vendor', value: vendor.isEmpty ? '-' : vendor),
              _ReviewRow(label: 'Total Workers', value: totalWorkers),
              _ReviewRow(
                label: 'Date of Work',
                value: dateStart == null || dateEnd == null
                    ? '-'
                    : '${dateStart!.day}/${dateStart!.month}/${dateStart!.year} – '
                        '${dateEnd!.day}/${dateEnd!.month}/${dateEnd!.year}',
                showDivider: false,
              ),
            ],
          ),
        ),
        HseChecklistGroup(
          title: 'General Checklist',
          options: generalChecklist.toList(),
          selected: generalChecklist,
          readOnly: true,
          otherController: TextEditingController(text: otherGeneral),
        ),
        HseChoiceChipGroup(
          title: 'Type of Works',
          options: typeOfWorks.toList(),
          selected: typeOfWorks,
          readOnly: true,
          otherController: TextEditingController(text: otherType),
        ),
        HseChoiceChipGroup(
          title: 'Personal Protective Equipment',
          options: ppe.toList(),
          selected: ppe,
          readOnly: true,
          otherController: TextEditingController(text: otherPpe),
        ),
      ],
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value, this.showDivider = true});

  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border: showDivider ? const Border(bottom: BorderSide(color: AppColors.border)) : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value.isEmpty ? '-' : value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.text),
            ),
          ),
        ],
      ),
    );
  }
}
