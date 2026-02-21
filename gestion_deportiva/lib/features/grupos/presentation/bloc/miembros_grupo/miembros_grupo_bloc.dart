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
    on<EliminarJugadorEvent>(_onEliminarJugador);
    on<PromoverACoadminEvent>(_onPromoverACoadmin);
    on<DegradarCoadminEvent>(_onDegradarCoadmin);
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

  /// E002-HU-006: Eliminar jugador del grupo
  /// CA-001, RN-001 a RN-005
  Future<void> _onEliminarJugador(
    EliminarJugadorEvent event,
    Emitter<MiembrosGrupoState> emit,
  ) async {
    emit(MiembrosGrupoLoading());

    final result = await repository.eliminarJugadorGrupo(
      grupoId: event.grupoId,
      miembroId: event.miembroId,
    );

    result.fold(
      (failure) => emit(MiembrosGrupoError(failure.message)),
      (_) => emit(EliminarJugadorSuccess(event.nombreJugador)),
    );
  }

  /// E002-HU-004 CA-001: Promover jugador a co-admin
  /// RN-001: Solo admin creador, RN-002: Limite plan, RN-003: Solo jugadores activos
  Future<void> _onPromoverACoadmin(
    PromoverACoadminEvent event,
    Emitter<MiembrosGrupoState> emit,
  ) async {
    emit(MiembrosGrupoLoading());

    final result = await repository.promoverACoadmin(
      grupoId: event.grupoId,
      miembroId: event.miembroId,
    );

    result.fold(
      (failure) => emit(MiembrosGrupoError(failure.message)),
      (_) => emit(PromoverCoadminSuccess(event.nombreJugador)),
    );
  }

  /// E002-HU-004 CA-002: Degradar co-admin a jugador
  /// RN-001: Solo admin creador, RN-005: Conserva membresia
  Future<void> _onDegradarCoadmin(
    DegradarCoadminEvent event,
    Emitter<MiembrosGrupoState> emit,
  ) async {
    emit(MiembrosGrupoLoading());

    final result = await repository.degradarCoadmin(
      grupoId: event.grupoId,
      miembroId: event.miembroId,
    );

    result.fold(
      (failure) => emit(MiembrosGrupoError(failure.message)),
      (_) => emit(DegradarCoadminSuccess(event.nombreJugador)),
    );
  }
}
