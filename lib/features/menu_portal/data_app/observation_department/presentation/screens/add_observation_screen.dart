import 'package:flutter/material.dart';

import '../../../../../../core/logging/app_logger.dart';
import '../../../../../../core/network/api_exception.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/widgets/app_card.dart';
import '../../../../../../core/widgets/app_date_field.dart';
import '../../../../../../core/widgets/app_dropdown.dart';
import '../../../../../../core/widgets/app_error_view.dart';
import '../../../../../../core/widgets/app_text_field.dart';
import '../../../../../../core/widgets/back_header.dart';
import '../../data/observation_repository.dart';
import '../../domain/observation_item.dart';
import '../../domain/observation_options.dart';
import '../widgets/observation_image_field.dart';

/// Layar "+ Add Observation" dan "Edit Observation"
///
/// Dibuka lewat Navigator.push. Validasi lewat snackbar. Hasilnya lewat
/// Navigator.pop: `true` bila tersimpan, null bila ditutup tanpa menyimpan.
/// [repository] harus instance yang sama dengan layar daftar.
class AddObservationScreen extends StatefulWidget {
  const AddObservationScreen({
    super.key,
    required this.repository,
    this.initialItem,
  });

  final ObservationRepository repository;

  /// Diisi untuk mode edit: form terisi data lama dan perubahan disimpan ke
  /// observasi yang sama. Null = mode tambah.
  final ObservationItem? initialItem;

  @override
  State<AddObservationScreen> createState() => _AddObservationScreenState();
}

class _AddObservationScreenState extends State<AddObservationScreen> {
  /// Nilai "belum dipilih" untuk dropdown.
  static const _none = '';

  String _category = _none;
  String _subCategory = _none;
  String _dept = _none;
  DateTime? _date;
  String? _imagePath;
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  /// True selama permintaan berjalan: tombol dikunci supaya ketukan ganda
  /// tidak membuat data dobel.
  bool _submitting = false;

  /// Pilihan form dari server (`/options`); null selama masih dimuat atau
  /// bila gagal dimuat ([_optionsError]).
  ObservationOptions? _options;
  String? _optionsError;

  bool get _isEdit => widget.initialItem != null;

