import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../shared/data/department_repository.dart';
import '../../../shared/domain/department.dart';
import '../../domain/announcement.dart';

/// Modal untuk HR Publisher membuat pengumuman baru.
///
/// Cara pakai:
/// ```dart
/// final result = await showModalBottomSheet<Announcement>(
///   context: context,
///   isScrollControlled: true,
///   backgroundColor: Colors.transparent,
///   builder: (_) => const CreateAnnouncementSheet(),
/// );
/// if (result != null) {
///   setState(() => _announcements = [result, ..._announcements]);
/// }
/// ```
///
/// [repository] boleh diisi manual (misalnya di test); kalau tidak, sheet
/// ini mengambilnya dari `RepositoryProvider` terdekat lewat context —
/// instance yang sama dipakai AuthRepository, jadi otomatis ikut terkirim
/// dengan Authorization header begitu user sudah login.
class CreateAnnouncementSheet extends StatefulWidget {
  const CreateAnnouncementSheet({super.key, this.repository});

  final DepartmentRepository? repository;

  @override
  State<CreateAnnouncementSheet> createState() => _CreateAnnouncementSheetState();
}

/// Warna badge untuk tiap departemen dipilih bergilir dari palet ini — API
/// departemen tidak mengirim warna, jadi ini cuma untuk tampilan lokal.
const _tagPalette = [
  (color: AppColors.primary, background: AppColors.primaryLight),
  (color: AppColors.accent, background: AppColors.accentBg),
  (color: AppColors.violet, background: AppColors.violetBg),
];

enum _LoadState { loading, error, loaded }

class _CreateAnnouncementSheetState extends State<CreateAnnouncementSheet> {
  late final DepartmentRepository _repository;

  _LoadState _loadState = _LoadState.loading;
  String? _loadError;
  List<Department> _departments = const [];
  Department? _department;

  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  String? _titleError;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? context.read<DepartmentRepository>();
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    setState(() => _loadState = _LoadState.loading);
    try {
      final departments = await _repository.getActiveDepartments();
      if (!mounted) return;
      setState(() {
        _departments = departments;
        _department = departments.isEmpty ? null : departments.first;
        _loadState = _LoadState.loaded;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.message;
        _loadState = _LoadState.error;
      });
    }
  }

  /// Warna badge untuk departemen terpilih, dicocokkan lewat posisinya di
  /// [_departments] supaya konsisten selama daftar itu tidak berubah.
  AnnouncementTag _tagFor(Department department) {
    final index = _departments.indexOf(department);
    final palette = _tagPalette[index % _tagPalette.length];
    return AnnouncementTag(
      label: department.name,
      color: palette.color,
      background: palette.background,
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final department = _department;
    if (department == null) return;

    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = 'Title is required');
      return;
    }

    final body = _bodyCtrl.text.trim();
    Navigator.of(context).pop(
      Announcement(
        tag: _tagFor(department),
        time: 'Just now',
        title: title,
        body: body.isEmpty ? null : body,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    const Expanded(
                      child: Text('New Announcement', style: AppTextStyles.h2),
                    ),
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(16),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.close, size: 20, color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _buildDepartmentField(),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Title',
                  controller: _titleCtrl,
                  hint: 'e.g. Office closed for public holiday',
                  required: true,
                  onChanged: _titleError == null
                      ? null
                      : (_) => setState(() => _titleError = null),
                ),
                if (_titleError != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _titleError!,
                    style: const TextStyle(fontSize: 11, color: AppColors.rejected),
                  ),
                ],
                const SizedBox(height: 16),
                Text('Details (optional)', style: AppTextStyles.label),
                const SizedBox(height: 6),
                TextField(
                  controller: _bodyCtrl,
                  maxLines: 3,
                  style: AppTextStyles.body,
                  decoration: InputDecoration(
                    hintText: 'Add more context for employees...',
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
                const SizedBox(height: 20),
                AppButton(
                  label: 'Post Announcement',
                  variant: AppButtonVariant.green,
                  onPressed: _department == null ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDepartmentField() {
    switch (_loadState) {
      case _LoadState.loading:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 10),
              Text('Loading departments...', style: AppTextStyles.body),
            ],
          ),
        );

      case _LoadState.error:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _loadError ?? 'Gagal memuat daftar departemen.',
              style: const TextStyle(fontSize: 12, color: AppColors.rejected),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: _loadDepartments,
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

      case _LoadState.loaded:
        if (_departments.isEmpty || _department == null) {
          return const Text(
            'Belum ada departemen aktif.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          );
        }
        return AppDropdown<Department>(
          label: 'Department',
          value: _department!,
          required: true,
          items: [
            for (final department in _departments)
              (value: department, label: department.name),
          ],
          onChanged: (v) => setState(() => _department = v),
        );
    }
  }
}
