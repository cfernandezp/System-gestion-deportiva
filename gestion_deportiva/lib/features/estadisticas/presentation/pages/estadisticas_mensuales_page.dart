import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../grupos/presentation/cubit/grupo_actual_cubit.dart';
import '../../data/models/estadisticas_mensuales_model.dart';
import '../bloc/estadisticas_mensuales/estadisticas_mensuales.dart';
import '../../../upgrade/presentation/models/upgrade_reason.dart';

/// E006-HU-005: Pagina de Estadisticas Mensuales
/// Muestra estadisticas agregadas por mes del grupo
class EstadisticasMensualesPage extends StatelessWidget {
  const EstadisticasMensualesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadisticas Mensuales'),
        centerTitle: true,
      ),
      body: BlocConsumer<EstadisticasMensualesBloc, EstadisticasMensualesState>(
        listener: (context, state) {
          // RN-008: Si error con hint plan_gratis, redirigir a upgrade
          if (state is EstadisticasMensualesError && state.hint == 'plan_gratis') {
            context.push(
              '/upgrade',
              extra: const UpgradeReason.feature('Estadisticas Mensuales'),
            );
          }
        },
        builder: (context, state) {
          if (state is EstadisticasMensualesLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is EstadisticasMensualesError) {
            // RN-008: No mostrar error si es plan_gratis (el listener ya redirige)
            if (state.hint == 'plan_gratis') {
              return const SizedBox.shrink();
            }
            return _buildError(context, state);
          }

          if (state is EstadisticasMensualesLoaded) {
            return _buildContent(context, state);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildError(BuildContext context, EstadisticasMensualesError state) {
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

  Widget _buildContent(BuildContext context, EstadisticasMensualesLoaded state) {
    final stats = state.estadisticas;

    return ListView(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      children: [
        // CA-001: Selector de mes
        _buildSelectorMes(context, stats, state.anioSeleccionado, state.mesSeleccionado),
        const SizedBox(height: DesignTokens.spacingM),

        // CA-008: Sin actividad
        if (!stats.tieneActividad) ...[
          _buildSinActividad(context, stats, state.anioSeleccionado, state.mesSeleccionado),
        ] else ...[
          // CA-002: Resumen del mes
          _buildResumenGrid(context, stats.resumen),
          const SizedBox(height: DesignTokens.spacingM),

          // CA-003: Goleador del mes
          if (stats.goleadorMes.isNotEmpty) ...[
            _buildGoleadorMes(context, stats.goleadorMes),
            const SizedBox(height: DesignTokens.spacingM),
          ],

          // CA-006: Jugador mas constante
          if (stats.jugadorConstante != null) ...[
            _buildJugadorConstante(context, stats.jugadorConstante!),
            const SizedBox(height: DesignTokens.spacingM),
          ],

          // CA-004: Rankings mensuales
          if (stats.rankingGoleadores.isNotEmpty || stats.rankingPuntos.isNotEmpty) ...[
            _buildRankings(context, stats.rankingGoleadores, stats.rankingPuntos),
            const SizedBox(height: DesignTokens.spacingM),
          ],

          // CA-005: Comparativa con mes anterior
          if (stats.comparativa != null) ...[
            _buildComparativa(context, stats.comparativa!),
            const SizedBox(height: DesignTokens.spacingM),
          ],

          // CA-007: Lista de fechas del mes
          if (stats.fechasMes.isNotEmpty) ...[
            _buildFechasMes(context, stats.fechasMes),
          ],
        ],

        const SizedBox(height: DesignTokens.spacingL),
      ],
    );
  }

  /// CA-001: Selector de mes con flechas izq/derecha
  Widget _buildSelectorMes(
    BuildContext context,
    EstadisticasMensualesResponseModel stats,
    int anioActual,
    int mesActual,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final meses = stats.mesesDisponibles;
    final indiceActual = meses.indexWhere(
      (m) => m.anio == anioActual && m.mes == mesActual,
    );

    // Buscar el display text del mes actual
    String mesDisplay;
    if (indiceActual >= 0) {
      mesDisplay = meses[indiceActual].displayText;
    } else {
      // Si el mes actual no esta en la lista, mostrar mes/anio generico
      mesDisplay = _getNombreMes(mesActual, anioActual);
    }

    final puedePrevio = indiceActual < meses.length - 1;
    final puedeSiguiente = indiceActual > 0;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingS,
          vertical: DesignTokens.spacingXs,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: puedePrevio
                  ? () {
                      final previo = meses[indiceActual + 1];
                      _cambiarMes(context, previo.anio, previo.mes);
                    }
                  : null,
            ),
            GestureDetector(
              onTap: meses.length > 1
                  ? () => _showSelectorMesDialog(context, meses, anioActual, mesActual)
                  : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_month,
                    size: 20,
                    color: DesignTokens.primaryColor,
                  ),
                  const SizedBox(width: DesignTokens.spacingS),
                  Text(
                    mesDisplay,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: DesignTokens.fontWeightSemiBold,
                        ),
                  ),
                  if (meses.length > 1) ...[
                    const SizedBox(width: DesignTokens.spacingXs),
                    Icon(
                      Icons.arrow_drop_down,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: puedeSiguiente
                  ? () {
                      final siguiente = meses[indiceActual - 1];
                      _cambiarMes(context, siguiente.anio, siguiente.mes);
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  void _showSelectorMesDialog(
    BuildContext context,
    List<MesDisponibleModel> meses,
    int anioActual,
    int mesActual,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (dialogContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(DesignTokens.spacingM),
                child: Text(
                  'Seleccionar mes',
                  style: Theme.of(dialogContext).textTheme.titleMedium?.copyWith(
                        fontWeight: DesignTokens.fontWeightSemiBold,
                      ),
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: meses.length,
                  itemBuilder: (dialogContext, index) {
                    final mes = meses[index];
                    final isSelected = mes.anio == anioActual && mes.mes == mesActual;
                    return ListTile(
                      title: Text(mes.displayText),
                      trailing: isSelected
                          ? Icon(Icons.check, color: DesignTokens.primaryColor)
                          : null,
                      selected: isSelected,
                      onTap: () {
                        Navigator.of(dialogContext).pop();
                        _cambiarMes(context, mes.anio, mes.mes);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _cambiarMes(BuildContext context, int anio, int mes) {
    final bloc = context.read<EstadisticasMensualesBloc>();
    final state = bloc.state;
    if (state is EstadisticasMensualesLoaded) {
      // Obtener grupoId del evento original; re-trigger con nuevo mes
      // No disponible directamente, usaremos el approach: extraer grupoId del cubit
    }
    // Despachar CambiarMesEvent reusa grupoId desde el router
    bloc.add(CambiarMesEvent(
      grupoId: _getGrupoId(context),
      anio: anio,
      mes: mes,
    ));
  }

  String _getGrupoId(BuildContext context) {
    return sl<GrupoActualCubit>().grupoActual?.grupoId ?? '';
  }

  String _getNombreMes(int mes, int anio) {
    const nombres = [
      '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
    ];
    if (mes >= 1 && mes <= 12) {
      return '${nombres[mes]} $anio';
    }
    return '$mes/$anio';
  }

  /// CA-008: Mes sin actividad
  Widget _buildSinActividad(
    BuildContext context,
    EstadisticasMensualesResponseModel stats,
    int anio,
    int mes,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: DesignTokens.spacingM),
            Text(
              'No hubo actividad en ${_getNombreMes(mes, anio)}',
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

  /// CA-002: Grid de 4 metricas del resumen mensual
  Widget _buildResumenGrid(BuildContext context, ResumenMensualModel resumen) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: DesignTokens.spacingS,
      crossAxisSpacing: DesignTokens.spacingS,
      childAspectRatio: 1.6,
      children: [
        _MetricaCard(
          titulo: 'Pichangas',
          valor: '${resumen.fechasJugadas}',
          icono: Icons.calendar_today,
          color: DesignTokens.primaryColor,
        ),
        _MetricaCard(
          titulo: 'Partidos',
          valor: '${resumen.totalPartidos}',
          icono: Icons.sports,
          color: Colors.indigo,
        ),
        _MetricaCard(
          titulo: 'Goles',
          valor: '${resumen.totalGoles}',
          icono: Icons.sports_soccer,
          color: DesignTokens.accentColor,
        ),
        _MetricaCard(
          titulo: 'Asistentes',
          valor: '${resumen.asistentesUnicos}',
          icono: Icons.group,
          color: Colors.teal,
        ),
      ],
    );
  }

  /// CA-003: Goleador del mes destacado
  Widget _buildGoleadorMes(BuildContext context, List<GoleadorMesModel> goleadores) {
    final colorScheme = Theme.of(context).colorScheme;
    final esCoGoleadores = goleadores.length > 1;

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
                Icon(Icons.emoji_events, size: 20, color: DesignTokens.accentColor),
                const SizedBox(width: DesignTokens.spacingS),
                Text(
                  esCoGoleadores ? 'Co-Goleadores del Mes' : 'Goleador del Mes',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: DesignTokens.fontWeightSemiBold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.spacingM),
            ...goleadores.map((goleador) => Padding(
                  padding: const EdgeInsets.only(bottom: DesignTokens.spacingS),
                  child: Row(
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: DesignTokens.accentColor.withValues(alpha: 0.15),
                        backgroundImage: goleador.fotoUrl != null
                            ? NetworkImage(goleador.fotoUrl!)
                            : null,
                        child: goleador.fotoUrl == null
                            ? Text(
                                goleador.displayName.isNotEmpty
                                    ? goleador.displayName[0].toUpperCase()
                                    : '?',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: DesignTokens.accentColor,
                                      fontWeight: DesignTokens.fontWeightBold,
                                    ),
                              )
                            : null,
                      ),
                      const SizedBox(width: DesignTokens.spacingM),
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              goleador.displayName,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: DesignTokens.fontWeightSemiBold,
                                  ),
                            ),
                            Text(
                              '${goleador.promedioPorFecha.toStringAsFixed(1)} goles/fecha',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      // Goles
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
                              '${goleador.goles}',
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
                )),
          ],
        ),
      ),
    );
  }

  /// CA-006: Jugador mas constante del mes
  Widget _buildJugadorConstante(BuildContext context, JugadorConstanteModel jugador) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        side: BorderSide(color: DesignTokens.primaryColor.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: DesignTokens.primaryColor.withValues(alpha: 0.15),
          child: Icon(
            Icons.calendar_month,
            color: DesignTokens.primaryColor,
            size: 20,
          ),
        ),
        title: Text(
          jugador.displayName,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: DesignTokens.fontWeightSemiBold,
              ),
        ),
        subtitle: Text(
          'Mas constante - ${jugador.fechasAsistidas} pichangas',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingS,
            vertical: DesignTokens.spacingXxs,
          ),
          decoration: BoxDecoration(
            color: DesignTokens.primaryColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, size: 14, color: DesignTokens.primaryColor),
              const SizedBox(width: 4),
              Text(
                '${jugador.fechasAsistidas}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: DesignTokens.primaryColor,
                      fontWeight: DesignTokens.fontWeightBold,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// CA-004: Rankings mensuales (top 5 goleadores y puntos)
  Widget _buildRankings(
    BuildContext context,
    List<RankingMensualItemModel> goleadores,
    List<RankingMensualItemModel> puntos,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (goleadores.isNotEmpty) ...[
          _buildRankingSection(
            context,
            titulo: 'Top 5 Goleadores',
            icono: Icons.sports_soccer,
            items: goleadores,
            esGoles: true,
          ),
          const SizedBox(height: DesignTokens.spacingM),
        ],
        if (puntos.isNotEmpty) ...[
          _buildRankingSection(
            context,
            titulo: 'Top 5 Puntos',
            icono: Icons.star,
            items: puntos,
            esGoles: false,
          ),
        ],
      ],
    );
  }

  Widget _buildRankingSection(
    BuildContext context, {
    required String titulo,
    required IconData icono,
    required List<RankingMensualItemModel> items,
    required bool esGoles,
  }) {
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
                Icon(
                  icono,
                  size: 20,
                  color: esGoles ? DesignTokens.primaryColor : DesignTokens.accentColor,
                ),
                const SizedBox(width: DesignTokens.spacingS),
                Text(
                  titulo,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: DesignTokens.fontWeightSemiBold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.spacingS),
            ...items.asMap().entries.map((entry) {
              final posicion = entry.key + 1;
              final item = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: DesignTokens.spacingXxs),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text(
                        '$posicion.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: DesignTokens.fontWeightBold,
                              color: posicion <= 3
                                  ? DesignTokens.primaryColor
                                  : colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item.displayName,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      '${item.valorPrincipal}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: DesignTokens.fontWeightBold,
                            color: esGoles
                                ? DesignTokens.primaryColor
                                : DesignTokens.accentColor,
                          ),
                    ),
                    const SizedBox(width: DesignTokens.spacingXs),
                    Text(
                      esGoles ? 'goles' : 'pts',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// CA-005: Comparativa con mes anterior
  Widget _buildComparativa(BuildContext context, ComparativaMesModel comparativa) {
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
                Icon(Icons.compare_arrows, size: 20, color: DesignTokens.secondaryColor),
                const SizedBox(width: DesignTokens.spacingS),
                Text(
                  'Comparativa vs mes anterior',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: DesignTokens.fontWeightSemiBold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.spacingM),
            _ComparativaRow(
              label: 'Pichangas',
              actual: comparativa.fechasActual,
              anterior: comparativa.fechasAnterior,
              diferencia: comparativa.difFechas,
              porcentaje: comparativa.porcentajeFechas,
              subio: comparativa.fechasSubieron,
              bajo: comparativa.fechasBajaron,
            ),
            const Divider(height: DesignTokens.spacingM),
            _ComparativaRow(
              label: 'Goles',
              actual: comparativa.golesActual,
              anterior: comparativa.golesAnterior,
              diferencia: comparativa.difGoles,
              porcentaje: comparativa.porcentajeGoles,
              subio: comparativa.golesSubieron,
              bajo: comparativa.golesBajaron,
            ),
            const Divider(height: DesignTokens.spacingM),
            _ComparativaRow(
              label: 'Asistentes',
              actual: comparativa.asistentesActual,
              anterior: comparativa.asistentesAnterior,
              diferencia: comparativa.difAsistentes,
              porcentaje: comparativa.porcentajeAsistentes,
              subio: comparativa.asistentesSubieron,
              bajo: comparativa.asistentesBajaron,
            ),
          ],
        ),
      ),
    );
  }

  /// CA-007: Lista de fechas del mes
  Widget _buildFechasMes(BuildContext context, List<FechaMesModel> fechas) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: DesignTokens.spacingS),
          child: Text(
            'Pichangas del mes',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: DesignTokens.fontWeightSemiBold,
                ),
          ),
        ),
        ...fechas.map((fecha) => _FechaMesTile(fecha: fecha)),
      ],
    );
  }
}