  @override
  void initState() {
    super.initState();
    final item = widget.initialItem;
    if (item != null) {
      _category = item.category.label;
      _subCategory = item.subCategory ?? _none;
      _date = item.createdDate;
      _imagePath = item.findingImage;
      _locationController.text = item.location;
      _descriptionController.text = item.description;
    }
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    if (_optionsError != null) setState(() => _optionsError = null);
    try {
      final options = await widget.repository.fetchOptions();
      if (!mounted) return;
      setState(() {
        _options = options;
        // Mode edit: item hanya membawa nama departemen, id-nya dicari di
        // daftar dari server.
        final name = widget.initialItem?.relevantDept;
        final dept = name == null ? null : options.departmentByName(name);
        if (dept != null) _dept = '${dept.id}';
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _optionsError = e.message);
    } catch (e, stack) {
      AppLogger.error('Options observation gagal tak terduga', e, stack);
      if (mounted) {
        setState(() {
          _optionsError = 'An unexpected error occurred. Please try again.';
        });
      }
    }
  }

  ObservationCategoryOption? get _selectedCategory =>
      _options?.categoryByValue(_category);

  @override
  void dispose() {
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String? _validate() {
    final category = _selectedCategory;
    if (category == null) return 'Please select a category.';
    if (category.subCategories.isNotEmpty && _subCategory == _none) {
      return 'Please select the ${category.value.toLowerCase()} type.';
    }
    if (_date == null) return 'Please select the date of the finding.';
    if (_dept == _none) return 'Please select the relevant department.';
    if (_locationController.text.trim().isEmpty) {
      return 'Please fill in the location.';
    }
    if (_descriptionController.text.trim().isEmpty) {
      return 'Please fill in the description.';
    }
    if (category.imageRequiredToReport && _imagePath == null) {
      return 'A photo is required for ${category.value} findings.';
    }
    return null;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    if (_submitting) return;

    if (_options == null) return;

    final error = _validate();
    if (error != null) {
      _showMessage(error);
      return;
    }

    setState(() => _submitting = true);
    try {
      final category = _selectedCategory!.value;
      final idDept = int.parse(_dept);
      final subCategory = _subCategory == _none ? null : _subCategory;
      final location = _locationController.text.trim();
      final description = _descriptionController.text.trim();

      if (_isEdit) {
        await widget.repository.update(
          widget.initialItem!.id,
          category: category,
          subCategory: subCategory,
          dateFinding: _date!,
          idDept: idDept,
          location: location,
          description: description,
          imagePath: _imagePath,
        );
      } else {
        await widget.repository.add(
          category: category,
          subCategory: subCategory,
          dateFinding: _date!,
          idDept: idDept,
          location: location,
          description: description,
          imagePath: _imagePath,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) _showMessage(e.message);
    } catch (e, stack) {
      AppLogger.error('Simpan observation gagal tak terduga', e, stack);
      if (mounted) {
        _showMessage('An unexpected error occurred. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = _options;
    final selected = _selectedCategory;
    final subCategories = selected?.subCategories ?? const <String>[];

    // Form baru ditampilkan setelah pilihan dari server siap.
    if (options == null) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: BackHeader(
          title: _isEdit ? 'Edit Observation' : 'Add Observation',
          onBack: () => Navigator.of(context).pop(),
        ),
        body: _optionsError == null
            ? const Center(child: CircularProgressIndicator())
            : AppErrorView(message: _optionsError!, onRetry: _loadOptions),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: BackHeader(
        title: _isEdit ? 'Edit Observation' : 'Add Observation',
        onBack: () => Navigator.of(context).pop(),
      ),
      // Tombol submit di bawah layar (bukan ikut scroll)
      bottomNavigationBar: _buildSubmitBar(),
      // Ketuk area kosong untuk menutup keyboard.
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _FormSection(
              icon: Icons.fact_check_outlined,
              title: 'Finding',
              children: [
                AppDropdown<String>(
                  label: 'Category',
                  required: true,
                  value: _category,
                  items: [
                    (value: _none, label: 'Select'),
                    for (final c in options.categories)
                      (value: c.value, label: c.value),
                  ],
                  onChanged: (v) => setState(() {
                    _category = v;
                    _subCategory = _none;
                  }),
                ),
                if (subCategories.isNotEmpty)
                  AppDropdown<String>(
                    label: '${selected!.value} type',
                    required: true,
                    value: _subCategory,
                    items: [
                      (value: _none, label: 'Select'),
                      for (final s in subCategories) (value: s, label: s),
                    ],
                    onChanged: (v) => setState(() => _subCategory = v),
                  ),
                AppDateField(
                  label: 'Date Finding',
                  value: _date,
                  required: true,
                  onChanged: (date) => setState(() => _date = date),
                ),
                AppDropdown<String>(
                  label: 'Relevant Dept.',
                  required: true,
                  value: _dept,
                  items: [
                    (value: _none, label: 'Select'),
                    for (final d in options.departments)
                      (value: '${d.id}', label: d.name),
                  ],
                  onChanged: (v) => setState(() => _dept = v),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _FormSection(
              icon: Icons.place_outlined,
              title: 'Details',
              children: [
                AppTextField(
                  label: 'Location',
                  controller: _locationController,
                  required: true,
                  hint: 'Location',
                ),
                AppTextField(
                  label: 'Description',
                  controller: _descriptionController,
                  required: true,
                  hint: 'Describe what you found',
                  // Mulai satu baris, memanjang mengikuti isi.
                  minLines: 1,
                  maxLines: 10,
                ),
              ],
            ),
            const SizedBox(height: 14),
            _FormSection(
              icon: Icons.photo_camera_outlined,
              title: 'Photo',
              children: [
                ObservationImageField(
                  label: selected?.imageRequiredToReport == true
                      ? 'Image Finding'
                      : 'Image Finding (optional)',
                  path: _imagePath,
                  onChanged: (p) => setState(() => _imagePath = p),
                  onError: _showMessage,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                // Tetap hijau saat loading (tombol dikunci, bukan abu-abu).
                disabledBackgroundColor: AppColors.primary,
                disabledForegroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _isEdit ? 'Save changes' : 'Save',
                      style: AppTextStyles.buttonText
                          .copyWith(color: Colors.white),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Kartu putih berisi satu kelompok field: ikon + judul di atas, lalu
/// field-nya dengan jarak seragam.
class _FormSection extends StatelessWidget {
  const _FormSection({
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
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: AppColors.primaryText),
              ),
              const SizedBox(width: 10),
              Text(title, style: AppTextStyles.sectionTitle),
            ],
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            children[i],
          ],
        ],
      ),
    );
  }
}
