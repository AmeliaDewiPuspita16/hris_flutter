import '../../../../core/utils/currency_formatter.dart';

/// nominal untuk ditampilkan; disamarkan bila user memilih menyembunyikan nominal
/// nominal (mis. saat membuka slip ditempat ramai)
String payslipAmountText(int amount, {required bool hidden}) {
  return hidden ? 'Rp ••••••••' : formatRupiah(amount);
}
