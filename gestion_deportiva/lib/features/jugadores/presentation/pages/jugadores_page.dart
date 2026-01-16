import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/dashboard_shell.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../data/models/jugador_model.dart';
import '../bloc/jugadores/jugadores.dart';
import '../widgets/widgets.dart';

/// Pagina de lista de jugadores
/// E002-HU-003: Lista de Jugadores
/// Usa ResponsiveLayout: Mobile App Style + Desktop Dashboard Style
class JugadoresPage extends StatelessWidget {
  const JugadoresPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<JugadoresBloc, JugadoresState>(
      builder: (context, state) {
        if (state is JugadoresLoading) {
          return const _LoadingView();
        }

        if (state is JugadoresError) {
          return _ErrorView(
            message: state.message,
            onRetry: () {
              context.read<JugadoresBloc>().add(const CargarJugadoresEvent());
            },
          );
        }

        // Obtener datos del estado
        final jugadores = _obtenerJugadores(state);
        final filtros = _obtenerFiltros(state);
        final isLoading = state is JugadoresRefreshing || state is JugadoresBuscando;
        final isEmpty = state is JugadoresVacio;

        return ResponsiveLayout(
          mobileBody: _MobileJugadoresView(
            jugadores: jugadores,
            filtros: filtros,
            isLoading: isLoading,
            isEmpty: isEmpty,
          ),
          desktopBody: _DesktopJugadoresView(
            jugadores: jugadores,
            filtros: filtros,
            isLoading: isLoading,
            isEmpty: isEmpty,
          ),
        );
      },
    );
  }

  List<JugadorModel> _obtenerJugadores(JugadoresState state) {
    if (state is JugadoresLoaded) return state.jugadores;
    if (state is JugadoresRefreshing) return state.jugadoresActuales;
    if (state is JugadoresBuscando) return state.jugadoresActuales;
    return [];
  }

  FiltrosJugadores _obtenerFiltros(JugadoresState state) {
    if (state is JugadoresLoaded) return state.filtros;
    if (state is JugadoresRefreshing) return state.filtros;
    if (state is JugadoresBuscando) return state.filtros;
    if (state is JugadoresVacio) return state.filtros;
    return const FiltrosJugadores();
  }
}

// ============================================
// VISTA MOBILE - App Style
// ============================================

class _MobileJugadoresView extends StatelessWidget {
  final List<JugadorModel> jugadores;
  final FiltrosJugadores filtros;
  final bool isLoading;
  final bool isEmpty;

