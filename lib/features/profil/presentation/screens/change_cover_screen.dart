import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/back_header.dart';
import '../../../../core/widgets/profile_ui.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/domain/auth_user.dart';
import '../../data/cover_picker_service.dart';
import '../../data/profil_repository.dart';
import '../../domain/photo_pick_exception.dart';
import '../../domain/photo_source.dart';
import '../../domain/profile_cover.dart';
import '../widgets/cover_background.dart';

/// Pilihan cover di langkah 1: preset, gambar baru dari perangkat, atau
/// gambar upload lama yang sudah ada di server (atur ulang posisinya saja).
sealed class _CoverChoice {
  const _CoverChoice();
}

class _PresetChoice extends _CoverChoice {
  const _PresetChoice(this.preset);
  final CoverPreset preset;
}

class _UploadChoice extends _CoverChoice {
  const _UploadChoice(this.picked);
  final PickedCover picked;
}

class _KeepChoice extends _CoverChoice {
  const _KeepChoice(this.cover);
  final ProfileCover cover;
}

/// Layar "Change cover", meniru modal di web portal dalam dua langkah:
/// 1. Choose a cover — preset desain atau gambar sendiri.
/// 2. Preview & adjust — geser dan zoom gambar, lalu simpan.
///
/// Mengembalikan [ProfileCover] baru dari server lewat Navigator.pop kalau
/// berhasil disimpan, atau null kalau dibatalkan.
class ChangeCoverScreen extends StatefulWidget {
  const ChangeCoverScreen(
      {super.key, required this.user, this.repository, this.picker});

  final AuthUser user;

  /// Diisi test; di aplikasi diambil dari [RepositoryProvider].
  final ProfilRepository? repository;

  /// Diisi test; di aplikasi memakai [CoverPickerService] bawaan.
  final CoverPickerService? picker;

  @override
  State<ChangeCoverScreen> createState() => _ChangeCoverScreenState();
}

class _ChangeCoverScreenState extends State<ChangeCoverScreen> {
  /// Batas atas slider zoom. API menerima sampai 1000, tapi di layar HP
  /// lebih dari ini sudah terlalu pecah.
  static const _maxZoom = 400;

  late final ProfilRepository _repository;
  late final CoverPickerService _picker;

  bool _loading = true;
  String? _loadError;
  List<CoverPreset> _presets = const [];
  ProfileCover? _current;

  _CoverChoice? _choice;
  int _step = 1;
  CoverPosition _position = CoverPosition.defaultPosition;

