import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../core/logging/app_logger.dart';
import '../../../../../../../core/network/api_exception.dart';
import '../../../data/indent_vehicle_repository.dart';
import 'indent_pending_event.dart';
import 'indent_pending_state.dart';

/// Tab "Pending Vehicle Assignment": memuat request yang menunggu kendaraan
/// (`GET /api/indent/admin/list`) dan mengirim penugasan admin
/// (`POST /api/admin_indent/approve`).
///
/// Aman dimulai untuk semua akun: server yang menentukan isinya, dan untuk
/// akun yang bukan `driver-admin` repository mengembalikan daftar kosong.
class IndentPendingBloc extends Bloc<IndentPendingEvent, IndentPendingState> {
  IndentPendingBloc({required IndentVehicleRepository repository})
      : _repository = repository,
        super(const IndentPendingState()) {
    on<IndentPendingStarted>(_onLoad);
    on<IndentPendingRefreshed>(_onLoad);
    on<IndentPendingAssigned>(_onAssigned);
  }

  final IndentVehicleRepository _repository;

  /// Muat ulang yang tumpang tindih bisa membalas dengan urutan terbalik;
  /// hasil yang bukan permintaan terakhir dibuang.
  int _requestToken = 0;

  Future<void> _onLoad(
    IndentPendingEvent event,
    Emitter<IndentPendingState> emit,
  ) async {
    final token = ++_requestToken;

    emit(state.copyWith(
      status: IndentPendingStatus.loading,
      errorMessage: null,
    ));

    try {
      final items = await _repository.fetchPendingAssignments();
      if (token != _requestToken) return;

      emit(state.copyWith(status: IndentPendingStatus.success, items: items));
    } on ApiException catch (e) {
      if (token != _requestToken) return;

      AppLogger.info('List pending gagal dimuat: ${e.kind.name} — ${e.message}');
      emit(state.copyWith(
        status: IndentPendingStatus.failure,
        items: const [],
        errorMessage: e.message,
      ));
    } catch (e, stack) {
      if (token != _requestToken) return;

      AppLogger.error('List pending gagal karena galat tak terduga', e, stack);
      emit(state.copyWith(
        status: IndentPendingStatus.failure,
        items: const [],
        errorMessage: 'An unexpected error occurred. Please try again.',
      ));
    }
  }

  /// Kirim penugasan dulu, baru keluarkan request dari daftar — kalau
  /// server gagal, request tetap ada supaya admin bisa mencoba lagi.
  Future<void> _onAssigned(
    IndentPendingAssigned event,
    Emitter<IndentPendingState> emit,
  ) async {
    final item = event.item;
    final result = event.result;
    if (state.busyIds.contains(item.id)) return;

    emit(state.copyWith(busyIds: {...state.busyIds, item.id}));

    try {
      await _repository.assignByAdmin(
        id: item.id,
        plateNumber: result.plateNumber,
        driverId: result.driverId,
        driverName: result.driver,
      );

      final driverText = result.driver == null ? '' : ' · ${result.driver}';
      emit(state.copyWith(
        items: state.items.where((r) => r.id != item.id).toList(),
        busyIds: Set.of(state.busyIds)..remove(item.id),
        notice: IndentPendingNotice(
          message: 'Vehicle ${result.plateNumber}$driverText '
              'assigned to ${item.name}',
          isError: false,
        ),
      ));
    } on ApiException catch (e) {
      AppLogger.info('Assign gagal: ${e.kind.name} — ${e.message}');
      emit(state.copyWith(
        busyIds: Set.of(state.busyIds)..remove(item.id),
        notice: IndentPendingNotice(message: e.message, isError: true),
      ));
    } catch (e, stack) {
      AppLogger.error('Assign gagal tak terduga', e, stack);
      emit(state.copyWith(
        busyIds: Set.of(state.busyIds)..remove(item.id),
        notice: const IndentPendingNotice(
          message: 'An unexpected error occurred. Please try again.',
          isError: true,
        ),
      ));
    }
  }
}