  const _MobileJugadoresView({
    required this.jugadores,
    required this.filtros,
    required this.isLoading,
    required this.isEmpty,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jugadores'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Barra de busqueda y filtros
          _buildSearchAndFilters(context),

          // Lista de jugadores
          Expanded(
            child: isEmpty
                ? JugadoresEmptyState(
                    tieneBusqueda: filtros.busqueda?.isNotEmpty ?? false,
                    onLimpiarBusqueda: () {
                      context.read<JugadoresBloc>().add(const LimpiarBusquedaEvent());
                    },
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      context.read<JugadoresBloc>().add(const RefrescarJugadoresEvent());
                    },
                    child: Stack(
                      children: [
                        ListView.separated(
                          padding: const EdgeInsets.all(DesignTokens.spacingM),
                          itemCount: jugadores.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: DesignTokens.spacingS),
                          itemBuilder: (context, index) {
                            final jugador = jugadores[index];
                            return JugadorCard(jugador: jugador);
                          },
                        ),
                        if (isLoading)
                          const Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: LinearProgressIndicator(),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 2),
    );
  }

  Widget _buildSearchAndFilters(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Column(
        children: [
          // Barra de busqueda (CA-003)
          JugadoresSearchBar(
            valorInicial: filtros.busqueda,
            onBuscar: (valor) {
              context.read<JugadoresBloc>().add(BuscarJugadoresEvent(valor));
            },
            onLimpiar: () {
              context.read<JugadoresBloc>().add(const LimpiarBusquedaEvent());
            },
          ),
          const SizedBox(height: DesignTokens.spacingS),

          // Ordenamiento (CA-004)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${jugadores.length} jugador${jugadores.length != 1 ? 'es' : ''}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              JugadoresSortButton(
                ordenCampo: filtros.ordenCampo,
                ordenDireccion: filtros.ordenDireccion,
                onCambiarCampo: (campo) {
                  context.read<JugadoresBloc>().add(CambiarOrdenEvent(ordenCampo: campo));
                },
                onAlternarDireccion: () {
                  context.read<JugadoresBloc>().add(const AlternarDireccionOrdenEvent());
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================
// VISTA DESKTOP - Dashboard Style
// ============================================

class _DesktopJugadoresView extends StatelessWidget {
  final List<JugadorModel> jugadores;
  final FiltrosJugadores filtros;
  final bool isLoading;
  final bool isEmpty;

  const _DesktopJugadoresView({
    required this.jugadores,
    required this.filtros,
    required this.isLoading,
    required this.isEmpty,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardShell(
      currentRoute: '/jugadores',
      title: 'Jugadores',
      breadcrumbs: const ['Inicio', 'Jugadores'],
      child: Column(
        children: [
          // Barra de busqueda y filtros
          _buildSearchAndFilters(context),

          // Lista de jugadores
          Expanded(
            child: isEmpty
                ? JugadoresEmptyState(
                    tieneBusqueda: filtros.busqueda?.isNotEmpty ?? false,
                    onLimpiarBusqueda: () {
                      context.read<JugadoresBloc>().add(const LimpiarBusquedaEvent());
                    },
                  )
                : Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(DesignTokens.spacingL),
                        child: _buildJugadoresGrid(context),
                      ),
                      if (isLoading)
                        const Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: LinearProgressIndicator(),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingL,
        vertical: DesignTokens.spacingM,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          // Barra de busqueda (CA-003)
          Expanded(
            flex: 2,
            child: JugadoresSearchBar(
              valorInicial: filtros.busqueda,
              onBuscar: (valor) {
                context.read<JugadoresBloc>().add(BuscarJugadoresEvent(valor));
              },
              onLimpiar: () {
                context.read<JugadoresBloc>().add(const LimpiarBusquedaEvent());
              },
            ),
          ),

          const SizedBox(width: DesignTokens.spacingL),

          // Contador
          Text(
            '${jugadores.length} jugador${jugadores.length != 1 ? 'es' : ''}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(width: DesignTokens.spacingL),

          // Ordenamiento (CA-004)
          JugadoresSortButton(
            ordenCampo: filtros.ordenCampo,
            ordenDireccion: filtros.ordenDireccion,
            onCambiarCampo: (campo) {
              context.read<JugadoresBloc>().add(CambiarOrdenEvent(ordenCampo: campo));
            },
            onAlternarDireccion: () {
              context.read<JugadoresBloc>().add(const AlternarDireccionOrdenEvent());
            },
          ),

          const SizedBox(width: DesignTokens.spacingS),

          // Boton refrescar
          IconButton(
            onPressed: () {
              context.read<JugadoresBloc>().add(const RefrescarJugadoresEvent());
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Refrescar lista',
          ),
        ],
      ),
    );
  }

  Widget _buildJugadoresGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calcular columnas basado en el ancho disponible
        final columns = (constraints.maxWidth / 400).floor().clamp(1, 3);

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: DesignTokens.spacingM,
            crossAxisSpacing: DesignTokens.spacingM,
            mainAxisExtent: 88, // Altura fija del card
          ),
          itemCount: jugadores.length,
          itemBuilder: (context, index) {
            final jugador = jugadores[index];
            return JugadorCard(jugador: jugador);
          },
        );
      },
    );
  }
}

// ============================================
// WIDGETS AUXILIARES
// ============================================

/// Vista de carga
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

/// Vista de error
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.spacingXl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: DesignTokens.iconSizeXxl,
                color: colorScheme.error,
              ),
              const SizedBox(height: DesignTokens.spacingM),
              Text(
                'Error al cargar jugadores',
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.error,
                ),
                textAlign: TextAlign.center,
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
        ),
      ),
    );
  }
}
