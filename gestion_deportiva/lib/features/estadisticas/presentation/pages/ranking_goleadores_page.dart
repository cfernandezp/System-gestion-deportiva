import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/dashboard_shell.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../auth/presentation/bloc/session/session.dart';
import '../../data/models/models.dart';
import '../bloc/ranking_goleadores/ranking_goleadores.dart';
import '../widgets/widgets.dart';

/// Pagina del Ranking de Goleadores
/// E006-HU-001: Ranking de Goleadores
///
/// Criterios de Aceptacion implementados:
/// - CA-001: Ranking general visible (lista ordenada por goles)
/// - CA-002: Informacion por jugador (posicion, avatar, apodo, goles, partidos, promedio)
/// - CA-003: Filtro por periodo (Historico, Este ano, Este mes, Ultima fecha)
/// - CA-005: Mi posicion destacada (fila del usuario actual resaltada)
/// - CA-006: Top 3 destacado (Podio con medallas oro, plata, bronce)
/// - CA-007: Ranking vacio (mensaje informativo cuando no hay datos)
class RankingGoleadoresPage extends StatelessWidget {
  const RankingGoleadoresPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RankingGoleadoresBloc, RankingGoleadoresState>(
      builder: (context, state) {
        // Obtener datos del estado
        final ranking = _obtenerRanking(state);
        final top3 = _obtenerTop3(state);
        final restoRanking = _obtenerRestoRanking(state);
        final periodo = _obtenerPeriodo(state);
        final isLoading = state is RankingGoleadoresLoading ||
            state is RankingGoleadoresRefreshing;
        final isEmpty = state is RankingGoleadoresVacio;
        final hasError = state is RankingGoleadoresError;
        final errorMessage = hasError ? state.message : null;
        final mensajeVacio = isEmpty ? state.mensaje : null;
        final tienePodioCompleto = _tienePodioCompleto(state);
        final totalJugadores = _obtenerTotalJugadores(state);

        return ResponsiveLayout(
          mobileBody: _MobileRankingView(
            ranking: ranking,
            top3: top3,
            restoRanking: restoRanking,
            periodo: periodo,
            isLoading: isLoading,
            isEmpty: isEmpty,
            hasError: hasError,
            errorMessage: errorMessage,
            mensajeVacio: mensajeVacio,
            tienePodioCompleto: tienePodioCompleto,
            totalJugadores: totalJugadores,
          ),
          desktopBody: _DesktopRankingView(
            ranking: ranking,
            top3: top3,
            restoRanking: restoRanking,
            periodo: periodo,
            isLoading: isLoading,
            isEmpty: isEmpty,
            hasError: hasError,
            errorMessage: errorMessage,
            mensajeVacio: mensajeVacio,
            tienePodioCompleto: tienePodioCompleto,
            totalJugadores: totalJugadores,
          ),
        );
      },
    );
  }

  List<RankingGoleadorModel> _obtenerRanking(RankingGoleadoresState state) {
    if (state is RankingGoleadoresLoaded) return state.ranking;
    if (state is RankingGoleadoresRefreshing) return state.rankingActual;
    return [];
  }

  List<RankingGoleadorModel> _obtenerTop3(RankingGoleadoresState state) {
    if (state is RankingGoleadoresLoaded) return state.top3;
    return [];
  }

  List<RankingGoleadorModel> _obtenerRestoRanking(RankingGoleadoresState state) {
    if (state is RankingGoleadoresLoaded) return state.restoRanking;
    return [];
  }

  PeriodoRanking _obtenerPeriodo(RankingGoleadoresState state) {
    if (state is RankingGoleadoresLoaded) return state.periodo;
    if (state is RankingGoleadoresLoading) return state.periodo;
    if (state is RankingGoleadoresRefreshing) return state.periodo;
    if (state is RankingGoleadoresVacio) return state.periodo;
    if (state is RankingGoleadoresError) return state.periodo;
    return PeriodoRanking.historico;
  }

  bool _tienePodioCompleto(RankingGoleadoresState state) {
    if (state is RankingGoleadoresLoaded) return state.tienePodioCompleto;
    return false;
  }

  int _obtenerTotalJugadores(RankingGoleadoresState state) {
    if (state is RankingGoleadoresLoaded) return state.totalJugadores;
    return 0;
  }
}

