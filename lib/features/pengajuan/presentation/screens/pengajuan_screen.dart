import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/network/api_client.dart';
import '../../../shared/domain/role.dart';

import '../../data/pengajuan_repository.dart';
import '../bloc/balance/leave_balance_bloc.dart';
import '../bloc/balance/leave_balance_event.dart';
import '../bloc/history/leave_history_bloc.dart';
import '../bloc/history/leave_history_event.dart';
import '../widgets/ajukan_tab.dart';
import '../widgets/ringkasan_tab.dart';
import '../widgets/status_tab.dart';

enum _SubmitTab { ringkasan, ajukan, status }

/// Shell tab Pengajuan (Ringkasan / Ajukan / Status).
///
/// Menyediakan [LeaveBalanceBloc] dan [LeaveHistoryBloc] di sini, satu
/// tingkat di atas ketiga tab, supaya [AjukanTab] bisa menyisipkan hasil
/// submit ke [LeaveHistoryBloc] yang sama yang dibaca [StatusTab] — tanpa
/// kedua bloc itu perlu saling kenal satu sama lain.
class PengajuanScreen extends StatelessWidget {
  const PengajuanScreen({super.key, required this.role, this.repository});

  final Role role;

  /// Diisi test; di aplikasi diambil dari [RepositoryProvider].
  final PengajuanRepository? repository;

  @override
  Widget build(BuildContext context) {
    final pengajuan = repository ?? PengajuanRepository(apiClient: ApiClient());

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => LeaveBalanceBloc(repository: pengajuan, role: role)
            ..add(const LeaveBalanceStarted()),
        ),
        BlocProvider(
          create: (_) => LeaveHistoryBloc(repository: pengajuan)
            ..add(const LeaveHistoryStarted()),
        ),
      ],
      child: _PengajuanView(role: role),
    );
  }
}

class _PengajuanView extends StatefulWidget {
  const _PengajuanView({required this.role});

  final Role role;

  @override
  State<_PengajuanView> createState() => _PengajuanViewState();
}

class _PengajuanViewState extends State<_PengajuanView> {
  _SubmitTab _tab = _SubmitTab.ringkasan;

  @override
  Widget build(BuildContext context) {
    // Strip status bar memakai warna header (putih), bukan warna halaman —
    // kalau tidak, ada garis beda warna tepat di atas header.
    return ColoredBox(
      color: AppColors.card,
      child: SafeArea(
        child: ColoredBox(
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              Expanded(
                child: switch (_tab) {
                  _SubmitTab.ringkasan => RingkasanTab(
                      onSeeAll: () => setState(() => _tab = _SubmitTab.status),
                    ),
                  _SubmitTab.ajukan => AjukanTab(
                      role: widget.role,
                      onSubmitted: () => setState(() => _tab = _SubmitTab.status),
                    ),
                  _SubmitTab.status => StatusTab(role: widget.role),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    Widget tabButton(_SubmitTab tab, String label, IconData icon) {
      final active = _tab == tab;

      return Expanded(
        child: InkWell(
          onTap: () => setState(() => _tab = tab),
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: active ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: active ? Colors.white : AppColors.textMuted),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: active ? Colors.white : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 14),
            child: Text('Leave Request', style: AppTextStyles.h2),
          ),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                tabButton(_SubmitTab.ringkasan, 'Summary', Icons.pie_chart_outline_rounded),
                tabButton(_SubmitTab.ajukan, 'Submit', Icons.edit_outlined),
                tabButton(_SubmitTab.status, 'Status', Icons.calendar_month_outlined),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
