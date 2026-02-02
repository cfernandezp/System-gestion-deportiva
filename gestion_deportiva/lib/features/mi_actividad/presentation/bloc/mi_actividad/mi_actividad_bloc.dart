import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/errors/failures.dart';
import '../../../domain/repositories/mi_actividad_repository.dart';
import 'mi_actividad_event.dart';
import 'mi_actividad_state.dart';

/// BLoC de Mi Actividad
/// E004-HU-008: Mi Actividad en Vivo
/// Maneja el estado de la actividad del jugador y actualizaciones en tiempo real
class MiActividadBloc extends Bloc<MiActividadEvent, MiActividadState> {
  final MiActividadRepository repository;
  final SupabaseClient supabase;

  // Suscripciones Realtime
  StreamSubscription<void>? _golesSubscription;
  StreamSubscription<void>? _partidosSubscription;

  MiActividadBloc({
    required this.repository,
    required this.supabase,
  }) : super(const MiActividadInitial()) {
    on<CargarMiActividadEvent>(_onCargarMiActividad);
    on<ActualizarActividadRealtimeEvent>(_onActualizarActividadRealtime);
  }

  /// Handler: Cargar actividad del jugador
  /// CA-003: Lista de todos los partidos
  /// CA-006: Mis goles totales
  /// RN-001: Pichanga Activa del Jugador
  Future<void> _onCargarMiActividad(
    CargarMiActividadEvent event,
    Emitter<MiActividadState> emit,
  ) async {
    emit(const MiActividadLoading());

    final result = await repository.obtenerMiActividadVivo();

    result.fold(
      (failure) {
        final serverFailure = failure is ServerFailure ? failure : null;
        emit(MiActividadError(
          message: failure.message,
          hint: serverFailure?.hint,
        ));
      },
      (actividad) {
        emit(MiActividadLoaded(actividad: actividad));

        // CA-009: Suscribirse a cambios en tiempo real si hay pichanga activa
        // RN-006: Supabase Realtime
        if (actividad.hayPichangaActiva &&
            actividad.pichangaActiva != null) {
          _suscribirseARealtimeChanges(actividad.pichangaActiva!.fechaId);
        }
      },
    );
  }

  /// Handler: Actualizar actividad desde Realtime
  /// CA-009: Actualizacion automatica sin recargar pagina
  /// RN-006: Latencia maxima 3 segundos
  Future<void> _onActualizarActividadRealtime(
    ActualizarActividadRealtimeEvent event,
    Emitter<MiActividadState> emit,
  ) async {
    // No mostrar loading para no interrumpir la UI
    final result = await repository.obtenerMiActividadVivo();

    result.fold(
      (failure) {
        // Mantener estado actual en caso de error temporal
        // No emitir error para no interrumpir la experiencia
      },
      (actividad) {
        emit(MiActividadLoaded(actividad: actividad));
      },
    );
  }

  /// Suscribe a cambios en tiempo real de goles y partidos
  /// RN-006: Supabase Realtime para actualizaciones automaticas
  void _suscribirseARealtimeChanges(String fechaId) {
    // Cancelar suscripciones previas
    _cancelarSuscripciones();

    // Suscribirse a cambios en goles
    _golesSubscription = repository.observarCambiosGoles(fechaId).listen(
      (_) {
        // Al detectar cambio, recargar actividad
        add(const ActualizarActividadRealtimeEvent());
      },
      onError: (error) {
        // Error en suscripcion, ignorar para no interrumpir
      },
    );

    // Suscribirse a cambios en partidos
    _partidosSubscription = repository.observarCambiosPartidos(fechaId).listen(
      (_) {
        // Al detectar cambio, recargar actividad
        add(const ActualizarActividadRealtimeEvent());
      },
      onError: (error) {
        // Error en suscripcion, ignorar para no interrumpir
      },
    );
  }

  /// Cancela suscripciones Realtime
  void _cancelarSuscripciones() {
    _golesSubscription?.cancel();
    _partidosSubscription?.cancel();
    _golesSubscription = null;
    _partidosSubscription = null;
  }

  @override
  Future<void> close() {
    _cancelarSuscripciones();
    return super.close();
  }
}
