import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/repositories/grupos_repository.dart';
import '../../cubit/grupo_actual_cubit.dart';
import 'seleccion_grupo_event.dart';
import 'seleccion_grupo_state.dart';

/// E001-HU-003: BLoC para Seleccion de Grupo Post-Login
/// CA-001 a CA-005, RN-001 a RN-004
class SeleccionGrupoBloc
    extends Bloc<SeleccionGrupoEvent, SeleccionGrupoState> {
  final GruposRepository repository;
  final GrupoActualCubit grupoActualCubit;

  SeleccionGrupoBloc({
    required this.repository,
    required this.grupoActualCubit,
  }) : super(const SeleccionGrupoInitial()) {
    on<CargarGruposParaSeleccionEvent>(_onCargarGrupos);
    on<GrupoSeleccionadoEvent>(_onGrupoSeleccionado);
  }

  /// Carga los grupos del usuario y determina el flujo
  /// CA-003 / RN-001: Si tiene 1 grupo, auto-skip (solo en login)
  /// CA-004 / RN-003: Ordenados por ultimo_acceso (ya viene del RPC)
  /// E002-HU-007: forzarSeleccion omite auto-skip para cambio de grupo
  Future<void> _onCargarGrupos(
    CargarGruposParaSeleccionEvent event,
    Emitter<SeleccionGrupoState> emit,
  ) async {
    emit(const SeleccionGrupoLoading());

    final result = await repository.obtenerMisGrupos();

    result.fold(
      (failure) => emit(SeleccionGrupoError(message: failure.message)),
      (grupos) {
        // E002-HU-007 RN-005: Almacenar total para swap condicional
        grupoActualCubit.setTotalGrupos(grupos.length);

        if (grupos.isEmpty) {
          emit(const SeleccionGrupoSinGrupos());
        } else if (grupos.length == 1 && !event.forzarSeleccion) {
          // CA-003 / RN-001: Auto-skip con 1 solo grupo (solo en login)
          // E002-HU-007: Si forzarSeleccion=true, mostrar lista
          final grupo = grupos.first;
          debugPrint('[SeleccionGrupoBloc] Auto-seleccionando grupo: ${grupo.nombre}');
          grupoActualCubit.seleccionarGrupo(grupo);
          repository.registrarAccesoGrupo(grupo.grupoId);
          emit(SeleccionGrupoAutoSeleccionado(grupo: grupo));
        } else {
          // CA-001: Mostrar lista de grupos
          // CA-004 / RN-003: Ya vienen ordenados por ultimo_acceso
          debugPrint('[SeleccionGrupoBloc] ${grupos.length} grupos para seleccion');
          emit(SeleccionGrupoLista(grupos: grupos));
        }
      },
    );
  }

  /// CA-002: Usuario selecciona un grupo
  /// RN-004: Sin re-autenticacion
  Future<void> _onGrupoSeleccionado(
    GrupoSeleccionadoEvent event,
    Emitter<SeleccionGrupoState> emit,
  ) async {
    debugPrint('[SeleccionGrupoBloc] Grupo seleccionado: ${event.grupo.nombre}');

    // Establecer grupo actual globalmente
    grupoActualCubit.seleccionarGrupo(event.grupo);

    // Registrar acceso (RN-003: actualiza ultimo_acceso)
    repository.registrarAccesoGrupo(event.grupo.grupoId);

    emit(SeleccionGrupoCompletada(grupo: event.grupo));
  }
}
