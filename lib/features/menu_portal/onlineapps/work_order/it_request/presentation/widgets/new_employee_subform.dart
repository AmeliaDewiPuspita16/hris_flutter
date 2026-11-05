import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../../core/widgets/app_shimmer.dart';
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
/// Dropdown Executive/Non-Executive dan Department tampil "-- Select --"
/// sampai user memilih, sama seperti form web — tidak ada nilai bawaan,
/// supaya tidak ada pilihan (mis. "Executive" / "AML") yang terkirim tanpa
/// sengaja.
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

/// Jarak antar grup (label + kotak) lebih besar daripada jarak label ke
/// kotaknya sendiri, supaya jelas label itu milik kotak yang tepat di
/// bawahnya, bukan kotak di atasnya.
const double _groupGap = 18;
const double _labelGap = 6;

class _NewEmployeeSubformState extends State<NewEmployeeSubform> {
  late final _fullNameCtrl = TextEditingController(text: widget.data.fullName);
  late final _employeeNumberCtrl = TextEditingController(text: widget.data.employeeNumber);
  late final _sectionCtrl = TextEditingController(text: widget.data.section);

  @override
  void dispose() {
    _fullNameCtrl.dispose();
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
        _LabeledTextField(
          label: 'Full name',
          controller: _fullNameCtrl,
          hint: 'Full name',
          required: true,
          onChanged: (v) => _emit((d) => d.copyWith(fullName: v)),
        ),
        const SizedBox(height: _groupGap),
        _LabeledTextField(
          label: 'Employee number',
          controller: _employeeNumberCtrl,
          hint: 'Employee number',
          required: true,
          onChanged: (v) => _emit((d) => d.copyWith(employeeNumber: v)),
        ),
        const SizedBox(height: _groupGap),
        _SelectField<ExecutiveType>(
          label: 'Executive / Non-Executive',
          required: true,
          value: widget.data.executiveType,
          items: [
            for (final type in ExecutiveType.values) (value: type, label: type.label),
          ],
          onChanged: (v) => _emit((d) => d.copyWith(executiveType: v)),
        ),
        const SizedBox(height: _groupGap),
        _buildDepartmentField(),
        const SizedBox(height: _groupGap),
        _LabeledTextField(
          label: 'Section (optional)',
          controller: _sectionCtrl,
          hint: 'Section',
          onChanged: (v) => _emit((d) => d.copyWith(section: v)),
        ),
        const SizedBox(height: _groupGap),
        const _FieldLabel(label: 'Equipment / Access needed (optional)'),
        const SizedBox(height: _labelGap),
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
            style: TextStyle(fontSize: 12, color: AppColors.rejected),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: widget.onRetryLoadDepartments,
            child: Text(
              'Try again',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    }

    if (widget.departments.isEmpty) {
      // Skeleton dropdown Department: label kecil + kotak setinggi field.
      return const AppShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerLine(width: 80, height: 10),
            SizedBox(height: 8),
            ShimmerBox(height: 46, borderRadius: 10),
          ],
        ),
      );
    }

    // Dicocokkan lewat id: daftar department bisa dimuat ulang (objeknya
    // baru), sedangkan DropdownButton butuh nilai yang persis ada di items.
    final selectedId = widget.data.department?.id;
    final selected = widget.departments
        .where((department) => department.id == selectedId)
        .firstOrNull;

    return _SelectField<Department>(
      label: 'Department',
      required: true,
      value: selected,
      items: [
        for (final department in widget.departments)
          (value: department, label: department.name),
      ],
      onChanged: (v) => _emit((d) => d.copyWith(department: v)),
    );
  }
}

/// Dropdown berlabel dengan hint "-- Select --" selagi belum ada pilihan —
/// tampilannya mengikuti kotak "Request type" di layar Add Request.
class _SelectField<T> extends StatelessWidget {
  const _SelectField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.required = false,
  });

  final String label;
  final bool required;
  final T? value;
  final List<({T value, String label})> items;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FieldLabel(label: label, required: required),
        const SizedBox(height: _labelGap),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border, width: 1.2),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.textMuted,
                size: 18,
              ),
              style: AppTextStyles.body.copyWith(color: AppColors.text),
              dropdownColor: AppColors.card,
              borderRadius: BorderRadius.circular(10),
              hint: Text(
                '-- Select --',
                style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
              ),
              items: [
                for (final item in items)
                  DropdownMenuItem<T>(
                    value: item.value,
                    child: Text(item.label, style: AppTextStyles.body),
                  ),
              ],
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// Label field: teks kecil + tanda bintang merah bila wajib.
class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, this.required = false});

  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: label,
        style: AppTextStyles.label,
        children: [
          if (required)
            TextSpan(
              text: ' *',
              style: AppTextStyles.label.copyWith(color: AppColors.rejected),
            ),
        ],
      ),
    );
  }
}

/// Text field berlabel dengan jarak label-ke-kotak yang rapat ([_labelGap]).
class _LabeledTextField extends StatelessWidget {
  const _LabeledTextField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.onChanged,
    this.required = false,
  });

  final String label;
  final String hint;
  final bool required;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: color, width: 1.2),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FieldLabel(label: label, required: required),
        const SizedBox(height: _labelGap),
        TextField(
          controller: controller,
          onChanged: onChanged,
          style: AppTextStyles.body,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.body.copyWith(color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.card,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: border(AppColors.border),
            enabledBorder: border(AppColors.border),
            focusedBorder: border(AppColors.primaryMid),
          ),
        ),
      ],
    );
  }
}
