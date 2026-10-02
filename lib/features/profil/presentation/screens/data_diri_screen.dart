import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/back_header.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/detail_field_tile.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../auth/domain/auth_user.dart';
import '../../domain/employee_profile.dart';


/// (Religion, Sex, Birth Place, Marital Status, Degree, Employee Category).
class DataDiriScreen extends StatefulWidget {
  const DataDiriScreen({super.key, required this.profile, this.user});

  final EmployeeProfile profile;

  /// Pengguna yang sedang masuk. Field yang dikirim API diambil dari sini;
  /// sisanya tetap dari [profile] karena API belum menyediakannya.
  final AuthUser? user;

  @override
  State<DataDiriScreen> createState() => _DataDiriScreenState();
}

class _DataDiriScreenState extends State<DataDiriScreen> {
  String? _editingField;
  late final _phoneCtrl = TextEditingController(
    text: widget.user?.phone ?? widget.profile.phone,
  );
  late final _emailCtrl = TextEditingController(
    text: widget.user?.email ?? widget.profile.email,
  );

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    final user = widget.user;

    // Hanya NIP dan tanggal lahir yang punya padanan di API. Kategori
    // pegawai, tempat lahir, agama, status pernikahan, dan pendidikan belum
    // dikirim server, jadi tetap dari data demo.
    final nip = user?.nik ?? p.nip;
    final birthDate =
        DateFormatter.dayMonthYearFromIso(user?.dateOfBirth) ?? p.birthDate;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: BackHeader(title: 'Data Diri', onBack: () => Navigator.of(context).pop()),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionLabel('DAPAT DIUBAH'),
            const SizedBox(height: 8),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Column(
                children: [
                  _editableRow(
                    fieldKey: 'phone',
                    label: 'No. HP',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    controller: _phoneCtrl,
                  ),
                  // indent 54 = lebar ikon (40) + jarak (14), sejajar dengan teks.
                  const Divider(height: 1, indent: 54, color: AppColors.border),
                  _editableRow(
                    fieldKey: 'email',
                    label: 'Email',
                    icon: Icons.mail_outline,
                    keyboardType: TextInputType.emailAddress,
                    controller: _emailCtrl,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _noteBox('Perubahan data memerlukan verifikasi Admin HR.'),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _sectionLabel('IDENTITAS'),
                _readOnlyBadge(),
              ],
            ),
            const SizedBox(height: 8),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  DetailFieldTile(label: 'NIP', value: nip),
                  DetailFieldTile(label: 'Kategori Pegawai', value: p.employeeCategory),
                  DetailFieldTile(label: 'Tempat Lahir', value: p.birthPlace),
                  DetailFieldTile(label: 'Tanggal Lahir', value: birthDate),
                  DetailFieldTile(label: 'Agama', value: p.religion),
                  DetailFieldTile(label: 'Status Pernikahan', value: p.maritalStatus),
                  DetailFieldTile(label: 'Pendidikan Terakhir', value: p.degree, showDivider: false),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _noteBox('Perubahan data identitas hanya dapat dilakukan oleh HR/Admin.'),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.6),
      ),
    );
  }

  /// Penanda "Hanya Baca" — pil kecil dengan ikon gembok (menggantikan emoji).
  Widget _readOnlyBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.neutralBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline, size: 11, color: AppColors.textMuted),
          SizedBox(width: 4),
          Text('Hanya Baca', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  /// Catatan kaki yang lebih terbaca (menggantikan teks miring 10px).
  Widget _noteBox(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.info_outline, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 11.5, height: 1.4, color: AppColors.textMuted)),
          ),
        ],
      ),
    );
  }

  Widget _editableRow({
    required String fieldKey,
    required String label,
    required IconData icon,
    required TextEditingController controller,
    TextInputType? keyboardType,
  }) {
    final isEditing = _editingField == fieldKey;
    void toggle() => setState(() => _editingField = isEditing ? null : fieldKey);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                isEditing
                    ? TextField(
                        controller: controller,
                        autofocus: true,
                        keyboardType: keyboardType,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                        ),
                      )
                    : Text(controller.text, style: const TextStyle(fontSize: 14, color: AppColors.text, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          isEditing
              ? FilledButton(
                  onPressed: toggle,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('Simpan', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                )
              : TextButton(
                  onPressed: toggle,
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.10),
                    foregroundColor: AppColors.primary,
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('Ubah', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                ),
        ],
      ),
    );
  }
}
