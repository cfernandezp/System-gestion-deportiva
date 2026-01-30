import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/errors/failures.dart';
import '../../../domain/repositories/fechas_repository.dart';
import 'inscritos_event.dart';
import 'inscritos_state.dart';

/// BLoC para gestionar lista de inscritos a fechas de pichanga
/// E003-HU-003: Ver Inscritos
///
/// Criterios de Aceptacion:
/// - CA-001: Acceso a lista de inscritos
/// - CA-002: Informacion de cada inscrito (foto, apodo, posicion)
/// - CA-003: Contador total de jugadores
/// - CA-004: Lista vacia con mensaje
/// - CA-005: Mi inscripcion destacada con "(Tu)"
/// - CA-006: Actualizacion en tiempo real
///
/// Reglas de Negocio:
/// - RN-001: Solo usuarios aprobados ven la lista
/// - RN-002: Solo campos publicos (foto, apodo, nombre, posicion)
/// - RN-003: Orden por fecha de inscripcion
/// - RN-004: Solo inscripciones con estado 'inscrito'
/// - RN-005: Supabase Realtime para actualizaciones en vivo
class InscritosBloc extends Bloc<InscritosEvent, InscritosState> {
  final FechasRepository repository;
  final SupabaseClient supabase;

  /// ID de la fecha actual (para refrescar y realtime)
  String? _fechaIdActual;

  /// Canal de Supabase Realtime
  RealtimeChannel? _channel;

  InscritosBloc({
    required this.repository,
    required this.supabase,
  }) : super(const InscritosInitial()) {
    on<CargarInscritosEvent>(_onCargarInscritos);
    on<InscritoAgregadoEvent>(_onInscritoAgregado);
    on<InscritoRemovidoEvent>(_onInscritoRemovido);
    on<RefrescarInscritosEvent>(_onRefrescar);
    on<IniciarRealtimeEvent>(_onIniciarRealtime);
    on<DetenerRealtimeEvent>(_onDetenerRealtime);
    on<ResetInscritosEvent>(_onReset);
  }

  /// CA-001, CA-002, CA-003: Cargar lista de inscritos
  Future<void> _onCargarInscritos(
    CargarInscritosEvent event,
    Emitter<InscritosState> emit,
  ) async {
    _fechaIdActual = event.fechaId;
    emit(const InscritosLoading());

    final result = await repository.obtenerInscritosFecha(event.fechaId);

    result.fold(
      (failure) {
        final serverFailure = failure is ServerFailure ? failure : null;
        emit(InscritosError(
          message: failure.message,
          code: serverFailure?.code,
          hint: serverFailure?.hint,
        ));
      },
      (response) {
        if (response.success && response.data != null) {
          emit(InscritosLoaded(
            data: response.data!,
            total: response.total,
            inscritos: response.inscritos,
            message: response.message,
            realtimeActivo: _channel != null,
          ));
        } else {
          emit(InscritosError(
            message: response.message.isNotEmpty
                ? response.message
                : 'Error al cargar inscritos',
          ));
        }
      },
    );
  }

  /// CA-006: Manejar inscrito agregado (realtime)
  Future<void> _onInscritoAgregado(
    InscritoAgregadoEvent event,
    Emitter<InscritosState> emit,
  ) async {
    // Recargar lista completa para mantener consistencia
    if (_fechaIdActual != null) {
      add(CargarInscritosEvent(fechaId: _fechaIdActual!));
    }
  }

  /// CA-006: Manejar inscrito removido (realtime)
  Future<void> _onInscritoRemovido(
    InscritoRemovidoEvent event,
    Emitter<InscritosState> emit,
  ) async {
    // Recargar lista completa para mantener consistencia
    if (_fechaIdActual != null) {
      add(CargarInscritosEvent(fechaId: _fechaIdActual!));
    }
  }

  /// RN-005: Refrescar lista manualmente (pull-to-refresh)
  Future<void> _onRefrescar(
    RefrescarInscritosEvent event,
    Emitter<InscritosState> emit,
  ) async {
    if (_fechaIdActual != null) {
      add(CargarInscritosEvent(fechaId: _fechaIdActual!));
    }
  }

  /// RN-005: Iniciar suscripcion a Supabase Realtime
  /// Escucha cambios en tabla inscripciones para la fecha especifica
  Future<void> _onIniciarRealtime(
    IniciarRealtimeEvent event,
    Emitter<InscritosState> emit,
  ) async {
    // Detener canal anterior si existe
    await _detenerCanal();

    _fechaIdActual = event.fechaId;

    // Crear nuevo canal con nombre unico
    _channel = supabase.channel('inscripciones_fecha_${event.fechaId}');

    // Suscribirse a cambios en la tabla inscripciones
    // Filtrado por fecha_id
    _channel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'inscripciones',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'fecha_id',
            value: event.fechaId,
          ),
          callback: (payload) {
            _manejarCambioRealtime(payload);
          },
        )
        .subscribe();

    // Actualizar estado para indicar que realtime esta activo
    final estadoActual = state;
    if (estadoActual is InscritosLoaded) {
      emit(estadoActual.copyWith(realtimeActivo: true));
    }
  }

  /// Manejar cambios recibidos por Realtime
  void _manejarCambioRealtime(PostgresChangePayload payload) {
    if (_fechaIdActual == null) return;

    switch (payload.eventType) {
      case PostgresChangeEvent.insert:
        // Nuevo inscrito agregado
        add(InscritoAgregadoEvent(fechaId: _fechaIdActual!));
        break;
      case PostgresChangeEvent.update:
        // Inscripcion actualizada (puede ser cancelacion)
        // Verificar si el estado cambio a 'cancelado'
        final newRecord = payload.newRecord;
        if (newRecord['estado'] == 'cancelado') {
          add(InscritoRemovidoEvent(fechaId: _fechaIdActual!));
        } else {
          add(InscritoAgregadoEvent(fechaId: _fechaIdActual!));
        }
        break;
      case PostgresChangeEvent.delete:
        // Inscripcion eliminada
        add(InscritoRemovidoEvent(fechaId: _fechaIdActual!));
        break;
      default:
        // Otros eventos, recargar por si acaso
        add(RefrescarInscritosEvent());
    }
  }

  /// Detener suscripcion realtime
  Future<void> _onDetenerRealtime(
    DetenerRealtimeEvent event,
    Emitter<InscritosState> emit,
  ) async {
    await _detenerCanal();

    // Actualizar estado para indicar que realtime no esta activo
    final estadoActual = state;
    if (estadoActual is InscritosLoaded) {
      emit(estadoActual.copyWith(realtimeActivo: false));
    }
  }

  /// Metodo interno para detener canal
  Future<void> _detenerCanal() async {
    if (_channel != null) {
      await supabase.removeChannel(_channel!);
      _channel = null;
    }
  }

  /// Reiniciar estado del bloc
  Future<void> _onReset(
    ResetInscritosEvent event,
    Emitter<InscritosState> emit,
  ) async {
    await _detenerCanal();
    _fechaIdActual = null;
    emit(const InscritosInitial());
  }

  /// Limpieza al cerrar el bloc
  @override
  Future<void> close() async {
    await _detenerCanal();
    return super.close();
  }
}
