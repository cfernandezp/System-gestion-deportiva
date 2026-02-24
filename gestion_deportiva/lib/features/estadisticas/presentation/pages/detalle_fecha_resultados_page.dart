import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../fechas/data/models/color_equipo.dart';
import '../../data/models/resultados_fecha_model.dart';
import '../bloc/detalle_fecha/detalle_fecha.dart';

/// E006-HU-004: Pagina de Detalle de Resultados de una Fecha
/// CA-002: Seleccionar fecha para ver detalle
/// CA-003: Resultados de partidos
/// CA-004: Tabla de posiciones (Plan 5+)
/// CA-005: Goleadores de la fecha (Plan 5+)
/// CA-006: Lista de asistentes por equipo
class DetalleFechaResultadosPage extends StatelessWidget {
  final String fechaId;

  const DetalleFechaResultadosPage({super.key, required this.fechaId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DetalleFechaBloc, DetalleFechaState>(
      builder: (context, state) {
        // Obtener titulo del AppBar segun estado
        String titulo = 'Detalle de Fecha';
        String? subtitulo;

        if (state is DetalleFechaLoaded) {
          titulo = state.detalle.fecha.fechaFormato;
          subtitulo = state.detalle.fecha.lugar;
        }

        return Scaffold(
          appBar: AppBar(
            title: Column(
              children: [
                Text(titulo),
                if (subtitulo != null)
                  Text(
                    subtitulo,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                  ),
              ],
            ),
            centerTitle: true,
          ),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, DetalleFechaState state) {
    if (state is DetalleFechaLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is DetalleFechaError) {
      return _buildError(context, state);
    }

    if (state is DetalleFechaLoaded) {
      return _buildDetalle(context, state.detalle);
    }

    return const SizedBox.shrink();
  }

  Widget _buildError(BuildContext context, DetalleFechaError state) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: colorScheme.error),
            const SizedBox(height: DesignTokens.spacingM),
            Text(
              state.message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (state.hint != null) ...[
              const SizedBox(height: DesignTokens.spacingS),
              Text(
                state.hint!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetalle(
      BuildContext context, DetalleFechaResultadosModel detalle) {
    return ListView(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      children: [
        // Info resumen
        _buildInfoResumen(context, detalle.fecha),
        const SizedBox(height: DesignTokens.spacingM),

        // CA-003: Partidos
        if (detalle.tienePartidos) ...[
          _buildSeccionTitulo(context, Icons.sports, 'Partidos'),
          const SizedBox(height: DesignTokens.spacingS),
          ...detalle.partidos.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: DesignTokens.spacingS),
                child: _PartidoCard(partido: p),
              )),
          const SizedBox(height: DesignTokens.spacingM),
        ],

        // CA-004: Tabla de posiciones (Plan 5+)
        if (detalle.statsAvanzadas &&
            detalle.tablaPosiciones != null &&
            detalle.tablaPosiciones!.isNotEmpty) ...[
          _buildSeccionTitulo(context, Icons.leaderboard, 'Tabla de Posiciones'),
          const SizedBox(height: DesignTokens.spacingS),
          _buildTablaPosiciones(context, detalle.tablaPosiciones!),
          const SizedBox(height: DesignTokens.spacingM),
        ],

        // CA-005: Goleadores (Plan 5+)
        if (detalle.statsAvanzadas &&
            detalle.goleadores != null &&
            detalle.goleadores!.isNotEmpty) ...[
          _buildSeccionTitulo(context, Icons.emoji_events, 'Goleadores'),
          const SizedBox(height: DesignTokens.spacingS),
          _buildGoleadores(context, detalle.goleadores!),
          const SizedBox(height: DesignTokens.spacingM),
        ],

        // CA-006: Asistentes por equipo
        if (detalle.asistentesPorEquipo.isNotEmpty) ...[
          _buildSeccionTitulo(context, Icons.groups, 'Asistentes'),
          const SizedBox(height: DesignTokens.spacingS),
          ...detalle.asistentesPorEquipo.map((equipo) => Padding(
                padding: const EdgeInsets.only(bottom: DesignTokens.spacingS),
                child: _EquipoAsistentesCard(equipoAsistentes: equipo),
              )),
        ],

        // Hint upgrade si no tiene stats avanzadas
        if (!detalle.statsAvanzadas) ...[
          const SizedBox(height: DesignTokens.spacingS),
          _buildUpgradeHint(context),
        ],

        const SizedBox(height: DesignTokens.spacingL),
      ],
    );
  }

  /// Resumen con total de asistentes
  Widget _buildInfoResumen(BuildContext context, FechaInfoModel fecha) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: DesignTokens.primaryColor.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        side: BorderSide(
            color: DesignTokens.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingM),
        child: Row(
          children: [
            Icon(Icons.people, color: DesignTokens.primaryColor, size: 20),
            const SizedBox(width: DesignTokens.spacingS),
            Text(
              '${fecha.totalAsistentes} asistentes',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: DesignTokens.fontWeightMedium,
                    color: colorScheme.onSurface,
                  ),
            ),
            const Spacer(),
            Icon(Icons.location_on_outlined,
                size: 16, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: DesignTokens.spacingXxs),
            Flexible(
              child: Text(
                fecha.lugar,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Titulo de seccion con icono
  Widget _buildSeccionTitulo(
      BuildContext context, IconData icon, String titulo) {
    return Row(
      children: [
        Icon(icon, size: 20, color: DesignTokens.primaryColor),
        const SizedBox(width: DesignTokens.spacingS),
        Text(
          titulo,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: DesignTokens.fontWeightSemiBold,
              ),
        ),
      ],
    );
  }

  /// CA-004: Tabla de posiciones
  /// RN-003, RN-004: Calculo y criterios de ordenamiento
  Widget _buildTablaPosiciones(
      BuildContext context, List<PosicionTablaModel> tabla) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 12,
          horizontalMargin: DesignTokens.spacingM,
          headingRowHeight: 40,
          dataRowMinHeight: 36,
          dataRowMaxHeight: 40,
          headingTextStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: DesignTokens.fontWeightBold,
                color: colorScheme.onSurfaceVariant,
              ),
          dataTextStyle: Theme.of(context).textTheme.bodySmall,
          columns: const [
            DataColumn(label: Text('#')),
            DataColumn(label: Text('Equipo')),
            DataColumn(label: Text('PJ'), numeric: true),
            DataColumn(label: Text('PG'), numeric: true),
            DataColumn(label: Text('PE'), numeric: true),
            DataColumn(label: Text('PP'), numeric: true),
            DataColumn(label: Text('GF'), numeric: true),
            DataColumn(label: Text('GC'), numeric: true),
            DataColumn(label: Text('DIF'), numeric: true),
            DataColumn(label: Text('PTS'), numeric: true),
          ],
          rows: tabla.map((pos) {
            final colorEquipo = ColorEquipo.fromString(pos.equipo);
            final esPrimero = pos.posicion == 1;

            return DataRow(
              color: esPrimero
                  ? WidgetStateProperty.all(
                      DesignTokens.accentColor.withValues(alpha: 0.08))
                  : null,
              cells: [
                DataCell(Text(
                  '${pos.posicion}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: DesignTokens.fontWeightBold,
                      ),
                )),
                DataCell(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (colorEquipo != null)
                      Container(
                        width: 12,
                        height: 12,
                        margin: const EdgeInsets.only(
                            right: DesignTokens.spacingXs),
                        decoration: BoxDecoration(
                          color: colorEquipo.color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorEquipo.borderColor,
                            width: 1,
                          ),
                        ),
                      ),
                    Text(
                      colorEquipo?.displayName ?? pos.equipo,
                      style:
                          Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight:
                                    DesignTokens.fontWeightMedium,
                              ),
                    ),
                  ],
                )),
                DataCell(Text('${pos.pj}')),
                DataCell(Text('${pos.pg}')),
                DataCell(Text('${pos.pe}')),
                DataCell(Text('${pos.pp}')),
                DataCell(Text('${pos.gf}')),
                DataCell(Text('${pos.gc}')),
                DataCell(Text(
                  '${pos.dif}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: pos.dif > 0
                            ? Colors.green
                            : pos.dif < 0
                                ? Colors.red
                                : null,
                        fontWeight: DesignTokens.fontWeightMedium,
                      ),
                )),
                DataCell(Text(
                  '${pos.pts}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: DesignTokens.fontWeightBold,
                        color: DesignTokens.primaryColor,
                      ),
                )),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  /// CA-005: Lista de goleadores de la fecha
  /// RN-005, RN-006: Goleadores y maximo goleador
  Widget _buildGoleadores(
      BuildContext context, List<GoleadorFechaModel> goleadores) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: DesignTokens.spacingS),
        child: Column(
          children: goleadores.map((goleador) {
            return ListTile(
              dense: true,
              leading: goleador.esMaximoGoleador
                  ? const Icon(Icons.emoji_events,
                      color: DesignTokens.accentColor, size: 24)
                  : Icon(Icons.sports_soccer,
                      color: colorScheme.onSurfaceVariant, size: 20),
              title: Text(
                goleador.displayName,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: goleador.esMaximoGoleador
                          ? DesignTokens.fontWeightSemiBold
                          : DesignTokens.fontWeightRegular,
                    ),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacingS,
                  vertical: DesignTokens.spacingXxs,
                ),
                decoration: BoxDecoration(
                  color: goleador.esMaximoGoleador
                      ? DesignTokens.accentColor.withValues(alpha: 0.15)
                      : DesignTokens.primaryColor.withValues(alpha: 0.12),
                  borderRadius:
                      BorderRadius.circular(DesignTokens.radiusFull),
                ),
                child: Text(
                  '${goleador.goles} ${goleador.goles == 1 ? 'gol' : 'goles'}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: DesignTokens.fontWeightMedium,
                        color: goleador.esMaximoGoleador
                            ? DesignTokens.accentColor
                            : DesignTokens.primaryColor,
                      ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildUpgradeHint(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: DesignTokens.accentColor.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        side: BorderSide(
            color: DesignTokens.accentColor.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingM),
        child: Row(
          children: [
            const Icon(Icons.lock_outline, color: DesignTokens.accentColor),
            const SizedBox(width: DesignTokens.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Detalle completo',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: DesignTokens.fontWeightSemiBold,
                        ),
                  ),
                  Text(
                    'Tabla de posiciones, goleadores y filtros disponibles desde Plan 5',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// CA-003: Card de resultado de un partido
class _PartidoCard extends StatelessWidget {
  final PartidoResultadoModel partido;

  const _PartidoCard({required this.partido});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final colorLocal = ColorEquipo.fromString(partido.equipoLocal);
    final colorVisitante = ColorEquipo.fromString(partido.equipoVisitante);

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingM,
          vertical: DesignTokens.spacingS,
        ),
        child: Row(
          children: [
            // Equipo local
            Expanded(
              child: _EquipoLabel(
                nombre: colorLocal?.displayName ?? partido.equipoLocal,
                color: colorLocal?.color,
                borderColor: colorLocal?.borderColor,
                alineacion: CrossAxisAlignment.end,
              ),
            ),

            // Marcador
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingM,
                vertical: DesignTokens.spacingS,
              ),
              margin: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacingS),
              decoration: BoxDecoration(
                color: DesignTokens.primaryColor.withValues(alpha: 0.1),
                borderRadius:
                    BorderRadius.circular(DesignTokens.radiusS),
              ),
              child: Text(
                '${partido.golesLocal} - ${partido.golesVisitante}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: DesignTokens.fontWeightBold,
                      color: DesignTokens.primaryColor,
                    ),
              ),
            ),

            // Equipo visitante
            Expanded(
              child: _EquipoLabel(
                nombre:
                    colorVisitante?.displayName ?? partido.equipoVisitante,
                color: colorVisitante?.color,
                borderColor: colorVisitante?.borderColor,
                alineacion: CrossAxisAlignment.start,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Label de equipo con circulo de color
class _EquipoLabel extends StatelessWidget {
  final String nombre;
  final Color? color;
  final Color? borderColor;
  final CrossAxisAlignment alineacion;

  const _EquipoLabel({
    required this.nombre,
    this.color,
    this.borderColor,
    required this.alineacion,
  });

  @override
  Widget build(BuildContext context) {
    final esEnd = alineacion == CrossAxisAlignment.end;
    final children = [
      if (color != null)
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: borderColor ?? color!,
              width: 1.5,
            ),
          ),
        ),
      if (color != null)
        const SizedBox(width: DesignTokens.spacingXs),
      Flexible(
        child: Text(
          nombre,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: DesignTokens.fontWeightMedium,
              ),
          textAlign: esEnd ? TextAlign.end : TextAlign.start,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ];

    return Row(
      mainAxisAlignment:
          esEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: esEnd ? children.reversed.toList() : children,
    );
  }
}

/// CA-006: Card de equipo con sus asistentes
/// RN-007: Asistentes agrupados por equipo
class _EquipoAsistentesCard extends StatelessWidget {
  final EquipoAsistentesModel equipoAsistentes;

  const _EquipoAsistentesCard({required this.equipoAsistentes});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final colorEquipo = ColorEquipo.fromString(equipoAsistentes.equipo);
    final equipoColor = colorEquipo?.color ?? DesignTokens.primaryColor;
    final equipoNombre =
        colorEquipo?.displayName ?? equipoAsistentes.equipo;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del equipo
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingM,
              vertical: DesignTokens.spacingS,
            ),
            decoration: BoxDecoration(
              color: equipoColor.withValues(alpha: 0.12),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(DesignTokens.radiusM),
                topRight: Radius.circular(DesignTokens.radiusM),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: equipoColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorEquipo?.borderColor ?? equipoColor,
                      width: 1.5,
                    ),
                  ),
                ),
                const SizedBox(width: DesignTokens.spacingS),
                Text(
                  'Equipo $equipoNombre',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: DesignTokens.fontWeightSemiBold,
                      ),
                ),
                const Spacer(),
                Text(
                  '${equipoAsistentes.jugadores.length} jugadores',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),

          // Lista de jugadores
          ...equipoAsistentes.jugadores.map((jugador) => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacingM,
                  vertical: DesignTokens.spacingXs,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        jugador.displayName,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    if (jugador.goles > 0)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.sports_soccer,
                              size: 14,
                              color: DesignTokens.primaryColor),
                          const SizedBox(width: DesignTokens.spacingXxs),
                          Text(
                            '${jugador.goles}',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  fontWeight:
                                      DesignTokens.fontWeightMedium,
                                  color: DesignTokens.primaryColor,
                                ),
                          ),
                        ],
                      ),
                  ],
                ),
              )),
          const SizedBox(height: DesignTokens.spacingXs),
        ],
      ),
    );
  }
}
