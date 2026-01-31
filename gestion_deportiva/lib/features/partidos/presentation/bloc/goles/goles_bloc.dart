import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/errors/failures.dart';
import '../../../domain/repositories/partidos_repository.dart';
import 'goles_event.dart';
import 'goles_state.dart';

/// BLoC para gestionar goles de un partido
/// E004-HU-003: Registrar Gol
///
/// Criterios de Aceptacion:
/// - CA-001: Boton de gol por equipo
/// - CA-002: Seleccionar goleador
/// - CA-003: Registro rapido con marcador actualizado
/// - CA-004: Gol en contra (autogol)
/// - CA-005: Deshacer gol (ventana 30 seg)
/// - CA-006: Minuto automatico
/// - CA-007: Gol sin asignar jugador
///
/// Reglas de Negocio:
/// - RN-001: Solo admin registra goles
/// - RN-002: Partido en curso obligatorio
/// - RN-003: Goleador del equipo correcto
/// - RN-004: Minuto automatico
/// - RN-005: Ventana de deshacer (30 seg)
/// - RN-006: Gol en contra invierte equipo
/// - RN-007: No goles durante pausa
/// - RN-008: Advertencia marcador inusual (10+ goles)
class GolesBloc extends Bloc<GolesEvent, GolesState> {
  final PartidosRepository repository;

  /// ID del partido actual
  String? _partidoIdActual;

  GolesBloc({required this.repository}) : super(const GolesInitial()) {
    on<CargarGolesEvent>(_onCargarGoles);
    on<RegistrarGolEvent>(_onRegistrarGol);
    on<EliminarGolEvent>(_onEliminarGol);
    on<LimpiarUltimoGolEvent>(_onLimpiarUltimoGol);
    on<ResetGolesEvent>(_onReset);
  }

  /// Carga los goles de un partido
  Future<void> _onCargarGoles(
    CargarGolesEvent event,
    Emitter<GolesState> emit,
  ) async {
    _partidoIdActual = event.partidoId;

    // Mantener datos previos si existen
    final estadoActual = state;
    final golesPrevios =
        estadoActual is GolesLoaded ? estadoActual.goles : null;
    final marcadorPrevio =
        estadoActual is GolesLoaded ? estadoActual.marcador : null;

    emit(GolesLoading(
      golesPrevios: golesPrevios,
      marcadorPrevio: marcadorPrevio,
    ));

    final result = await repository.obtenerGolesPartido(event.partidoId);

    result.fold(
      (failure) {
        final serverFailure = failure is ServerFailure ? failure : null;
        emit(GolesError(
          message: failure.message,
          code: serverFailure?.code,
          hint: serverFailure?.hint,
          golesPrevios: golesPrevios,
          marcadorPrevio: marcadorPrevio,
        ));
      },
      (response) {
        if (response.success) {
          emit(GolesLoaded(
            partidoId: event.partidoId,
            goles: response.goles,
            golesLocal: response.marcador?.golesLocal ?? 0,
            golesVisitante: response.marcador?.golesVisitante ?? 0,
            marcador: response.marcador,
          ));
        } else {
          emit(GolesError(
            message: response.message.isNotEmpty
                ? response.message
                : 'Error al cargar goles',
            golesPrevios: golesPrevios,
            marcadorPrevio: marcadorPrevio,
          ));
        }
      },
    );
  }

  /// CA-001 a CA-007: Registra un gol
  /// RN-001 a RN-008: Validaciones en backend
  Future<void> _onRegistrarGol(
    RegistrarGolEvent event,
    Emitter<GolesState> emit,
  ) async {
    final estadoActual = state;
    final golesPrevios =
        estadoActual is GolesLoaded ? estadoActual.goles : null;
    final marcadorPrevio =
        estadoActual is GolesLoaded ? estadoActual.marcador : null;

    emit(GolesProcesando(
      operacion: 'registrando',
      golesPrevios: golesPrevios,
      marcadorPrevio: marcadorPrevio,
    ));

    final result = await repository.registrarGol(
      partidoId: event.partidoId,
      equipoAnotador: event.equipoAnotador,
      jugadorId: event.jugadorId,
      esAutogol: event.esAutogol,
    );

    result.fold(
      (failure) {
        final serverFailure = failure is ServerFailure ? failure : null;
        emit(GolesError(
          message: failure.message,
          code: serverFailure?.code,
          hint: serverFailure?.hint,
          golesPrevios: golesPrevios,
          marcadorPrevio: marcadorPrevio,
        ));
      },
      (response) {
        if (response.success && response.gol != null && response.marcador != null) {
          // Emitir estado de gol registrado
          emit(GolRegistrado(
            gol: response.gol!,
            marcador: response.marcador!,
            advertencia: response.advertencia,
            message: response.message,
          ));

          // Recargar goles para tener estado actualizado
          add(CargarGolesEvent(partidoId: event.partidoId));
        } else {
          emit(GolesError(
            message: response.message.isNotEmpty
                ? response.message
                : 'Error al registrar gol',
            golesPrevios: golesPrevios,
            marcadorPrevio: marcadorPrevio,
          ));
        }
      },
    );
  }

  /// CA-005: Elimina/deshace un gol
  /// RN-005: Ventana de deshacer
  Future<void> _onEliminarGol(
    EliminarGolEvent event,
    Emitter<GolesState> emit,
  ) async {
    final estadoActual = state;
    final golesPrevios =
        estadoActual is GolesLoaded ? estadoActual.goles : null;
    final marcadorPrevio =
        estadoActual is GolesLoaded ? estadoActual.marcador : null;
    final partidoId = estadoActual is GolesLoaded
        ? estadoActual.partidoId
        : _partidoIdActual;

    emit(GolesProcesando(
      operacion: 'eliminando',
      golesPrevios: golesPrevios,
      marcadorPrevio: marcadorPrevio,
    ));

    final result = await repository.eliminarGol(event.golId);

    result.fold(
      (failure) {
        final serverFailure = failure is ServerFailure ? failure : null;
        emit(GolesError(
          message: failure.message,
          code: serverFailure?.code,
          hint: serverFailure?.hint,
          golesPrevios: golesPrevios,
          marcadorPrevio: marcadorPrevio,
        ));
      },
      (response) {
        if (response.success && response.marcador != null) {
          // Emitir estado de gol eliminado
          emit(GolEliminado(
            marcador: response.marcador!,
            message: response.message,
          ));

          // Recargar goles para tener estado actualizado
          if (partidoId != null) {
            add(CargarGolesEvent(partidoId: partidoId));
          }
        } else {
          emit(GolesError(
            message: response.message.isNotEmpty
                ? response.message
                : 'Error al eliminar gol',
            golesPrevios: golesPrevios,
            marcadorPrevio: marcadorPrevio,
          ));
        }
      },
    );
  }

  /// Limpia el ultimo gol (despues de mostrar confirmacion)
  void _onLimpiarUltimoGol(
    LimpiarUltimoGolEvent event,
    Emitter<GolesState> emit,
  ) {
    final estadoActual = state;
    if (estadoActual is GolesLoaded) {
      emit(estadoActual.copyWithoutUltimoGol());
    }
  }

  /// Reinicia el estado del bloc
  void _onReset(
    ResetGolesEvent event,
    Emitter<GolesState> emit,
  ) {
    _partidoIdActual = null;
    emit(const GolesInitial());
  }
}
