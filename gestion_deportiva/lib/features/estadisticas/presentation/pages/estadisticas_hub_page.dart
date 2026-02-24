import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/design_tokens.dart';

/// Pagina hub de Estadisticas
/// Menu con lista de opciones de estadisticas disponibles
class EstadisticasHubPage extends StatelessWidget {
  const EstadisticasHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: const Text('Estadisticas'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(DesignTokens.spacingM),
        children: const [
          _EstadisticaMenuItem(
            titulo: 'Ranking Goleadores',
            subtitulo: 'Los maximos anotadores del grupo',
            icono: Icons.emoji_events,
            habilitado: true,
            ruta: '/ranking-goleadores',
          ),
          SizedBox(height: DesignTokens.spacingS),
          _EstadisticaMenuItem(
            titulo: 'Ranking de Puntos',
            subtitulo: 'Clasificacion por puntos acumulados',
            icono: Icons.star,
            habilitado: false,
            badgeTexto: 'Proximamente',
          ),
          SizedBox(height: DesignTokens.spacingS),
          _EstadisticaMenuItem(
            titulo: 'Mis Estadisticas',
            subtitulo: 'Tu rendimiento personal',
            icono: Icons.person,
            habilitado: true,
            ruta: '/mis-estadisticas',
          ),
          SizedBox(height: DesignTokens.spacingS),
          _EstadisticaMenuItem(
            titulo: 'Resultados por Fecha',
            subtitulo: 'Resultados de cada pichanga',
            icono: Icons.calendar_today,
            habilitado: true,
            ruta: '/resultados-fecha',
          ),
          SizedBox(height: DesignTokens.spacingS),
          _EstadisticaMenuItem(
            titulo: 'Estadisticas Mensuales',
            subtitulo: 'Resumen mensual del grupo',
            icono: Icons.bar_chart,
            habilitado: true,
            ruta: '/estadisticas-mensuales',
            requierePlan: true,
          ),
          SizedBox(height: DesignTokens.spacingS),
          _EstadisticaMenuItem(
            titulo: 'Goleador de la Fecha',
            subtitulo: 'Mejor anotador por pichanga',
            icono: Icons.sports_soccer,
            habilitado: false,
            badgeTexto: 'Proximamente',
          ),
        ],
      ),
    );
  }
}

class _EstadisticaMenuItem extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final IconData icono;
  final bool habilitado;
  final String? ruta;
  final String? badgeTexto;
  final bool requierePlan;

  const _EstadisticaMenuItem({
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.habilitado,
    this.ruta,
    this.badgeTexto,
    this.requierePlan = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final iconColor = habilitado
        ? DesignTokens.primaryColor
        : colorScheme.onSurfaceVariant;

    final titleColor = habilitado
        ? colorScheme.onSurface
        : colorScheme.onSurfaceVariant;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        side: BorderSide(
          color: habilitado
              ? DesignTokens.primaryColor.withValues(alpha: 0.3)
              : colorScheme.outlineVariant,
        ),
      ),
      child: ListTile(
        leading: Icon(icono, color: iconColor),
        title: Text(
          titulo,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: DesignTokens.fontWeightMedium,
            color: titleColor,
          ),
        ),
        subtitle: Text(
          subtitulo,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: habilitado
            ? Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant)
            : _buildBadges(context),
        onTap: habilitado && ruta != null ? () => context.push(ruta!) : null,
      ),
    );
  }

  Widget _buildBadges(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (badgeTexto != null)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingS,
              vertical: DesignTokens.spacingXxs,
            ),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
            ),
            child: Text(
              badgeTexto!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.grey,
                fontWeight: DesignTokens.fontWeightMedium,
              ),
            ),
          ),
        if (requierePlan) ...[
          const SizedBox(width: DesignTokens.spacingXs),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingS,
              vertical: DesignTokens.spacingXxs,
            ),
            decoration: BoxDecoration(
              color: DesignTokens.accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
            ),
            child: Text(
              'Plan 5+',
              style: theme.textTheme.labelSmall?.copyWith(
                color: DesignTokens.accentColor,
                fontWeight: DesignTokens.fontWeightMedium,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
