import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/back_header.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/detail_field_tile.dart';
import '../../domain/employee_profile.dart';


/// (Religion, Sex, Birth Place, Marital Status, Degree, Employee Category).
class DataDiriScreen extends StatefulWidget {
  const DataDiriScreen({super.key, required this.profile});

  final EmployeeProfile profile;

  @override
  State<DataDiriScreen> createState() => _DataDiriScreenState();
}

class _DataDiriScreenState extends State<DataDiriScreen> {
  String? _editingField;
  late final _phoneCtrl = TextEditingController(text: widget.profile.phone);
  late final _emailCtrl = TextEditingController(text: widget.profile.email);

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: BackHeader(title: 'Data Diri', onBack: () => Navigator.of(context).pop()),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('DAPAT DIUBAH', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.3)),
            const SizedBox(height: 8),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: [
                  _editableRow(fieldKey: 'phone', label: 'No. HP', controller: _phoneCtrl),
                  const Divider(height: 1, color: AppColors.border),
                  _editableRow(fieldKey: 'email', label: 'Email', controller: _emailCtrl, isLast: true),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('* Perubahan data memerlukan verifikasi Admin HR', style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontStyle: FontStyle.italic)),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('IDENTITAS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.3)),
                Row(children: [Text('🔒', style: TextStyle(fontSize: 11)), SizedBox(width: 4), Text('Hanya Baca', style: TextStyle(fontSize: 10, color: AppColors.textMuted))]),
              ],
            ),
            const SizedBox(height: 8),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  DetailFieldTile(label: 'NIP', value: p.nip),
                  DetailFieldTile(label: 'Kategori Pegawai', value: p.employeeCategory),
                  DetailFieldTile(label: 'Tempat Lahir', value: p.birthPlace),
                  DetailFieldTile(label: 'Tanggal Lahir', value: p.birthDate),
                  DetailFieldTile(label: 'Agama', value: p.religion),
                  DetailFieldTile(label: 'Status Pernikahan', value: p.maritalStatus),
                  DetailFieldTile(label: 'Pendidikan Terakhir', value: p.degree, showDivider: false),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Perubahan data identitas hanya dapat dilakukan oleh HR/Admin.', style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontStyle: FontStyle.italic)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _editableRow({required String fieldKey, required String label, required TextEditingController controller, bool isLast = false}) {
    final isEditing = _editingField == fieldKey;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                isEditing
                    ? TextField(
                        controller: controller,
                        autofocus: true,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primaryMid, width: 1.5)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primaryMid, width: 1.5)),
                        ),
                      )
                    : Text(controller.text, style: const TextStyle(fontSize: 13, color: AppColors.text, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _editingField = isEditing ? null : fieldKey),
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
            child: Text(isEditing ? 'Simpan' : 'Ubah', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryMid)),
          ),
        ],
      ),
    );
  }
}