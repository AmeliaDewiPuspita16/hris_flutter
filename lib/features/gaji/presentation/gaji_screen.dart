/// halaman list

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/back_header.dart';
import '../domain/payslip.dart';
import 'slip_gaji_detail_screen.dart';

/// Daftar riwayat slip gaji per bulan. 
class PayslipScreen extends StatelessWidget {
  const PayslipScreen({super.key});

  // dummy 
  static const _year = '2026';
  static const _payslips = Payslip.dummy2026;

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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildYearSelector(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              itemCount: _payslips.length,
              itemBuilder: (context, index) {
                final payslip = _payslips[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _PayslipCard(
                    payslip: payslip,
                    onTap: () => _openDetail(context, payslip),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearSelector() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      color: AppColors.bg,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Tahun', style: AppTextStyles.label),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.card,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(_year, style: TextStyle(fontSize: 13, color: AppColors.text)),
                SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.textMuted),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PayslipCard extends StatelessWidget {
  const _PayslipCard({required this.payslip, required this.onTap});

  final Payslip payslip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(payslip.periodLabel, style: AppTextStyles.sectionTitle),
                const SizedBox(height: 4),
                const Text('Take home pay', style: AppTextStyles.caption),
                const SizedBox(height: 2),
                Text(
                  formatRupiah(payslip.netPay),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _PayslipStatusChip(status: payslip.status),
              const SizedBox(height: 8),
              const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
            ],
          ),
        ],
      ),
    );
  }
}

class _PayslipStatusChip extends StatelessWidget {
  const _PayslipStatusChip({required this.status});

  final PayslipStatus status;

  @override
  Widget build(BuildContext context) {
    final isPaid = status == PayslipStatus.paid;
    final fg = isPaid ? AppColors.present : AppColors.pending;
    final bg = isPaid ? AppColors.presentBg : AppColors.pendingBg;
    final label = isPaid ? 'Sudah Dibayar' : 'Menunggu';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}