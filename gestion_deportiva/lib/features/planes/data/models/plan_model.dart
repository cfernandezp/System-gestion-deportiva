import 'package:equatable/equatable.dart';

/// Modelo de plan con limites numericos y feature flags
/// E000-HU-002: Infraestructura de Planes y Limites
/// CA-001 a CA-008: Definicion de planes con limites y features
/// RN-001: Limites numericos + feature flags como conceptos distintos
class PlanModel extends Equatable {
  final String id;
  final String nombre;
  final String slug;
  final double precioMensual;

  // Limites numericos (RN-001, RN-006)
  final int maxGruposPorAdmin;
  final int maxJugadoresPorGrupo;
  final int maxInvitadosPorGrupo;
  final int maxCoadminsPorGrupo;
  final int maxEquiposPorFecha;
  final int maxTamanoLogoMb;

  // Feature flags (RN-001, RN-007, RN-008)
  final bool estadisticasAvanzadas;
  final bool temasPersonalizadosGrupo;

  const PlanModel({
    required this.id,
    required this.nombre,
    required this.slug,
    required this.precioMensual,
    required this.maxGruposPorAdmin,
    required this.maxJugadoresPorGrupo,
    required this.maxInvitadosPorGrupo,
    required this.maxCoadminsPorGrupo,
    required this.maxEquiposPorFecha,
    required this.maxTamanoLogoMb,
    required this.estadisticasAvanzadas,
    required this.temasPersonalizadosGrupo,
  });

  /// Crea instancia desde JSON del backend
  /// Mapeo: snake_case -> camelCase
  factory PlanModel.fromJson(Map<String, dynamic> json) {
    return PlanModel(
      id: json['id'] ?? json['plan_id'] ?? '',
      nombre: json['nombre'] ?? '',
      slug: json['slug'] ?? '',
      precioMensual: (json['precio_mensual'] as num?)?.toDouble() ?? 0.0,
      maxGruposPorAdmin: json['max_grupos_por_admin'] ?? 1,
      maxJugadoresPorGrupo: json['max_jugadores_por_grupo'] ?? 25,
      maxInvitadosPorGrupo: json['max_invitados_por_grupo'] ?? 1,
      maxCoadminsPorGrupo: json['max_coadmins_por_grupo'] ?? 1,
      maxEquiposPorFecha: json['max_equipos_por_fecha'] ?? 2,
      maxTamanoLogoMb: json['max_tamano_logo_mb'] ?? 2,
      estadisticasAvanzadas: json['estadisticas_avanzadas'] ?? false,
      temasPersonalizadosGrupo: json['temas_personalizados_grupo'] ?? false,
    );
  }

  /// RN-002: Plan Gratis es el default universal
  bool get esGratis => slug == 'gratis';

  /// RN-003: Planes de pago definidos pero no comprables aun
  bool get esDePago => !esGratis;

  /// RN-011: Precio formateado en Soles
  String get precioFormateado =>
      esGratis ? 'Gratis' : 'S/ ${precioMensual.toStringAsFixed(2)}/mes';

  /// Obtiene el limite numerico por nombre de recurso
  /// RN-009: Consulta centralizada
  int getLimite(String recurso) {
    switch (recurso) {
      case 'grupos_por_admin':
        return maxGruposPorAdmin;
      case 'jugadores_por_grupo':
        return maxJugadoresPorGrupo;
      case 'invitados_por_grupo':
        return maxInvitadosPorGrupo;
      case 'coadmins_por_grupo':
        return maxCoadminsPorGrupo;
      case 'equipos_por_fecha':
        return maxEquiposPorFecha;
      case 'tamano_logo_mb':
        return maxTamanoLogoMb;
      default:
        return 0;
    }
  }

  /// Verifica si una feature esta habilitada
  /// RN-007, RN-008
  bool tieneFeature(String feature) {
    switch (feature) {
      case 'estadisticas_avanzadas':
        return estadisticasAvanzadas;
      case 'temas_personalizados_grupo':
        return temasPersonalizadosGrupo;
      default:
        return false;
    }
  }

  @override
  List<Object?> get props => [
        id,
        nombre,
        slug,
        precioMensual,
        maxGruposPorAdmin,
        maxJugadoresPorGrupo,
        maxInvitadosPorGrupo,
        maxCoadminsPorGrupo,
        maxEquiposPorFecha,
        maxTamanoLogoMb,
        estadisticasAvanzadas,
        temasPersonalizadosGrupo,
      ];
}
