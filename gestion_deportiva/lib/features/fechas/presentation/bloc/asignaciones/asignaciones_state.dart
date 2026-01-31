import 'package:equatable/equatable.dart';

import '../../../data/models/fecha_asignacion_info_model.dart';
import '../../../data/models/asignaciones_resumen_model.dart';
import '../../../data/models/obtener_asignaciones_response_model.dart';
import '../../../data/models/asignar_equipo_response_model.dart';
import '../../../data/models/confirmar_equipos_response_model.dart';

/// Estados del BLoC de asignaciones de equipos
/// E003-HU-005: Asignar Equipos
abstract class AsignacionesState extends Equatable {
  const AsignacionesState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial - Sin datos cargados
class AsignacionesInitial extends AsignacionesState {
  const AsignacionesInitial();
}

/// Estado de carga al obtener asignaciones
class AsignacionesLoading extends AsignacionesState {
  const AsignacionesLoading();
}

/// CA-001, CA-002, CA-003: Estado con asignaciones cargadas
/// Contiene lista de jugadores, equipos disponibles y resumen
class AsignacionesLoaded extends AsignacionesState {
  /// Datos completos de asignaciones
  final ObtenerAsignacionesDataModel data;

  /// Mensaje del servidor (opcional)
  final String? message;

  const AsignacionesLoaded({
    required this.data,
    this.message,
  });

  /// Informacion de la fecha
  FechaAsignacionInfoModel get fecha => data.fecha;

  /// RN-003: Numero de equipos segun duracion
  int get numEquipos => data.fecha.numEquipos;

  /// RN-002: Indica si se pueden asignar equipos
  bool get puedeAsignar => data.fecha.puedeAsignar;

  /// CA-003: Colores disponibles segun num_equipos
  List get coloresDisponibles => data.coloresDisponibles;

  /// Lista de todos los jugadores
  List get jugadores => data.jugadores;

  /// RN-005: Resumen de progreso
  AsignacionesResumenModel get resumen => data.resumen;

  /// Indica si la asignacion esta completa
  bool get asignacionCompleta => data.resumen.asignacionCompleta;

  /// CA-006: Verifica si hay desbalance (diferencia > 1)
  bool get hayDesbalance {
    if (data.equipos.isEmpty) return false;
    final cantidades = data.equipos.map((e) => e.cantidad).toList();
    if (cantidades.isEmpty) return false;
    final max = cantidades.reduce((a, b) => a > b ? a : b);
    final min = cantidades.reduce((a, b) => a < b ? a : b);
    return (max - min) > 1;
  }

  @override
  List<Object?> get props => [data, message];
}

/// Estado de error al cargar asignaciones
class AsignacionesError extends AsignacionesState {
  /// Mensaje de error
  final String message;

  /// Codigo de error del backend
  final String? code;

  /// Hint del backend para identificar tipo de error
  final String? hint;

  const AsignacionesError({
    required this.message,
    this.code,
    this.hint,
  });

  /// RN-001: Verifica si el error es de permisos
  bool get esSinPermisos => hint == 'sin_permisos';

  /// RN-002: Verifica si el estado es invalido
  bool get esEstadoInvalido => hint == 'estado_invalido';

  /// Verifica si la fecha no existe
  bool get esFechaNoEncontrada => hint == 'fecha_no_encontrada';

  @override
  List<Object?> get props => [message, code, hint];
}

/// Estado de carga al asignar equipo individual
class AsignandoEquipo extends AsignacionesState {
  /// Datos actuales (para mantener UI)
  final ObtenerAsignacionesDataModel data;

  /// ID del usuario que se esta asignando
  final String usuarioId;

  const AsignandoEquipo({
    required this.data,
    required this.usuarioId,
  });

  @override
  List<Object?> get props => [data, usuarioId];
}

/// CA-004, CA-005: Estado de exito al asignar equipo
class EquipoAsignado extends AsignacionesState {
  /// Datos actualizados de asignaciones
  final ObtenerAsignacionesDataModel data;

  /// Datos de la asignacion realizada
  final AsignarEquipoDataModel asignacion;

  /// Mensaje de confirmacion
  final String message;

  const EquipoAsignado({
    required this.data,
    required this.asignacion,
    required this.message,
  });