  bool _picking = false;
  bool _saving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? context.read<ProfilRepository>();
    _picker = widget.picker ?? CoverPickerService();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final data = await _repository.fetchCover();
      if (!mounted) return;
      final current = data.cover ?? widget.user.cover;
      setState(() {
        _loading = false;
        _presets = data.presets;
        _current = current;
        _choice = _initialChoice(current, data.presets);
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e.message;
      });
    }
  }

  /// Cover yang sedang terpasang langsung tampil terpilih.
  static _CoverChoice? _initialChoice(
      ProfileCover? current, List<CoverPreset> presets) {
    if (current == null) return null;
    if (current.preset != null) {
      for (final p in presets) {
        if (p.key == current.preset) return _PresetChoice(p);
      }
    }
    if (current.hasFile && current.isImage) return _KeepChoice(current);
    return null;
  }

  bool get _adjustable => _choice is _UploadChoice || _choice is _KeepChoice;

  String get _choiceLabel => switch (_choice) {
        _PresetChoice(:final preset) => preset.label,
        _UploadChoice() => 'Your new image',
        _KeepChoice() => 'Your image',
        null => '',
      };

  Future<void> _pickImage(PhotoSource source) async {
    setState(() => _picking = true);
    try {
      final picked = await _picker.pick(source);
      if (!mounted || picked == null) return;
      setState(() => _choice = _UploadChoice(picked));
    } on PhotoPickException catch (e) {
      if (mounted) _toast(e.message);
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _goToPreview() {
    setState(() {
      _step = 2;
      _saveError = null;
      _position = switch (_choice) {
        _KeepChoice(:final cover) =>
          cover.position ?? CoverPosition.defaultPosition,
        _ => CoverPosition.defaultPosition,
      };
    });
  }

  Future<void> _save() async {
    final choice = _choice;
    if (choice == null || _saving) return;
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      final cover = await switch (choice) {
        _PresetChoice(:final preset) =>
          _repository.selectCoverPreset(preset.key),
        _UploadChoice(:final picked) =>
          _repository.uploadCover(picked.file, _position),
        _KeepChoice() => _repository.repositionCover(_position),
      };
      if (!mounted) return;
      Navigator.of(context).pop(cover);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveError = e.message;
      });
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Tombol kembali sistem di langkah 2 kembali ke langkah 1, bukan
      // menutup layar.
      canPop: _step == 1 && !_saving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _step == 2 && !_saving) setState(() => _step = 1);
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: BackHeader(
          title: 'Change cover',
          onBack: () => Navigator.of(context).maybePop(),
        ),
        body: Column(
          children: [
            _StepIndicator(step: _step),
            Expanded(child: _buildBody()),
            if (!_loading && _loadError == null) _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Center(
          child: CircularProgressIndicator(color: AppColors.primaryText));
    }
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_loadError!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMid)),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _load, child: const Text('Try again')),
            ],
          ),
        ),
      );
    }
    return _step == 1 ? _buildChooseStep() : _buildPreviewStep();
  }

  // ---------------------------------------------------------------------------
  // Langkah 1: Choose a cover
  // ---------------------------------------------------------------------------

  Widget _buildChooseStep() {
    final current = _current;
    final hasOwnImage = current != null && current.hasFile && current.isImage;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        const _SectionTitle(
            icon: Icons.palette_outlined, text: 'Choose a design'),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.75,
          children: [
            if (hasOwnImage)
              _CoverTile(
                label: 'Your image',
                selected: _choice is _KeepChoice,
                onTap: () => setState(() => _choice = _KeepChoice(current)),
                child: CoverBackground(cover: current),
              ),
            for (final preset in _presets)
              _CoverTile(
                label: preset.isDefault
                    ? '${preset.label} (default)'
                    : preset.label,
                selected: _choice is _PresetChoice &&
                    (_choice as _PresetChoice).preset.key == preset.key,
                onTap: () => setState(() => _choice = _PresetChoice(preset)),
                child: CoverBackground(cover: preset.toCover()),
              ),
          ],
        ),
        const SizedBox(height: 22),
        const _SectionTitle(
            icon: Icons.upload_outlined, text: 'Or add your own image'),
        const SizedBox(height: 10),
        _buildUploadBox(),
        const SizedBox(height: 12),
        const InfoNote(
          'Use a wide, landscape image: at least ${CoverPickerService.minWidth} × '
          '${CoverPickerService.minHeight} px (1500 × 640 px or larger recommended), '
          'JPG or PNG up to 6 MB. Your profile photo sits at the bottom left, so '
          'keep the important part elsewhere.',
        ),
      ],
    );
  }

  Widget _buildUploadBox() {
    final choice = _choice;
    final picked = choice is _UploadChoice ? choice.picked : null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: picked != null ? AppColors.primaryText : AppColors.border,
          width: picked != null ? 2 : 1.5,
        ),
      ),
      child: Column(
        children: [
          if (picked != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: AspectRatio(
                  aspectRatio: 7 / 3,
                  child: CoverBackground(file: picked.file)),
            ),
            const SizedBox(height: 8),
            Text(
              '${picked.width} × ${picked.height} px',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ] else ...[
            Icon(Icons.cloud_upload, size: 36, color: AppColors.primaryText),
            const SizedBox(height: 6),
            Text(
              'Pick an image from your phone',
              style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text),
            ),
          ],
          const SizedBox(height: 12),
          if (_picking)
            const Padding(
              padding: EdgeInsets.all(8),
              child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5)),
            )
          else
            Row(
              children: [
                Expanded(
                  child: _OutlineAction(
                    icon: Icons.photo_library_outlined,
                    label: picked != null ? 'Change image' : 'Gallery',
                    onTap: () => _pickImage(PhotoSource.gallery),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _OutlineAction(
                    icon: Icons.photo_camera_outlined,
                    label: 'Camera',
                    onTap: () => _pickImage(PhotoSource.camera),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Langkah 2: Preview & adjust
  // ---------------------------------------------------------------------------

  Widget _buildPreviewStep() {
    final choice = _choice!;
    final (cover, file) = switch (choice) {
      _PresetChoice(:final preset) => (preset.toCover(), null),
      _UploadChoice(:final picked) => (null, picked.file),
      _KeepChoice(:final cover) => (cover, null),
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Row(
          children: [
            _SectionTitle(
              icon: _adjustable ? Icons.open_with : Icons.visibility_outlined,
              text: _adjustable ? 'Adjust position' : 'How your profile looks',
            ),
            Flexible(
              child: Text(
                '  —  $_choiceLabel',
                overflow: TextOverflow.ellipsis,
                style:
                    TextStyle(fontSize: 12.5, color: AppColors.textMuted),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _ProfilePreview(
          user: widget.user,
          cover: cover,
          file: file,
          position: _adjustable ? _position : null,
          onDrag: _adjustable ? _onDrag : null,
        ),
        if (_adjustable) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.zoom_out, size: 20, color: AppColors.primaryText),
              Expanded(
                child: Slider(
                  value: _position.size.clamp(100, _maxZoom).toDouble(),
                  min: 100,
                  max: _maxZoom.toDouble(),
                  activeColor: AppColors.primaryText,
                  onChanged: (v) => setState(
                      () => _position = _position.copyWith(size: v.round())),
                ),
              ),
              Icon(Icons.zoom_in, size: 20, color: AppColors.primaryText),
              SizedBox(
                width: 48,
                child: Text(
                  '${_position.size}%',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMid),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () =>
                  setState(() => _position = CoverPosition.defaultPosition),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reset position'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primaryText),
            ),
          ),
          const InfoNote(
              'Drag the image to move it and use the slider to resize it.'),
        ],
      ],
    );
  }

  /// Menggeser sejauh lebar/tinggi preview = menyapu seluruh rentang 0–100.
  /// Arahnya dibalik: jari ke kanan berarti gambar ikut ke kanan, jadi
  /// bagian kiri gambar yang terlihat (x mengecil).
  void _onDrag(Offset delta, Size area) {
    setState(() {
      _position = _position.copyWith(
        x: (_position.x - delta.dx / area.width * 100).round().clamp(0, 100),
        y: (_position.y - delta.dy / area.height * 100).round().clamp(0, 100),
      );
    });
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, 12 + MediaQuery.paddingOf(context).bottom),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      // Pesan galat simpan ditaruh di sini, bukan di ujung daftar, supaya
      // tetap terlihat walau preview-nya panjang.
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_step == 2 && _saveError != null) ...[
            Text(_saveError!,
                style:
                    TextStyle(fontSize: 12.5, color: AppColors.rejected)),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: _step == 1 ? 'Cancel' : 'Back',
                  variant: AppButtonVariant.secondary,
                  enabled: !_saving,
                  onPressed: () => _step == 1
                      ? Navigator.of(context).pop()
                      : setState(() => _step = 1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _step == 1
                    ? AppButton(
                        label: 'Next: preview',
                        variant: AppButtonVariant.primaryGradient,
                        enabled: _choice != null && !_picking,
                        onPressed: _goToPreview,
                      )
                    : AppButton(
                        label: 'Finish & save',
                        variant: AppButtonVariant.primaryGradient,
                        isLoading: _saving,
                        onPressed: _save,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "① Choose a cover —— ② Preview & adjust" dengan bilah progres.
class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.card,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // Label dipotong (ellipsis) di layar sempit atau font besar.
              Flexible(child: _dot(1, 'Choose a cover')),
              Container(
                width: 24,
                height: 1.5,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: step > 1 ? AppColors.primary : AppColors.border,
              ),
              Flexible(child: _dot(2, 'Preview & adjust')),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: step / 2,
              minHeight: 3,
              backgroundColor: AppColors.border,
              color: AppColors.primaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(int n, String label) {
    final done = step > n;
    final active = step == n;
    final color = done || active ? AppColors.primary : AppColors.textMuted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: done ? AppColors.primary : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1.5),
          ),
          child: done
              ? const Icon(Icons.check, size: 14, color: Colors.white)
              : Text('$n',
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w600, color: color)),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: AppColors.primaryText),
        const SizedBox(width: 6),
        Text(text,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryText)),
      ],
    );
  }
}

