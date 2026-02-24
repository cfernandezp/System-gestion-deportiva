/// Tipo de motivo por el que se muestra la pantalla de upgrade
/// RN-002: Mensaje contextualizado segun el motivo
enum UpgradeReasonType {
  /// Feature bloqueada (ej: formato triangular, estadisticas avanzadas)
  featureBloqueada,

  /// Limite numerico alcanzado (ej: 25 jugadores en plan Gratis)
  limiteAlcanzado,

  /// Explorando planes desde configuracion
  explorarPlanes,
}

/// Datos de contexto para la pantalla de upgrade
/// CA-001, CA-002, RN-002: Permite personalizar el mensaje segun el motivo
class UpgradeReason {
  final UpgradeReasonType type;

  /// Nombre de la feature bloqueada (ej: "Formato triangular")
  final String? featureName;

  /// Limite actual alcanzado (ej: 25)
  final int? limiteActual;

  /// Limite superior disponible en planes de pago (ej: 70)
  final int? limiteSuperior;

  /// Recurso del limite (ej: "jugadores")
  final String? recursoLimite;

  const UpgradeReason({
    required this.type,
    this.featureName,
    this.limiteActual,
    this.limiteSuperior,
    this.recursoLimite,
  });

  /// Factory para feature bloqueada
  const UpgradeReason.feature(String feature)
      : type = UpgradeReasonType.featureBloqueada,
        featureName = feature,
        limiteActual = null,
        limiteSuperior = null,
        recursoLimite = null;

  /// Factory para limite alcanzado
  const UpgradeReason.limite({
    required String recurso,
    required int actual,
    required int superior,
  })  : type = UpgradeReasonType.limiteAlcanzado,
        featureName = null,
        limiteActual = actual,
        limiteSuperior = superior,
        recursoLimite = recurso;

  /// Factory para explorar planes
  const UpgradeReason.explorar()
      : type = UpgradeReasonType.explorarPlanes,
        featureName = null,
        limiteActual = null,
        limiteSuperior = null,
        recursoLimite = null;

  /// Mensaje contextualizado segun el tipo (RN-002)
  String get mensajeContextual {
    switch (type) {
      case UpgradeReasonType.featureBloqueada:
        return '$featureName esta disponible en nuestros planes de pago';
      case UpgradeReasonType.limiteAlcanzado:
        return 'Tu grupo alcanzo el limite de $limiteActual $recursoLimite. '
            'Con nuestros planes de pago puedes tener hasta $limiteSuperior';
      case UpgradeReasonType.explorarPlanes:
        return 'Conoce los beneficios de nuestros planes';
    }
  }
}
