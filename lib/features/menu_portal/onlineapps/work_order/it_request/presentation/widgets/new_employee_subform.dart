import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../../core/widgets/app_dropdown.dart';
import '../../../../../../../core/widgets/app_text_field.dart';
import '../../../../../../shared/domain/department.dart';
import '../../domain/new_employee_data.dart';
import 'need_choice_chips.dart';

/// Sub-form yang muncul saat opsi "New employee account creation" dipilih
/// di "What do you need?" — satu-satunya opsi dengan field sendiri (bukan
/// checkbox/text field generik seperti opsi lain).
///
/// Menyimpan controller-nya sendiri (mirip pola `ItRequestFeedbackSheet`)
/// dan melaporkan tiap perubahan ke pemanggil lewat [onChanged], supaya
/// nilai [data] tetap jadi satu-satunya sumber kebenaran di layar induk.
///
/// [departments] dimuat sekali oleh layar induk (lihat `AddItRequestScreen`)
/// lewat `DepartmentRepository` yang sama dipakai form pengumuman — bukan
/// daftar tebakan lokal, karena `new_employee_department` yang dikirim ke
/// server butuh ID numerik departemen sungguhan. Selama [departments] masih
/// kosong (belum selesai dimuat) atau [departmentsError] terisi (gagal
/// dimuat), dropdown-nya diganti indikator/retry.
///
/// Dropdown Executive type sengaja langsung diisi nilai default (bukan
/// menampilkan "-- Select --") begitu sub-form ini terbuka — supaya terasa
/// lebih siap pakai, bukan formulir kosong yang kaku. Department ikut
/// diisi begitu [departments] tersedia. Default itu langsung dikirim ke
/// [onChanged] lewat [WidgetsBinding.addPostFrameCallback] saat sub-form
/// pertama kali terbuka (atau saat departemen baru selesai dimuat), supaya
/// validasi "wajib isi" di layar induk tidak keliru menganggap field ini
/// belum diisi padahal sudah kelihatan terisi.
class NewEmployeeSubform extends StatefulWidget {
  const NewEmployeeSubform({
    super.key,
    required this.data,
    required this.onChanged,
    required this.departments,
    this.departmentsError,
    this.onRetryLoadDepartments,
  });

  final NewEmployeeData data;
  final ValueChanged<NewEmployeeData> onChanged;
  final List<Department> departments;
  final String? departmentsError;
  final VoidCallback? onRetryLoadDepartments;

  @override
  State<NewEmployeeSubform> createState() => _NewEmployeeSubformState();
}

class _NewEmployeeSubformState extends State<NewEmployeeSubform> {
  late final _fullNameCtrl = TextEditingController(text: widget.data.fullName);
  late final _preferredNameCtrl = TextEditingController(text: widget.data.preferredName);
  late final _employeeNumberCtrl = TextEditingController(text: widget.data.employeeNumber);
  late final _sectionCtrl = TextEditingController(text: widget.data.section);

  @override
  void initState() {
    super.initState();
    _fillDefaultsIfNeeded();
  }

  @override
  void didUpdateWidget(NewEmployeeSubform oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Departemen baru selesai dimuat setelah sub-form ini terbuka — isi
    // default begitu daftarnya tersedia, bukan cuma sekali di initState.
    if (oldWidget.departments.isEmpty && widget.departments.isNotEmpty) {
      _fillDefaultsIfNeeded();
    }
  }

  void _fillDefaultsIfNeeded() {
    if (widget.data.executiveType != null &&
        (widget.data.department != null || widget.departments.isEmpty)) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _emit((d) => d.copyWith(
            executiveType: d.executiveType ?? ExecutiveType.values.first,
            department: d.department ??
                (widget.departments.isEmpty ? null : widget.departments.first),
          ));
    });
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _preferredNameCtrl.dispose();
    _employeeNumberCtrl.dispose();
    _sectionCtrl.dispose();
    super.dispose();
  }

  void _emit(NewEmployeeData Function(NewEmployeeData current) update) {
    widget.onChanged(update(widget.data));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          label: 'Full name',
          controller: _fullNameCtrl,
          hint: 'Full name',
          required: true,
          onChanged: (v) => _emit((d) => d.copyWith(fullName: v)),
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: 'Preferred name (optional)',
          controller: _preferredNameCtrl,
          hint: 'Preferred name',
          onChanged: (v) => _emit((d) => d.copyWith(preferredName: v)),
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: 'Employee number',
          controller: _employeeNumberCtrl,
          hint: 'Employee number',
          required: true,
          onChanged: (v) => _emit((d) => d.copyWith(employeeNumber: v)),
        ),
        const SizedBox(height: 12),
        AppDropdown<ExecutiveType>(
          label: 'Executive / Non-Executive',
          required: true,
          value: widget.data.executiveType ?? ExecutiveType.values.first,
          items: [
            for (final type in ExecutiveType.values) (value: type, label: type.label),
          ],
          onChanged: (v) => _emit((d) => d.copyWith(executiveType: v)),
        ),
        const SizedBox(height: 12),
        _buildDepartmentField(),
        const SizedBox(height: 12),
        AppTextField(
          label: 'Section (optional)',
          controller: _sectionCtrl,
          hint: 'Section',
          onChanged: (v) => _emit((d) => d.copyWith(section: v)),
        ),
        const SizedBox(height: 12),
        const Text('Equipment / Access needed (optional)', style: AppTextStyles.label),
        const SizedBox(height: 8),
        NeedChoiceChips(
          labels: NewEmployeeEquipment.all,
          selected: widget.data.equipmentNeeded,
          onChanged: (v) => _emit((d) => d.copyWith(equipmentNeeded: v)),
        ),
      ],
    );
  }

  Widget _buildDepartmentField() {
    if (widget.departmentsError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.departmentsError!,
            style: const TextStyle(fontSize: 12, color: AppColors.rejected),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: widget.onRetryLoadDepartments,
            child: const Text(
              'Coba lagi',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    }

    if (widget.departments.isEmpty) {
      return const Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 10),
          Text('Loading departments...', style: AppTextStyles.body),
        ],
      );
    }

    return AppDropdown<Department>(
      label: 'Department',
      required: true,
      value: widget.data.department ?? widget.departments.first,
      items: [
        for (final department in widget.departments)
          (value: department, label: department.name),
      ],
      onChanged: (v) => _emit((d) => d.copyWith(department: v)),
    );
  }
}