// ============================================
// VISTA MOBILE - App Style
// ============================================

class _MobileRankingView extends StatelessWidget {
  final List<RankingGoleadorModel> ranking;
  final List<RankingGoleadorModel> top3;
  final List<RankingGoleadorModel> restoRanking;
  final PeriodoRanking periodo;
  final bool isLoading;
  final bool isEmpty;
  final bool hasError;
  final String? errorMessage;
  final String? mensajeVacio;
  final bool tienePodioCompleto;
  final int totalJugadores;

  const _MobileRankingView({
    required this.ranking,
    required this.top3,
    required this.restoRanking,
    required this.periodo,
    required this.isLoading,
    required this.isEmpty,
    required this.hasError,
    this.errorMessage,
    this.mensajeVacio,
    required this.tienePodioCompleto,
    required this.totalJugadores,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ranking Goleadores'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              context.read<RankingGoleadoresBloc>().add(const RefrescarRankingEvent());
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar ranking',
          ),
        ],
      ),
      body: Column(
        children: [
          // Selector de periodo (CA-003)
          Container(
            color: colorScheme.surface,
            padding: const EdgeInsets.symmetric(vertical: DesignTokens.spacingS),
            child: PeriodoSelectorWidget(
              periodoActual: periodo,
              isLoading: isLoading,
              onPeriodoChanged: (nuevoPeriodo) {
                context.read<RankingGoleadoresBloc>().add(
                  CambiarPeriodoEvent(nuevoPeriodo),
                );
              },
            ),
          ),

          // Contenido
          Expanded(
            child: _buildContent(context),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildContent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Estado de carga inicial
    if (isLoading && ranking.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Estado de error
    if (hasError && ranking.isEmpty) {
      return _ErrorWidget(
        message: errorMessage ?? 'Error al cargar el ranking',
        onRetry: () {
          context.read<RankingGoleadoresBloc>().add(const CargarRankingEvent());
        },
      );
    }

    // Estado vacio (CA-007)
    if (isEmpty) {
      return _EmptyWidget(mensaje: mensajeVacio ?? 'No hay goles registrados');
    }

    // Obtener ID del usuario actual para destacar su posicion (CA-005)
    final currentUserId = _getCurrentUserId(context);

    // Lista con datos
    return RefreshIndicator(
      onRefresh: () async {
        context.read<RankingGoleadoresBloc>().add(const RefrescarRankingEvent());
      },
      child: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Header con total
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(DesignTokens.spacingM),
                  child: Row(
                    children: [
                      Icon(
                        Icons.sports_soccer,
                        size: DesignTokens.iconSizeS,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: DesignTokens.spacingXs),
                      Text(
                        '$totalJugadores goleador${totalJugadores != 1 ? 'es' : ''}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Podio (CA-006)
              if (tienePodioCompleto)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.spacingM,
                    ),
                    child: PodioGoleadoresWidget(
                      top3: top3,
                      currentUserId: currentUserId,
                    ),
                  ),
                ),

              // Espacio
              if (tienePodioCompleto)
                const SliverToBoxAdapter(
                  child: SizedBox(height: DesignTokens.spacingL),
                ),

              // Resto del ranking (posicion 4+)
              if (restoRanking.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.spacingM,
                    ),
                    child: Text(
                      'Resto del ranking',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: DesignTokens.fontWeightSemiBold,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: DesignTokens.spacingS),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.spacingM,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final goleador = restoRanking[index];
                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: DesignTokens.spacingS,
                          ),
                          child: GoleadorListItem(
                            goleador: goleador,
                            isCurrentUser: goleador.jugadorId == currentUserId,
                          ),
                        );
                      },
                      childCount: restoRanking.length,
                    ),
                  ),
                ),
              ],

              // Si no hay podio completo, mostrar todo el ranking como lista
              if (!tienePodioCompleto && ranking.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.spacingM,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final goleador = ranking[index];
                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: DesignTokens.spacingS,
                          ),
                          child: GoleadorListItem(
                            goleador: goleador,
                            isCurrentUser: goleador.jugadorId == currentUserId,
                          ),
                        );
                      },
                      childCount: ranking.length,
                    ),
                  ),
                ),

              // Espacio final
              const SliverToBoxAdapter(
                child: SizedBox(height: DesignTokens.spacingL),
              ),
            ],
          ),

          // Indicador de carga superpuesto
          if (isLoading && ranking.isNotEmpty)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }

  String? _getCurrentUserId(BuildContext context) {
    final sessionState = context.read<SessionBloc>().state;
    if (sessionState is SessionAuthenticated) {
      return sessionState.usuarioId;
    }
    return null;
  }
}

