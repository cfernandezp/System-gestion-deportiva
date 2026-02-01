import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/dashboard_shell.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../profile/data/models/perfil_model.dart';
import '../../data/models/jugador_model.dart';
import '../bloc/jugadores/jugadores.dart';
import '../widgets/widgets.dart';

/// Pagina de lista de jugadores
/// E002-HU-003: Lista de Jugadores
/// Estilo: CRM Moderno con layout de 3 columnas en desktop
/// - Sidebar (via DashboardShell)
/// - Panel de filtros lateral (320px)
/// - Tabla de datos expandida
class JugadoresPage extends StatefulWidget {
  const JugadoresPage({super.key});

  @override
  State<JugadoresPage> createState() => _JugadoresPageState();
}

class _JugadoresPageState extends State<JugadoresPage> {
  final _searchController = TextEditingController();
  final _debouncer = _Debouncer(milliseconds: 500);
  PosicionJugador? _filtroPosicion;

  // Estado de paginacion
  int _currentPage = 1;
  int _itemsPerPage = 10;
  static const List<int> _itemsPerPageOptions = [10, 25, 50];

  @override
  void dispose() {
    _searchController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<JugadoresBloc, JugadoresState>(
      builder: (context, state) {
        // Obtener datos del estado
        final jugadores = _obtenerJugadores(state);
        final filtros = _obtenerFiltros(state);
        final isLoading = state is JugadoresLoading ||
            state is JugadoresRefreshing ||
            state is JugadoresBuscando;
        final isEmpty = state is JugadoresVacio;
        final hasError = state is JugadoresError;
        final errorMessage = hasError ? state.message : null;

        // Filtrar por posicion local
        final jugadoresFiltrados = _filtrarPorPosicion(jugadores);

        // Calcular metricas
        final metricas = _calcularMetricas(jugadores);

        // Calcular paginacion
        final totalPages = (jugadoresFiltrados.length / _itemsPerPage).ceil();
        final startIndex = (_currentPage - 1) * _itemsPerPage;
        final endIndex = startIndex + _itemsPerPage > jugadoresFiltrados.length
            ? jugadoresFiltrados.length
            : startIndex + _itemsPerPage;
        final jugadoresPaginados = jugadoresFiltrados.isEmpty
            ? <JugadorModel>[]
            : jugadoresFiltrados.sublist(startIndex, endIndex);

        // Siempre mostrar el layout, el loading/error va dentro del contenido
        return ResponsiveLayout(
          mobileBody: _MobileJugadoresView(
            jugadores: jugadoresFiltrados,
            filtros: filtros,
            isLoading: isLoading,
            isEmpty: isEmpty && jugadoresFiltrados.isEmpty,
            hasError: hasError,
            errorMessage: errorMessage,
            searchController: _searchController,
            onSearch: _onSearch,
            onClearSearch: _onClearSearch,
            onRefresh: _onRefresh,
          ),
          desktopBody: _DesktopJugadoresView(
            jugadores: jugadoresPaginados,
            totalJugadores: jugadoresFiltrados.length,
            filtros: filtros,
            isLoading: isLoading,
            isEmpty: isEmpty && jugadoresFiltrados.isEmpty,
            hasError: hasError,
            errorMessage: errorMessage,
            metricas: metricas,
            filtroPosicion: _filtroPosicion,
            searchController: _searchController,
            onSearch: _onSearch,
            onClearSearch: _onClearSearch,
            onRefresh: _onRefresh,
            onCambiarFiltroPosicion: _onCambiarFiltroPosicion,
            // Paginacion
            currentPage: _currentPage,
            totalPages: totalPages,
            itemsPerPage: _itemsPerPage,
            itemsPerPageOptions: _itemsPerPageOptions,
            startIndex: startIndex,
            endIndex: endIndex,
            onPageChanged: _onPageChanged,
            onItemsPerPageChanged: _onItemsPerPageChanged,
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

  List<JugadorModel> _filtrarPorPosicion(List<JugadorModel> jugadores) {
    if (_filtroPosicion == null) return jugadores;
    return jugadores
        .where((j) => j.posicionPreferida == _filtroPosicion)
        .toList();
  }

  Map<String, int> _calcularMetricas(List<JugadorModel> jugadores) {
    int total = jugadores.length;
    int arqueros = jugadores
        .where((j) => j.posicionPreferida == PosicionJugador.arquero)
        .length;
    int defensas = jugadores
        .where((j) => j.posicionPreferida == PosicionJugador.defensa)
        .length;
    int mediocampistas = jugadores
        .where((j) => j.posicionPreferida == PosicionJugador.mediocampista)
        .length;
    int delanteros = jugadores
        .where((j) => j.posicionPreferida == PosicionJugador.delantero)
        .length;
    int sinPosicion =
        jugadores.where((j) => j.posicionPreferida == null).length;

    return {
      'total': total,
      'arqueros': arqueros,
      'defensas': defensas,
      'mediocampistas': mediocampistas,
      'delanteros': delanteros,
      'sinPosicion': sinPosicion,
    };
  }

  void _onSearch(String value) {
    setState(() {
      _currentPage = 1; // Reset a primera pagina al buscar
    });
    _debouncer.run(() {
      context.read<JugadoresBloc>().add(BuscarJugadoresEvent(value));
    });
  }

  void _onClearSearch() {
    _searchController.clear();
    context.read<JugadoresBloc>().add(const LimpiarBusquedaEvent());
    setState(() {
      _currentPage = 1; // Reset a primera pagina al limpiar busqueda
    });
  }

  void _onRefresh() {
    _searchController.clear();
    setState(() {
      _filtroPosicion = null;
      _currentPage = 1; // Reset a primera pagina al refrescar
    });
    context.read<JugadoresBloc>().add(const RefrescarJugadoresEvent());
  }

  void _onCambiarFiltroPosicion(PosicionJugador? nuevaPosicion) {
    setState(() {
      _filtroPosicion = nuevaPosicion;
      _currentPage = 1; // Reset a primera pagina al cambiar filtro
    });
  }

  void _onPageChanged(int newPage) {
    setState(() {
      _currentPage = newPage;
    });
  }

  void _onItemsPerPageChanged(int newItemsPerPage) {
    setState(() {
      _itemsPerPage = newItemsPerPage;
      _currentPage = 1; // Reset a primera pagina al cambiar items por pagina
    });
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
  final bool hasError;
  final String? errorMessage;
  final TextEditingController searchController;
  final void Function(String) onSearch;
  final VoidCallback onClearSearch;
  final VoidCallback onRefresh;

  const _MobileJugadoresView({
    required this.jugadores,
    required this.filtros,
    required this.isLoading,
    required this.isEmpty,
    this.hasError = false,
    this.errorMessage,
    required this.searchController,
    required this.onSearch,
    required this.onClearSearch,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jugadores'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar lista',
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de busqueda
          _MobileSearchBar(
            controller: searchController,
            colorScheme: Theme.of(context).colorScheme,
            onSearch: onSearch,
            onClear: onClearSearch,
          ),

          // Lista de jugadores
          Expanded(
            child: _buildContent(context),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 2),
    );
  }

  Widget _buildContent(BuildContext context) {
    // Estado de carga inicial
    if (isLoading && jugadores.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Estado de error
    if (hasError && jugadores.isEmpty) {
      return _buildErrorContent(context);
    }

    // Estado vacio
    if (isEmpty) {
      return JugadoresEmptyState(
        tieneBusqueda: filtros.busqueda?.isNotEmpty ?? false,
        onLimpiarBusqueda: onClearSearch,
      );
    }

    // Lista con datos
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: Column(
        children: [
          // Header con contador
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingM,
              vertical: DesignTokens.spacingS,
            ),
            child: Row(
              children: [
                Text(
                  '${jugadores.length} jugador${jugadores.length != 1 ? 'es' : ''}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                if (filtros.busqueda != null &&
                    filtros.busqueda!.isNotEmpty) ...[
                  const SizedBox(width: DesignTokens.spacingS),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.spacingS,
                      vertical: DesignTokens.spacingXxs,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radiusFull),
                    ),
                    child: Text(
                      'Filtrado',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Lista de jugadores
          Expanded(
            child: Stack(
              children: [
                ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.spacingS,
                    vertical: DesignTokens.spacingXs,
                  ),
                  itemCount: jugadores.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: DesignTokens.spacingS),
                  itemBuilder: (context, index) {
                    final jugador = jugadores[index];
                    return JugadorCard(
                      jugador: jugador,
                      onTap: () =>
                          context.push('/jugadores/${jugador.jugadorId}'),
                    );
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
        ],
      ),
    );
  }

  Widget _buildErrorContent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: colorScheme.error),
          const SizedBox(height: DesignTokens.spacingM),
          Text(
            errorMessage ?? 'Error al cargar jugadores',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DesignTokens.spacingM),
          FilledButton.icon(
            onPressed: () {
              context.read<JugadoresBloc>().add(const CargarJugadoresEvent());
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

// ============================================
// VISTA DESKTOP - CRM Style con 3 Columnas
// ============================================

class _DesktopJugadoresView extends StatelessWidget {
  final List<JugadorModel> jugadores;
  final int totalJugadores;
  final FiltrosJugadores filtros;
  final bool isLoading;
  final bool isEmpty;
  final bool hasError;
  final String? errorMessage;
  final Map<String, int> metricas;
  final PosicionJugador? filtroPosicion;
  final TextEditingController searchController;
  final void Function(String) onSearch;
  final VoidCallback onClearSearch;
  final VoidCallback onRefresh;
  final void Function(PosicionJugador?) onCambiarFiltroPosicion;
  // Paginacion
  final int currentPage;
  final int totalPages;
  final int itemsPerPage;
  final List<int> itemsPerPageOptions;
  final int startIndex;
  final int endIndex;
  final void Function(int) onPageChanged;
  final void Function(int) onItemsPerPageChanged;

  const _DesktopJugadoresView({
    required this.jugadores,
    required this.totalJugadores,
    required this.filtros,
    required this.isLoading,
    required this.isEmpty,
    this.hasError = false,
    this.errorMessage,
    required this.metricas,
    required this.filtroPosicion,
    required this.searchController,
    required this.onSearch,
    required this.onClearSearch,
    required this.onRefresh,
    required this.onCambiarFiltroPosicion,
    // Paginacion
    required this.currentPage,
    required this.totalPages,
    required this.itemsPerPage,
    required this.itemsPerPageOptions,
    required this.startIndex,
    required this.endIndex,
    required this.onPageChanged,
    required this.onItemsPerPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardShell(
      currentRoute: '/jugadores',
      title: 'Jugadores',
      breadcrumbs: const ['Inicio', 'Jugadores'],
      actions: [
        IconButton(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh),
          tooltip: 'Actualizar lista',
        ),
      ],
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Panel de filtros lateral (320px fijo)
          SizedBox(
            width: 320,
            child: _FilterPanel(
              metricas: metricas,
              filtroPosicion: filtroPosicion,
              searchController: searchController,
              onSearch: onSearch,
              onClearSearch: onClearSearch,
              onCambiarFiltroPosicion: onCambiarFiltroPosicion,
            ),
          ),

          // Separador vertical
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),

          // Tabla de datos (expandida)
          Expanded(
            child: _DataTablePanel(
              jugadores: jugadores,
              totalJugadores: totalJugadores,
              filtros: filtros,
              isLoading: isLoading,
              isEmpty: isEmpty,
              hasError: hasError,
              errorMessage: errorMessage,
              onRefresh: onRefresh,
              onClearSearch: onClearSearch,
              // Paginacion
              currentPage: currentPage,
              totalPages: totalPages,
              itemsPerPage: itemsPerPage,
              itemsPerPageOptions: itemsPerPageOptions,
              startIndex: startIndex,
              endIndex: endIndex,
              onPageChanged: onPageChanged,
              onItemsPerPageChanged: onItemsPerPageChanged,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// PANEL DE FILTROS (320px)
// ============================================

class _FilterPanel extends StatelessWidget {
  final Map<String, int> metricas;
  final PosicionJugador? filtroPosicion;
  final TextEditingController searchController;
  final void Function(String) onSearch;
  final VoidCallback onClearSearch;
  final void Function(PosicionJugador?) onCambiarFiltroPosicion;

  const _FilterPanel({
    required this.metricas,
    required this.filtroPosicion,
    required this.searchController,
    required this.onSearch,
    required this.onClearSearch,
    required this.onCambiarFiltroPosicion,
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
            'Lista de Jugadores',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: DesignTokens.fontWeightSemiBold,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingXs),
          Text(
            'Consulta los jugadores del equipo',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: DesignTokens.spacingL),

          // Campo de busqueda (CA-003)
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Buscar por nombre o apodo...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      onPressed: onClearSearch,
                      icon: const Icon(Icons.clear),
                      tooltip: 'Limpiar busqueda',
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              ),
              filled: true,
              fillColor:
                  colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingM,
                vertical: DesignTokens.spacingS,
              ),
            ),
            onChanged: onSearch,
          ),

          const SizedBox(height: DesignTokens.spacingL),

          // Card de resumen con metricas
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

                // Metricas en grid 2x2
                Row(
                  children: [
                    Expanded(
                      child: _MetricTile(
                        label: 'Total',
                        value: metricas['total'] ?? 0,
                        icon: Icons.people,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: DesignTokens.spacingS),
                    Expanded(
                      child: _MetricTile(
                        label: 'Arqueros',
                        value: metricas['arqueros'] ?? 0,
                        icon: Icons.sports_handball,
                        color: _getPosicionColor(PosicionJugador.arquero),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.spacingS),
                Row(
                  children: [
                    Expanded(
                      child: _MetricTile(
                        label: 'Defensas',
                        value: metricas['defensas'] ?? 0,
                        icon: Icons.shield_outlined,
                        color: _getPosicionColor(PosicionJugador.defensa),
                      ),
                    ),
                    const SizedBox(width: DesignTokens.spacingS),
                    Expanded(
                      child: _MetricTile(
                        label: 'Medios',
                        value: metricas['mediocampistas'] ?? 0,
                        icon: Icons.swap_horiz,
                        color: _getPosicionColor(PosicionJugador.mediocampista),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.spacingS),
                Row(
                  children: [
                    Expanded(
                      child: _MetricTile(
                        label: 'Delanteros',
                        value: metricas['delanteros'] ?? 0,
                        icon: Icons.sports_soccer,
                        color: _getPosicionColor(PosicionJugador.delantero),
                      ),
                    ),
                    const SizedBox(width: DesignTokens.spacingS),
                    Expanded(
                      child: _MetricTile(
                        label: 'Sin pos.',
                        value: metricas['sinPosicion'] ?? 0,
                        icon: Icons.help_outline,
                        color: colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: DesignTokens.spacingL),

          // Filtros por posicion
          Text(
            'POSICION',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: DesignTokens.fontWeightSemiBold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingS),
          Wrap(
            spacing: DesignTokens.spacingS,
            runSpacing: DesignTokens.spacingS,
            children: [
              _FilterChip(
                label: 'Todos',
                isSelected: filtroPosicion == null,
                onTap: () => onCambiarFiltroPosicion(null),
              ),
              _FilterChip(
                label: 'Arquero',
                isSelected: filtroPosicion == PosicionJugador.arquero,
                onTap: () => onCambiarFiltroPosicion(PosicionJugador.arquero),
                color: _getPosicionColor(PosicionJugador.arquero),
              ),
              _FilterChip(
                label: 'Defensa',
                isSelected: filtroPosicion == PosicionJugador.defensa,
                onTap: () => onCambiarFiltroPosicion(PosicionJugador.defensa),
                color: _getPosicionColor(PosicionJugador.defensa),
              ),
              _FilterChip(
                label: 'Medio',
                isSelected: filtroPosicion == PosicionJugador.mediocampista,
                onTap: () =>
                    onCambiarFiltroPosicion(PosicionJugador.mediocampista),
                color: _getPosicionColor(PosicionJugador.mediocampista),
              ),
              _FilterChip(
                label: 'Delantero',
                isSelected: filtroPosicion == PosicionJugador.delantero,
                onTap: () => onCambiarFiltroPosicion(PosicionJugador.delantero),
                color: _getPosicionColor(PosicionJugador.delantero),
              ),
            ],
          ),

          const SizedBox(height: DesignTokens.spacingL),

          // Leyenda de posiciones
          Text(
            'LEYENDA',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: DesignTokens.fontWeightSemiBold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingS),
          _PosicionLegend(),
        ],
      ),
    );
  }

  Color _getPosicionColor(PosicionJugador posicion) {
    switch (posicion) {
      case PosicionJugador.arquero:
        return const Color(0xFFFF9800); // Naranja
      case PosicionJugador.defensa:
        return const Color(0xFF2196F3); // Azul
      case PosicionJugador.mediocampista:
        return const Color(0xFF4CAF50); // Verde
      case PosicionJugador.delantero:
        return const Color(0xFFF44336); // Rojo
    }
  }
}

// ============================================
// PANEL DE DATOS (Tabla)
// ============================================

class _DataTablePanel extends StatelessWidget {
  final List<JugadorModel> jugadores;
  final int totalJugadores;
  final FiltrosJugadores filtros;
  final bool isLoading;
  final bool isEmpty;
  final bool hasError;
  final String? errorMessage;
  final VoidCallback onRefresh;
  final VoidCallback onClearSearch;
  // Paginacion
  final int currentPage;
  final int totalPages;
  final int itemsPerPage;
  final List<int> itemsPerPageOptions;
  final int startIndex;
  final int endIndex;
  final void Function(int) onPageChanged;
  final void Function(int) onItemsPerPageChanged;

  const _DataTablePanel({
    required this.jugadores,
    required this.totalJugadores,
    required this.filtros,
    required this.isLoading,
    required this.isEmpty,
    required this.hasError,
    this.errorMessage,
    required this.onRefresh,
    required this.onClearSearch,
    // Paginacion
    required this.currentPage,
    required this.totalPages,
    required this.itemsPerPage,
    required this.itemsPerPageOptions,
    required this.startIndex,
    required this.endIndex,
    required this.onPageChanged,
    required this.onItemsPerPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header de la tabla
        Container(
          padding: const EdgeInsets.all(DesignTokens.spacingL),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Listado de Jugadores',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: DesignTokens.fontWeightSemiBold,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spacingXxs),
                    Text(
                      'Miembros activos del equipo',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Contador de registros totales
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
                      Icons.people_outline,
                      size: DesignTokens.iconSizeS,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: DesignTokens.spacingXs),
                    Text(
                      '$totalJugadores jugador${totalJugadores != 1 ? 'es' : ''}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: DesignTokens.fontWeightMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Controles de paginacion (ARRIBA de la tabla segun convencion)
        if (totalJugadores > 0)
          _PaginationControls(
            currentPage: currentPage,
            totalPages: totalPages,
            itemsPerPage: itemsPerPage,
            itemsPerPageOptions: itemsPerPageOptions,
            startIndex: startIndex,
            endIndex: endIndex,
            totalItems: totalJugadores,
            onPageChanged: onPageChanged,
            onItemsPerPageChanged: onItemsPerPageChanged,
          ),

        // Contenido de la tabla
        Expanded(
          child: _buildTableContent(context),
        ),
      ],
    );
  }

  Widget _buildTableContent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Estado de carga inicial
    if (isLoading && jugadores.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error sin datos previos
    if (hasError && jugadores.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: colorScheme.error),
            const SizedBox(height: DesignTokens.spacingM),
            Text(
              errorMessage ?? 'Error al cargar jugadores',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.spacingM),
            FilledButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    // Estado vacio
    if (isEmpty) {
      if (filtros.busqueda != null && filtros.busqueda!.isNotEmpty) {
        return Center(
          child: JugadoresEmptyState(
            tieneBusqueda: true,
            onLimpiarBusqueda: onClearSearch,
          ),
        );
      }
      return const Center(
        child: JugadoresEmptyState(
          tieneBusqueda: false,
          onLimpiarBusqueda: null,
        ),
      );
    }

    // Tabla con datos
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(DesignTokens.spacingL),
          child: AppCard(
            variant: AppCardVariant.outlined,
            padding: EdgeInsets.zero,
            margin: EdgeInsets.zero,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: MediaQuery.of(context).size.width -
                        320 -
                        280 -
                        DesignTokens.spacingL * 2,
                  ),
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                      colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                    ),
                    columns: const [
                      DataColumn(label: Text('Jugador')),
                      DataColumn(label: Text('Posicion')),
                      DataColumn(label: Text('Apodo')),
                      DataColumn(label: Text('Acciones')),
                    ],
                    rows: jugadores.map((jugador) {
                      return DataRow(
                        cells: [
                          // Columna: Jugador (Avatar + Nombre)
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildAvatar(jugador, colorScheme),
                                const SizedBox(width: DesignTokens.spacingM),
                                ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 200),
                                  child: Text(
                                    jugador.nombreCompleto,
                                    style: const TextStyle(
                                      fontWeight: DesignTokens.fontWeightMedium,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Columna: Posicion (Badge con color)
                          DataCell(
                            _buildPosicionBadge(jugador, colorScheme),
                          ),

                          // Columna: Apodo
                          DataCell(
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 150),
                              child: Text(
                                jugador.apodo,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),

                          // Columna: Acciones
                          DataCell(
                            _buildAcciones(context, jugador, colorScheme),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (isLoading)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(),
          ),
      ],
    );
  }

  Widget _buildAvatar(JugadorModel jugador, ColorScheme colorScheme) {
    final inicial = jugador.nombreCompleto.isNotEmpty
        ? jugador.nombreCompleto[0].toUpperCase()
        : '?';

    Color avatarColor = _getPosicionColor(jugador.posicionPreferida);

    if (jugador.tieneFoto) {
      return CircleAvatar(
        radius: 18,
        backgroundImage: NetworkImage(jugador.fotoUrl!),
        backgroundColor: avatarColor,
      );
    }

    return CircleAvatar(
      radius: 18,
      backgroundColor: avatarColor,
      child: Text(
        inicial,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: DesignTokens.fontWeightBold,
          fontSize: DesignTokens.fontSizeS,
        ),
      ),
    );
  }

  Widget _buildPosicionBadge(JugadorModel jugador, ColorScheme colorScheme) {
    final posicion = jugador.posicionPreferida;

    if (posicion == null) {
      return StatusBadge(
        label: 'Sin definir',
        backgroundColor: colorScheme.outline,
        size: StatusBadgeSize.small,
        icon: Icons.help_outline,
      );
    }

    Color bgColor = _getPosicionColor(posicion);
    IconData icon;

    switch (posicion) {
      case PosicionJugador.arquero:
        icon = Icons.sports_handball;
        break;
      case PosicionJugador.defensa:
        icon = Icons.shield_outlined;
        break;
      case PosicionJugador.mediocampista:
        icon = Icons.swap_horiz;
        break;
      case PosicionJugador.delantero:
        icon = Icons.sports_soccer;
        break;
    }

    return StatusBadge(
      label: posicion.displayName,
      backgroundColor: bgColor,
      size: StatusBadgeSize.small,
      icon: icon,
    );
  }

  Widget _buildAcciones(
    BuildContext context,
    JugadorModel jugador,
    ColorScheme colorScheme,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Boton ver perfil
        Tooltip(
          message: 'Ver perfil',
          child: IconButton(
            onPressed: () => context.push('/jugadores/${jugador.jugadorId}'),
            icon: Icon(
              Icons.visibility_outlined,
              color: colorScheme.primary,
            ),
            iconSize: DesignTokens.iconSizeS + 2,
          ),
        ),
      ],
    );
  }

  Color _getPosicionColor(PosicionJugador? posicion) {
    if (posicion == null) return const Color(0xFF9E9E9E);

    switch (posicion) {
      case PosicionJugador.arquero:
        return const Color(0xFFFF9800); // Naranja
      case PosicionJugador.defensa:
        return const Color(0xFF2196F3); // Azul
      case PosicionJugador.mediocampista:
        return const Color(0xFF4CAF50); // Verde
      case PosicionJugador.delantero:
        return const Color(0xFFF44336); // Rojo
    }
  }
}

// ============================================
// WIDGETS AUXILIARES
// ============================================

/// Barra de busqueda para mobile
class _MobileSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ColorScheme colorScheme;
  final void Function(String) onSearch;
  final VoidCallback onClear;

  const _MobileSearchBar({
    required this.controller,
    required this.colorScheme,
    required this.onSearch,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Buscar por nombre o apodo...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  onPressed: onClear,
                  icon: const Icon(Icons.clear),
                  tooltip: 'Limpiar busqueda',
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          ),
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingM,
            vertical: DesignTokens.spacingS,
          ),
        ),
        onChanged: onSearch,
      ),
    );
  }
}

/// Tile de metrica para el panel de filtros
class _MetricTile extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: DesignTokens.iconSizeS, color: color),
              const Spacer(),
              Text(
                value.toString(),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: DesignTokens.fontWeightBold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacingXxs),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Chip de filtro
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveColor = color ?? colorScheme.primary;

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
            color: isSelected ? effectiveColor : Colors.transparent,
            borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
            border: Border.all(
              color: isSelected ? effectiveColor : colorScheme.outline,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeXs,
              fontWeight: DesignTokens.fontWeightMedium,
              color: isSelected ? Colors.white : colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

/// Leyenda de posiciones
class _PosicionLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        _PosicionLegendItem(
          icon: Icons.sports_handball,
          label: 'Arquero',
          color: const Color(0xFFFF9800),
        ),
        const SizedBox(height: DesignTokens.spacingXs),
        _PosicionLegendItem(
          icon: Icons.shield_outlined,
          label: 'Defensa',
          color: const Color(0xFF2196F3),
        ),
        const SizedBox(height: DesignTokens.spacingXs),
        _PosicionLegendItem(
          icon: Icons.swap_horiz,
          label: 'Mediocampista',
          color: const Color(0xFF4CAF50),
        ),
        const SizedBox(height: DesignTokens.spacingXs),
        _PosicionLegendItem(
          icon: Icons.sports_soccer,
          label: 'Delantero',
          color: const Color(0xFFF44336),
        ),
        const SizedBox(height: DesignTokens.spacingXs),
        _PosicionLegendItem(
          icon: Icons.help_outline,
          label: 'Sin definir',
          color: colorScheme.outline,
        ),
      ],
    );
  }
}

class _PosicionLegendItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _PosicionLegendItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: DesignTokens.spacingS),
        Icon(icon, size: DesignTokens.iconSizeS, color: color),
        const SizedBox(width: DesignTokens.spacingS),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Controles de paginacion mejorados (ubicados ARRIBA de la tabla segun convencion)
/// Incluye: navegacion rapida (<<, <, >, >>) + input de pagina directa
class _PaginationControls extends StatefulWidget {
  final int currentPage;
  final int totalPages;
  final int itemsPerPage;
  final List<int> itemsPerPageOptions;
  final int startIndex;
  final int endIndex;
  final int totalItems;
  final void Function(int) onPageChanged;
  final void Function(int) onItemsPerPageChanged;

  const _PaginationControls({
    required this.currentPage,
    required this.totalPages,
    required this.itemsPerPage,
    required this.itemsPerPageOptions,
    required this.startIndex,
    required this.endIndex,
    required this.totalItems,
    required this.onPageChanged,
    required this.onItemsPerPageChanged,
  });

  @override
  State<_PaginationControls> createState() => _PaginationControlsState();
}

class _PaginationControlsState extends State<_PaginationControls> {
  late TextEditingController _pageInputController;
  late FocusNode _pageInputFocusNode;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _pageInputController =
        TextEditingController(text: widget.currentPage.toString());
    _pageInputFocusNode = FocusNode();
    _pageInputFocusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant _PaginationControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Actualizar el texto del input cuando cambia la pagina externamente
    if (oldWidget.currentPage != widget.currentPage) {
      _pageInputController.text = widget.currentPage.toString();
      _hasError = false;
    }
  }

  @override
  void dispose() {
    _pageInputFocusNode.removeListener(_onFocusChange);
    _pageInputFocusNode.dispose();
    _pageInputController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_pageInputFocusNode.hasFocus) {
      _navigateToPage();
    }
  }

  void _navigateToPage() {
    final text = _pageInputController.text.trim();
    final page = int.tryParse(text);

    if (page == null) {
      // Restaurar el valor anterior si no es un numero valido
      setState(() {
        _hasError = true;
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _pageInputController.text = widget.currentPage.toString();
            _hasError = false;
          });
        }
      });
      return;
    }

    setState(() {
      _hasError = false;
    });

    // Validar rango y navegar
    if (page < 1) {
      widget.onPageChanged(1);
    } else if (page > widget.totalPages) {
      widget.onPageChanged(widget.totalPages > 0 ? widget.totalPages : 1);
    } else if (page != widget.currentPage) {
      widget.onPageChanged(page);
    }
  }

  void _onSubmitted(String value) {
    _navigateToPage();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final effectiveTotalPages = widget.totalPages > 0 ? widget.totalPages : 1;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingL,
        vertical: DesignTokens.spacingM,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          // Botones de navegacion con input de pagina
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Boton Primera pagina (<<)
              _PaginationButton(
                icon: Icons.first_page,
                tooltip: 'Primera pagina',
                enabled: widget.currentPage > 1,
                onPressed: () => widget.onPageChanged(1),
              ),
              const SizedBox(width: DesignTokens.spacingXs),

              // Boton Anterior (<)
              _PaginationButton(
                icon: Icons.chevron_left,
                tooltip: 'Pagina anterior',
                enabled: widget.currentPage > 1,
                onPressed: () => widget.onPageChanged(widget.currentPage - 1),
              ),
              const SizedBox(width: DesignTokens.spacingM),

              // Input de pagina directa
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Pagina',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spacingS),
                  SizedBox(
                    width: 60,
                    child: TextField(
                      controller: _pageInputController,
                      focusNode: _pageInputFocusNode,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: DesignTokens.fontWeightMedium,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: DesignTokens.spacingS,
                          vertical: DesignTokens.spacingS,
                        ),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(DesignTokens.radiusS),
                          borderSide: BorderSide(
                            color: _hasError
                                ? colorScheme.error
                                : colorScheme.outlineVariant,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(DesignTokens.radiusS),
                          borderSide: BorderSide(
                            color: _hasError
                                ? colorScheme.error
                                : colorScheme.outlineVariant,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(DesignTokens.radiusS),
                          borderSide: BorderSide(
                            color:
                                _hasError ? colorScheme.error : colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: _hasError
                            ? colorScheme.errorContainer.withValues(alpha: 0.3)
                            : colorScheme.surface,
                      ),
                      onSubmitted: _onSubmitted,
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spacingS),
                  Text(
                    'de $effectiveTotalPages',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: DesignTokens.spacingM),

              // Boton Siguiente (>)
              _PaginationButton(
                icon: Icons.chevron_right,
                tooltip: 'Pagina siguiente',
                enabled: widget.currentPage < widget.totalPages,
                onPressed: () => widget.onPageChanged(widget.currentPage + 1),
              ),
              const SizedBox(width: DesignTokens.spacingXs),

              // Boton Ultima pagina (>>)
              _PaginationButton(
                icon: Icons.last_page,
                tooltip: 'Ultima pagina',
                enabled: widget.currentPage < widget.totalPages,
                onPressed: () => widget.onPageChanged(widget.totalPages),
              ),
            ],
          ),

          const SizedBox(width: DesignTokens.spacingL),

          // Separador vertical
          Container(
            width: 1,
            height: 24,
            color: colorScheme.outlineVariant,
          ),

          const SizedBox(width: DesignTokens.spacingL),

          // Selector de items por pagina
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Mostrar',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: DesignTokens.spacingS),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacingS,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                  border: Border.all(
                    color: colorScheme.outlineVariant,
                  ),
                ),
                child: DropdownButton<int>(
                  value: widget.itemsPerPage,
                  underline: const SizedBox.shrink(),
                  isDense: true,
                  items: widget.itemsPerPageOptions.map((option) {
                    return DropdownMenuItem<int>(
                      value: option,
                      child: Text(
                        '$option',
                        style: theme.textTheme.labelMedium,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      widget.onItemsPerPageChanged(value);
                    }
                  },
                ),
              ),
              const SizedBox(width: DesignTokens.spacingS),
              Text(
                'por pagina',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),

          const Spacer(),

          // Informacion de registros mostrados
          Text(
            'Mostrando ${widget.startIndex + 1}-${widget.endIndex} de ${widget.totalItems}',
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Boton de paginacion
class _PaginationButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onPressed;

  const _PaginationButton({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: enabled
            ? colorScheme.primaryContainer.withValues(alpha: 0.5)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(DesignTokens.radiusS),
          child: Container(
            padding: const EdgeInsets.all(DesignTokens.spacingS),
            child: Icon(
              icon,
              size: DesignTokens.iconSizeS + 4,
              color: enabled
                  ? colorScheme.primary
                  : colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ),
        ),
      ),
    );
  }
}

/// Debouncer para la busqueda
class _Debouncer {
  final int milliseconds;
  VoidCallback? _action;
  bool _isDisposed = false;

  _Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    _action = action;
    Future.delayed(Duration(milliseconds: milliseconds), () {
      if (!_isDisposed && _action != null) {
        _action!();
      }
    });
  }

  void dispose() {
    _isDisposed = true;
    _action = null;
  }
}
