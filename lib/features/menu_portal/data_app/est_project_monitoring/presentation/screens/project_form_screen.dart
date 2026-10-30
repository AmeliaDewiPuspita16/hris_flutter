import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../../core/network/api_exception.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/widgets/back_header.dart';
import '../../data/est_project_repository.dart';
import '../../domain/est_form_worker.dart';
import '../../domain/est_mandor.dart';
import '../widgets/est_form_info_section.dart';
import '../widgets/est_form_mandor_picker.dart';
import '../widgets/est_form_schedule_section.dart';
import '../widgets/est_form_section.dart';
import '../widgets/est_form_submit_button.dart';
import '../widgets/est_form_worker_picker.dart';
import 'location_picker_screen.dart';

/// Format untuk API: Y-m-d
String _formatDateApi(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Form buat / edit proyek. [project] null = mode buat, berisi = mode edit
/// (kunci: id, name, location, budget_hours, start_date, target_end_date,
/// latitude, longitude). Pop dengan `true` bila tersimpan.
class ProjectFormScreen extends StatefulWidget {
  const ProjectFormScreen({super.key, this.project});

  final Map<String, dynamic>? project;

  @override
  State<ProjectFormScreen> createState() => _ProjectFormScreenState();
}

class _ProjectFormScreenState extends State<ProjectFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _budgetHoursCtrl = TextEditingController();

  late final EstProjectRepository _repository;

  bool get _isEdit => widget.project != null;

  EstMandor? _selectedMandor;
  List<EstMandor> _mandors = [];
  bool _mandorsLoading = false;
  String? _mandorsError;

  DateTime? _startDate;
  DateTime? _endDate;

  double? _latitude;
  double? _longitude;

  List<EstFormWorker> _workers = [];
  // Menyimpan semua worker yang dipilih, persist antar search
  final Map<int, EstFormWorker> _selectedWorkers = {};
  bool _workersLoading = false;
  String? _workersError;
  String _dwSearchQuery = '';
  Timer? _searchDebounce;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _repository = context.read<EstProjectRepository>();

    if (_isEdit) {
      _nameCtrl.text = widget.project!['name'] ?? '';
      _locationCtrl.text = widget.project!['location'] ?? '';
      _budgetHoursCtrl.text = widget.project!['budget_hours']?.toString() ?? '';
      _startDate = DateTime.tryParse(widget.project!['start_date'] ?? '');
      _endDate = DateTime.tryParse(widget.project!['target_end_date'] ?? '');
      _latitude = (widget.project!['latitude'] as num?)?.toDouble();
      _longitude = (widget.project!['longitude'] as num?)?.toDouble();
    }

    _fetchMandors();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    _budgetHoursCtrl.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  int get _selectedDwCount => _selectedWorkers.length;

  // ── Data ──────────────────────────────────────────────
  Future<void> _fetchWorkers({String search = ''}) async {
    setState(() {
      _workersLoading = true;
      _workersError = null;
    });
    try {
      final params = <String, String>{};
      if (search.isNotEmpty) params['search'] = search;
      if (_isEdit && widget.project!['id'] != null) {
        params['project_id'] = widget.project!['id'].toString();
      }

      final incoming = await _repository.fetchFormWorkers(
        query: params.isEmpty ? null : params,
      );

      // Tandai item yang sudah dipilih sebelumnya
      for (final w in incoming) {
        if (_selectedWorkers.containsKey(w.id)) w.isSelected = true;
      }

      if (mounted) setState(() => _workers = incoming);
    } on ApiException catch (e) {
      if (mounted) setState(() => _workersError = e.message);
    } catch (_) {
      if (mounted) setState(() => _workersError = 'Gagal memuat daftar worker');
    } finally {
      if (mounted) setState(() => _workersLoading = false);
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _dwSearchQuery = value;
      if (value.isEmpty) _workers = [];
    });
    _searchDebounce?.cancel();
    if (value.isNotEmpty) {
      _searchDebounce = Timer(const Duration(milliseconds: 500), () {
        _fetchWorkers(search: value);
      });
    }
  }

  void _toggleWorker(EstFormWorker dw) {
    setState(() {
      dw.isSelected = !dw.isSelected;
      if (dw.isSelected) {
        _selectedWorkers[dw.id] = dw;
      } else {
        _selectedWorkers.remove(dw.id);
      }
    });
  }

  void _toggleAllWorkers() {
    final allSelected =
        _workers.isNotEmpty && _workers.every((d) => d.isSelected);
    setState(() {
      for (final dw in _workers) {
        dw.isSelected = !allSelected;
        if (dw.isSelected) {
          _selectedWorkers[dw.id] = dw;
        } else {
          _selectedWorkers.remove(dw.id);
        }
      }
    });
  }

  Future<void> _fetchMandors() async {
    setState(() {
      _mandorsLoading = true;
      _mandorsError = null;
    });
    try {
      final list = await _repository.fetchMandors();
      if (mounted) setState(() => _mandors = list);
    } on ApiException catch (e) {
      if (mounted) setState(() => _mandorsError = e.message);
    } catch (_) {
      if (mounted) setState(() => _mandorsError = 'Gagal memuat daftar mandor');
    } finally {
      if (mounted) setState(() => _mandorsLoading = false);
    }
  }

  // ── Submit ────────────────────────────────────────────
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null) {
      _showError('Tanggal mulai wajib dipilih');
      return;
    }
    if (_endDate == null) {
      _showError('Estimasi selesai wajib dipilih');
      return;
    }
    if (!_isEdit) {
      if (_selectedMandor == null) {
        _showError('Mandor wajib dipilih');
        return;
      }
      if (_selectedDwCount == 0) {
        _showError('Pilih minimal 1 DW untuk proyek ini');
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      final body = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
        'budget_hours': int.parse(_budgetHoursCtrl.text),
        'start_date': _formatDateApi(_startDate!),
        'target_end_date': _formatDateApi(_endDate!),
        if (!_isEdit) 'mandor_id': _selectedMandor!.id,
        if (!_isEdit) 'worker_ids': _selectedWorkers.keys.toList(),
        if (_latitude != null) 'latitude': _latitude,
        if (_longitude != null) 'longitude': _longitude,
      };
      if (_isEdit) {
        await _repository.updateProject(widget.project!['id'] as int, body);
      } else {
        await _repository.createProject(body);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 10),
              Text(
                _isEdit
                    ? 'Proyek berhasil diperbarui'
                    : 'Proyek berhasil dibuat',
              ),
            ],
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('Terjadi kesalahan, coba lagi');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: AppColors.rejected,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Pickers ───────────────────────────────────────────
  Future<void> _openLocationPicker() async {
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLat: _latitude,
          initialLng: _longitude,
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _latitude = result.latitude;
        _longitude = result.longitude;
      });
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initial = isStart
        ? (_startDate ?? now)
        : (_endDate ?? (_startDate ?? now).add(const Duration(days: 30)));
    final first = isStart ? now : (_startDate ?? now);
    final last = DateTime(2030);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: AppColors.isDark
              ? ColorScheme.dark(
                  primary: AppColors.primaryText,
                  onPrimary: Colors.black,
                  surface: AppColors.card,
                )
              : ColorScheme.light(
                  primary: AppColors.primary,
                  onPrimary: Colors.white,
                  surface: AppColors.card,
                ),
        ),
        child: child!,
      ),
    );

    if (picked != null && mounted) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(picked)) _endDate = null;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  // ── Build ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: BackHeader(
        title: _isEdit ? 'Edit Proyek' : 'Tambah Proyek',
        onBack: () => Navigator.pop(context),
      ),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        child: Column(
          children: [
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      EstFormInfoSection(
                        nameController: _nameCtrl,
                        locationController: _locationCtrl,
                        budgetHoursController: _budgetHoursCtrl,
                        latitude: _latitude,
                        longitude: _longitude,
                        onOpenMap: _openLocationPicker,
                      ),
                      const SizedBox(height: 20),
                      EstFormScheduleSection(
                        startDate: _startDate,
                        endDate: _endDate,
                        onPickStart: () => _pickDate(isStart: true),
                        onPickEnd: () => _pickDate(isStart: false),
                      ),
                      const SizedBox(height: 20),
                      EstFormSection(
                        title: 'Supervisor',
                        icon: Icons.person_outline,
                        children: [
                          EstFormMandorPicker(
                            mandors: _mandors,
                            loading: _mandorsLoading,
                            error: _mandorsError,
                            selected: _selectedMandor,
                            onRetry: _fetchMandors,
                            onChanged: (v) =>
                                setState(() => _selectedMandor = v),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      EstFormSection(
                        title: 'Assign Pekerja',
                        icon: Icons.groups_outlined,
                        badge: _selectedDwCount > 0
                            ? '$_selectedDwCount dipilih'
                            : null,
                        children: [
                          EstFormWorkerPicker(
                            workers: _workers,
                            loading: _workersLoading,
                            error: _workersError,
                            searchQuery: _dwSearchQuery,
                            selectedCount: _selectedDwCount,
                            onSearchChanged: _onSearchChanged,
                            onRetry: () =>
                                _fetchWorkers(search: _dwSearchQuery),
                            onToggle: _toggleWorker,
                            onToggleAll: _toggleAllWorkers,
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      EstFormSubmitButton(
                        isEdit: _isEdit,
                        isLoading: _isLoading,
                        onPressed: _handleSubmit,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
