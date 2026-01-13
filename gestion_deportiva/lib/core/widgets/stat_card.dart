import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';
import '../theme/app_colors.dart';
import 'app_card.dart';

/// Direccion del layout de la stat card
enum StatCardLayout {
  /// Icono arriba, valor abajo
  vertical,

  /// Icono a la izquierda, valor a la derecha
  horizontal,
}

/// Card para mostrar estadisticas con icono, valor y etiqueta
/// Ideal para dashboards y resumenes
class StatCard extends StatelessWidget {
  /// Constructor principal
  const StatCard({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.iconColor,
    this.iconBackgroundColor,
    this.layout = StatCardLayout.vertical,
    this.onTap,
    this.trend,
    this.trendValue,
    this.subtitle,
  });

  /// Constructor para estadistica con tendencia positiva
  const StatCard.positive({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    required double trendPercent,
    this.layout = StatCardLayout.vertical,
    this.onTap,
    this.subtitle,
  })  : iconColor = null,
        iconBackgroundColor = null,
        trend = StatTrend.up,
        trendValue = trendPercent;

  /// Constructor para estadistica con tendencia negativa
  const StatCard.negative({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    required double trendPercent,
    this.layout = StatCardLayout.vertical,
    this.onTap,
    this.subtitle,
  })  : iconColor = null,
        iconBackgroundColor = null,
        trend = StatTrend.down,
        trendValue = trendPercent;

  /// Valor principal a mostrar (numero, porcentaje, etc.)
  final String value;

  /// Etiqueta descriptiva
  final String label;

  /// Icono representativo
  final IconData? icon;

  /// Color del icono
  final Color? iconColor;

  /// Color de fondo del icono
  final Color? iconBackgroundColor;

  /// Layout de la card
  final StatCardLayout layout;

  /// Callback al tocar
  final VoidCallback? onTap;

  /// Tendencia (arriba, abajo, neutral)
  final StatTrend? trend;

  /// Valor de la tendencia (porcentaje)
  final double? trendValue;

  /// Subtitulo opcional
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget content;

    if (layout == StatCardLayout.vertical) {
      content = _buildVerticalLayout(context, colorScheme);
    } else {
      content = _buildHorizontalLayout(context, colorScheme);
    }

    return AppCard(
      variant: AppCardVariant.standard,
      onTap: onTap,
      child: content,
    );
  }

  Widget _buildVerticalLayout(BuildContext context, ColorScheme colorScheme) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (icon != null) _buildIconContainer(colorScheme),
            if (trend != null) _buildTrendIndicator(colorScheme),
          ],
        ),
        const SizedBox(height: DesignTokens.spacingM),
        Text(
          value,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: DesignTokens.fontWeightBold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingXs),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: DesignTokens.spacingXxs),
          Text(
            subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHorizontalLayout(BuildContext context, ColorScheme colorScheme) {
    final theme = Theme.of(context);

    return Row(
      children: [
        if (icon != null) ...[
          _buildIconContainer(colorScheme),
          const SizedBox(width: DesignTokens.spacingM),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: DesignTokens.fontWeightBold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (trend != null) _buildTrendIndicator(colorScheme),
                ],
              ),
              const SizedBox(height: DesignTokens.spacingXxs),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIconContainer(ColorScheme colorScheme) {
    final bgColor =
        iconBackgroundColor ?? colorScheme.primaryContainer;
    final fgColor = iconColor ?? colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingS),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
      ),
      child: Icon(icon, color: fgColor, size: DesignTokens.iconSizeM),
    );
  }

  Widget _buildTrendIndicator(ColorScheme colorScheme) {
    if (trend == null) return const SizedBox.shrink();

    final (trendColor, trendIcon) = switch (trend!) {
      StatTrend.up => (AppColors.victoria, Icons.trending_up),
      StatTrend.down => (AppColors.derrota, Icons.trending_down),
      StatTrend.neutral => (AppColors.empate, Icons.trending_flat),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingS,
        vertical: DesignTokens.spacingXxs,
      ),
      decoration: BoxDecoration(
        color: trendColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(trendIcon, size: 16, color: trendColor),
          if (trendValue != null) ...[
            const SizedBox(width: 4),
            Text(
              '${trendValue!.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeXs,
                fontWeight: DesignTokens.fontWeightMedium,
                color: trendColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Tendencia de la estadistica
enum StatTrend {
  up,
  down,
  neutral,
}

/// Grid de stat cards para dashboards
class StatCardGrid extends StatelessWidget {
  const StatCardGrid({
    super.key,
    required this.stats,
    this.crossAxisCount = 2,
    this.spacing = DesignTokens.spacingS,
  });

  final List<StatCard> stats;
  final int crossAxisCount;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: spacing,
        crossAxisSpacing: spacing,
        childAspectRatio: 1.2,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) => stats[index],
    );
  }
}

/// Card de marcador para partidos
class ScoreCard extends StatelessWidget {
  const ScoreCard({
    super.key,
    required this.homeScore,
    required this.awayScore,
    required this.homeTeam,
    required this.awayTeam,
    this.isLive = false,
    this.minute,
    this.onTap,
  });

  final int homeScore;
  final int awayScore;
  final String homeTeam;
  final String awayTeam;
  final bool isLive;
  final int? minute;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
      variant: isLive ? AppCardVariant.elevated : AppCardVariant.standard,
      onTap: onTap,
      borderColor: isLive ? AppColors.enCurso : null,
      child: Column(
        children: [
          if (isLive && minute != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingS,
                vertical: DesignTokens.spacingXxs,
              ),
              decoration: BoxDecoration(
                color: AppColors.enCurso,
                borderRadius: BorderRadius.circular(DesignTokens.radiusS),
              ),
              child: Text(
                "$minute'",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: DesignTokens.fontSizeXs,
                  fontWeight: DesignTokens.fontWeightBold,
                ),
              ),
            ),
          const SizedBox(height: DesignTokens.spacingS),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  homeTeam,
                  textAlign: TextAlign.end,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: DesignTokens.fontWeightMedium,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: DesignTokens.spacingM),
                child: Text(
                  '$homeScore - $awayScore',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: DesignTokens.fontWeightBold,
                    color: isLive ? AppColors.enCurso : colorScheme.onSurface,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  awayTeam,
                  textAlign: TextAlign.start,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: DesignTokens.fontWeightMedium,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
