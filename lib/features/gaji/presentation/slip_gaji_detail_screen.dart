/// halaman detail per bulan.

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/back_header.dart';
import '../domain/payslip.dart';

/// Rincian pendapatan & potongan untuk satu periode slip gaji.
class SlipGajiDetailScreen extends StatelessWidget {
  const SlipGajiDetailScreen({super.key, required this.payslip});

  final Payslip payslip;

  void _downloadPdf(BuildContext context) {
    // TODO(fitur-download-slip): nanti ganti dengan export PDF asli.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Unduh slip gaji belum tersedia.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPaid = payslip.status == PayslipStatus.paid;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: BackHeader(
        title: payslip.periodLabel,
        onBack: () => Navigator.of(context).pop(),
        trailing: InkWell(
          onTap: () => _downloadPdf(context),
          child: const Icon(Icons.file_download_outlined, size: 20, color: AppColors.primary),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeroCard(payslip: payslip),
            if (payslip.paidDate != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  'Dibayarkan ${payslip.paidDate}'
                  '${payslip.bankInfo != null ? ' · Rekening ${payslip.bankInfo}' : ''}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ),
            ],
            const SizedBox(height: 20),
            const Text('Pendapatan', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 8),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  for (var i = 0; i < payslip.earnings.length; i++)
                    _ItemRow(
                      item: payslip.earnings[i],
                      showDivider: i != payslip.earnings.length - 1,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Potongan', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 8),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  for (var i = 0; i < payslip.deductions.length; i++)
                    _ItemRow(
                      item: payslip.deductions[i],
                      isDeduction: true,
                      showDivider: i != payslip.deductions.length - 1,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Diterima', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text)),
                  Text(
                    formatRupiah(payslip.netPay),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary),
                  ),
                ],
              ),
            ),
            if (!isPaid) ...[
              const SizedBox(height: 4),
              const Text(
                '🔒 Slip masih dalam proses payroll dan dapat berubah sebelum tanggal pembayaran.',
                style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.payslip});

  final Payslip payslip;

  @override
  Widget build(BuildContext context) {
    final isPaid = payslip.status == PayslipStatus.paid;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Take Home Pay', style: TextStyle(fontSize: 11, color: AppColors.bannerAccent)),
                const SizedBox(height: 2),
                Text(
                  formatRupiah(payslip.netPay),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isPaid ? 'Sudah Dibayar' : 'Menunggu',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.item,
    this.isDeduction = false,
    this.showDivider = true,
  });

  final PayslipItem item;
  final bool isDeduction;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border: showDivider ? const Border(bottom: BorderSide(color: AppColors.border)) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(item.label, style: const TextStyle(fontSize: 13, color: AppColors.textMid)),
          Text(
            '${isDeduction ? '- ' : ''}${formatRupiah(item.amount)}',
            style: TextStyle(
              fontSize: 13,
              color: isDeduction ? AppColors.rejected : AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}