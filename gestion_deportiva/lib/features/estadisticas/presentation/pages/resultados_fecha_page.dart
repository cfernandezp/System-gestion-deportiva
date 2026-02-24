import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../data/models/resultados_fecha_model.dart';
import '../bloc/resultados_fecha/resultados_fecha.dart';

/// E006-HU-004: Pagina de Resultados por Fecha
/// CA-001: Lista de fechas finalizadas
/// CA-007: Filtros (Plan 5+)
/// CA-008: Empty state
class ResultadosFechaPage extends StatelessWidget {
  const ResultadosFechaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados por Fecha'),
        centerTitle: true,
      ),
      body: BlocBuilder<ResultadosFechaBloc, ResultadosFechaState>(
        builder: (context, state) {
          if (state is ResultadosFechaLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ResultadosFechaError) {
            return _buildError(context, state);
          }

          if (state is HistorialFechasLoaded) {
            return _buildContent(context, state);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildError(BuildContext context, ResultadosFechaError state) {
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

  Widget _buildContent(BuildContext context, HistorialFechasLoaded state) {
    final historial = state.historial;

    return Column(
      children: [
        // CA-007: Filtros (solo Plan 5+)
        if (historial.statsAvanzadas && historial.filtros != null)
          _buildFiltros(context, state),

        // CA-001: Lista de fechas o CA-008: Empty state
        Expanded(
          child: historial.estaVacio
              ? _buildEmptyState(context)
              : _buildListaFechas(context, historial.fechas),
        ),
      ],
    );
  }

  /// CA-007: Filtros de ano, mes y "Mis fechas"
  Widget _buildFiltros(BuildContext context, HistorialFechasLoaded state) {
    final filtros = state.historial.filtros!;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingM,
        vertical: DesignTokens.spacingS,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Filtro ano
            if (filtros.anios.isNotEmpty)
              _FiltroDropdown(
                label: 'Ano',
                valor: state.anioActual,
                opciones: filtros.anios,
                onChanged: (anio) {
                  context.read<ResultadosFechaBloc>().add(
                        CambiarFiltroEvent(anio: anio),
                      );
                },
              ),
            const SizedBox(width: DesignTokens.spacingS),

            // Filtro mes
            if (filtros.meses.isNotEmpty)
              _FiltroMesDropdown(
                valor: state.mesActual,
                mesesDisponibles: filtros.meses,
                onChanged: (mes) {
                  context.read<ResultadosFechaBloc>().add(
                        CambiarFiltroEvent(mes: mes),
                      );
                },
              ),
            const SizedBox(width: DesignTokens.spacingS),

            // Filtro "Mis fechas"
            FilterChip(
              label: const Text('Mis fechas'),
              selected: state.soloMias,
              onSelected: (value) {
                context.read<ResultadosFechaBloc>().add(
                      CambiarFiltroEvent(soloMias: value),
                    );
              },
              selectedColor: DesignTokens.primaryColor.withValues(alpha: 0.15),
              checkmarkColor: DesignTokens.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  /// CA-008: Sin fechas finalizadas
  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: DesignTokens.spacingM),
            Text(
              'No hay fechas finalizadas aun',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: DesignTokens.spacingS),
            Text(
              'Los resultados apareceran cuando se finalicen las pichangas',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  /// CA-001: Lista de fechas finalizadas
  Widget _buildListaFechas(
      BuildContext context, List<FechaHistorialModel> fechas) {
    return RefreshIndicator(
      onRefresh: () async {
        // El bloc tiene el grupoId guardado internamente
        // Se re-carga con los filtros actuales del state
        final bloc = context.read<ResultadosFechaBloc>();
        final currentState = bloc.state;
        if (currentState is HistorialFechasLoaded) {
          bloc.add(CambiarFiltroEvent(
            anio: currentState.anioActual,
            mes: currentState.mesActual,
            soloMias: currentState.soloMias,
          ));
        }
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(DesignTokens.spacingM),
        itemCount: fechas.length,
        separatorBuilder: (_, __) =>
            const SizedBox(height: DesignTokens.spacingS),
        itemBuilder: (context, index) {
          final fecha = fechas[index];
          return _FechaCard(
            fecha: fecha,
            onTap: () => context.push('/resultados-fecha/${fecha.fechaId}'),
          );
        },
      ),
    );
  }
}

/// Card de una fecha en el historial
class _FechaCard extends StatelessWidget {
  final FechaHistorialModel fecha;
  final VoidCallback onTap;

  const _FechaCard({
    required this.fecha,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.spacingM),
          child: Row(
            children: [
              // Icono de fecha
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color:
                      DesignTokens.primaryColor.withValues(alpha: 0.12),
                  borderRadius:
                      BorderRadius.circular(DesignTokens.radiusS),
                ),
                child: const Icon(
                  Icons.sports_soccer,
                  color: DesignTokens.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: DesignTokens.spacingM),

              // Info de la fecha
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fecha.fechaFormato,
                      style:
                          Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: DesignTokens.fontWeightMedium,
                              ),
                    ),
                    const SizedBox(height: DesignTokens.spacingXxs),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: DesignTokens.spacingXxs),
                        Expanded(
                          child: Text(
                            fecha.lugar,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: DesignTokens.spacingXxs),
                    Row(
                      children: [
                        _InfoBadge(
                          icon: Icons.people_outline,
                          text: '${fecha.totalAsistentes}',
                        ),
                        const SizedBox(width: DesignTokens.spacingS),
                        _InfoBadge(
                          icon: Icons.sports,
                          text:
                              '${fecha.totalPartidos} ${fecha.totalPartidos == 1 ? 'partido' : 'partidos'}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Chevron
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Badge pequeno con icono y texto
class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoBadge({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: DesignTokens.spacingXxs),
        Text(
          text,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

/// Dropdown para filtro de ano
class _FiltroDropdown extends StatelessWidget {
  final String label;
  final int? valor;
  final List<int> opciones;
  final ValueChanged<int?> onChanged;

  const _FiltroDropdown({
    required this.label,
    required this.valor,
    required this.opciones,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingS,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: valor,
          hint: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium,
          ),
          isDense: true,
          items: [
            DropdownMenuItem<int?>(
              value: null,
              child: Text('Todos', style: Theme.of(context).textTheme.labelMedium),
            ),
            ...opciones.map((anio) => DropdownMenuItem<int?>(
                  value: anio,
                  child: Text('$anio',
                      style: Theme.of(context).textTheme.labelMedium),
                )),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/// Dropdown para filtro de mes con nombres en espanol
class _FiltroMesDropdown extends StatelessWidget {
  final int? valor;
  final List<int> mesesDisponibles;
  final ValueChanged<int?> onChanged;

  const _FiltroMesDropdown({
    required this.valor,
    required this.mesesDisponibles,
    required this.onChanged,
  });

  static const Map<int, String> _nombresMeses = {
    1: 'Enero',
    2: 'Febrero',
    3: 'Marzo',
    4: 'Abril',
    5: 'Mayo',
    6: 'Junio',
    7: 'Julio',
    8: 'Agosto',
    9: 'Septiembre',
    10: 'Octubre',
    11: 'Noviembre',
    12: 'Diciembre',
  };

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingS,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: valor,
          hint: Text(
            'Mes',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          isDense: true,
          items: [
            DropdownMenuItem<int?>(
              value: null,
              child: Text('Todos', style: Theme.of(context).textTheme.labelMedium),
            ),
            ...mesesDisponibles.map((mes) => DropdownMenuItem<int?>(
                  value: mes,
                  child: Text(
                    _nombresMeses[mes] ?? '$mes',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                )),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
