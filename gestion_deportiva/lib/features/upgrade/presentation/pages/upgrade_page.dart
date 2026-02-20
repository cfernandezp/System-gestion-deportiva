import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../models/upgrade_reason.dart';

/// Pantalla de Upgrade - Placeholder Freemium
/// CA-001: Redireccion desde feature bloqueada
/// CA-002: Redireccion desde limite alcanzado
/// CA-003: Informacion del plan Premium
/// CA-004: Mensaje "Proximamente"
/// CA-005: Volver a pantalla anterior
/// CA-006: Respeta tema activo
/// RN-001: Informativa, no transaccional
/// RN-002: Mensaje contextualizado segun motivo
/// RN-003: No bloquea la experiencia (navegacion normal)
class UpgradePage extends StatelessWidget {
  final UpgradeReason reason;

  const UpgradePage({super.key, required this.reason});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan Premium'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          // CA-005: Volver a pantalla anterior sin perder contexto
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DesignTokens.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: DesignTokens.spacingL),

              // Icono hero
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: colorScheme.tertiary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.workspace_premium,
                  size: 40,
                  color: colorScheme.tertiary,
                ),
              ),

              const SizedBox(height: DesignTokens.spacingL),

              // RN-002: Mensaje contextualizado
              Text(
                reason.mensajeContextual,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: DesignTokens.fontWeightSemiBold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: DesignTokens.spacingXl),

              // CA-003: Lista de beneficios Premium
              _BeneficiosCard(colorScheme: colorScheme, theme: theme),

              const SizedBox(height: DesignTokens.spacingL),

              // Comparativa de planes
              _PlanesComparativa(colorScheme: colorScheme, theme: theme),

              const SizedBox(height: DesignTokens.spacingXl),

              // CA-004: Mensaje "Proximamente"
              // RN-001: Informativa, no transaccional
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(DesignTokens.spacingM),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.construction_rounded,
                      color: colorScheme.primary,
                      size: DesignTokens.iconSizeL,
                    ),
                    const SizedBox(height: DesignTokens.spacingS),
                    Text(
                      'Proximamente',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: DesignTokens.fontWeightSemiBold,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spacingXs),
                    Text(
                      'Estamos trabajando en la suscripcion Premium.\nTe avisaremos cuando este disponible.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: DesignTokens.spacingXl),

              // CA-005: Boton volver
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Volver'),
                ),
              ),

              const SizedBox(height: DesignTokens.spacingL),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card con lista de beneficios Premium
class _BeneficiosCard extends StatelessWidget {
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _BeneficiosCard({
    required this.colorScheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star, color: colorScheme.tertiary, size: 20),
                const SizedBox(width: DesignTokens.spacingS),
                Text(
                  'Beneficios Premium',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: DesignTokens.fontWeightSemiBold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.spacingM),
            _BeneficioItem(
              icon: Icons.group_work,
              text: 'Formato triangular (3 equipos)',
              colorScheme: colorScheme,
              theme: theme,
            ),
            _BeneficioItem(
              icon: Icons.people,
              text: 'Hasta 70 jugadores por grupo',
              colorScheme: colorScheme,
              theme: theme,
            ),
            _BeneficioItem(
              icon: Icons.groups,
              text: 'Hasta 20 grupos',
              colorScheme: colorScheme,
              theme: theme,
            ),
            _BeneficioItem(
              icon: Icons.bar_chart,
              text: 'Estadisticas avanzadas',
              colorScheme: colorScheme,
              theme: theme,
            ),
            _BeneficioItem(
              icon: Icons.palette,
              text: 'Temas personalizados por grupo',
              colorScheme: colorScheme,
              theme: theme,
            ),
          ],
        ),
      ),
    );
  }
}

class _BeneficioItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _BeneficioItem({
    required this.icon,
    required this.text,
    required this.colorScheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.spacingS),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: DesignTokens.successColor,
            size: 20,
          ),
          const SizedBox(width: DesignTokens.spacingS),
          Icon(icon, color: colorScheme.onSurfaceVariant, size: 18),
          const SizedBox(width: DesignTokens.spacingS),
          Expanded(
            child: Text(text, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

/// Comparativa de limites Gratuito vs Premium
class _PlanesComparativa extends StatelessWidget {
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _PlanesComparativa({
    required this.colorScheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comparacion de planes',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: DesignTokens.fontWeightSemiBold,
              ),
            ),
            const SizedBox(height: DesignTokens.spacingM),
            // Header
            Row(
              children: [
                const Expanded(flex: 3, child: SizedBox()),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Gratis',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Premium',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.tertiary,
                      fontWeight: DesignTokens.fontWeightSemiBold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const Divider(height: DesignTokens.spacingM),
            _ComparativaRow(
              label: 'Jugadores/grupo',
              gratuito: '35',
              premium: '70',
              theme: theme,
              colorScheme: colorScheme,
            ),
            _ComparativaRow(
              label: 'Grupos',
              gratuito: '5',
              premium: '20',
              theme: theme,
              colorScheme: colorScheme,
            ),
            _ComparativaRow(
              label: 'Co-admins',
              gratuito: '3',
              premium: '5',
              theme: theme,
              colorScheme: colorScheme,
            ),
            _ComparativaRow(
              label: 'Logo (MB)',
              gratuito: '2',
              premium: '5',
              theme: theme,
              colorScheme: colorScheme,
            ),
            _ComparativaRow(
              label: '3 equipos',
              gratuito: '-',
              premium: 'Si',
              theme: theme,
              colorScheme: colorScheme,
            ),
            _ComparativaRow(
              label: 'Estadisticas+',
              gratuito: '-',
              premium: 'Si',
              theme: theme,
              colorScheme: colorScheme,
            ),
          ],
        ),
      ),
    );
  }
}

class _ComparativaRow extends StatelessWidget {
  final String label;
  final String gratuito;
  final String premium;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _ComparativaRow({
    required this.label,
    required this.gratuito,
    required this.premium,
    required this.theme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.spacingXs),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
          Expanded(
            flex: 2,
            child: Text(
              gratuito,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              premium,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.tertiary,
                fontWeight: DesignTokens.fontWeightSemiBold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
