/// Hal-hal ynag bisa terjadi pada daftar slip gaji
sealed class PayslipListEvent {
  const PayslipListEvent();
}

/// Layar dibuka: muat slip untuk tahun awal
class PayslipListStarted extends PayslipListEvent {
  const PayslipListStarted();
}

/// User memilih tahun lain.
class PayslipYearSelected extends PayslipListEvent {
  const PayslipYearSelected(this.year);

  final int year;
}

/// User menekan tombol "coba lagi" setelah gagal memuat slip.
class PayslipListRetried extends PayslipListEvent {
  const PayslipListRetried();
}
