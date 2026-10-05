/// Halaman daftar slip gaji per tahun.
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/back_header.dart';
import '../../data/mock_payslip_repository.dart';
import '../../domain/payslip.dart';
import '../../domain/payslip_repository.dart';
import '../bloc/list/payslip_list_bloc.dart';
import '../bloc/list/payslip_list_event.dart';
import '../bloc/list/payslip_list_state.dart';
import '../widgets/payslip_card.dart';
import '../widgets/payslip_year_selector.dart';
import 'slip_gaji_detail_screen.dart';

/// Daftar riwayat slip gaji per bulan. Hanya menyediakan [PayslipListBloc];
/// tampilannya ada di [_PayslipView].
class PayslipScreen extends StatelessWidget {
  const PayslipScreen({super.key, this.repository});

  /// Sumber data. Selama API belum ada, bawaannya data contoh.
  ///
  /// TODO(api-slip-gaji): saat API siap, buat `ApiPayslipRepository`, daftarkan
  /// di `main.dart` seperti repository lain, lalu ganti bawaan di bawah
  /// menjadi `context.read<PayslipRepository>()`.
  final PayslipRepository? repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PayslipListBloc(
        repository: repository ?? const MockPayslipRepository(),
      )..add(const PayslipListStarted()),
      child: const _PayslipView(),
    );
  }
}

class _PayslipView extends StatelessWidget {
  const _PayslipView();

  void _openDetail(BuildContext context, Payslip payslip) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SlipGajiDetailScreen(payslip: payslip)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: BackHeader(title: 'Slip Gaji', onBack: () => Navigator.of(context).pop()),
      body: BlocBuilder<PayslipListBloc, PayslipListState>(
        builder: (context, state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PayslipYearSelector(
                years: state.years,
                selected: state.year,
                onSelected: (year) =>
                    context.read<PayslipListBloc>().add(PayslipYearSelected(year)),
              ),
              Expanded(child: _buildBody(context, state)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, PayslipListState state) {
    switch (state.status) {
      case PayslipListStatus.loading:
        return const Center(child: CircularProgressIndicator(color: AppColors.primary));
      case PayslipListStatus.failure:
        return AppErrorView(
          message: state.errorMessage ?? 'Gagal memuat slip gaji.',
          onRetry: () => context.read<PayslipListBloc>().add(const PayslipListRetried()),
        );
      case PayslipListStatus.success:
        if (state.payslips.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'Belum ada slip gaji untuk tahun ${state.year}.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMuted,
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          itemCount: state.payslips.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final payslip = state.payslips[index];
            return PayslipCard(
              payslip: payslip,
              onTap: () => _openDetail(context, payslip),
            );
          },
        );
    }
  }
}
