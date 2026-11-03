import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/network/api_exception.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/widgets/app_attachment_field.dart';
import '../../../../../../core/widgets/app_button.dart';
import '../../../../../../core/widgets/app_card.dart';
import '../../../../../../core/widgets/app_date_range_field.dart';
import '../../../../../../core/widgets/app_dropdown.dart';
import '../../../../../../core/widgets/app_error_view.dart';
import '../../../../../../core/widgets/app_text_field.dart';
import '../../../../../../core/widgets/back_header.dart';
import '../../data/hse_work_request_repository.dart';
import '../../domain/hse_form_options.dart';
import '../../domain/hse_work_request.dart';
import '../widgets/hse_checklist_group.dart';
import '../widgets/hse_choice_chip_group.dart';
import '../widgets/hse_file_picker.dart';
import '../widgets/hse_wizard_header.dart';

/// Wizard "Add Permit Request" — `POST /hse_permit`.
///
/// Semua pilihan (kategori, departemen, section, checklist, type of works,
/// PPE, aturan dokumen) diambil dari `GET /hse_permit/options`, karena nilai
/// yang dikirim harus persis sama dengan daftar di server.
///
/// 4 step: Detail Pekerjaan (+ dokumen PDF untuk NON-RUTIN) → General
/// Checklist → Jenis Pekerjaan & APD → Review. Pop `true` bila tersimpan.
class HseWorkRequestFormScreen extends StatefulWidget {
  const HseWorkRequestFormScreen({super.key});

  @override
  State<HseWorkRequestFormScreen> createState() =>
      _HseWorkRequestFormScreenState();
}

class _HseWorkRequestFormScreenState extends State<HseWorkRequestFormScreen> {
  static const _stepTitles = [
    'Job Details',
    'General Checklist',
    'Work Type & PPE',
    'Review & Submit',
  ];

  late final HseWorkRequestRepository _repository;
  HseFormOptions? _options;
  String? _optionsError;

  final _pageController = PageController();
  int _step = 0;
  bool _isSubmitting = false;

  // Step 1 — detail pekerjaan.
  final _picController = TextEditingController();
  final _locationController = TextEditingController();
  final _materialsController = TextEditingController();
  final _vendorController = TextEditingController();
  final _totalWorkersController = TextEditingController();
  int? _departmentId;
  String? _section;
  String? _categoryCode;
  DateTime? _dateStart;
  DateTime? _dateEnd;

  /// Dokumen PDF per field (`jsa`, `timeline`, `soft_drawing`) — NON-RUTIN.
  final _documents = <String, HsePickedFile>{};

  // Step 2 — general checklist.
  final _generalChecklist = <String>{};
  final _otherGeneralController = TextEditingController();

