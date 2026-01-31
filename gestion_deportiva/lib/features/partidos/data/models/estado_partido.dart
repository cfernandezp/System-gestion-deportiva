/// Enum de estados de partido
/// E004-HU-001: Iniciar Partido
/// Mapea al ENUM estado_partido de la BD
enum EstadoPartido {
  pendiente,
  enCurso,
  pausado,
  finalizado,
  cancelado;

  /// Convierte string del backend (snake_case) a enum
  static EstadoPartido fromString(String value) {
    switch (value) {
      case 'pendiente':
        return EstadoPartido.pendiente;
      case 'en_curso':
        return EstadoPartido.enCurso;
      case 'pausado':
        return EstadoPartido.pausado;
      case 'finalizado':
        return EstadoPartido.finalizado;
      case 'cancelado':
        return EstadoPartido.cancelado;
      default:
        return EstadoPartido.pendiente;
    }
  }

  /// Convierte enum a string para enviar al backend (snake_case)
  String toBackend() {
    switch (this) {
      case EstadoPartido.pendiente:
        return 'pendiente';
      case EstadoPartido.enCurso:
        return 'en_curso';
      case EstadoPartido.pausado:
        return 'pausado';
      case EstadoPartido.finalizado:
        return 'finalizado';
      case EstadoPartido.cancelado:
        return 'cancelado';
    }
  }

  /// Nombre formateado para mostrar en UI
  String get displayName {
    switch (this) {
      case EstadoPartido.pendiente:
        return 'Pendiente';
      case EstadoPartido.enCurso:
        return 'En curso';
      case EstadoPartido.pausado:
        return 'Pausado';
      case EstadoPartido.finalizado:
        return 'Finalizado';
      case EstadoPartido.cancelado:
        return 'Cancelado';
    }
  }

  /// Indica si el partido esta activo (en_curso o pausado)
  bool get esActivo =>
      this == EstadoPartido.enCurso || this == EstadoPartido.pausado;

  /// Indica si el partido puede ser pausado
  bool get puedePausar => this == EstadoPartido.enCurso;

  /// Indica si el partido puede ser reanudado
  bool get puedeReanudar => this == EstadoPartido.pausado;
}