  /// CA-008: Indica si fue actualizacion (cambio de equipo)
  bool get esActualizacion => asignacion.esActualizacion;

  @override
  List<Object?> get props => [data, asignacion, message];
}

/// Estado de error al asignar equipo
class AsignarEquipoError extends AsignacionesState {
  /// Datos actuales (para mantener UI)
  final ObtenerAsignacionesDataModel data;

  /// Mensaje de error
  final String message;

  /// Hint del backend
  final String? hint;

  const AsignarEquipoError({
    required this.data,
    required this.message,
    this.hint,
  });

  /// RN-004: Color no valido
  bool get esColorInvalido =>
      hint == 'color_invalido' || hint == 'color_no_permitido';

  /// Usuario no inscrito
  bool get esUsuarioNoInscrito => hint == 'usuario_no_inscrito';

  @override
  List<Object?> get props => [data, message, hint];
}

/// Estado de carga al desasignar equipo
class DesasignandoEquipo extends AsignacionesState {
  /// Datos actuales (para mantener UI)
  final ObtenerAsignacionesDataModel data;

  /// ID del usuario que se esta desasignando
  final String usuarioId;

  const DesasignandoEquipo({
    required this.data,
    required this.usuarioId,
  });

  @override
  List<Object?> get props => [data, usuarioId];
}

/// Estado de exito al desasignar equipo (jugador vuelve a Sin Asignar)
class EquipoDesasignado extends AsignacionesState {
  /// Datos actualizados de asignaciones
  final ObtenerAsignacionesDataModel data;

  /// Nombre del usuario desasignado
  final String usuarioNombre;

  /// Equipo del que fue removido
  final String equipoAnterior;

  /// Mensaje de confirmacion
  final String message;

  const EquipoDesasignado({
    required this.data,
    required this.usuarioNombre,
    required this.equipoAnterior,
    required this.message,
  });

  @override
  List<Object?> get props => [data, usuarioNombre, equipoAnterior, message];
}

/// Estado de error al desasignar equipo
class DesasignarEquipoError extends AsignacionesState {
  /// Datos actuales (para mantener UI)
  final ObtenerAsignacionesDataModel data;

  /// Mensaje de error
  final String message;

  /// Hint del backend
  final String? hint;

  const DesasignarEquipoError({
    required this.data,
    required this.message,
    this.hint,
  });

  @override
  List<Object?> get props => [data, message, hint];
}

/// Estado de carga al confirmar equipos
class ConfirmandoEquipos extends AsignacionesState {
  /// Datos actuales (para mantener UI)
  final ObtenerAsignacionesDataModel data;

  const ConfirmandoEquipos({required this.data});

  @override
  List<Object?> get props => [data];
}

/// CA-007: Estado de exito al confirmar equipos
/// RN-006: Incluye balance de equipos
/// RN-007: Incluye notificaciones enviadas
class EquiposConfirmados extends AsignacionesState {
  /// Datos de confirmacion
  final ConfirmarEquiposDataModel confirmacion;

  /// Mensaje de confirmacion
  final String message;

  const EquiposConfirmados({
    required this.confirmacion,
    required this.message,
  });

  /// Total de jugadores
  int get totalJugadores => confirmacion.totalJugadores;

  /// Lista de equipos con cantidades
  List get equipos => confirmacion.equipos;

  /// CA-006: Estado de balance
  bool get estaBalanceado => confirmacion.balance.estaBalanceado;

  /// Diferencia maxima entre equipos
  int get diferenciaMaxima => confirmacion.balance.diferenciaMaxima;

  /// RN-007: Notificaciones enviadas
  int get notificacionesEnviadas => confirmacion.notificacionesEnviadas;

  @override
  List<Object?> get props => [confirmacion, message];
}

/// Estado de error al confirmar equipos
class ConfirmarEquiposError extends AsignacionesState {
  /// Datos actuales (para mantener UI)
  final ObtenerAsignacionesDataModel data;

  /// Mensaje de error
  final String message;

  /// Hint del backend
  final String? hint;

  const ConfirmarEquiposError({
    required this.data,
    required this.message,
    this.hint,
  });

  /// RN-005: Asignacion incompleta
  bool get esAsignacionIncompleta => hint == 'asignacion_incompleta';

  @override
  List<Object?> get props => [data, message, hint];
}
