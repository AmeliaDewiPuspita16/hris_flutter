import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../core/logging/app_logger.dart';
import '../../../../../../../core/network/api_exception.dart';
import '../../../data/indent_vehicle_repository.dart';
import 'indent_request_list_event.dart';
import 'indent_request_list_state.dart';

/// Memuat daftar "List of User Requests" dari `GET /api/indent`.
///
/// [currentUserId] / [currentUserName] diambil layar dari sesi login
/// (AuthBloc) dan diteruskan ke repository, supaya request milik sendiri
/// bisa ditandai (hak edit/hapus & banner feedback hanya untuk milik
/// sendiri).
class IndentRequestListBloc
    extends Bloc<IndentRequestListEvent, IndentRequestListState> {
  IndentRequestListBloc({
    required IndentVehicleRepository repository,
    int? currentUserId,
    String? currentUserName,
  })  : _repository = repository,
        _currentUserId = currentUserId,
        _currentUserName = currentUserName,
        super(const IndentRequestListState()) {
    on<IndentRequestListStarted>(_onLoad);
    on<IndentRequestListRefreshed>(_onLoad);
    on<IndentRequestLocalAdded>(_onLocalAdded);
    on<IndentRequestLocalUpdated>(_onLocalUpdated);
    on<IndentRequestLocalRemoved>(_onLocalRemoved);
  }

  final IndentVehicleRepository _repository;
  final int? _currentUserId;
  final String? _currentUserName;

  /// Dua permintaan yang tumpang tindih (mis. refresh ditekan dua kali)
  /// bisa membalas dengan urutan terbalik. Hasil yang bukan permintaan
  /// terakhir dibuang.
  int _requestToken = 0;

  Future<void> _onLoad(
    IndentRequestListEvent event,
    Emitter<IndentRequestListState> emit,
  ) async {
    final token = ++_requestToken;

    emit(state.copyWith(
      status: IndentRequestListStatus.loading,
      errorMessage: null,
    ));

    try {
      final items = await _repository.fetchRequests(
        currentUserId: _currentUserId,
        currentUserName: _currentUserName,
      );
      if (token != _requestToken) return;

      emit(state.copyWith(
        status: IndentRequestListStatus.success,
        items: items,
      ));
    } on ApiException catch (e) {
      if (token != _requestToken) return;

      AppLogger.info('List Indent gagal dimuat: ${e.kind.name} — ${e.message}');
      emit(state.copyWith(
        status: IndentRequestListStatus.failure,
        items: const [],
        errorMessage: e.message,
      ));
    } catch (e, stack) {
      if (token != _requestToken) return;

      AppLogger.error('List Indent gagal karena galat tak terduga', e, stack);
      emit(state.copyWith(
        status: IndentRequestListStatus.failure,
        items: const [],
        errorMessage: 'Terjadi kesalahan tak terduga. Coba lagi.',
      ));
    }
  }

  void _onLocalAdded(
    IndentRequestLocalAdded event,
    Emitter<IndentRequestListState> emit,
  ) {
    emit(state.copyWith(items: [event.item, ...state.items]));
  }

  void _onLocalUpdated(
    IndentRequestLocalUpdated event,
    Emitter<IndentRequestListState> emit,
  ) {
    emit(state.copyWith(
      items: [
        for (final item in state.items)
          if (item.id == event.item.id) event.item else item,
      ],
    ));
  }

  void _onLocalRemoved(
    IndentRequestLocalRemoved event,
    Emitter<IndentRequestListState> emit,
  ) {
    emit(state.copyWith(
      items: state.items.where((item) => item.id != event.id).toList(),
    ));
  }
}
