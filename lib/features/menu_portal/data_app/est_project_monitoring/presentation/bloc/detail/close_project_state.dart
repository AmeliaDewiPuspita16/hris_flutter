sealed class CloseProjectState {
  const CloseProjectState();
}

class CloseProjectInitial extends CloseProjectState {
  const CloseProjectInitial();
}

class CloseProjectLoading extends CloseProjectState {
  const CloseProjectLoading();
}

/// Request berhasil dikirim: status proyek jadi pending_close. Proyek belum
/// benar-benar tutup sampai HOD menyetujui.
class CloseProjectSuccess extends CloseProjectState {
  const CloseProjectSuccess();
}

class CloseProjectFailure extends CloseProjectState {
  const CloseProjectFailure(this.message);

  final String message;
}
