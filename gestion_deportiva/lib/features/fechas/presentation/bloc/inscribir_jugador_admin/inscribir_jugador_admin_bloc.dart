import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../../core/errors/failures.dart';
import '../../../data/models/inscribir_jugador_admin_response_model.dart';
import '../../../domain/repositories/fechas_repository.dart';

part 'inscribir_jugador_admin_event.dart';
part 'inscribir_jugador_admin_state.dart';

/// E003-HU-011: BLoC para Inscribir Jugador como Admin
/// Gestiona la carga de jugadores disponibles y la inscripcion administrativa
///
/// Criterios de Aceptacion:
/// - CA-001: Acceso exclusivo admin/organizador (validado en backend)
/// - CA-002: Selector de jugadores (aprobados, no inscritos)
/// - CA-003: Validacion jugador no inscrito (backend)
/// - CA-004: Confirmacion de inscripcion exitosa
/// - CA-005: Generacion de deuda (backend)
/// - CA-006: Notificacion al jugador (backend)
/// - CA-007: Respeto al limite de cupos (backend)
/// - CA-008: Solo fechas abiertas (backend)
class InscribirJugadorAdminBloc
    extends Bloc<InscribirJugadorAdminEvent, InscribirJugadorAdminState> {
  final FechasRepository repository;

  InscribirJugadorAdminBloc({required this.repository})
      : super(const InscribirJugadorAdminInitial()) {
    on<CargarJugadoresDisponiblesEvent>(_onCargarJugadoresDisponibles);
    on<InscribirJugadorEvent>(_onInscribirJugador);
    on<InscribirJugadoresMultipleEvent>(_onInscribirJugadoresMultiple);
    on<ResetInscribirJugadorAdminEvent>(_onReset);
  }

  /// CA-002: Cargar lista de jugadores disponibles para inscripcion
  Future<void> _onCargarJugadoresDisponibles(
    CargarJugadoresDisponiblesEvent event,
    Emitter<InscribirJugadorAdminState> emit,
  ) async {
    emit(const JugadoresDisponiblesCargando());

    final result =
        await repository.listarJugadoresDisponiblesInscripcion(event.fechaId);

    result.fold(
      (failure) => emit(InscribirJugadorAdminError(
        message: failure.message,
        hint: failure is ServerFailure ? failure.hint : null,
      )),
      (response) => emit(JugadoresDisponiblesCargados(
        jugadores: response.jugadores,
        total: response.total,
        message: response.message,
      )),
    );
  }

  /// CA-003, CA-004, CA-005, CA-006, CA-007, CA-008: Inscribir jugador seleccionado
  Future<void> _onInscribirJugador(
    InscribirJugadorEvent event,
    Emitter<InscribirJugadorAdminState> emit,
  ) async {
    emit(InscripcionAdminProcesando(jugadorNombre: event.jugadorNombre));

    final result = await repository.inscribirJugadorAdmin(
      fechaId: event.fechaId,
      jugadorId: event.jugadorId,
    );

    result.fold(
      (failure) => emit(InscribirJugadorAdminError(
        message: failure.message,
        hint: failure is ServerFailure ? failure.hint : null,
      )),
      (response) {
        if (response.success && response.data != null) {
          emit(InscripcionAdminExitosa(
            inscripcion: response.data!,
            message: response.message,
          ));
        } else {
          emit(InscribirJugadorAdminError(
            message: response.message.isNotEmpty
                ? response.message
                : 'Error al inscribir jugador',
          ));
        }
      },
    );
  }

  /// Inscribir multiples jugadores en secuencia
  Future<void> _onInscribirJugadoresMultiple(
    InscribirJugadoresMultipleEvent event,
    Emitter<InscribirJugadorAdminState> emit,
  ) async {
    final jugadores = event.jugadores;
    final total = jugadores.length;
    int inscritos = 0;
    int fallidos = 0;
    final List<String> errores = [];

    for (int i = 0; i < jugadores.length; i++) {
      final jugador = jugadores[i];

      // Emitir progreso
      emit(InscripcionMultipleProcesando(
        totalJugadores: total,
        procesados: i,
        jugadorActual: jugador.nombre,
      ));

      // Intentar inscribir
      final result = await repository.inscribirJugadorAdmin(
        fechaId: event.fechaId,
        jugadorId: jugador.id,
      );

      result.fold(
        (failure) {
          fallidos++;
          errores.add('${jugador.nombre}: ${failure.message}');
        },
        (response) {
          if (response.success && response.data != null) {
            inscritos++;
          } else {
            fallidos++;
            errores.add(
              '${jugador.nombre}: ${response.message.isNotEmpty ? response.message : "Error desconocido"}',
            );
          }
        },
      );
    }

    // Generar mensaje final
    String message;
    if (fallidos == 0) {
      message = inscritos == 1
          ? '1 jugador inscrito correctamente'
          : '$inscritos jugadores inscritos correctamente';
    } else if (inscritos == 0) {
      message = 'No se pudo inscribir ningun jugador';
    } else {
      message = '$inscritos inscritos, $fallidos con errores';
    }

    emit(InscripcionMultipleExitosa(
      totalInscritos: inscritos,
      totalFallidos: fallidos,
      errores: errores,
      message: message,
    ));
  }

  /// Reiniciar estado
  void _onReset(
    ResetInscribirJugadorAdminEvent event,
    Emitter<InscribirJugadorAdminState> emit,
  ) {
    emit(const InscribirJugadorAdminInitial());
  }
}
