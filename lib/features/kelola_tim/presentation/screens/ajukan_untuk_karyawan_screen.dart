import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../pengajuan/domain/leave_type.dart';
import '../../../shared/domain/role.dart';
import '../../domain/team_member.dart';

/// Padanan form web "Manage Leave Request Department" — Admin/HOD mengajukan
/// cuti/izin atas nama karyawan bawahan. Struktur field (Plafond, Used Leave,
/// Leave Below One Day → Start/End Time) mengikuti screenshot Individual
/// Leave Request & Manage Leave Request Department dari tim HRIS.
class AjukanUntukKaryawanScreen extends StatefulWidget {
  const AjukanUntukKaryawanScreen({super.key, required this.member});

  final TeamMember member;

  @override
  State<AjukanUntukKaryawanScreen> createState() => _AjukanUntukKaryawanScreenState();
}

class _AjukanUntukKaryawanScreenState extends State<AjukanUntukKaryawanScreen> {
  LeaveType _leaveType = LeaveType.cutiTahunan;
  LeaveCategory _izinCategory = LeaveCategory.mcSakit;
  bool _belowOneDay = false;
  bool _isUrgent = false;
  bool _submitted = false;

  final _startDateCtrl = TextEditingController();
  final _endDateCtrl = TextEditingController();
  final _startTimeCtrl = TextEditingController();
  final _endTimeCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _internalNoteCtrl = TextEditingController();

  @override
  void dispose() {
    _startDateCtrl.dispose();
    _endDateCtrl.dispose();
    _startTimeCtrl.dispose();
    _endTimeCtrl.dispose();
    _descriptionCtrl.dispose();
    _internalNoteCtrl.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    setState(() => _submitted = true);
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.member;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.text,
        elevation: 0,
        title: const Text('Ajukan untuk Karyawan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: _submitted
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.presentBg,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.presentMid, width: 2),
                        ),
                        child: const Text('✅', style: TextStyle(fontSize: 36)),
                      ),
                      const SizedBox(height: 16),
                      Text('Pengajuan untuk ${m.name} Terkirim', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.present)),
                    ],
                  ),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildEmployeeInfoCard(m),
                    const SizedBox(height: 16),
                    AppDropdown<LeaveType>(
                      label: 'Jenis Pengajuan',
                      value: _leaveType,
                      required: true,
                      items: LeaveTypeX.optionsFor(Role.nonExecutive).map((o) => (value: o, label: o.label)).toList(),
                      onChanged: (v) => setState(() => _leaveType = v),
                    ),
                    if (_leaveType == LeaveType.izin) ...[
                      const SizedBox(height: 16),
                      AppDropdown<LeaveCategory>(
                        label: 'Kategori Izin',
                        value: _izinCategory,
                        required: true,
                        items: LeaveCategory.values.map((c) => (value: c, label: c.label)).toList(),
                        onChanged: (v) => setState(() => _izinCategory = v),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: AppTextField(label: 'Tanggal Mulai', controller: _startDateCtrl, hint: 'DD/MM/YYYY', required: true, icon: Icons.calendar_today_outlined)),
                        const SizedBox(width: 12),
                        Expanded(child: AppTextField(label: 'Tanggal Selesai', controller: _endDateCtrl, hint: 'DD/MM/YYYY', required: true, icon: Icons.calendar_today_outlined)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Padanan checkbox "Leave Below One Day" di web — saat aktif,
                    // muncul field jam (dipakai utk KJK/lembur & izin per-jam).
                    InkWell(
                      onTap: () => setState(() => _belowOneDay = !_belowOneDay),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Checkbox(
                              value: _belowOneDay,
                              onChanged: (v) => setState(() => _belowOneDay = v ?? false),
                              activeColor: AppColors.primary,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            const SizedBox(width: 4),
                            const Text('Kurang dari sehari (per jam)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSub)),
                          ],
                        ),
                      ),
                    ),
                    if (_belowOneDay) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: AppTextField(label: 'Jam Mulai', controller: _startTimeCtrl, hint: '00:00')),
                          const SizedBox(width: 12),
                          Expanded(child: AppTextField(label: 'Jam Selesai', controller: _endTimeCtrl, hint: '00:00')),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    _labeledTextArea(label: 'Keterangan', controller: _descriptionCtrl, hint: 'Contoh: Menikahkan anak, sakit, dll...'),
                    const SizedBox(height: 16),
                    _labeledTextArea(label: 'Catatan Internal (opsional)', controller: _internalNoteCtrl, hint: 'Catatan khusus HR/Admin, tidak terlihat karyawan...'),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () => setState(() => _isUrgent = !_isUrgent),
                      borderRadius: BorderRadius.circular(8),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _isUrgent,
                            onChanged: (v) => setState(() => _isUrgent = v ?? false),
                            activeColor: AppColors.rejected,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          const SizedBox(width: 4),
                          const Text('Tandai sebagai mendesak', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSub)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    AppButton(label: 'Ajukan untuk ${m.name.split(' ').first}', variant: AppButtonVariant.green, onPressed: _handleSubmit),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildEmployeeInfoCard(TeamMember m) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      color: AppColors.primaryLight,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: Text(m.name.trim()[0].toUpperCase(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primaryMid)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.text)),
                const SizedBox(height: 2),
                Text('${m.position} · ${m.department}', style: const TextStyle(fontSize: 11, color: AppColors.textSub)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${m.leaveRemaining.toStringAsFixed(m.leaveRemaining.truncateToDouble() == m.leaveRemaining ? 0 : 1)} hari', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primaryMid)),
              Text('sisa dr ${m.leavePlafond.toStringAsFixed(0)} plafond', style: const TextStyle(fontSize: 9.5, color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _labeledTextArea({required String label, required TextEditingController controller, required String hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: 3,
          style: AppTextStyles.body,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.body.copyWith(color: AppColors.textMuted),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border, width: 1.5)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border, width: 1.5)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primaryMid, width: 1.5)),
          ),
        ),
      ],
    );
  }
}