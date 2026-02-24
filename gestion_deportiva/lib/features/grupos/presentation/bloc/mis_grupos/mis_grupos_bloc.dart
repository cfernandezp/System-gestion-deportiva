import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/repositories/grupos_repository.dart';
import 'mis_grupos_event.dart';
import 'mis_grupos_state.dart';

/// E002-HU-002: BLoC para Ver Mis Grupos
/// CA-001 a CA-005, RN-001 a RN-005
class MisGruposBloc extends Bloc<MisGruposEvent, MisGruposState> {
  final GruposRepository repository;

  MisGruposBloc({required this.repository})
      : super(const MisGruposInitial()) {
    on<CargarMisGruposEvent>(_onCargarMisGrupos);
    on<SeleccionarGrupoEvent>(_onSeleccionarGrupo);
  }

  /// CA-001: Carga la lista de grupos del usuario
  /// CA-003 / RN-003: Ordenados por ultimo_acceso DESC
  Future<void> _onCargarMisGrupos(
    CargarMisGruposEvent event,
    Emitter<MisGruposState> emit,
  ) async {
    emit(const MisGruposLoading());

    final result = await repository.obtenerMisGrupos();

    result.fold(
      (failure) => emit(MisGruposError(message: failure.message)),
      (grupos) {
        if (grupos.isEmpty) {
          // CA-005 / RN-004 / RN-005: Estado vacio
          emit(const MisGruposEmpty());
        } else {
          emit(MisGruposLoaded(grupos: grupos));
        }
      },
    );
  }

  /// CA-004: Seleccionar grupo y registrar acceso
  /// RN-003: Actualiza ultimo_acceso al entrar
  Future<void> _onSeleccionarGrupo(
    SeleccionarGrupoEvent event,
    Emitter<MisGruposState> emit,
  ) async {
    debugPrint('[MisGruposBloc] Seleccionando grupo: ${event.grupoId}');

    // Registrar acceso (operacion secundaria, no bloquea)
    await repository.registrarAccesoGrupo(event.grupoId);
  }
}
