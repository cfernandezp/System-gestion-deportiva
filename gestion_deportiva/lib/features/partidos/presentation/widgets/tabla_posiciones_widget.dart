import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../fechas/data/models/color_equipo.dart';
import '../../data/models/resumen_jornada_model.dart';

/// Widget que muestra la tabla de posiciones de la jornada
/// E004-HU-007: Resumen de Jornada
/// CA-002: Tabla con PJ, PG, PE, PP, GF, GC, DIF, PTS
class TablaPosicionesWidget extends StatelessWidget {
  /// Lista de posiciones a mostrar
  final List<TablaPosicionModel> posiciones;

  /// Titulo opcional para la tabla
  final String? titulo;

  /// Si mostrar encabezado compacto
  final bool compacto;

  const TablaPosicionesWidget({
    super.key,
    required this.posiciones,
    this.titulo,
    this.compacto = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (posiciones.isEmpty) {
      return _buildEmptyState(context);
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Titulo
            if (titulo != null || !compacto) ...[
              Row(
                children: [
                  Icon(
                    Icons.leaderboard_outlined,
                    color: colorScheme.primary,
                    size: DesignTokens.iconSizeM,
                  ),
                  const SizedBox(width: DesignTokens.spacingS),
                  Text(
                    titulo ?? 'Tabla de Posiciones',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: DesignTokens.fontWeightSemiBold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.spacingM),
            ],

            // Tabla
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _buildDataTable(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DataTable(
      columnSpacing: compacto ? DesignTokens.spacingS : DesignTokens.spacingM,
      horizontalMargin: DesignTokens.spacingS,
      headingRowHeight: 40,
      dataRowMinHeight: 44,
      dataRowMaxHeight: 48,
      headingTextStyle: textTheme.labelSmall?.copyWith(
        fontWeight: DesignTokens.fontWeightSemiBold,
        color: colorScheme.onSurfaceVariant,
      ),
      columns: const [
        DataColumn(
          label: Text('POS'),
          numeric: true,
        ),
        DataColumn(
          label: Text('EQUIPO'),
        ),
        DataColumn(
          label: Text('PJ'),
          numeric: true,
          tooltip: 'Partidos Jugados',
        ),
        DataColumn(
          label: Text('PG'),
          numeric: true,
          tooltip: 'Partidos Ganados',
        ),
        DataColumn(
          label: Text('PE'),
          numeric: true,
          tooltip: 'Partidos Empatados',
        ),
        DataColumn(
          label: Text('PP'),
          numeric: true,
          tooltip: 'Partidos Perdidos',
        ),
        DataColumn(
          label: Text('GF'),
          numeric: true,
          tooltip: 'Goles a Favor',
        ),
        DataColumn(
          label: Text('GC'),
          numeric: true,
          tooltip: 'Goles en Contra',
        ),
        DataColumn(
          label: Text('DIF'),
          numeric: true,
          tooltip: 'Diferencia de Goles',
        ),
        DataColumn(
          label: Text('PTS'),
          numeric: true,
          tooltip: 'Puntos',
        ),
      ],
      rows: posiciones.map((pos) => _buildDataRow(context, pos)).toList(),
    );
  }

  DataRow _buildDataRow(BuildContext context, TablaPosicionModel pos) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final colorEquipo = ColorEquipo.fromString(pos.equipo);

    // Color de fondo segun posicion
    Color? rowColor;
    if (pos.posicion == 1) {
      rowColor = AppColors.oro.withValues(alpha: 0.1);
    } else if (pos.posicion == 2) {
      rowColor = AppColors.plata.withValues(alpha: 0.1);
    } else if (pos.posicion == 3) {
      rowColor = AppColors.bronce.withValues(alpha: 0.1);
    }

    return DataRow(
      color: rowColor != null
          ? WidgetStateProperty.all(rowColor)
          : null,
      cells: [
        // Posicion con icono para top 3
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (pos.posicion <= 3)
                Icon(
                  Icons.emoji_events,
                  size: 16,
                  color: AppColors.posicionRanking(pos.posicion),
                ),
              if (pos.posicion <= 3) const SizedBox(width: 4),
              Text(
                '${pos.posicion}',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: pos.posicion <= 3
                      ? DesignTokens.fontWeightBold
                      : DesignTokens.fontWeightMedium,
                ),
              ),
            ],
          ),
        ),

        // Equipo con color
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: colorEquipo?.color ?? colorScheme.primary,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusXs),
                  border: colorEquipo == ColorEquipo.blanco
                      ? Border.all(color: Colors.grey.shade400)
                      : null,
                ),
                child: Center(
                  child: Text(
                    pos.equipo.isNotEmpty ? pos.equipo[0].toUpperCase() : '?',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorEquipo?.textColor ?? Colors.white,
                      fontWeight: DesignTokens.fontWeightBold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: DesignTokens.spacingS),
              Text(
                _capitalize(pos.equipo),
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: DesignTokens.fontWeightMedium,
                ),
              ),
            ],
          ),
        ),

        // PJ
        DataCell(Text('${pos.pj}')),

        // PG
        DataCell(
          Text(
            '${pos.pg}',
            style: textTheme.bodyMedium?.copyWith(
              color: pos.pg > 0 ? AppColors.victoria : null,
            ),
          ),
        ),

        // PE
        DataCell(
          Text(
            '${pos.pe}',
            style: textTheme.bodyMedium?.copyWith(
              color: pos.pe > 0 ? AppColors.empate : null,
            ),
          ),
        ),

        // PP
        DataCell(
          Text(
            '${pos.pp}',
            style: textTheme.bodyMedium?.copyWith(
              color: pos.pp > 0 ? AppColors.derrota : null,
            ),
          ),
        ),

        // GF
        DataCell(Text('${pos.gf}')),

        // GC
        DataCell(Text('${pos.gc}')),

        // DIF
        DataCell(
          Text(
            pos.dif > 0 ? '+${pos.dif}' : '${pos.dif}',
            style: textTheme.bodyMedium?.copyWith(
              color: pos.dif > 0
                  ? AppColors.victoria
                  : pos.dif < 0
                      ? AppColors.derrota
                      : null,
              fontWeight: DesignTokens.fontWeightMedium,
            ),
          ),
        ),

        // PTS
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingS,
              vertical: DesignTokens.spacingXxs,
            ),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(DesignTokens.radiusS),
            ),
            child: Text(
              '${pos.pts}',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: DesignTokens.fontWeightBold,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.leaderboard_outlined,
              size: DesignTokens.iconSizeXl,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: DesignTokens.spacingM),
            Text(
              'Sin posiciones',
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: DesignTokens.spacingXs),
            Text(
              'Aun no hay partidos finalizados para mostrar la tabla',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
}
