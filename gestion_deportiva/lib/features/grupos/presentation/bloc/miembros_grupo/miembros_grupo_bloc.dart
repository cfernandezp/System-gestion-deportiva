import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/repositories/grupos_repository.dart';
import 'miembros_grupo_event.dart';
import 'miembros_grupo_state.dart';

/// Bloc para ver miembros del grupo
/// E002-HU-005: Ver Miembros del Grupo
/// CA-001 a CA-005, RN-001 a RN-005
class MiembrosGrupoBloc extends Bloc<MiembrosGrupoEvent, MiembrosGrupoState> {
  final GruposRepository repository;

  MiembrosGrupoBloc({required this.repository}) : super(MiembrosGrupoInitial()) {
    on<CargarMiembrosGrupoEvent>(_onCargarMiembros);
    on<FiltrarPorRolEvent>(_onFiltrarPorRol);
    on<BuscarMiembroEvent>(_onBuscarMiembro);
  }

  Future<void> _onCargarMiembros(
    CargarMiembrosGrupoEvent event,
    Emitter<MiembrosGrupoState> emit,
  ) async {
    emit(MiembrosGrupoLoading());

    final result = await repository.obtenerMiembrosGrupo(event.grupoId);

    result.fold(
      (failure) => emit(MiembrosGrupoError(failure.message)),
      (miembros) => emit(MiembrosGrupoLoaded(miembros)),
    );
  }

  /// CA-003 / RN-004: Filtrar por rol (client-side)
  void _onFiltrarPorRol(
    FiltrarPorRolEvent event,
    Emitter<MiembrosGrupoState> emit,
  ) {
    final currentState = state;
    if (currentState is MiembrosGrupoLoaded) {
      emit(currentState.copyWith(
        filtroRol: event.rol,
        clearFiltroRol: event.rol == null,
      ));
    }
  }

  /// CA-004 / RN-005: Buscar por nombre (client-side, tiempo real)
  void _onBuscarMiembro(
    BuscarMiembroEvent event,
    Emitter<MiembrosGrupoState> emit,
  ) {
    final currentState = state;
    if (currentState is MiembrosGrupoLoaded) {
      emit(currentState.copyWith(busqueda: event.query));
    }
  }
}
