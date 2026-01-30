/// Enum para estados del ciclo de vida de un partido
/// E004-HU-001: Iniciar Partido
/// Estados: pendiente -> en_curso <-> pausado -> finalizado
/// Alternativo: en cualquier momento -> cancelado
enum EstadoPartido {
  pendiente,
  enCurso,
  pausado,
  finalizado,
  cancelado;

  /// Convierte string de BD a enum
  /// BD usa: 'pendiente', 'en_curso', 'pausado', 'finalizado', 'cancelado'
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

  /// Convierte enum a string para BD
  String get valor {
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

  /// Nombre para mostrar en UI
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

  /// Estados activos (partido jugandose o pausado)
  bool get esActivo => this == EstadoPartido.enCurso || this == EstadoPartido.pausado;

  /// Partido en progreso (contando tiempo)
  bool get esEnCurso => this == EstadoPartido.enCurso;

  /// Partido pausado temporalmente
  bool get esPausado => this == EstadoPartido.pausado;

  /// Partido terminado (finalizado o cancelado)
  bool get esTerminado => this == EstadoPartido.finalizado || this == EstadoPartido.cancelado;
}