/// Widget para cada metrica del grid (reutilizado del patron de mis_estadisticas)
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

/// Widget para fila de comparativa
class _ComparativaRow extends StatelessWidget {
  final String label;
  final int actual;
  final int anterior;
  final int diferencia;
  final double porcentaje;
  final bool subio;
  final bool bajo;

  const _ComparativaRow({
    required this.label,
    required this.actual,
    required this.anterior,
    required this.diferencia,
    required this.porcentaje,
    required this.subio,
    required this.bajo,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = subio
        ? Colors.green
        : bajo
            ? Colors.red
            : colorScheme.onSurfaceVariant;

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Text(
          '$actual',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: DesignTokens.fontWeightBold,
              ),
        ),
        const SizedBox(width: DesignTokens.spacingS),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingS,
            vertical: DesignTokens.spacingXxs,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (subio || bajo)
                Icon(
                  subio ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 12,
                  color: color,
                ),
              const SizedBox(width: 2),
              Text(
                diferencia == 0
                    ? '='
                    : '${diferencia > 0 ? '+' : ''}${porcentaje.toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: DesignTokens.fontWeightMedium,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Widget para item de fecha del mes
class _FechaMesTile extends StatelessWidget {
  final FechaMesModel fecha;

  const _FechaMesTile({required this.fecha});

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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fecha.fechaFormato,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: DesignTokens.fontWeightMedium,
                        ),
                  ),
                  Text(
                    fecha.lugar,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Text(
                  '${fecha.totalPartidos}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: DesignTokens.fontWeightBold,
                        color: Colors.indigo,
                      ),
                ),
                Text(
                  'partidos',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            const SizedBox(width: DesignTokens.spacingM),
            Column(
              children: [
                Text(
                  '${fecha.totalGoles}',
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
          ],
        ),
      ),
    );
  }
}


