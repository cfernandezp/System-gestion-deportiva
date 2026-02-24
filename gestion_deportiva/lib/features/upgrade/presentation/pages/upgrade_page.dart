import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../models/upgrade_reason.dart';

/// Pantalla de Upgrade - Placeholder Freemium (5 planes)
/// CA-001: Redireccion desde feature bloqueada
/// CA-002: Redireccion desde limite alcanzado
/// CA-003: Informacion de los planes de pago
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
        title: const Text('Planes'),
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

              // CA-003: Resumen de beneficios de planes de pago
              _BeneficiosCard(colorScheme: colorScheme, theme: theme),

              const SizedBox(height: DesignTokens.spacingL),

              // Comparativa de los 5 planes (scroll horizontal)
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
                      'Estamos trabajando en las suscripciones.\nTe avisaremos cuando esten disponibles.',
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

/// Card con lista de beneficios de los planes de pago
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
                  'Beneficios de nuestros planes',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: DesignTokens.fontWeightSemiBold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.spacingM),
            _BeneficioItem(
              icon: Icons.groups,
              text: 'Hasta 20 grupos por administrador',
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
              icon: Icons.group_work,
              text: 'Formato triangular (hasta 4 equipos)',
              colorScheme: colorScheme,
              theme: theme,
            ),
            _BeneficioItem(
              icon: Icons.person_add,
              text: 'Hasta 10 invitados por grupo',
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

/// Datos de un plan para la tabla comparativa
class _PlanData {
  final String nombre;
  final String precio;
  final bool destacado;
  final String grupos;
  final String jugadores;
  final String invitados;
  final String coAdmins;
  final String equiposFecha;
  final String logoMb;
  final bool estadisticas;
  final bool temasPersonalizados;

  const _PlanData({
    required this.nombre,
    required this.precio,
    this.destacado = false,
    required this.grupos,
    required this.jugadores,
    required this.invitados,
    required this.coAdmins,
    required this.equiposFecha,
    required this.logoMb,
    required this.estadisticas,
    required this.temasPersonalizados,
  });
}

/// Comparativa de los 5 planes con scroll horizontal
class _PlanesComparativa extends StatelessWidget {
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _PlanesComparativa({
    required this.colorScheme,
    required this.theme,
  });

  static const _planes = <_PlanData>[
    _PlanData(
      nombre: 'Gratis',
      precio: 'S/ 0',
      grupos: '1',
      jugadores: '25',
      invitados: '1',
      coAdmins: '1',
      equiposFecha: '2',
      logoMb: '2',
      estadisticas: false,
      temasPersonalizados: false,
    ),
    _PlanData(
      nombre: 'Plan 5',
      precio: 'S/ 9.90',
      grupos: '5',
      jugadores: '50',
      invitados: '3',
      coAdmins: '3',
      equiposFecha: '3',
      logoMb: '2',
      estadisticas: true,
      temasPersonalizados: false,
    ),
    _PlanData(
      nombre: 'Plan 10',
      precio: 'S/ 19.90',
      destacado: true,
      grupos: '10',
      jugadores: '50',
      invitados: '5',
      coAdmins: '6',
      equiposFecha: '4',
      logoMb: '2',
      estadisticas: true,
      temasPersonalizados: true,
    ),
    _PlanData(
      nombre: 'Plan 15',
      precio: 'S/ 29.90',
      grupos: '15',
      jugadores: '70',
      invitados: '8',
      coAdmins: '9',
      equiposFecha: '4',
      logoMb: '2',
      estadisticas: true,
      temasPersonalizados: true,
    ),
    _PlanData(
      nombre: 'Plan 20',
      precio: 'S/ 39.90',
      grupos: '20',
      jugadores: '70',
      invitados: '10',
      coAdmins: '9',
      equiposFecha: '4',
      logoMb: '2',
      estadisticas: true,
      temasPersonalizados: true,
    ),
  ];

  static const _conceptos = <String>[
    'Grupos',
    'Jugadores/grupo',
    'Invitados/grupo',
    'Co-admins/grupo',
    'Equipos/fecha',
    'Logo (MB)',
    'Estadisticas avanzadas',
    'Temas personalizados',
  ];

  String _valorPlan(_PlanData plan, int conceptoIndex) {
    switch (conceptoIndex) {
      case 0:
        return plan.grupos;
      case 1:
        return plan.jugadores;
      case 2:
        return plan.invitados;
      case 3:
        return plan.coAdmins;
      case 4:
        return plan.equiposFecha;
      case 5:
        return plan.logoMb;
      case 6:
        return plan.estadisticas ? 'Si' : '-';
      case 7:
        return plan.temasPersonalizados ? 'Si' : '-';
      default:
        return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    const double labelColumnWidth = 130.0;
    const double planColumnWidth = 80.0;

    return Card(
      clipBehavior: Clip.antiAlias,
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
            const SizedBox(height: DesignTokens.spacingS),
            Text(
              'Desliza para ver todos los planes',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: DesignTokens.spacingM),

            // Tabla con scroll horizontal
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: labelColumnWidth +
                      (planColumnWidth * _planes.length),
                ),
                child: Column(
                  children: [
                    // Header: nombres de planes
                    _buildHeaderRow(labelColumnWidth, planColumnWidth),
                    const SizedBox(height: DesignTokens.spacingXs),

                    // Header: precios
                    _buildPrecioRow(labelColumnWidth, planColumnWidth),

                    Divider(
                      height: DesignTokens.spacingM,
                      color: colorScheme.outlineVariant,
                    ),

                    // Filas de conceptos
                    for (int i = 0; i < _conceptos.length; i++) ...[
                      _buildConceptoRow(
                        labelColumnWidth,
                        planColumnWidth,
                        _conceptos[i],
                        i,
                      ),
                      if (i < _conceptos.length - 1)
                        const SizedBox(height: DesignTokens.spacingXs),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderRow(double labelWidth, double planWidth) {
    return Row(
      children: [
        SizedBox(width: labelWidth),
        for (final plan in _planes)
          SizedBox(
            width: planWidth,
            child: Column(
              children: [
                if (plan.destacado)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.spacingXs,
                      vertical: DesignTokens.spacingXxs,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.tertiary,
                      borderRadius: BorderRadius.circular(
                        DesignTokens.radiusXs,
                      ),
                    ),
                    child: Text(
                      'Popular',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onTertiary,
                        fontWeight: DesignTokens.fontWeightSemiBold,
                        fontSize: 9,
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 18),
                const SizedBox(height: DesignTokens.spacingXxs),
                Text(
                  plan.nombre,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: plan.destacado
                        ? DesignTokens.fontWeightBold
                        : DesignTokens.fontWeightSemiBold,
                    color: plan.destacado
                        ? colorScheme.tertiary
                        : colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPrecioRow(double labelWidth, double planWidth) {
    return Row(
      children: [
        SizedBox(
          width: labelWidth,
          child: Text(
            'Precio/mes',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        for (final plan in _planes)
          SizedBox(
            width: planWidth,
            child: Text(
              plan.precio,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: DesignTokens.fontWeightSemiBold,
                color: plan.nombre == 'Gratis'
                    ? colorScheme.onSurfaceVariant
                    : colorScheme.tertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _buildConceptoRow(
    double labelWidth,
    double planWidth,
    String concepto,
    int conceptoIndex,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.spacingXs),
      decoration: BoxDecoration(
        color: conceptoIndex.isEven
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(DesignTokens.radiusXs),
      ),
      child: Row(
        children: [
          SizedBox(
            width: labelWidth,
            child: Padding(
              padding: const EdgeInsets.only(left: DesignTokens.spacingXs),
              child: Text(
                concepto,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ),
          for (int p = 0; p < _planes.length; p++)
            SizedBox(
              width: planWidth,
              child: _buildCellValue(
                _valorPlan(_planes[p], conceptoIndex),
                isGratuito: p == 0,
                isDestacado: _planes[p].destacado,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCellValue(
    String valor, {
    required bool isGratuito,
    required bool isDestacado,
  }) {
    // Para valores booleanos Si/-
    if (valor == 'Si') {
      return Icon(
        Icons.check_circle,
        size: 18,
        color: DesignTokens.successColor,
      );
    }
    if (valor == '-') {
      return Icon(
        Icons.remove_circle_outline,
        size: 16,
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
      );
    }

    // Para valores numericos
    return Text(
      valor,
      style: theme.textTheme.bodySmall?.copyWith(
        fontWeight: isDestacado
            ? DesignTokens.fontWeightBold
            : DesignTokens.fontWeightMedium,
        color: isGratuito
            ? colorScheme.onSurfaceVariant
            : isDestacado
                ? colorScheme.tertiary
                : colorScheme.onSurface,
      ),
      textAlign: TextAlign.center,
    );
  }
}
