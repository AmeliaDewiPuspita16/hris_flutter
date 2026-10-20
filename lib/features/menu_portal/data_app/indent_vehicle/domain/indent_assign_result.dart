/// Hasil popup "Assign Vehicle" yang dikembalikan ke layar: plat nomor
/// (wajib) serta driver — nama dan id-nya — yang null kalau request tanpa
/// driver. Server meminta keduanya (`driver` dan `id_driver`)
class IndentAssignResult {
  const IndentAssignResult(
      {required this.plateNumber, this.driver, this.driverId});

  final String plateNumber;
  final String? driver;
  final int? driverId;
}
