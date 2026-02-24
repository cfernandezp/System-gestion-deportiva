import 'package:equatable/equatable.dart';

/// Modelo de Request para crear una fecha de pichanga
/// E003-HU-001: Crear Fecha
/// Parametros requeridos por RPC: crear_fecha()
class CrearFechaRequestModel extends Equatable {
  /// Fecha y hora de inicio (UTC)
  /// CA-002, RN-004: Debe ser fecha futura
  final DateTime fechaHoraInicio;

  /// Duracion en horas (1, 1.5, 2, 2.5, 3, 3.5, 4, 4.5, 5)
  /// CA-002: Seleccionado por el administrador
  final double duracionHoras;

  /// Nombre de cancha o direccion
  /// CA-005: Campo obligatorio, minimo 3 caracteres
  final String lugar;

  /// Numero de equipos (2-4)
  /// Definido por el administrador
  final int numEquipos;

  /// Costo por jugador en soles
  /// Definido por el administrador
  final double costoPorJugador;

  const CrearFechaRequestModel({
    required this.fechaHoraInicio,
    required this.duracionHoras,
    required this.lugar,
    required this.numEquipos,
    required this.costoPorJugador,
  });

  /// Convierte a Map para enviar como params al RPC
  /// Mapeo: camelCase -> snake_case (prefijo p_)
  Map<String, dynamic> toParams() {
    return {
      'p_fecha_hora_inicio': fechaHoraInicio.toUtc().toIso8601String(),
      'p_duracion_horas': duracionHoras,
      'p_lugar': lugar.trim(),
      'p_num_equipos': numEquipos,
      'p_costo_por_jugador': costoPorJugador,
    };
  }

  /// Valida los datos antes de enviar (validacion frontend)
  /// CA-004: Fecha futura
  /// CA-005: Lugar no vacio
  String? validar() {
    // Fecha futura
    if (fechaHoraInicio.isBefore(DateTime.now())) {
      return 'La fecha debe ser futura';
    }

    // Duracion valida (1-5 horas, incrementos de 0.5)
    if (duracionHoras < 1.0 || duracionHoras > 5.0) {
      return 'La duracion debe ser entre 1 y 5 horas';
    }

    // CA-005: Lugar obligatorio
    if (lugar.trim().isEmpty) {
      return 'El lugar es obligatorio';
    }

    if (lugar.trim().length < 3) {
      return 'El lugar debe tener al menos 3 caracteres';
    }

    // Numero de equipos valido (2-4)
    if (numEquipos < 2 || numEquipos > 4) {
      return 'El numero de equipos debe ser entre 2 y 4';
    }

    // Costo valido (0-100)
    if (costoPorJugador < 0 || costoPorJugador > 100) {
      return 'El costo debe ser entre S/ 0.00 y S/ 100.00';
    }

    return null; // Sin errores
  }

  /// Obtiene el formato de juego segun numero de equipos
  String get formatoJuego {
    if (numEquipos == 2) {
      return 'Partido directo';
    } else {
      return '$numEquipos equipos con rotacion';
    }
  }

  /// Formato del costo para mostrar
  String get costoFormato {
    return 'S/ ${costoPorJugador.toStringAsFixed(2)}';
  }

  @override
  List<Object?> get props => [
        fechaHoraInicio,
        duracionHoras,
        lugar,
        numEquipos,
        costoPorJugador,
      ];
}
