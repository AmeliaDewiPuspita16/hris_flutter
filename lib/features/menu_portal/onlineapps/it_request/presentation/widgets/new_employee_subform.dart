import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/widgets/app_dropdown.dart';
import '../../../../../../core/widgets/app_text_field.dart';
import '../../domain/new_employee_data.dart';
import 'need_checkbox_group.dart';

/// Sub-form yang muncul saat opsi "New employee account creation" dipilih
/// di "What do you need?" — satu-satunya opsi dengan field sendiri (bukan
/// checkbox/text field generik seperti opsi lain).
///
/// Menyimpan controller-nya sendiri (mirip pola `ItRequestFeedbackSheet`)
/// dan melaporkan tiap perubahan ke pemanggil lewat [onChanged], supaya
/// nilai [data] tetap jadi satu-satunya sumber kebenaran di layar induk.
class NewEmployeeSubform extends StatefulWidget {
  const NewEmployeeSubform({
    super.key,
    required this.data,
    required this.onChanged,
  });

  final NewEmployeeData data;
  final ValueChanged<NewEmployeeData> onChanged;

  @override
  State<NewEmployeeSubform> createState() => _NewEmployeeSubformState();
}

class _NewEmployeeSubformState extends State<NewEmployeeSubform> {
  late final _fullNameCtrl = TextEditingController(text: widget.data.fullName);
  late final _preferredNameCtrl = TextEditingController(text: widget.data.preferredName);
  late final _employeeNumberCtrl = TextEditingController(text: widget.data.employeeNumber);
  late final _sectionCtrl = TextEditingController(text: widget.data.section);

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
        AppDropdown<ExecutiveType?>(
          label: 'Executive / Non-Executive',
          required: true,
          value: widget.data.executiveType,
          items: [
            (value: null, label: '-- Select --'),
            for (final type in ExecutiveType.values) (value: type, label: type.label),
          ],
          onChanged: (v) => _emit((d) => d.copyWith(executiveType: v)),
        ),
        const SizedBox(height: 12),
        AppDropdown<Department?>(
          label: 'Department',
          required: true,
          value: widget.data.department,
          items: [
            (value: null, label: '-- Select --'),
            for (final dept in Department.values) (value: dept, label: dept.label),
          ],
          onChanged: (v) => _emit((d) => d.copyWith(department: v)),
        ),
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
        NeedCheckboxGroup(
          labels: NewEmployeeEquipment.all,
          selected: widget.data.equipmentNeeded,
          onChanged: (v) => _emit((d) => d.copyWith(equipmentNeeded: v)),
        ),
      ],
    );
  }
}