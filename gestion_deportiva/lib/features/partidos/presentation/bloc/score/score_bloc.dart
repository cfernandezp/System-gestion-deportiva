import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/errors/failures.dart';
import '../../../data/models/gol_model.dart';
import '../../../domain/repositories/partidos_repository.dart';
import 'score_event.dart';
import 'score_state.dart';

/// BLoC para gestionar el Score en Vivo de un partido
/// E004-HU-004: Ver Score en Vivo
///
/// Criterios de Aceptacion:
/// - CA-001: Marcador visible (Equipo1 [goles] - [goles] Equipo2)
/// - CA-002: Colores de equipo (naranja, verde, azul)
/// - CA-003: Actualizacion en tiempo real (Supabase realtime en tabla goles)
/// - CA-004: Lista de goles (jugador, minuto, equipo)
/// - CA-005: Tiempo restante junto al score
/// - CA-006: Indicador de equipo ganando (destacar visualmente)
/// - CA-007: Empate visible
class ScoreBloc extends Bloc<ScoreEvent, ScoreState> {
  final PartidosRepository repository;
  final SupabaseClient supabase;

  /// Timer para actualizar tiempo restante cada segundo
  Timer? _countdownTimer;

  /// Timer para limpiar flag de gol reciente (5 segundos)
  Timer? _golRecienteTimer;

  /// Suscripcion a realtime de goles
  RealtimeChannel? _golesChannel;

  /// ID del partido actual (usado para resetear)
  // ignore: unused_field
  String? _partidoIdActual;

  ScoreBloc({
    required this.repository,
    required this.supabase,
  }) : super(const ScoreInitial()) {
    on<CargarScoreEvent>(_onCargarScore);
    on<ScoreActualizadoEvent>(_onScoreActualizado);
    on<ActualizarTiempoScoreEvent>(_onActualizarTiempo);
    on<LimpiarGolRecienteEvent>(_onLimpiarGolReciente);
    on<SuscribirseRealtimeEvent>(_onSuscribirseRealtime);
    on<DesuscribirseRealtimeEvent>(_onDesuscribirseRealtime);
    on<ResetScoreEvent>(_onReset);
  }

  /// CA-001 a CA-007: Carga el score inicial de un partido
  Future<void> _onCargarScore(
    CargarScoreEvent event,
    Emitter<ScoreState> emit,
  ) async {
    _partidoIdActual = event.partidoId;

    // Mantener score previo si existe
    final estadoActual = state;
    final scorePrevio =
        estadoActual is ScoreLoaded ? estadoActual.score : null;

    emit(ScoreLoading(scorePrevio: scorePrevio));

    final result = await repository.obtenerScorePartido(event.partidoId);

    result.fold(
      (failure) {
        final serverFailure = failure is ServerFailure ? failure : null;
        emit(ScoreError(
          message: failure.message,
          code: serverFailure?.code,
          hint: serverFailure?.hint,
          scorePrevio: scorePrevio,
          partidoId: event.partidoId,
        ));
      },
      (response) {
        if (response.success && response.score != null) {
          emit(ScoreLoaded(
            score: response.score!,
            message: response.message,
          ));

          // Iniciar countdown si el partido esta en curso
          if (response.score!.estadoPartido.name == 'en_curso' ||
              response.score!.estadoPartido.name == 'enCurso') {
            _iniciarCountdown();
          }

          // Suscribirse a realtime automaticamente
          add(SuscribirseRealtimeEvent(partidoId: event.partidoId));
        } else {
          emit(ScoreError(
            message: response.message.isNotEmpty
                ? response.message
                : 'Error al cargar score',
            scorePrevio: scorePrevio,
            partidoId: event.partidoId,
          ));
        }
      },
    );
  }

  /// CA-003: Maneja actualizaciones de score via realtime
  Future<void> _onScoreActualizado(
    ScoreActualizadoEvent event,
    Emitter<ScoreState> emit,
  ) async {
    final estadoActual = state;
    if (estadoActual is ScoreLoaded) {
      // Si viene con datos del gol, agregarlo localmente
      if (event.golData != null) {
        try {
          final nuevoGol = GolModel.fromJson(event.golData!);
          final nuevoScore = estadoActual.score.copyWithNuevoGol(nuevoGol);
          emit(estadoActual.copyWithScore(nuevoScore));

          // Programar limpieza de gol reciente en 5 segundos
          _programarLimpiezaGolReciente();

          return;
        } catch (_) {
          // Si falla el parsing, recargar desde servidor
        }
      }

      // Recargar score completo desde servidor
      add(CargarScoreEvent(partidoId: event.partidoId));
    }
  }

