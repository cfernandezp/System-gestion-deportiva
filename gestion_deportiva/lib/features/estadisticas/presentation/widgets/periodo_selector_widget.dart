import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../data/models/ranking_response_model.dart';

/// Widget selector de periodo para filtrar el ranking
/// CA-003: Filtro por periodo (Historico, Este ano, Este mes, Ultima fecha)
class PeriodoSelectorWidget extends StatelessWidget {
  /// Periodo actualmente seleccionado
  final PeriodoRanking periodoActual;

  /// Callback cuando cambia el periodo
  final ValueChanged<PeriodoRanking> onPeriodoChanged;

  /// Si esta en estado de carga
  final bool isLoading;

  const PeriodoSelectorWidget({
    super.key,
    required this.periodoActual,
    required this.onPeriodoChanged,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingM),
      child: Row(
        children: PeriodoRanking.values.map((periodo) {
          final isSelected = periodo == periodoActual;
          return Padding(
            padding: const EdgeInsets.only(right: DesignTokens.spacingS),
            child: _PeriodoChip(
              periodo: periodo,
              isSelected: isSelected,
              isLoading: isLoading && isSelected,
              onTap: isLoading ? null : () => onPeriodoChanged(periodo),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Chip individual de periodo
class _PeriodoChip extends StatelessWidget {
  final PeriodoRanking periodo;
  final bool isSelected;
  final bool isLoading;
  final VoidCallback? onTap;

  const _PeriodoChip({
    required this.periodo,
    required this.isSelected,
    this.isLoading = false,
    this.onTap,
  });

  IconData _getIcon() {
    switch (periodo) {
      case PeriodoRanking.historico:
        return Icons.history;
      case PeriodoRanking.esteAno:
        return Icons.calendar_today;
      case PeriodoRanking.esteMes:
        return Icons.date_range;
      case PeriodoRanking.ultimaFecha:
        return Icons.event;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
        child: AnimatedContainer(
          duration: DesignTokens.animFast,
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingM,
            vertical: DesignTokens.spacingS,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                SizedBox(
                  width: DesignTokens.iconSizeS,
                  height: DesignTokens.iconSizeS,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.onPrimary,
                  ),
                )
              else
                Icon(
                  _getIcon(),
                  size: DesignTokens.iconSizeS,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                ),
              const SizedBox(width: DesignTokens.spacingXs),
              Text(
                periodo.displayName,
                style: textTheme.labelMedium?.copyWith(
                  fontWeight: isSelected
                      ? DesignTokens.fontWeightSemiBold
                      : DesignTokens.fontWeightMedium,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Version compacta del selector para el panel de filtros (desktop)
class PeriodoSelectorCompact extends StatelessWidget {
  final PeriodoRanking periodoActual;
  final ValueChanged<PeriodoRanking> onPeriodoChanged;
  final bool isLoading;

  const PeriodoSelectorCompact({
    super.key,
    required this.periodoActual,
    required this.onPeriodoChanged,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PERIODO',
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: DesignTokens.fontWeightSemiBold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingS),
        Wrap(
          spacing: DesignTokens.spacingS,
          runSpacing: DesignTokens.spacingS,
          children: PeriodoRanking.values.map((periodo) {
            final isSelected = periodo == periodoActual;
            return _CompactChip(
              label: periodo.displayName,
              isSelected: isSelected,
              isLoading: isLoading && isSelected,
              onTap: isLoading ? null : () => onPeriodoChanged(periodo),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _CompactChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isLoading;
  final VoidCallback? onTap;

  const _CompactChip({
    required this.label,
    required this.isSelected,
    this.isLoading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingM,
            vertical: DesignTokens.spacingS,
          ),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outline,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading) ...[
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(width: DesignTokens.spacingXs),
              ],
              Text(
                label,
                style: textTheme.labelSmall?.copyWith(
                  fontWeight: DesignTokens.fontWeightMedium,
                  color: isSelected ? Colors.white : colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