  // Step 3 — jenis pekerjaan & APD.
  final _typeOfWorks = <String>{};
  final _otherTypeOfWorkController = TextEditingController();
  final _ppe = <String>{};
  final _otherPpeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _repository = context.read<HseWorkRequestRepository>();
    _loadOptions();
  }

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

  Future<void> _loadOptions() async {
    setState(() {
      _options = null;
      _optionsError = null;
    });
    try {
      final options = await _repository.fetchOptions();
      if (!mounted) return;
      setState(() {
        _options = options;
        _categoryCode ??=
            options.categories.isEmpty ? null : options.categories.first.code;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _optionsError = e.message);
    } catch (_) {
      if (mounted) setState(() => _optionsError = 'Failed to load form options.');
    }
  }

  bool get _needsDocuments =>
      _options?.requiresDocuments(_categoryCode) ?? false;

  bool get _step1Valid =>
      _picController.text.trim().isNotEmpty &&
      _departmentId != null &&
      _categoryCode != null &&
      _locationController.text.trim().isNotEmpty &&
      _materialsController.text.trim().isNotEmpty &&
      (int.tryParse(_totalWorkersController.text.trim()) ?? 0) > 0 &&
      _dateStart != null &&
      _dateEnd != null;

  bool get _documentsValid =>
      !_needsDocuments ||
      _options!.documentFields.every(_documents.containsKey);

  bool get _step2Valid =>
      _generalChecklist.isNotEmpty ||
      _otherGeneralController.text.trim().isNotEmpty;

  bool get _step3Valid =>
      (_typeOfWorks.isNotEmpty ||
          _otherTypeOfWorkController.text.trim().isNotEmpty) &&
      (_ppe.isNotEmpty || _otherPpeController.text.trim().isNotEmpty);

  void _snack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.solid(AppColors.rejected) : null,
      ),
    );
  }

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
      _snack('Please complete the required job details.');
      return;
    }
    if (_step == 0 && !_documentsValid) {
      _snack('Non-routine permits require all PDF documents.');
      return;
    }
    if (_step == 1 && !_step2Valid) {
      _snack('Select at least one general checklist item, or fill in Other.');
      return;
    }
    if (_step == 2 && !_step3Valid) {
      _snack(
          'Select at least one Type of Work and one PPE, or fill in Other.');
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

  Future<void> _toggleDocument(String field) async {
    if (_isSubmitting) return;
    if (_documents.containsKey(field)) {
      setState(() => _documents.remove(field));
      return;
    }
    final options = _options!;
    try {
      final picked = await pickHseFile(
        options.documentExtensions.isEmpty
            ? const ['pdf']
            : options.documentExtensions,
      );
      if (picked == null || !mounted) return;
      final sizeError = hseFileSizeError(picked, options.documentMaxKb);
      if (sizeError != null) {
        _snack(sizeError, error: true);
        return;
      }
      setState(() => _documents[field] = picked);
    } catch (_) {
      if (mounted) _snack('Unable to open the file picker.', error: true);
    }
  }

  void _onDepartmentChanged(int id) {
    setState(() {
      _departmentId = id;
      // Section hanya berlaku untuk departemen tertentu (EST).
      if (!_options!.hasSections(id)) _section = null;
    });
  }

  Future<void> _submit() async {
    if (!_step1Valid || !_documentsValid || !_step2Valid || !_step3Valid) {
      _snack('Some required fields are still empty.');
      return;
    }

    String? text(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();

    final draft = HsePermitDraft(
      pic: _picController.text,
      departmentId: _departmentId!,
      section: _section,
      categoryCode: _categoryCode!,
      location: _locationController.text,
      materials: _materialsController.text,
      vendor: text(_vendorController),
      totalWorkers: int.parse(_totalWorkersController.text.trim()),
      dateStart: _dateStart!,
      dateEnd: _dateEnd!,
      generalChecklist: _generalChecklist.toList(),
      otherGeneralChecklist: text(_otherGeneralController),
      typeOfWorks: _typeOfWorks.toList(),
      otherTypeOfWork: text(_otherTypeOfWorkController),
      ppe: _ppe.toList(),
      otherPpe: text(_otherPpeController),
      documents: _needsDocuments
          ? {for (final e in _documents.entries) e.key: e.value.path}
          : const {},
    );

    setState(() => _isSubmitting = true);
    try {
      final result = await _repository.submit(draft);
      if (!mounted) return;
      _snack(result.message);
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) _snack(e.message, error: true);
    } catch (_) {
      if (mounted) _snack('Failed to submit the permit. Please try again.', error: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = _options;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: BackHeader(title: 'Add Permit Request', onBack: _back),
      body: SafeArea(
        top: false,
        child: options == null
            ? (_optionsError != null
                ? AppErrorView(message: _optionsError!, onRetry: _loadOptions)
                : const Center(child: CircularProgressIndicator()))
            : _buildWizard(options),
      ),
    );
  }

  Widget _buildWizard(HseFormOptions options) {
    return Column(
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
                options: options,
                picController: _picController,
                locationController: _locationController,
                materialsController: _materialsController,
                vendorController: _vendorController,
                totalWorkersController: _totalWorkersController,
                departmentId: _departmentId,
                onDepartmentChanged: _onDepartmentChanged,
                section: _section,
                onSectionChanged: (v) => setState(() => _section = v),
                categoryCode: _categoryCode,
                onCategoryChanged: (v) => setState(() => _categoryCode = v),
                dateStart: _dateStart,
                dateEnd: _dateEnd,
                onDateChanged: (start, end) => setState(() {
                  _dateStart = start;
                  _dateEnd = end;
                }),
                needsDocuments: _needsDocuments,
                documents: _documents,
                onToggleDocument: _toggleDocument,
              ),
              _StepGeneralChecklist(
                options: options.generalChecklist,
                selected: _generalChecklist,
                otherController: _otherGeneralController,
                onToggle: (option) => setState(() {
                  if (!_generalChecklist.remove(option)) {
                    _generalChecklist.add(option);
                  }
                }),
              ),
              _StepTypeAndPpe(
                typeOptions: options.typeOfWorks,
                selectedTypes: _typeOfWorks,
                otherTypeController: _otherTypeOfWorkController,
                onToggleType: (option) => setState(() {
                  if (!_typeOfWorks.remove(option)) _typeOfWorks.add(option);
                }),
                ppeOptions: options.ppe,
                selectedPpe: _ppe,
                otherPpeController: _otherPpeController,
                onTogglePpe: (option) => setState(() {
                  if (!_ppe.remove(option)) _ppe.add(option);
                }),
              ),
              _StepReview(
                pic: _picController.text,
                department: options.departmentName(_departmentId) ?? '-',
                section: _section,
                category: options.categoryLabel(_categoryCode) ?? '-',
                location: _locationController.text,
                materials: _materialsController.text,
                vendor: _vendorController.text,
                totalWorkers: _totalWorkersController.text,
                dateStart: _dateStart,
                dateEnd: _dateEnd,
                documents: _needsDocuments
                    ? {
                        for (final f in options.documentFields)
                          HseFormOptions.documentLabel(f):
                              _documents[f]?.name ?? '-',
                      }
                    : const {},
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
          decoration: BoxDecoration(
            color: AppColors.card,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: AppButton(
                  label: _step == 0 ? 'Cancel' : 'Back',
                  variant: AppButtonVariant.ghost,
                  onPressed: _isSubmitting ? null : _back,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: AppButton(
                  label: _step == _stepTitles.length - 1 ? 'Submit' : 'Next',
                  isLoading: _isSubmitting,
                  onPressed: _step == _stepTitles.length - 1 ? _submit : _next,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepDetailPekerjaan extends StatelessWidget {
  const _StepDetailPekerjaan({
    required this.options,
    required this.picController,
    required this.locationController,
    required this.materialsController,
    required this.vendorController,
    required this.totalWorkersController,
    required this.departmentId,
    required this.onDepartmentChanged,
    required this.section,
    required this.onSectionChanged,
    required this.categoryCode,
    required this.onCategoryChanged,
    required this.dateStart,
    required this.dateEnd,
    required this.onDateChanged,
    required this.needsDocuments,
    required this.documents,
    required this.onToggleDocument,
  });

  final HseFormOptions options;
  final TextEditingController picController;
  final TextEditingController locationController;
  final TextEditingController materialsController;
  final TextEditingController vendorController;
  final TextEditingController totalWorkersController;
  final int? departmentId;
  final ValueChanged<int> onDepartmentChanged;
  final String? section;
  final ValueChanged<String?> onSectionChanged;
  final String? categoryCode;
  final ValueChanged<String> onCategoryChanged;
  final DateTime? dateStart;
  final DateTime? dateEnd;
  final void Function(DateTime start, DateTime end) onDateChanged;
  final bool needsDocuments;
  final Map<String, HsePickedFile> documents;
  final ValueChanged<String> onToggleDocument;

  @override
  Widget build(BuildContext context) {
    final maxMb = (options.documentMaxKb / 1024).round();
    final extensions = options.documentExtensions.isEmpty
        ? 'PDF'
        : options.documentExtensions.map((e) => e.toUpperCase()).join(', ');

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          'Fill in the job details before continuing to the safety checklist.',
          style: AppTextStyles.bodyMuted,
        ),
        const SizedBox(height: 14),
        _SectionCard(
          icon: Icons.badge_outlined,
          title: 'PIC Information',
          children: [
            AppTextField(
              label: 'PIC',
              controller: picController,
              required: true,
              hint: 'PIC name',
            ),
            const SizedBox(height: 14),
            AppDropdown<int>(
              label: 'Department',
              // 0 = belum dipilih (id departemen dari server mulai dari 1).
              value: departmentId ?? 0,
              required: true,
              items: [
                const (value: 0, label: 'Select'),
                for (final d in options.departments)
                  (value: d.id, label: d.name),
              ],
              onChanged: (value) {
                if (value != 0) onDepartmentChanged(value);
              },
            ),
            if (options.hasSections(departmentId)) ...[
              const SizedBox(height: 14),
              AppDropdown<String>(
                label: 'Section',
                value: section ?? '',
                items: [
                  const (value: '', label: 'Select (optional)'),
                  for (final s in options.sections) (value: s, label: s),
                ],
                onChanged: (value) =>
                    onSectionChanged(value.isEmpty ? null : value),
              ),
            ],
            const SizedBox(height: 14),
            AppDropdown<String>(
              label: 'Category',
              value: categoryCode ?? '',
              required: true,
              items: [
                if (categoryCode == null) const (value: '', label: 'Select'),
                for (final c in options.categories)
                  (value: c.code, label: c.label),
              ],
              onChanged: (value) {
                if (value.isNotEmpty) onCategoryChanged(value);
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        _SectionCard(
          icon: Icons.location_on_outlined,
          title: 'Location & Scope of Work',
          children: [
            AppTextField(
              label: 'Location',
              controller: locationController,
              required: true,
              hint: 'Work location',
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Materials',
              controller: materialsController,
              required: true,
              hint: 'Materials / tools used',
              maxLines: 3,
              minLines: 2,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Vendor',
              controller: vendorController,
              hint: 'Vendor name (optional)',
            ),
          ],
        ),
        const SizedBox(height: 16),
        _SectionCard(
          icon: Icons.event_outlined,
          title: 'Schedule & Workforce',
          children: [
            AppTextField(
              label: 'Total Workers',
              controller: totalWorkersController,
              required: true,
              hint: 'Number of workers',
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
        ),
        if (needsDocuments) ...[
          const SizedBox(height: 16),
          _SectionCard(
            icon: Icons.picture_as_pdf_outlined,
            title: 'Supporting Documents',
            children: [
              Text(
                'Required for non-routine permits.',
                style: AppTextStyles.caption,
              ),
              for (final field in options.documentFields) ...[
                const SizedBox(height: 14),
                AppAttachmentField(
                  label: HseFormOptions.documentLabel(field),
                  required: true,
                  fileName: documents[field]?.name,
                  onTap: () => onToggleDocument(field),
                  hint: '$extensions — max $maxMb MB',
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

/// Kartu bertajuk (ikon bulat + judul) yang membungkus satu grup field.
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: AppColors.primaryText),
              ),
              const SizedBox(width: 8),
              Text(title, style: AppTextStyles.sectionTitle),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _StepGeneralChecklist extends StatelessWidget {
  const _StepGeneralChecklist({
    required this.options,
    required this.selected,
    required this.otherController,
    required this.onToggle,
  });

  final List<String> options;
  final Set<String> selected;
  final TextEditingController otherController;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          'Make sure site conditions meet the following checklist before work begins.',
          style: AppTextStyles.bodyMuted,
        ),
        const SizedBox(height: 12),
        HseChecklistGroup(
          title: 'General Checklist',
          required: true,
          options: options,
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
    required this.typeOptions,
    required this.selectedTypes,
    required this.otherTypeController,
    required this.onToggleType,
    required this.ppeOptions,
    required this.selectedPpe,
    required this.otherPpeController,
    required this.onTogglePpe,
  });

  final List<String> typeOptions;
  final Set<String> selectedTypes;
  final TextEditingController otherTypeController;
  final ValueChanged<String> onToggleType;
  final List<String> ppeOptions;
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
          options: typeOptions,
          selected: selectedTypes,
          onChanged: onToggleType,
          otherController: otherTypeController,
          required: true,
        ),
        HseChoiceChipGroup(
          title: 'Personal Protective Equipment',
          options: ppeOptions,
          selected: selectedPpe,
          onChanged: onTogglePpe,
          otherController: otherPpeController,
          required: true,
        ),
      ],
    );
  }
}

class _StepReview extends StatelessWidget {
  const _StepReview({
    required this.pic,
    required this.department,
    required this.section,
    required this.category,
    required this.location,
    required this.materials,
    required this.vendor,
    required this.totalWorkers,
    required this.dateStart,
    required this.dateEnd,
    required this.documents,
    required this.generalChecklist,
    required this.otherGeneral,
    required this.typeOfWorks,
    required this.otherType,
    required this.ppe,
    required this.otherPpe,
  });

  final String pic;
  final String department;
  final String? section;
  final String category;
  final String location;
  final String materials;
  final String vendor;
  final String totalWorkers;
  final DateTime? dateStart;
  final DateTime? dateEnd;

  /// Label dokumen → nama berkas. Kosong untuk RUTIN.
  final Map<String, String> documents;
  final Set<String> generalChecklist;
  final String otherGeneral;
  final Set<String> typeOfWorks;
  final String otherType;
  final Set<String> ppe;
  final String otherPpe;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      ('PIC', pic),
      ('Department', department),
      if (section != null) ('Section', section!),
      ('Category', category),
      ('Location', location),
      ('Materials', materials),
      ('Vendor', vendor.isEmpty ? '-' : vendor),
      ('Total Workers', totalWorkers),
      (
        'Date of Work',
        dateStart == null || dateEnd == null
            ? '-'
            : '${dateStart!.day}/${dateStart!.month}/${dateStart!.year} – '
                '${dateEnd!.day}/${dateEnd!.month}/${dateEnd!.year}',
      ),
      for (final doc in documents.entries) (doc.key, doc.value),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          'Double-check before submitting — submitted permits wait for HOD approval and cannot be edited.',
          style: AppTextStyles.bodyMuted,
        ),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++)
                _ReviewRow(
                  label: rows[i].$1,
                  value: rows[i].$2,
                  showDivider: i < rows.length - 1,
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
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
  const _ReviewRow({
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(bottom: BorderSide(color: AppColors.border))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value.isEmpty ? '-' : value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
