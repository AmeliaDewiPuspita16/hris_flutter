/// Berkas yang dilampirkan pada sebuah Purchase Requisition.
class PrAttachment {
  const PrAttachment({required this.fileName, required this.sizeLabel});

  final String fileName;

  /// Ukuran berkas siap tampil, ex: "720.94 KB". Sengaja String karena
  /// sumbernya nanti API yang sudah memformat, bukan jumlah byte mentah.
  final String sizeLabel;
}
