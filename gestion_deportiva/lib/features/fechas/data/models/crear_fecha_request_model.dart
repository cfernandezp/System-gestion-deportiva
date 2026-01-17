import 'package:equatable/equatable.dart';

/// Modelo de Request para crear una fecha de pichanga
/// E003-HU-001: Crear Fecha
/// Parametros requeridos por RPC: crear_fecha()
class CrearFechaRequestModel extends Equatable {
  /// Fecha y hora de inicio (UTC)
  /// CA-002, RN-004: Debe ser fecha futura
  final DateTime fechaHoraInicio;

  /// Duracion en horas (1 o 2)
  /// CA-002, RN-002: Determina formato y numero de equipos
  final int duracionHoras;

  /// Nombre de cancha o direccion
  /// CA-005: Campo obligatorio, minimo 3 caracteres
  final String lugar;

  const CrearFechaRequestModel({
    required this.fechaHoraInicio,
    required this.duracionHoras,
    required this.lugar,
  });

  /// Convierte a Map para enviar como params al RPC
  /// Mapeo: camelCase -> snake_case (prefijo p_)
  Map<String, dynamic> toParams() {
    return {
      'p_fecha_hora_inicio': fechaHoraInicio.toUtc().toIso8601String(),
      'p_duracion_horas': duracionHoras,
      'p_lugar': lugar.trim(),
    };
  }

  /// Valida los datos antes de enviar (validacion frontend)
  /// CA-004: Fecha futura
  /// CA-005: Lugar no vacio
  /// RN-002: Duracion 1 o 2
  String? validar() {
    // RN-004: Fecha futura
    if (fechaHoraInicio.isBefore(DateTime.now())) {
      return 'La fecha debe ser futura';
    }

    // RN-002: Duracion valida
    if (duracionHoras != 1 && duracionHoras != 2) {
      return 'La duracion debe ser 1 o 2 horas';
    }

    // CA-005: Lugar obligatorio
    if (lugar.trim().isEmpty) {
      return 'El lugar es obligatorio';
    }

    if (lugar.trim().length < 3) {
      return 'El lugar debe tener al menos 3 caracteres';
    }

    return null; // Sin errores
  }

  /// Obtiene el formato de juego segun duracion (CA-003, RN-002)
  String get formatoJuego {
    if (duracionHoras == 1) {
      return '2 equipos';
    } else {
      return '3 equipos con rotacion';
    }
  }

  /// Obtiene el costo segun duracion (CA-003, RN-003)
  double get costoPorJugador {
    if (duracionHoras == 1) {
      return 8.00;
    } else {
      return 10.00;
    }
  }

  /// Formato del costo para mostrar (CA-003)
  String get costoFormato {
    return 'S/ ${costoPorJugador.toStringAsFixed(2)}';
  }

  /// Numero de equipos segun duracion (RN-007)
  int get numEquipos {
    if (duracionHoras == 1) {
      return 2;
    } else {
      return 3;
    }
  }

  @override
  List<Object?> get props => [fechaHoraInicio, duracionHoras, lugar];
}
