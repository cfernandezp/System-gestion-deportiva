import 'package:equatable/equatable.dart';

import '../../../data/models/editar_fecha_response_model.dart';

/// Estados del BLoC de editar fecha
/// E003-HU-008: Editar Fecha
abstract class EditarFechaState extends Equatable {
  const EditarFechaState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial - Sin formulario inicializado
class EditarFechaInitial extends EditarFechaState {
  const EditarFechaInitial();
}

/// CA-003: Estado con formulario inicializado y datos precargados
class EditarFechaFormularioListo extends EditarFechaState {
  /// ID de la fecha
  final String fechaId;

  /// Fecha y hora actual (para precargar)
  final DateTime fechaHoraInicio;

  /// Duracion actual
  final int duracionHoras;

  /// Lugar actual
  final String lugar;

  /// Costo actual
  final double costoActual;

  /// Total de inscritos (para mostrar advertencia)
  final int totalInscritos;

  const EditarFechaFormularioListo({
    required this.fechaId,
    required this.fechaHoraInicio,
    required this.duracionHoras,
    required this.lugar,
    required this.costoActual,
    required this.totalInscritos,
  });

  /// CA-004: Calcula el nuevo costo segun duracion
  /// RN-003: 1 hora = S/8.00, 2 horas = S/10.00
  double calcularNuevoCosto(int nuevaDuracion) {
    return nuevaDuracion == 1 ? 8.00 : 10.00;
  }

  /// CA-004: Verifica si el costo cambiaria con nueva duracion
  bool costoCambiaria(int nuevaDuracion) {
    return calcularNuevoCosto(nuevaDuracion) != costoActual;
  }

  @override
  List<Object?> get props => [
        fechaId,
        fechaHoraInicio,
        duracionHoras,
        lugar,
        costoActual,
        totalInscritos,
      ];
}

/// Estado de carga - Enviando datos al servidor
class EditarFechaLoading extends EditarFechaState {
  const EditarFechaLoading();
}

/// CA-006: Estado de exito - Fecha editada correctamente
/// Contiene resumen de cambios realizados
class EditarFechaSuccess extends EditarFechaState {
  /// Datos de la fecha editada
  final EditarFechaResponseModel fecha;

  /// Mensaje de confirmacion del servidor
  /// CA-007: Incluye cantidad de notificaciones enviadas
  /// CA-008: Incluye cantidad de deudas actualizadas
  final String message;

  const EditarFechaSuccess({
    required this.fecha,
    required this.message,
  });

  /// CA-006: Indica si hubo cambios
  bool get huboCambios => fecha.cambiosRealizados;

  /// CA-007: Indica si se notificaron inscritos
  bool get seNotificaronInscritos => fecha.inscritosNotificados > 0;

  /// CA-008: Indica si se actualizaron deudas
  bool get seActualizaronDeudas => fecha.deudasActualizadas > 0;

  @override
  List<Object?> get props => [fecha, message];
}

/// Estado de error - Fallo al editar la fecha
/// Maneja todos los errores de backend
class EditarFechaError extends EditarFechaState {
  /// Mensaje de error para mostrar al usuario
  final String message;

  /// Codigo de error del backend (opcional)
  final String? code;

  /// Hint del backend para identificar tipo de error
  /// Valores posibles segun HU-008:
  /// - no_autenticado: Usuario no ha iniciado sesion
  /// - usuario_no_encontrado: Usuario no existe
  /// - sin_permisos: No es admin aprobado (RN-001)
  /// - fecha_id_requerido: No se proporciono ID de fecha
  /// - fecha_hora_requerida: No se proporciono fecha/hora
  /// - duracion_requerida: No se proporciono duracion
  /// - lugar_invalido: Lugar nulo o menos de 3 caracteres
  /// - fecha_no_encontrada: Fecha con ese ID no existe
  /// - fecha_no_editable: Fecha no tiene estado 'abierta' (RN-002)
  /// - duracion_invalida: Duracion no es 1 o 2 horas
  /// - fecha_pasada: Fecha/hora no es futura (RN-004)
  /// - fecha_duplicada: Ya existe otra fecha en ese horario (RN-005)
  final String? hint;

  const EditarFechaError({
    required this.message,
    this.code,
    this.hint,
  });

  /// RN-001: Verifica si el error es de permisos
  bool get esSinPermisos => hint == 'sin_permisos';

  /// RN-002: Verifica si la fecha no es editable
  bool get esFechaNoEditable => hint == 'fecha_no_editable';

  /// RN-004: Verifica si el error es por fecha pasada
  bool get esFechaPasada => hint == 'fecha_pasada';

  /// RN-005: Verifica si el error es por fecha duplicada
  bool get esFechaDuplicada => hint == 'fecha_duplicada';

  /// Verifica si el error es por duracion invalida
  bool get esDuracionInvalida => hint == 'duracion_invalida';

  /// Verifica si el error es por lugar invalido
  bool get esLugarInvalido => hint == 'lugar_invalido';

  @override
  List<Object?> get props => [message, code, hint];
}
