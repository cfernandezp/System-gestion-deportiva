import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/errors/failures.dart';
import '../../../data/models/estado_partido.dart';
import '../../../domain/repositories/partidos_repository.dart';
import 'partido_event.dart';
import 'partido_state.dart';

/// BLoC para gestionar partidos de pichanga
/// E004-HU-001: Iniciar Partido
/// E004-HU-002: Temporizador con Alarma
///
/// Criterios de Aceptacion HU-001:
/// - CA-001: Seleccionar equipos
/// - CA-002: Duracion segun formato (10 o 20 min)
/// - CA-003: Iniciar temporizador con cuenta regresiva
/// - CA-004: Mostrar partido en curso con tiempo restante
/// - CA-005: Pausar y reanudar partido
/// - CA-006: Un partido a la vez por fecha
///
/// Criterios de Aceptacion HU-002:
/// - CA-001: Visualizacion del tiempo en MM:SS
/// - CA-002: Cuenta regresiva segundo a segundo
/// - CA-006: Tiempo extra visible (-MM:SS)
///
/// Reglas de Negocio HU-001:
/// - RN-001: Solo admin aprobado puede iniciar
/// - RN-002: Fecha debe estar en estado en_juego
/// - RN-003: Equipos deben tener jugadores asignados
/// - RN-004: Duracion automatica segun formato
/// - RN-005: Un partido activo por fecha
/// - RN-006: Equipos diferentes obligatorio
/// - RN-007: Registro de pausas
///
/// Reglas de Negocio HU-002:
/// - RN-003: Tiempo extra sin limite (contador en negativo)
class PartidoBloc extends Bloc<PartidoEvent, PartidoState> {
  final PartidosRepository repository;

  /// Timer para actualizar tiempo restante cada segundo
  Timer? _countdownTimer;

  /// ID de la fecha actual
  String? _fechaIdActual;

  PartidoBloc({required this.repository}) : super(const PartidoInitial()) {
    on<CargarPartidoActivoEvent>(_onCargarPartidoActivo);
    on<IniciarPartidoEvent>(_onIniciarPartido);
    on<PausarPartidoEvent>(_onPausarPartido);
    on<ReanudarPartidoEvent>(_onReanudarPartido);
    on<ActualizarTiempoEvent>(_onActualizarTiempo);
    on<ResetPartidoEvent>(_onReset);
  }

  /// CA-004: Cargar partido activo de una fecha
  Future<void> _onCargarPartidoActivo(
    CargarPartidoActivoEvent event,
    Emitter<PartidoState> emit,
  ) async {
    _fechaIdActual = event.fechaId;
    emit(const PartidoLoading());

    final result = await repository.obtenerPartidoActivo(event.fechaId);

    result.fold(
      (failure) {
        final serverFailure = failure is ServerFailure ? failure : null;
        emit(PartidoError(
          message: failure.message,
          code: serverFailure?.code,
          hint: serverFailure?.hint,
          fechaId: event.fechaId,
        ));
      },
      (response) {
        if (response.success) {
          if (response.partidoActivo && response.partido != null) {
            final partido = response.partido!;
            if (partido.estado == EstadoPartido.enCurso) {
              _iniciarCountdown();
              emit(PartidoEnCurso(
                partido: partido,
                puedePausar: response.puedePausar,
                message: response.message,
              ));
            } else if (partido.estado == EstadoPartido.pausado) {
              _detenerCountdown();
              emit(PartidoPausado(
                partido: partido,
                puedeReanudar: response.puedeReanudar,
                message: response.message,
              ));
            } else {
              emit(SinPartidoActivo(
                fechaId: event.fechaId,
                puedeIniciarPartido: response.puedeIniciarPartido,
                message: response.message,
              ));
            }
          } else {
            emit(SinPartidoActivo(
              fechaId: event.fechaId,
              puedeIniciarPartido: response.puedeIniciarPartido,
              message: response.message,
            ));
          }
        } else {
          emit(PartidoError(
            message: response.message.isNotEmpty
                ? response.message
                : 'Error al cargar partido activo',
            fechaId: event.fechaId,
          ));
        }
      },
    );
  }

  /// CA-001, CA-002, CA-003: Iniciar nuevo partido
  /// RN-001 a RN-006: Validaciones en backend
  Future<void> _onIniciarPartido(
    IniciarPartidoEvent event,
    Emitter<PartidoState> emit,
  ) async {
    _fechaIdActual = event.fechaId;
    emit(const PartidoProcesando(operacion: 'iniciando'));

    final result = await repository.iniciarPartido(
      fechaId: event.fechaId,
      equipoLocal: event.equipoLocal,
      equipoVisitante: event.equipoVisitante,
    );

    result.fold(
      (failure) {
        final serverFailure = failure is ServerFailure ? failure : null;
        emit(PartidoError(
          message: failure.message,
          code: serverFailure?.code,
          hint: serverFailure?.hint,
          fechaId: event.fechaId,
        ));
      },
      (response) {
        if (response.success && response.partido != null) {
          _iniciarCountdown();
          emit(PartidoEnCurso(
            partido: response.partido!,
            puedePausar: true, // Admin que inicio puede pausar
            message: response.message,
          ));
        } else {
          emit(PartidoError(
            message: response.message.isNotEmpty
                ? response.message
                : 'Error al iniciar partido',
            fechaId: event.fechaId,
          ));
        }
      },
    );
  }

