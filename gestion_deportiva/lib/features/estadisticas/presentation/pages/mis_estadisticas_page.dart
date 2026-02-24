import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../data/models/mis_estadisticas_model.dart';
import '../bloc/mis_estadisticas/mis_estadisticas.dart';

/// E006-HU-003: Pagina de Mis Estadisticas
/// Dashboard personal del jugador logueado
class MisEstadisticasPage extends StatelessWidget {
  const MisEstadisticasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Estadisticas'),
        centerTitle: true,
      ),
      body: BlocBuilder<MisEstadisticasBloc, MisEstadisticasState>(
        builder: (context, state) {
          if (state is MisEstadisticasLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is MisEstadisticasError) {
            return _buildError(context, state);
          }

          if (state is MisEstadisticasLoaded) {
            final stats = state.estadisticas;

            // CA-008: Sin datos
            if (!stats.tieneDatos) {
              return _buildSinDatos(context, stats.message);
            }

            return _buildDashboard(context, stats);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildError(BuildContext context, MisEstadisticasError state) {
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
          ],
        ),
      ),
    );
  }

  /// CA-008: Mensaje cuando no tiene participaciones
  Widget _buildSinDatos(BuildContext context, String message) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_soccer,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: DesignTokens.spacingM),
            Text(
              message.isNotEmpty
                  ? message
                  : 'Aun no tienes estadisticas. Inscribete a tu primera pichanga!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, MisEstadisticasResponseModel stats) {
    return RefreshIndicator(
      onRefresh: () async {
        // Re-trigger load (el bloc ya tiene el grupoId en el evento previo)
      },
      child: ListView(
        padding: const EdgeInsets.all(DesignTokens.spacingM),
        children: [
          // Header con nombre
          _buildHeader(context, stats.jugador),
          const SizedBox(height: DesignTokens.spacingM),

          // CA-002: Metricas principales
          _buildMetricasGrid(context, stats.metricas),
          const SizedBox(height: DesignTokens.spacingM),

          // CA-003: Rankings (Plan 5+)
          if (stats.statsAvanzadas && stats.rankings != null) ...[
            _buildRankingsCard(context, stats.rankings!),
            const SizedBox(height: DesignTokens.spacingM),
          ],

          // CA-004: Promedio (Plan 5+)
          if (stats.statsAvanzadas && stats.promedio != null) ...[
            _buildPromedioCard(context, stats.promedio!),
            const SizedBox(height: DesignTokens.spacingM),
          ],

          // CA-007: Racha (Plan 5+)
          if (stats.statsAvanzadas && stats.rachaAsistencia != null) ...[
            _buildRachaCard(context, stats.rachaAsistencia!),
            const SizedBox(height: DesignTokens.spacingM),
          ],

          // CA-006: Mejor fecha (Plan 5+)
          if (stats.statsAvanzadas && stats.mejorFecha != null) ...[
            _buildMejorFechaCard(context, stats.mejorFecha!),
            const SizedBox(height: DesignTokens.spacingM),
          ],

          // CA-005: Historial (Plan 5+)
          if (stats.statsAvanzadas &&
              stats.historial != null &&
              stats.historial!.isNotEmpty) ...[
            _buildHistorialSection(context, stats.historial!),
          ],

          // Badge "Plan 5+" si no tiene stats avanzadas
          if (!stats.statsAvanzadas) ...[
            _buildUpgradeHint(context),
          ],

          const SizedBox(height: DesignTokens.spacingL),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, JugadorInfoModel jugador) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: DesignTokens.primaryColor.withValues(alpha: 0.15),
          child: Text(
            jugador.displayName.isNotEmpty
                ? jugador.displayName[0].toUpperCase()
                : '?',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: DesignTokens.primaryColor,
                  fontWeight: DesignTokens.fontWeightBold,
                ),
          ),
        ),
        const SizedBox(width: DesignTokens.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                jugador.displayName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: DesignTokens.fontWeightSemiBold,
                    ),
              ),
              Text(
                'Rendimiento personal',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// CA-002: Grid de 4 metricas principales
  Widget _buildMetricasGrid(BuildContext context, MetricasModel metricas) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: DesignTokens.spacingS,
      crossAxisSpacing: DesignTokens.spacingS,
      childAspectRatio: 1.6,
      children: [
        _MetricaCard(
          titulo: 'Goles',
          valor: '${metricas.golesTotales}',
          icono: Icons.sports_soccer,
          color: DesignTokens.primaryColor,
        ),
        _MetricaCard(
          titulo: 'Puntos',
          valor: '${metricas.puntosAcumulados}',
          icono: Icons.star,
          color: DesignTokens.accentColor,
        ),
        _MetricaCard(
          titulo: 'Pichangas',
          valor: '${metricas.fechasAsistidas}',
          icono: Icons.calendar_today,
          color: Colors.teal,
        ),
        _MetricaCard(
          titulo: 'Partidos',
          valor: '${metricas.partidosJugados}',
          icono: Icons.sports,
          color: Colors.indigo,
        ),
      ],
    );
  }

  /// CA-003: Rankings
  Widget _buildRankingsCard(BuildContext context, RankingsModel rankings) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events, size: 20, color: DesignTokens.accentColor),
                const SizedBox(width: DesignTokens.spacingS),
                Text(
                  'Mi Posicion en Rankings',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: DesignTokens.fontWeightSemiBold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.spacingM),
            Row(
              children: [
                Expanded(
                  child: _RankingItem(
                    titulo: 'Goleadores',
                    posicion: rankings.goleadores,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: colorScheme.outlineVariant,
                ),
                Expanded(
                  child: _RankingItem(
                    titulo: 'Puntos',
                    posicion: rankings.puntos,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// CA-004: Promedio de goles
  Widget _buildPromedioCard(BuildContext context, PromedioModel promedio) {
    final colorScheme = Theme.of(context).colorScheme;
    final esPositivo = promedio.mejorQueGrupo;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, size: 20, color: DesignTokens.primaryColor),
                const SizedBox(width: DesignTokens.spacingS),
                Text(
                  'Promedio de Goles',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: DesignTokens.fontWeightSemiBold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.spacingM),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      promedio.golesPorPartido.toStringAsFixed(2),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: DesignTokens.fontWeightBold,
                            color: DesignTokens.primaryColor,
                          ),
                    ),
                    Text(
                      'Mis goles/partido',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.spacingS,
                    vertical: DesignTokens.spacingXxs,
                  ),
                  decoration: BoxDecoration(
                    color: (esPositivo ? Colors.green : Colors.orange).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        esPositivo ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 14,
                        color: esPositivo ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${promedio.diferencia.abs().toStringAsFixed(2)} vs grupo',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: esPositivo ? Colors.green : Colors.orange,
                              fontWeight: DesignTokens.fontWeightMedium,
                            ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Text(
                      promedio.promedioGrupo.toStringAsFixed(2),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: DesignTokens.fontWeightBold,
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                    Text(
                      'Promedio grupo',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// CA-007: Racha de asistencia
  Widget _buildRachaCard(BuildContext context, int racha) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: ListTile(
        leading: Icon(Icons.local_fire_department, color: Colors.deepOrange, size: 28),
        title: Text(
          '$racha pichangas consecutivas',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: DesignTokens.fontWeightSemiBold,
              ),
        ),
        subtitle: Text(
          'Racha de asistencia',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
      ),
    );
  }

  /// CA-006: Mejor fecha destacada
  Widget _buildMejorFechaCard(BuildContext context, MejorFechaModel mejor) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: DesignTokens.accentColor.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        side: BorderSide(color: DesignTokens.accentColor.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.military_tech, size: 20, color: DesignTokens.accentColor),
                const SizedBox(width: DesignTokens.spacingS),
                Text(
                  'Mejor Fecha',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: DesignTokens.fontWeightSemiBold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.spacingS),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${mejor.fechaFormato} - ${mejor.lugar}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: DesignTokens.spacingXxs),
                      Text(
                        'Equipo ${mejor.equipo} - ${mejor.resultado}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.spacingM,
                    vertical: DesignTokens.spacingS,
                  ),
                  decoration: BoxDecoration(
                    color: DesignTokens.accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${mejor.goles}',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: DesignTokens.fontWeightBold,
                              color: DesignTokens.accentColor,
                            ),
                      ),
                      Text(
                        'goles',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: DesignTokens.accentColor,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// CA-005: Historial
  Widget _buildHistorialSection(BuildContext context, List<HistorialFechaModel> historial) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: DesignTokens.spacingS),
          child: Text(
            'Historial de Pichangas',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: DesignTokens.fontWeightSemiBold,
                ),
          ),
        ),
        ...historial.map((item) => _HistorialTile(item: item)),
      ],
    );
  }

  Widget _buildUpgradeHint(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: DesignTokens.accentColor.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        side: BorderSide(color: DesignTokens.accentColor.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingM),
        child: Row(
          children: [
            Icon(Icons.lock_outline, color: DesignTokens.accentColor),
            const SizedBox(width: DesignTokens.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estadisticas avanzadas',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: DesignTokens.fontWeightSemiBold,
                        ),
                  ),
                  Text(
                    'Rankings, promedios, rachas y mas disponibles desde Plan 5',
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

/// Widget para cada metrica del grid
class _MetricaCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icono;
  final Color color;

  const _MetricaCard({
    required this.titulo,
    required this.valor,
    required this.icono,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icono, size: 18, color: color),
                const Spacer(),
                Text(
                  valor,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: DesignTokens.fontWeightBold,
                        color: color,
                      ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.spacingXxs),
            Text(
              titulo,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget para ranking individual
class _RankingItem extends StatelessWidget {
  final String titulo;
  final RankingPosicionModel posicion;

  const _RankingItem({
    required this.titulo,
    required this.posicion,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          posicion.displayText,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: DesignTokens.fontWeightBold,
                color: posicion.sinClasificar
                    ? colorScheme.onSurfaceVariant
                    : DesignTokens.primaryColor,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: DesignTokens.spacingXxs),
        Text(
          titulo,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Widget para item del historial
class _HistorialTile extends StatelessWidget {
  final HistorialFechaModel item;

  const _HistorialTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      margin: const EdgeInsets.only(bottom: DesignTokens.spacingXs),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingM,
          vertical: DesignTokens.spacingS,
        ),
        child: Row(
          children: [
            // Fecha y lugar
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.fechaFormato,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: DesignTokens.fontWeightMedium,
                        ),
                  ),
                  Text(
                    item.lugar,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                  if (item.equipo != null)
                    Text(
                      '${item.equipo} - ${item.resultado}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                ],
              ),
            ),
            // Goles
            Column(
              children: [
                Text(
                  '${item.goles}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: DesignTokens.fontWeightBold,
                        color: DesignTokens.primaryColor,
                      ),
                ),
                Text(
                  'goles',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            const SizedBox(width: DesignTokens.spacingM),
            // Puntos
            Column(
              children: [
                Text(
                  '${item.puntos}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: DesignTokens.fontWeightBold,
                        color: DesignTokens.accentColor,
                      ),
                ),
                Text(
                  'pts',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
