import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../shared/data/department_repository.dart';
import '../../../shared/domain/department.dart';
import '../../data/announcement_repository.dart';
import '../../domain/announcement_photo.dart';

/// Membuka galeri dan mengembalikan foto yang dipilih.
///
/// Disuntik lewat konstruktor supaya test bisa menggantinya tanpa perlu
/// plugin galeri sungguhan.
typedef PhotoPicker = Future<List<AnnouncementPhoto>> Function();

/// Modal untuk HR Publisher membuat pengumuman baru.
///
/// Cara pakai:
/// ```dart
/// final result = await showModalBottomSheet<PublishedAnnouncement>(
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
  const CreateAnnouncementSheet({
    super.key,
    this.departmentRepository,
    this.announcementRepository,
    this.pickPhotos,
  });

  final DepartmentRepository? departmentRepository;
  final AnnouncementRepository? announcementRepository;

  /// Null berarti memakai galeri sungguhan lewat image_picker.
  final PhotoPicker? pickPhotos;

  @override
  State<CreateAnnouncementSheet> createState() => _CreateAnnouncementSheetState();
}

enum _LoadState { loading, error, loaded }

class _CreateAnnouncementSheetState extends State<CreateAnnouncementSheet> {
  late final DepartmentRepository _repository;
  late final AnnouncementRepository _announcements;

  _LoadState _loadState = _LoadState.loading;
  String? _loadError;
  List<Department> _departments = const [];
  Department? _department;

  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  String? _titleError;

  List<AnnouncementPhoto> _photos = const [];

  /// Galat pemilihan foto, mis. format salah atau jumlahnya kelewat batas.
  String? _photoError;

  /// Galat dari server saat menerbitkan.
  String? _submitError;

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _repository =
        widget.departmentRepository ?? context.read<DepartmentRepository>();
    _announcements = widget.announcementRepository ??
        context.read<AnnouncementRepository>();
    _loadDepartments();
  }

  /// Memilih foto dari galeri lalu memvalidasinya sebagai satu kumpulan,
  /// supaya batas "maksimal 10" dihitung bersama foto yang sudah dipilih.
  Future<void> _addPhotos() async {
    final picker = widget.pickPhotos ?? _pickFromGallery;

    final List<AnnouncementPhoto> picked;
    try {
      picked = await picker();
    } catch (e) {
      if (mounted) {
        setState(() => _photoError = 'Tidak bisa membuka galeri.');
      }
      return;
    }

    if (!mounted || picked.isEmpty) return;

    final combined = [..._photos, ...picked];
    final error = AnnouncementPhoto.errorForSelection(combined);

    setState(() {
      if (error != null) {
        // Pilihan ditolak seluruhnya — lebih jujur daripada diam-diam
        // memasukkan sebagian dan membuang sisanya.
        _photoError = error;
      } else {
        _photos = combined;
        _photoError = null;
      }
    });
  }

  Future<List<AnnouncementPhoto>> _pickFromGallery() async {
    final files = await ImagePicker().pickMultiImage();

    return Future.wait(
      files.map((file) async {
        return AnnouncementPhoto(
          path: file.path,
          fileName: file.name,
          sizeBytes: await file.length(),
        );
      }),
    );
  }

  void _removePhoto(AnnouncementPhoto photo) {
    setState(() {
      _photos = _photos.where((p) => p.path != photo.path).toList();
      _photoError = null;
    });
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

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final department = _department;
    if (department == null || _submitting) return;

    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = 'Title is required');
      return;
    }

    setState(() {
      _submitting = true;
      _submitError = null;
    });

    try {
      final published = await _announcements.publish(
        departmentId: department.id,
        title: title,
        body: _bodyCtrl.text,
        photos: _photos,
      );

      if (!mounted) return;
      Navigator.of(context).pop(published);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitError = e.message;
        _submitting = false;
      });
    } catch (e, stack) {
      // Berkas foto yang sudah terhapus setelah dipilih sampai ke sini
      // sebagai FileSystemException — tidak boleh bocor mentah ke layar.
      AppLogger.error('Gagal menerbitkan pengumuman', e, stack);
      if (!mounted) return;
      setState(() {
        _submitError = 'Gagal menerbitkan pengumuman. Coba lagi.';
        _submitting = false;
      });
    }
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
          // Isinya bisa panjang — baris foto, pesan galat, dan keyboard yang
          // terbuka semuanya menambah tinggi. Tanpa scroll, bagian bawah
          // terpotong di layar pendek.
          child: SingleChildScrollView(
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
                const SizedBox(height: 16),
                _buildPhotoField(),
                if (_submitError != null) ...[
                  const SizedBox(height: 16),
                  _SheetError(message: _submitError!),
                ],
                const SizedBox(height: 20),
                AppButton(
                  label: 'Post Announcement',
                  variant: AppButtonVariant.green,
                  isLoading: _submitting,
                  onPressed: _department == null ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Photos (optional)', style: AppTextStyles.label),
            const SizedBox(width: 6),
            Text(
              '${_photos.length}/${AnnouncementPhoto.maxCount}',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 72,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final photo in _photos)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _PhotoThumbnail(
                    photo: photo,
                    onRemove: _submitting ? null : () => _removePhoto(photo),
                  ),
                ),
              if (_photos.length < AnnouncementPhoto.maxCount)
                _AddPhotoButton(onTap: _submitting ? null : _addPhotos),
            ],
          ),
        ),
        if (_photoError != null) ...[
          const SizedBox(height: 6),
          Text(
            _photoError!,
            style: const TextStyle(fontSize: 11, color: AppColors.rejected),
          ),
        ],
      ],
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

/// Pratinjau satu foto yang dipilih, dengan tombol hapus di pojoknya.
class _PhotoThumbnail extends StatelessWidget {
  const _PhotoThumbnail({required this.photo, this.onRemove});

  final AnnouncementPhoto photo;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: ValueKey('photo-${photo.fileName}'),
      width: 72,
      height: 72,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(
                File(photo.path),
                fit: BoxFit.cover,
                // Berkas bisa saja sudah tidak ada saat digambar — tampilkan
                // penanda, jangan melempar galat ke layar.
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.neutralBg,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: InkWell(
              key: ValueKey('remove-${photo.fileName}'),
              onTap: onRemove,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 13, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kotak putus-putus untuk menambah foto.
class _AddPhotoButton extends StatelessWidget {
  const _AddPhotoButton({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 96,
        height: 72,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.neutralBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_a_photo_outlined, size: 18, color: AppColors.primaryMid),
            SizedBox(height: 4),
            Text(
              'Tambah foto',
              style: TextStyle(fontSize: 10, color: AppColors.primaryMid),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pesan galat dari server, ditaruh tepat di atas tombol terbit.
class _SheetError extends StatelessWidget {
  const _SheetError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.rejectedBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.rejected),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 16, color: AppColors.rejected),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12, color: AppColors.rejected),
            ),
          ),
        ],
      ),
    );
  }
}
