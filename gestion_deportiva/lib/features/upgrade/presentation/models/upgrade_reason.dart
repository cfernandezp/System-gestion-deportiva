/// Tipo de motivo por el que se muestra la pantalla de upgrade
/// RN-002: Mensaje contextualizado segun el motivo
enum UpgradeReasonType {
  /// Feature bloqueada (ej: formato triangular)
  featureBloqueada,

  /// Limite numerico alcanzado (ej: 35 jugadores)
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

  /// Limite actual alcanzado (ej: 35)
  final int? limiteActual;

  /// Limite Premium disponible (ej: 70)
  final int? limitePremium;

  /// Recurso del limite (ej: "jugadores")
  final String? recursoLimite;

  const UpgradeReason({
    required this.type,
    this.featureName,
    this.limiteActual,
    this.limitePremium,
    this.recursoLimite,
  });

  /// Factory para feature bloqueada
  const UpgradeReason.feature(String feature)
      : type = UpgradeReasonType.featureBloqueada,
        featureName = feature,
        limiteActual = null,
        limitePremium = null,
        recursoLimite = null;

  /// Factory para limite alcanzado
  const UpgradeReason.limite({
    required String recurso,
    required int actual,
    required int premium,
  })  : type = UpgradeReasonType.limiteAlcanzado,
        featureName = null,
        limiteActual = actual,
        limitePremium = premium,
        recursoLimite = recurso;

  /// Factory para explorar planes
  const UpgradeReason.explorar()
      : type = UpgradeReasonType.explorarPlanes,
        featureName = null,
        limiteActual = null,
        limitePremium = null,
        recursoLimite = null;

  /// Mensaje contextualizado segun el tipo (RN-002)
  String get mensajeContextual {
    switch (type) {
      case UpgradeReasonType.featureBloqueada:
        return '$featureName esta disponible en el Plan Premium';
      case UpgradeReasonType.limiteAlcanzado:
        return 'Tu grupo alcanzo el limite de $limiteActual $recursoLimite. '
            'Con Plan Premium puedes tener hasta $limitePremium';
      case UpgradeReasonType.explorarPlanes:
        return 'Conoce los beneficios del Plan Premium';
    }
  }
}
