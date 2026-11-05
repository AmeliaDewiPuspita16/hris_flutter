import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/logging/app_logger.dart';
import '../../../../../../core/network/api_exception.dart';
import '../../data/observation_repository.dart';
import '../../domain/observation_filter.dart';
import 'observation_list_state.dart';

/// Memuat dua daftar Observation sekaligus dan menyimpan pencarian/filter.
/// Dipanggil ulang ([load]) setelah Add atau Close berhasil.
class ObservationListCubit extends Cubit<ObservationListState> {
  ObservationListCubit({required ObservationRepository repository})
      : _repository = repository,
        super(const ObservationListState());

  final ObservationRepository _repository;

  /// Permintaan yang tumpang tindih (refresh ditekan dua kali) bisa membalas
  /// dengan urutan terbalik; hasil yang bukan permintaan terakhir dibuang.
  int _token = 0;

  Future<void> load() async {
    final token = ++_token;
    emit(state.copyWith(
      status: ObservationListStatus.loading,
      errorMessage: null,
    ));

    try {
      // Dimulai bersamaan supaya berjalan paralel.
      final results = await Future.wait([
        _repository.fetchOpenFromMyDept(),
        _repository.fetchAll(),
      ]);
      if (token != _token) return;

      emit(state.copyWith(
        status: ObservationListStatus.success,
        myOpen: results[0],
        all: results[1],
      ));
    } on ApiException catch (e) {
      if (token != _token) return;
      AppLogger.info('Observation gagal dimuat: ${e.kind.name} — ${e.message}');
      emit(state.copyWith(
        status: ObservationListStatus.failure,
        errorMessage: e.message,
      ));
    } catch (e, stack) {
      if (token != _token) return;
      AppLogger.error('Observation gagal karena galat tak terduga', e, stack);
      emit(state.copyWith(
        status: ObservationListStatus.failure,
        errorMessage: 'An unexpected error occurred. Please try again.',
      ));
    }
  }

  void setQuery(String query) => emit(state.copyWith(query: query));

  void setFilter(ObservationFilter filter) =>
      emit(state.copyWith(filter: filter));
}