// ============================================
// VISTA DESKTOP - Dashboard CRM Style
// ============================================

class _DesktopRankingView extends StatelessWidget {
  final List<RankingGoleadorModel> ranking;
  final List<RankingGoleadorModel> top3;
  final List<RankingGoleadorModel> restoRanking;
  final PeriodoRanking periodo;
  final bool isLoading;
  final bool isEmpty;
  final bool hasError;
  final String? errorMessage;
  final String? mensajeVacio;
  final bool tienePodioCompleto;
  final int totalJugadores;

  const _DesktopRankingView({
    required this.ranking,
    required this.top3,
    required this.restoRanking,
    required this.periodo,
    required this.isLoading,
    required this.isEmpty,
    required this.hasError,
    this.errorMessage,
    this.mensajeVacio,
    required this.tienePodioCompleto,
    required this.totalJugadores,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardShell(
      currentRoute: '/ranking-goleadores',
      title: 'Ranking de Goleadores',
      breadcrumbs: const ['Inicio', 'Estadisticas', 'Ranking Goleadores'],
      actions: [
        IconButton(
          onPressed: () {
            context.read<RankingGoleadoresBloc>().add(const RefrescarRankingEvent());
          },
          icon: const Icon(Icons.refresh),
          tooltip: 'Actualizar ranking',
        ),
      ],
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Panel de filtros lateral (320px fijo)
          SizedBox(
            width: 320,
            child: _FilterPanel(
              periodo: periodo,
              isLoading: isLoading,
              totalJugadores: totalJugadores,
            ),
          ),

          // Separador vertical
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),

          // Contenido principal (expandido)
          Expanded(
            child: _MainContent(
              ranking: ranking,
              top3: top3,
              restoRanking: restoRanking,
              isLoading: isLoading,
              isEmpty: isEmpty,
              hasError: hasError,
              errorMessage: errorMessage,
              mensajeVacio: mensajeVacio,
              tienePodioCompleto: tienePodioCompleto,
              totalJugadores: totalJugadores,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// PANEL DE FILTROS (Desktop - 320px)
// ============================================

class _FilterPanel extends StatelessWidget {
  final PeriodoRanking periodo;
  final bool isLoading;
  final int totalJugadores;

  const _FilterPanel({
    required this.periodo,
    required this.isLoading,
    required this.totalJugadores,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del panel
          Text(
            'Ranking de Goleadores',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: DesignTokens.fontWeightSemiBold,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingXs),
          Text(
            'Maximos anotadores del grupo',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: DesignTokens.spacingL),

          // Card de resumen
          AppCard(
            variant: AppCardVariant.outlined,
            padding: const EdgeInsets.all(DesignTokens.spacingM),
            margin: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      size: DesignTokens.iconSizeS,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: DesignTokens.spacingS),
                    Text(
                      'RESUMEN',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: DesignTokens.fontWeightSemiBold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.spacingM),

                // Metrica: Total goleadores
                _MetricTile(
                  icon: Icons.sports_soccer,
                  label: 'Goleadores',
                  value: totalJugadores,
                  color: colorScheme.primary,
                ),

                const SizedBox(height: DesignTokens.spacingS),

                // Metrica: Periodo actual
                Container(
                  padding: const EdgeInsets.all(DesignTokens.spacingS),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.date_range,
                        size: DesignTokens.iconSizeS,
                        color: colorScheme.secondary,
                      ),
                      const SizedBox(width: DesignTokens.spacingS),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Periodo',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              periodo.displayName,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: DesignTokens.fontWeightMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: DesignTokens.spacingL),

          // Selector de periodo (CA-003)
          PeriodoSelectorCompact(
            periodoActual: periodo,
            isLoading: isLoading,
            onPeriodoChanged: (nuevoPeriodo) {
              context.read<RankingGoleadoresBloc>().add(
                CambiarPeriodoEvent(nuevoPeriodo),
              );
            },
          ),

          const SizedBox(height: DesignTokens.spacingL),

          // Leyenda de medallas
          Text(
            'MEDALLAS',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: DesignTokens.fontWeightSemiBold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingS),
          _MedallaLegend(),
        ],
      ),
    );
  }
}

// ============================================
// CONTENIDO PRINCIPAL (Desktop)
// ============================================

class _MainContent extends StatelessWidget {
  final List<RankingGoleadorModel> ranking;
  final List<RankingGoleadorModel> top3;
  final List<RankingGoleadorModel> restoRanking;
  final bool isLoading;
  final bool isEmpty;
  final bool hasError;
  final String? errorMessage;
  final String? mensajeVacio;
  final bool tienePodioCompleto;
  final int totalJugadores;

  const _MainContent({
    required this.ranking,
    required this.top3,
    required this.restoRanking,
    required this.isLoading,
    required this.isEmpty,
    required this.hasError,
    this.errorMessage,
    this.mensajeVacio,
    required this.tienePodioCompleto,
    required this.totalJugadores,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Estado de carga inicial
    if (isLoading && ranking.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Estado de error
    if (hasError && ranking.isEmpty) {
      return Center(
        child: _ErrorWidget(
          message: errorMessage ?? 'Error al cargar el ranking',
          onRetry: () {
            context.read<RankingGoleadoresBloc>().add(const CargarRankingEvent());
          },
        ),
      );
    }

    // Estado vacio (CA-007)
    if (isEmpty) {
      return Center(
        child: _EmptyWidget(mensaje: mensajeVacio ?? 'No hay goles registrados'),
      );
    }

    // Obtener ID del usuario actual para destacar su posicion (CA-005)
    final currentUserId = _getCurrentUserId(context);

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(DesignTokens.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tabla de Goleadores',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: DesignTokens.fontWeightSemiBold,
                          ),
                        ),
                        const SizedBox(height: DesignTokens.spacingXxs),
                        Text(
                          'Jugadores ordenados por cantidad de goles',
                          style: textTheme.bodySmall?.copyWith(
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
                      color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.sports_soccer,
                          size: DesignTokens.iconSizeS,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: DesignTokens.spacingXs),
                        Text(
                          '$totalJugadores goleador${totalJugadores != 1 ? 'es' : ''}',
                          style: textTheme.labelMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: DesignTokens.fontWeightMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: DesignTokens.spacingL),

              // Podio (CA-006)
              if (tienePodioCompleto) ...[
                PodioGoleadoresWidget(
                  top3: top3,
                  currentUserId: currentUserId,
                ),
                const SizedBox(height: DesignTokens.spacingXl),
              ],

              // Tabla del resto del ranking
              if (restoRanking.isNotEmpty || !tienePodioCompleto) ...[
                Text(
                  tienePodioCompleto ? 'Resto del ranking' : 'Ranking completo',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: DesignTokens.fontWeightSemiBold,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: DesignTokens.spacingM),

                // Tabla de datos
                AppCard(
                  variant: AppCardVariant.outlined,
                  padding: EdgeInsets.zero,
                  margin: EdgeInsets.zero,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                    child: _RankingDataTable(
                      goleadores: tienePodioCompleto ? restoRanking : ranking,
                      currentUserId: currentUserId,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Indicador de carga superpuesto
        if (isLoading && ranking.isNotEmpty)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(),
          ),
      ],
    );
  }

  String? _getCurrentUserId(BuildContext context) {
    final sessionState = context.read<SessionBloc>().state;
    if (sessionState is SessionAuthenticated) {
      return sessionState.usuarioId;
    }
    return null;
  }
}

// ============================================
// TABLA DE DATOS DEL RANKING
// ============================================

class _RankingDataTable extends StatelessWidget {
  final List<RankingGoleadorModel> goleadores;
  final String? currentUserId;

  const _RankingDataTable({
    required this.goleadores,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DataTable(
      headingRowColor: WidgetStateProperty.all(
        colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      ),
      columns: const [
        DataColumn(label: Text('#')),
        DataColumn(label: Text('Jugador')),
        DataColumn(label: Text('Goles'), numeric: true),
        DataColumn(label: Text('Partidos'), numeric: true),
        DataColumn(label: Text('Promedio'), numeric: true),
      ],
      rows: goleadores.map((goleador) {
        final isCurrentUser = goleador.jugadorId == currentUserId;

        return DataRow(
          color: isCurrentUser
              ? WidgetStateProperty.all(
                  colorScheme.primaryContainer.withValues(alpha: 0.3),
                )
              : null,
          cells: [
            // Posicion
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacingS,
                  vertical: DesignTokens.spacingXxs,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusXs),
                ),
                child: Text(
                  '#${goleador.posicion}',
                  style: TextStyle(
                    fontWeight: DesignTokens.fontWeightBold,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),

            // Jugador (avatar + nombre)
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Avatar
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.primaryContainer,
                      border: isCurrentUser
                          ? Border.all(color: colorScheme.primary, width: 2)
                          : null,
                    ),
                    child: ClipOval(
                      child: goleador.tieneAvatar
                          ? Image.network(
                              goleador.avatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                child: Text(
                                  goleador.iniciales,
                                  style: TextStyle(
                                    fontSize: DesignTokens.fontSizeXs,
                                    fontWeight: DesignTokens.fontWeightBold,
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                goleador.iniciales,
                                style: TextStyle(
                                  fontSize: DesignTokens.fontSizeXs,
                                  fontWeight: DesignTokens.fontWeightBold,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spacingS),
                  // Nombre
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 150),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            goleador.apodo,
                            style: TextStyle(
                              fontWeight: DesignTokens.fontWeightMedium,
                              color: isCurrentUser
                                  ? colorScheme.primary
                                  : colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCurrentUser) ...[
                          const SizedBox(width: DesignTokens.spacingXs),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: DesignTokens.spacingXs,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                            ),
                            child: Text(
                              'Tu',
                              style: TextStyle(
                                fontSize: 10,
                                color: colorScheme.onPrimary,
                                fontWeight: DesignTokens.fontWeightBold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Goles
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.sports_soccer,
                    size: DesignTokens.iconSizeS - 2,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: DesignTokens.spacingXxs),
                  Text(
                    '${goleador.goles}',
                    style: TextStyle(
                      fontWeight: DesignTokens.fontWeightBold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),

            // Partidos
            DataCell(
              Text(
                '${goleador.partidosJugados}',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),

            // Promedio
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacingS,
                  vertical: DesignTokens.spacingXxs,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                ),
                child: Text(
                  goleador.promedioFormateado,
                  style: TextStyle(
                    fontWeight: DesignTokens.fontWeightMedium,
                    color: colorScheme.secondary,
                  ),
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

// ============================================
// WIDGETS AUXILIARES
// ============================================

/// Widget de error
class _ErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorWidget({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(DesignTokens.spacingXl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: DesignTokens.iconSizeXl,
            color: colorScheme.error,
          ),
          const SizedBox(height: DesignTokens.spacingM),
          Text(
            'Error al cargar',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: DesignTokens.fontWeightSemiBold,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingS),
          Text(
            message,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DesignTokens.spacingL),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

/// Widget de estado vacio (CA-007)
class _EmptyWidget extends StatelessWidget {
  final String mensaje;

  const _EmptyWidget({required this.mensaje});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(DesignTokens.spacingXl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.sports_soccer_outlined,
              size: DesignTokens.iconSizeXl,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingL),
          Text(
            'Sin goleadores',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: DesignTokens.fontWeightSemiBold,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingS),
          Text(
            mensaje,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DesignTokens.spacingM),
          Text(
            'Prueba seleccionando otro periodo',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tile de metrica para el panel
class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingS),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
      ),
      child: Row(
        children: [
          Icon(icon, size: DesignTokens.iconSizeM, color: color),
          const SizedBox(width: DesignTokens.spacingS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  value.toString(),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: DesignTokens.fontWeightBold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Leyenda de medallas
class _MedallaLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MedallaLegendItem(
          color: const Color(0xFFFFD700),
          label: '1ro - Oro',
        ),
        const SizedBox(height: DesignTokens.spacingXs),
        _MedallaLegendItem(
          color: const Color(0xFFC0C0C0),
          label: '2do - Plata',
        ),
        const SizedBox(height: DesignTokens.spacingXs),
        _MedallaLegendItem(
          color: const Color(0xFFCD7F32),
          label: '3ro - Bronce',
        ),
      ],
    );
  }
}

class _MedallaLegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _MedallaLegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        const SizedBox(width: DesignTokens.spacingS),
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
