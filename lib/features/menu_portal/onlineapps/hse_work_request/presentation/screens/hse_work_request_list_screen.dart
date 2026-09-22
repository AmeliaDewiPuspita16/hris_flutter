import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/widgets/app_button.dart';
import '../../../../../../core/widgets/app_error_view.dart';
import '../../../../../../core/widgets/back_header.dart';
import '../../data/hse_work_request_repository.dart';
import '../../domain/hse_request_status.dart';
import '../../domain/hse_work_request.dart';
import '../widgets/hse_request_card.dart';
import '../widgets/hse_status_tabs.dart';
import 'hse_work_request_detail_screen.dart';
import 'hse_work_request_form_screen.dart';

class HseWorkRequestListScreen extends StatefulWidget {
  HseWorkRequestListScreen({super.key, HseWorkRequestRepository? repository})
      : repository = repository ?? HseWorkRequestRepository();

  final HseWorkRequestRepository repository;

  @override
  State<HseWorkRequestListScreen> createState() => _HseWorkRequestListScreenState();
}

class _HseWorkRequestListScreenState extends State<HseWorkRequestListScreen> {
  HseRequestStatus? _statusFilter;
  String _query = '';

  late Future<List<HseWorkRequest>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.fetchRequests();
  }

  void _reload() {
    setState(() => _future = widget.repository.fetchRequests());
  }

  Future<void> _openForm() async {
    final submitted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => HseWorkRequestFormScreen(repository: widget.repository),
      ),
    );
    if (submitted == true) _reload();
  }

  void _openDetail(HseWorkRequest request) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => HseWorkRequestDetailScreen(request: request)),
    );
  }

  List<HseWorkRequest> _applyFilters(List<HseWorkRequest> requests) {
    final query = _query.trim().toLowerCase();
    return requests.where((r) {
      final matchesStatus = _statusFilter == null || r.status == _statusFilter;
      final matchesQuery = query.isEmpty ||
          r.pic.toLowerCase().contains(query) ||
          (r.idRegister ?? '').toLowerCase().contains(query) ||
          r.location.toLowerCase().contains(query);
      return matchesStatus && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: BackHeader(
        title: 'HSE Work Request',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppButton(
                    label: '+ Add Request',
                    variant: AppButtonVariant.accent,
                    onPressed: _openForm,
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      hintText: 'Cari ID register, nama, atau lokasi...',
                      hintStyle: AppTextStyles.body.copyWith(color: AppColors.textMuted),
                      prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textMuted),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border, width: 1.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  HseStatusTabs(
                    selected: _statusFilter,
                    onChanged: (status) => setState(() => _statusFilter = status),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<HseWorkRequest>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return AppErrorView(
                      message: 'Gagal memuat daftar permit HSE.',
                      onRetry: _reload,
                    );
                  }

                  final requests = _applyFilters(snapshot.data ?? const []);
                  if (requests.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          'Belum ada permit HSE untuk filter ini.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMuted,
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async => _reload(),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: requests.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final request = requests[index];
                        return HseRequestCard(
                          request: request,
                          onTap: () => _openDetail(request),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
