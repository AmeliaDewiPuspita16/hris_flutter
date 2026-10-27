import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../core/logging/app_logger.dart';
import '../../../../../../../core/network/api_exception.dart';
import '../../../data/indent_vehicle_repository.dart';
import '../../../domain/indent_driver_demo_data.dart';
import '../../../domain/indent_assigned_item.dart';

enum IndentDriverStatus { initial, loading, success, failure }

/// Keadaan tab "My Assignments".
class IndentDriverState {
  const IndentDriverState({
    this.status = IndentDriverStatus.initial,
    this.items = const [],
    this.errorMessage,
  });

  final IndentDriverStatus status;

  /// Perjalanan yang ditugaskan ke driver ini.
  final List<IndentAssignedItem> items;

  /// Alasan gagal memuat, sudah siap ditampilkan.
  final String? errorMessage;

  /// Muat pertama kali: belum ada yang bisa ditampilkan, jadi layar
  /// menampilkan kerangka. Saat refresh, daftar lama tetap tampil.
  bool get isFirstLoad =>
      status == IndentDriverStatus.loading && items.isEmpty;
}

/// Memuat daftar tugas driver (`GET /api/indent/admin/list`). Hanya
/// dijalankan untuk akun role `driver`.
class IndentDriverCubit extends Cubit<IndentDriverState> {
  IndentDriverCubit({
    required IndentVehicleRepository repository,
    this.useDemoData = false,
  })  : _repository = repository,
        super(const IndentDriverState());

  final IndentVehicleRepository _repository;

  /// Pratinjau: isi dengan [IndentDriverDemoData], tanpa memanggil API.
  final bool useDemoData;

  /// Muat ulang yang tumpang tindih bisa membalas dengan urutan terbalik;
  /// hasil yang bukan permintaan terakhir dibuang.
  int _token = 0;

  /// Driver menutup perjalanan ([IndentVehicleRepository.closeRequest]).
  /// Mengembalikan null bila berhasil, atau pesan galat yang siap
  /// ditampilkan. Yang berhasil langsung dibuang dari daftar tanpa memuat
  /// ulang, supaya posisi scroll tidak lompat.
  Future<String?> finish(IndentAssignedItem item) async {
    try {
      if (useDemoData) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
      } else {
        await _repository.closeRequest(item.id);
      }
      if (isClosed) return null;

      emit(IndentDriverState(
        status: IndentDriverStatus.success,
        items: [
          for (final i in state.items)
            if (i.id != item.id) i,
        ],
      ));
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (e, stack) {
      AppLogger.error('Tutup request gagal karena galat tak terduga', e, stack);
      return 'An unexpected error occurred. Please try again.';
    }
  }

  Future<void> load() async {
    final token = ++_token;

    emit(IndentDriverState(
      status: IndentDriverStatus.loading,
      items: state.items,
    ));

    try {
      if (useDemoData) {
        // Jeda singkat supaya kerangka loading ikut terlihat saat pratinjau.
        await Future<void>.delayed(const Duration(milliseconds: 600));
      }
      final items = useDemoData
          ? IndentDriverDemoData.items()
          : await _repository.fetchDriverAssignments();
      if (token != _token || isClosed) return;

      emit(IndentDriverState(
        status: IndentDriverStatus.success,
        // Paling awal di atas (lihat IndentAssignedItem.bySchedule).
        items: [...items]..sort(IndentAssignedItem.bySchedule),
      ));
    } on ApiException catch (e) {
      if (token != _token || isClosed) return;

      AppLogger.info('Tugas driver gagal dimuat: ${e.kind.name} — ${e.message}');
      emit(IndentDriverState(
        status: IndentDriverStatus.failure,
        errorMessage: e.message,
      ));
    } catch (e, stack) {
      if (token != _token || isClosed) return;

      AppLogger.error('Tugas driver gagal karena galat tak terduga', e, stack);
      emit(const IndentDriverState(
        status: IndentDriverStatus.failure,
        errorMessage: 'An unexpected error occurred. Please try again.',
      ));
    }
  }
}