  /// Actualiza el tiempo restante cada segundo
  void _onActualizarTiempo(
    ActualizarTiempoScoreEvent event,
    Emitter<ScoreState> emit,
  ) {
    final estadoActual = state;
    if (estadoActual is ScoreLoaded) {
      final tiempoActual = estadoActual.score.tiempoRestanteSegundos;
      final nuevoTiempo = tiempoActual - 1;
      emit(estadoActual.copyWithTiempo(nuevoTiempo));
    }
  }

  /// Limpia el flag de gol reciente despues de 5 segundos
  void _onLimpiarGolReciente(
    LimpiarGolRecienteEvent event,
    Emitter<ScoreState> emit,
  ) {
    final estadoActual = state;
    if (estadoActual is ScoreLoaded && estadoActual.hayGolReciente) {
      emit(estadoActual.copyWithGolReciente(false));
    }
  }

  /// CA-003: Suscribe a eventos realtime de la tabla goles
  Future<void> _onSuscribirseRealtime(
    SuscribirseRealtimeEvent event,
    Emitter<ScoreState> emit,
  ) async {
    // Cancelar suscripcion previa si existe
    await _cancelarSuscripcionRealtime();

    try {
      // Crear canal para escuchar inserts en tabla goles filtrado por partido_id
      _golesChannel = supabase
          .channel('score_goles_${event.partidoId}')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'goles',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'partido_id',
              value: event.partidoId,
            ),
            callback: (payload) {
              // Emitir evento cuando llega un nuevo gol
              add(ScoreActualizadoEvent(
                partidoId: event.partidoId,
                golData: payload.newRecord,
              ));
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.delete,
            schema: 'public',
            table: 'goles',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'partido_id',
              value: event.partidoId,
            ),
            callback: (payload) {
              // Recargar score cuando se elimina un gol
              add(ScoreActualizadoEvent(partidoId: event.partidoId));
            },
          )
          .subscribe();

      // Actualizar estado para indicar que esta suscrito
      final estadoActual = state;
      if (estadoActual is ScoreLoaded) {
        emit(ScoreLoaded(
          score: estadoActual.score,
          suscritoRealtime: true,
          message: estadoActual.message,
        ));
      }
    } catch (e) {
      // Fallar silenciosamente - el score seguira funcionando sin realtime
    }
  }

  /// Cancela suscripcion a realtime
  Future<void> _onDesuscribirseRealtime(
    DesuscribirseRealtimeEvent event,
    Emitter<ScoreState> emit,
  ) async {
    await _cancelarSuscripcionRealtime();

    final estadoActual = state;
    if (estadoActual is ScoreLoaded) {
      emit(ScoreLoaded(
        score: estadoActual.score,
        suscritoRealtime: false,
        message: estadoActual.message,
      ));
    }
  }

  /// Reinicia el estado del bloc
  void _onReset(
    ResetScoreEvent event,
    Emitter<ScoreState> emit,
  ) {
    _detenerCountdown();
    _cancelarGolRecienteTimer();
    _cancelarSuscripcionRealtime();
    _partidoIdActual = null;
    emit(const ScoreInitial());
  }

  /// Inicia el timer de countdown (cada segundo)
  void _iniciarCountdown() {
    _detenerCountdown();
    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => add(const ActualizarTiempoScoreEvent()),
    );
  }

  /// Detiene el timer de countdown
  void _detenerCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  /// Programa limpieza de gol reciente en 5 segundos
  void _programarLimpiezaGolReciente() {
    _cancelarGolRecienteTimer();
    _golRecienteTimer = Timer(
      const Duration(seconds: 5),
      () => add(const LimpiarGolRecienteEvent()),
    );
  }

  /// Cancela timer de gol reciente
  void _cancelarGolRecienteTimer() {
    _golRecienteTimer?.cancel();
    _golRecienteTimer = null;
  }

  /// Cancela suscripcion a realtime
  Future<void> _cancelarSuscripcionRealtime() async {
    if (_golesChannel != null) {
      await supabase.removeChannel(_golesChannel!);
      _golesChannel = null;
    }
  }

  @override
  Future<void> close() {
    _detenerCountdown();
    _cancelarGolRecienteTimer();
    _cancelarSuscripcionRealtime();
    return super.close();
  }
}