/// Thumbnail satu pilihan cover; bingkai hijau + centang saat terpilih.
class _CoverTile extends StatelessWidget {
  const _CoverTile(
      {required this.label,
      required this.selected,
      required this.onTap,
      required this.child});

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected ? AppColors.primaryText : AppColors.border,
                    width: selected ? 2.5 : 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(selected ? 7.5 : 9),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      child,
                      if (selected)
                        Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white, width: 1.5),
                            ),
                            child: const Icon(Icons.check,
                                size: 13, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutlineAction extends StatelessWidget {
  const _OutlineAction(
      {required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryText,
        side: BorderSide(color: AppColors.primaryText),
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

/// Tiruan kecil header Profil: cover dengan overlay yang sama, lalu
/// avatar dan nama di bawahnya. Area cover bisa digeser lewat [onDrag].
class _ProfilePreview extends StatelessWidget {
  const _ProfilePreview(
      {required this.user, this.cover, this.file, this.position, this.onDrag});

  final AuthUser user;
  final ProfileCover? cover;
  final File? file;
  final CoverPosition? position;
  final void Function(Offset delta, Size area)? onDrag;

  /// Kira-kira rasio area cover di header Profil (lebar HP : tinggi foto).
  static const aspectRatio = 1.8;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: aspectRatio,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final area = constraints.biggest;
                return GestureDetector(
                  onPanUpdate:
                      onDrag == null ? null : (d) => onDrag!(d.delta, area),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CoverBackground(
                          cover: cover, file: file, position: position),
                      const CoverReadabilityOverlay(),
                      const Positioned(
                        left: 16,
                        top: 14,
                        child: Text(
                          'Profile',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                      ),
                      if (onDrag != null)
                        Positioned(
                          right: 10,
                          bottom: 10,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.4),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.open_with,
                                size: 16, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(
              children: [
                UserAvatar(
                  initials: user.initials,
                  photoUrl: user.photoUrl,
                  radius: 22,
                  fontSize: 15,
                  backgroundColor: AppColors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text),
                      ),
                      if (user.section != null)
                        Text(
                          user.section!,
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textMid),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