  /// CA-005: Pausar partido en curso
  /// RN-007: Registra momento de pausa
  Future<void> _onPausarPartido(
    PausarPartidoEvent event,
    Emitter<PartidoState> emit,
  ) async {
    final estadoActual = state;
    final partidoActual =
        estadoActual is PartidoEnCurso ? estadoActual.partido : null;

    emit(PartidoProcesando(
      operacion: 'pausando',
      partido: partidoActual,
    ));

    final result = await repository.pausarPartido(event.partidoId);

    result.fold(
      (failure) {
        final serverFailure = failure is ServerFailure ? failure : null;
        emit(PartidoError(
          message: failure.message,
          code: serverFailure?.code,
          hint: serverFailure?.hint,
          partido: partidoActual,
          fechaId: _fechaIdActual,
        ));
      },
      (response) {
        if (response.success && partidoActual != null) {
          _detenerCountdown();
          final partidoPausado = partidoActual
              .copyWithEstado(EstadoPartido.pausado)
              .copyWithTiempo(response.tiempoRestanteSegundos);
          emit(PartidoPausado(
            partido: partidoPausado,
            puedeReanudar: true,
            message: response.message,
          ));
        } else {
          emit(PartidoError(
            message: response.message.isNotEmpty
                ? response.message
                : 'Error al pausar partido',
            partido: partidoActual,
            fechaId: _fechaIdActual,
          ));
        }
      },
    );
  }

  /// CA-005: Reanudar partido pausado
  /// RN-007: Registra tiempo de pausa
  Future<void> _onReanudarPartido(
    ReanudarPartidoEvent event,
    Emitter<PartidoState> emit,
  ) async {
    final estadoActual = state;
    final partidoActual =
        estadoActual is PartidoPausado ? estadoActual.partido : null;

    emit(PartidoProcesando(
      operacion: 'reanudando',
      partido: partidoActual,
    ));

    final result = await repository.reanudarPartido(event.partidoId);

    result.fold(
      (failure) {
        final serverFailure = failure is ServerFailure ? failure : null;
        emit(PartidoError(
          message: failure.message,
          code: serverFailure?.code,
          hint: serverFailure?.hint,
          partido: partidoActual,
          fechaId: _fechaIdActual,
        ));
      },
      (response) {
        if (response.success && partidoActual != null) {
          final partidoReanudado = partidoActual
              .copyWithEstado(EstadoPartido.enCurso)
              .copyWithTiempo(response.tiempoRestanteSegundos);
          _iniciarCountdown();
          emit(PartidoEnCurso(
            partido: partidoReanudado,
            puedePausar: true,
            message: response.message,
          ));
        } else {
          emit(PartidoError(
            message: response.message.isNotEmpty
                ? response.message
                : 'Error al reanudar partido',
            partido: partidoActual,
            fechaId: _fechaIdActual,
          ));
        }
      },
    );
  }

  /// Actualizar tiempo restante (llamado por timer cada segundo)
  /// E004-HU-002 CA-002: Cuenta regresiva segundo a segundo
  /// E004-HU-002 CA-006, RN-003: Soporta tiempo negativo (tiempo extra sin limite)
  void _onActualizarTiempo(
    ActualizarTiempoEvent event,
    Emitter<PartidoState> emit,
  ) {
    final estadoActual = state;
    if (estadoActual is PartidoEnCurso) {
      final tiempoActual = estadoActual.partido.tiempoRestanteSegundos;

      // Decrementar tiempo (permite negativos para tiempo extra)
      final nuevoTiempo = tiempoActual - 1;
      final partidoActualizado = estadoActual.partido.copyWithTiempo(nuevoTiempo);

      // Determinar si el tiempo acaba de terminar (transicion de 1 a 0)
      final tiempoAcabaDeTerminar = tiempoActual == 1;

      emit(PartidoEnCurso(
        partido: partidoActualizado,
        puedePausar: estadoActual.puedePausar,
        message: tiempoAcabaDeTerminar
            ? 'Tiempo terminado'
            : (nuevoTiempo < 0 ? 'Tiempo extra' : estadoActual.message),
      ));
    }
  }

  /// Reiniciar estado del bloc
  void _onReset(
    ResetPartidoEvent event,
    Emitter<PartidoState> emit,
  ) {
    _detenerCountdown();
    _fechaIdActual = null;
    emit(const PartidoInitial());
  }

  /// Inicia el timer de countdown (cada segundo)
  void _iniciarCountdown() {
    _detenerCountdown();
    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => add(const ActualizarTiempoEvent()),
    );
  }

  /// Detiene el timer de countdown
  void _detenerCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  @override
  Future<void> close() {
    _detenerCountdown();
    return super.close();
  }
}
