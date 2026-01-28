import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../domain/repositories/fechas_repository.dart';
import 'mi_equipo_event.dart';
import 'mi_equipo_state.dart';

/// BLoC para Ver Mi Equipo
/// E003-HU-006: Ver Mi Equipo
/// Maneja la carga del equipo del usuario y todos los equipos de la fecha
/// Incluye suscripcion Realtime para actualizaciones en vivo (RN-004)
class MiEquipoBloc extends Bloc<MiEquipoEvent, MiEquipoState> {
  final FechasRepository repository;
  final SupabaseClient supabase;

  RealtimeChannel? _realtimeChannel;
  String? _currentFechaId;

  MiEquipoBloc({
    required this.repository,
    required this.supabase,
  }) : super(const MiEquipoInitial()) {
    on<CargarMiEquipoEvent>(_onCargarMiEquipo);
    on<CargarEquiposFechaEvent>(_onCargarEquiposFecha);
    on<ActualizarEquipoRealtimeEvent>(_onActualizarEquipoRealtime);
    on<IniciarRealtimeEvent>(_onIniciarRealtime);
    on<DetenerRealtimeEvent>(_onDetenerRealtime);
  }

  /// Carga mi equipo para una fecha
  /// CA-001, CA-002, CA-003, CA-005, CA-006
  Future<void> _onCargarMiEquipo(
    CargarMiEquipoEvent event,
    Emitter<MiEquipoState> emit,
  ) async {
    emit(const MiEquipoLoading());

    final result = await repository.obtenerMiEquipo(event.fechaId);

    result.fold(
      (failure) => emit(MiEquipoError(message: failure.message)),
      (response) {
        if (response.data == null) {
          emit(MiEquipoError(message: response.message));
          return;
        }

        final data = response.data!;

        // CA-006: No inscrito
        if (!data.estaInscrito) {
          emit(NoInscrito(mensaje: data.mensaje ?? 'No estas inscrito a esta fecha'));
          return;
        }

        // CA-005: Equipos no asignados aun
        if (!data.equiposAsignados || !data.tieneEquipo) {
          emit(EquiposPendientes(
            estaInscrito: data.estaInscrito,
            mensaje: data.mensaje ?? 'Esperando asignacion de equipos',
          ));
          return;
        }

        // CA-001, CA-002, CA-003: Mi equipo cargado
        emit(MiEquipoCargado(data: data));
      },
    );
  }

  /// Carga todos los equipos de una fecha
  /// CA-004
  Future<void> _onCargarEquiposFecha(
    CargarEquiposFechaEvent event,
    Emitter<MiEquipoState> emit,
  ) async {
    emit(const MiEquipoLoading());

    final result = await repository.obtenerEquiposFecha(event.fechaId);

    result.fold(
      (failure) => emit(MiEquipoError(message: failure.message)),
      (response) {
        if (response.data == null) {
          emit(MiEquipoError(message: response.message));
          return;
        }

        final data = response.data!;

        // Si no hay equipos asignados
        if (!data.equiposAsignados) {
          emit(EquiposPendientes(
            estaInscrito: data.estaInscrito,
            mensaje: 'Aun no se han asignado equipos para esta fecha',
          ));
          return;
        }

        // CA-004: Todos los equipos cargados
        emit(EquiposFechaCargados(data: data));
      },
    );
  }

  /// Actualiza equipo desde Realtime
  /// CA-007, RN-004
  Future<void> _onActualizarEquipoRealtime(
    ActualizarEquipoRealtimeEvent event,
    Emitter<MiEquipoState> emit,
  ) async {
    // Recargar datos sin mostrar loading
    final currentState = state;

    final result = await repository.obtenerMiEquipo(event.fechaId);

    result.fold(
      (failure) {
        // En caso de error, mantener estado anterior si existe
        if (currentState is MiEquipoCargado) {
          emit(currentState);
        }
      },
      (response) {
        if (response.data == null) return;

        final data = response.data!;

        if (!data.estaInscrito) {
          emit(NoInscrito(mensaje: data.mensaje ?? 'No estas inscrito'));
          return;
        }

        if (!data.equiposAsignados || !data.tieneEquipo) {
          emit(EquiposPendientes(
            estaInscrito: data.estaInscrito,
            mensaje: data.mensaje ?? 'Esperando asignacion de equipos',
          ));
          return;
        }

        // Marcar como actualizado via realtime
        emit(MiEquipoCargado(data: data, actualizadoRealtime: true));
      },
    );
  }

  /// Inicia suscripcion Realtime a tabla asignaciones_equipos
  /// RN-004: Latencia maxima 5 segundos
  Future<void> _onIniciarRealtime(
    IniciarRealtimeEvent event,
    Emitter<MiEquipoState> emit,
  ) async {
    // Detener suscripcion anterior si existe
    await _cancelarSuscripcion();

    _currentFechaId = event.fechaId;

    // Suscribirse a cambios en asignaciones_equipos para esta fecha
    _realtimeChannel = supabase
        .channel('asignaciones_equipos:${event.fechaId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'asignaciones_equipos',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'fecha_id',
            value: event.fechaId,
          ),
          callback: (payload) {
            // Cuando hay un cambio, recargar datos
            if (_currentFechaId != null) {
              add(ActualizarEquipoRealtimeEvent(fechaId: _currentFechaId!));
            }
          },
        )
        .subscribe();
  }

  /// Detiene suscripcion Realtime
  Future<void> _onDetenerRealtime(
    DetenerRealtimeEvent event,
    Emitter<MiEquipoState> emit,
  ) async {
    await _cancelarSuscripcion();
  }

  /// Cancela la suscripcion Realtime actual
  Future<void> _cancelarSuscripcion() async {
    if (_realtimeChannel != null) {
      await supabase.removeChannel(_realtimeChannel!);
      _realtimeChannel = null;
    }
    _currentFechaId = null;
  }

  @override
  Future<void> close() async {
    await _cancelarSuscripcion();
    return super.close();
  }
}
