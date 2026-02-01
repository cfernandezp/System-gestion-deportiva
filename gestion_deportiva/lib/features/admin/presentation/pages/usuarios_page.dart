import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/dashboard_shell.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_shimmer.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/presentation/bloc/session/session_bloc.dart';
import '../../../auth/presentation/bloc/session/session_state.dart';
import '../../data/models/usuario_admin_model.dart';
import '../bloc/usuarios/usuarios_bloc.dart';
import '../bloc/usuarios/usuarios_event.dart';
import '../bloc/usuarios/usuarios_state.dart';
import '../widgets/rol_selector_dialog.dart';
import '../widgets/usuario_card.dart';

/// Pagina de gestion de usuarios y roles
/// HU-005: Gestion de Roles
///
/// Criterios de Aceptacion:
/// - CA-001: Lista de usuarios con rol actual
/// - CA-002: Cambiar rol de usuario
/// - CA-003: Roles disponibles (Admin, Entrenador, Jugador, Arbitro)
/// - CA-004: Deshabilitado para el usuario actual
/// - CA-005: Busqueda por nombre/email
/// - CA-006: Solo administradores (validado en backend)
///
/// Estilo: CRM Moderno con layout de 3 columnas en desktop
/// - Sidebar (via DashboardShell)
/// - Panel de filtros lateral (320px)
/// - Tabla de datos expandida
class UsuariosPage extends StatelessWidget {
  const UsuariosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<UsuariosBloc>()..add(const CargarUsuariosEvent()),
      child: const _UsuariosPageContent(),
    );
  }
}

class _UsuariosPageContent extends StatefulWidget {
  const _UsuariosPageContent();

  @override
  State<_UsuariosPageContent> createState() => _UsuariosPageContentState();
}

class _UsuariosPageContentState extends State<_UsuariosPageContent> {
  final _searchController = TextEditingController();
  final _debouncer = _Debouncer(milliseconds: 500);
  String _filtroEstado = 'todos'; // todos, aprobado, pendiente

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
    return BlocConsumer<UsuariosBloc, UsuariosState>(
      listener: _handleStateChanges,
      builder: (context, state) {
        // Obtener datos del estado
        final usuarios = _obtenerUsuarios(state);
        final total = _obtenerTotal(state);
        final busquedaActual = _obtenerBusqueda(state);
        final isLoading = state is UsuariosLoading;
        final errorState = state is UsuariosError ? state : null;
        final hasError = errorState != null;
        final errorMessage = errorState?.message;
        final cambiandoRolState = state is UsuariosCambiandoRol ? state : null;
        final usuarioIdCambiando = cambiandoRolState?.usuarioIdCambiando;

        // Filtrar por estado local
        final usuariosFiltrados = _filtrarPorEstado(usuarios);

        // Calcular metricas
        final metricas = _calcularMetricas(usuarios);

        // Calcular paginacion
        final totalPages = (usuariosFiltrados.length / _itemsPerPage).ceil();
        final startIndex = (_currentPage - 1) * _itemsPerPage;
        final endIndex = startIndex + _itemsPerPage > usuariosFiltrados.length
            ? usuariosFiltrados.length
            : startIndex + _itemsPerPage;
        final usuariosPaginados = usuariosFiltrados.isEmpty
            ? <UsuarioAdminModel>[]
            : usuariosFiltrados.sublist(startIndex, endIndex);

        return ResponsiveLayout(
          mobileBody: _MobileUsuariosView(
            usuarios: usuariosFiltrados,
            total: total,
            busquedaActual: busquedaActual,
            isLoading: isLoading,
            hasError: hasError,
            errorMessage: errorMessage,
            usuarioIdCambiando: usuarioIdCambiando,
            searchController: _searchController,
            onSearch: _onSearch,
            onClearSearch: _onClearSearch,
            onRefresh: _onRefresh,
            onCambiarRol: _showCambiarRolDialog,
          ),
          desktopBody: _DesktopUsuariosView(
            usuarios: usuariosPaginados,
            totalUsuarios: usuariosFiltrados.length,
            busquedaActual: busquedaActual,
            isLoading: isLoading,
            hasError: hasError,
            errorMessage: errorMessage,
            usuarioIdCambiando: usuarioIdCambiando,
            metricas: metricas,
            filtroEstado: _filtroEstado,
            searchController: _searchController,
            onSearch: _onSearch,
            onClearSearch: _onClearSearch,
            onRefresh: _onRefresh,
            onCambiarRol: _showCambiarRolDialog,
            onCambiarFiltroEstado: _onCambiarFiltroEstado,
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

  List<UsuarioAdminModel> _obtenerUsuarios(UsuariosState state) {
    if (state is UsuariosLoaded) return state.usuarios;
    if (state is UsuariosCambiandoRol) return state.usuarios;
    if (state is UsuariosError && state.usuariosPrevios != null) {
      return state.usuariosPrevios!;
    }
    return [];
  }

  int _obtenerTotal(UsuariosState state) {
    if (state is UsuariosLoaded) return state.total;
    if (state is UsuariosCambiandoRol) return state.total;
    if (state is UsuariosError) return state.totalPrevio ?? 0;
    return 0;
  }

  String? _obtenerBusqueda(UsuariosState state) {
    if (state is UsuariosLoaded) return state.busquedaActual;
    if (state is UsuariosCambiandoRol) return state.busquedaActual;
    if (state is UsuariosError) return state.busquedaActual;
    return null;
  }

  List<UsuarioAdminModel> _filtrarPorEstado(List<UsuarioAdminModel> usuarios) {
    if (_filtroEstado == 'todos') return usuarios;
    return usuarios.where((u) => u.estado == _filtroEstado).toList();
  }

  Map<String, int> _calcularMetricas(List<UsuarioAdminModel> usuarios) {
    int totalUsuarios = usuarios.length;
    int admins = usuarios.where((u) => u.rol == 'admin').length;
    int jugadores = usuarios.where((u) => u.rol == 'jugador').length;
    int entrenadores = usuarios.where((u) => u.rol == 'entrenador').length;
    int arbitros = usuarios.where((u) => u.rol == 'arbitro').length;
    int aprobados = usuarios.where((u) => u.estado == 'aprobado').length;
    int pendientes = usuarios.where((u) => u.estado == 'pendiente').length;

    return {
      'total': totalUsuarios,
      'admins': admins,
      'jugadores': jugadores,
      'entrenadores': entrenadores,
      'arbitros': arbitros,
      'aprobados': aprobados,
      'pendientes': pendientes,
    };
  }

  void _handleStateChanges(BuildContext context, UsuariosState state) {
    // Mostrar mensaje de exito
    if (state is UsuariosLoaded && state.mensajeExito != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: DesignTokens.spacingS),
              Expanded(child: Text(state.mensajeExito!)),
            ],
          ),
          backgroundColor: DesignTokens.successColor,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      context.read<UsuariosBloc>().add(const LimpiarMensajeEvent());
    }

    // Mostrar error
    if (state is UsuariosError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: DesignTokens.spacingS),
              Expanded(child: Text(state.message)),
            ],
          ),
          backgroundColor: DesignTokens.errorColor,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          action: state.usuariosPrevios != null
              ? SnackBarAction(
                  label: 'Reintentar',
                  textColor: Colors.white,
                  onPressed: () {
                    context.read<UsuariosBloc>().add(const CargarUsuariosEvent());
                  },
                )
              : null,
        ),
      );
    }
  }

  void _onSearch(String value) {
    setState(() {
      _currentPage = 1; // Reset a primera pagina al buscar
    });
    _debouncer.run(() {
      context.read<UsuariosBloc>().add(BuscarUsuariosEvent(query: value));
    });
  }

  void _onClearSearch() {
    _searchController.clear();
    context.read<UsuariosBloc>().add(const CargarUsuariosEvent());
    setState(() {
      _currentPage = 1; // Reset a primera pagina al limpiar busqueda
    });
  }

  void _onRefresh() {
    _searchController.clear();
    setState(() {
      _filtroEstado = 'todos';
      _currentPage = 1; // Reset a primera pagina al refrescar
    });
    context.read<UsuariosBloc>().add(const CargarUsuariosEvent());
  }

  void _onCambiarFiltroEstado(String nuevoFiltro) {
    setState(() {
      _filtroEstado = nuevoFiltro;
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

  Future<void> _showCambiarRolDialog(BuildContext context, UsuarioAdminModel usuario) async {
    final nuevoRol = await RolSelectorDialog.show(
      context: context,
      nombreUsuario: usuario.nombreCompleto,
      rolActual: usuario.rol,
    );

    if (nuevoRol != null && context.mounted) {
      context.read<UsuariosBloc>().add(CambiarRolEvent(
            usuarioId: usuario.id,
            nuevoRol: nuevoRol,
          ));
    }
  }
}

// ============================================
// VISTA MOBILE - App Style con Cards
// ============================================

class _MobileUsuariosView extends StatelessWidget {
  final List<UsuarioAdminModel> usuarios;
  final int total;
  final String? busquedaActual;
  final bool isLoading;
  final bool hasError;
  final String? errorMessage;
  final String? usuarioIdCambiando;
  final TextEditingController searchController;
  final void Function(String) onSearch;
  final VoidCallback onClearSearch;
  final VoidCallback onRefresh;
  final Future<void> Function(BuildContext, UsuarioAdminModel) onCambiarRol;

  const _MobileUsuariosView({
    required this.usuarios,
    required this.total,
    required this.busquedaActual,
    required this.isLoading,
    required this.hasError,
    required this.errorMessage,
    required this.usuarioIdCambiando,
    required this.searchController,
    required this.onSearch,
    required this.onClearSearch,
    required this.onRefresh,
    required this.onCambiarRol,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion de Usuarios'),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
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
            colorScheme: colorScheme,
            onSearch: onSearch,
            onClear: onClearSearch,
          ),

          // Contenido principal
          Expanded(
            child: _buildContent(context),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 3),
    );
  }

  Widget _buildContent(BuildContext context) {
    // Obtener ID del usuario actual para CA-004
    final sessionState = context.read<SessionBloc>().state;
    String? currentUserId;
    if (sessionState is SessionAuthenticated) {
      currentUserId = sessionState.usuarioId;
    }

    // Estado de carga inicial
    if (isLoading && usuarios.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(DesignTokens.spacingM),
        child: ShimmerList(
          itemCount: 5,
          itemHeight: 120,
          hasAvatar: true,
        ),
      );
    }

    // Error sin datos previos
    if (hasError && usuarios.isEmpty) {
      return EmptyStateWidget.error(
        title: 'Error al cargar usuarios',
        description: errorMessage ?? 'Ocurrio un error inesperado',
        actionLabel: 'Reintentar',
        onAction: onRefresh,
      );
    }

    // Estado vacio
    if (usuarios.isEmpty) {
      if (busquedaActual != null && busquedaActual!.isNotEmpty) {
        return EmptyStateWidget.noResults(
          description: 'No se encontraron usuarios para "$busquedaActual"',
          onAction: onClearSearch,
        );
      }
      return const EmptyStateWidget.noData(
        title: 'No hay usuarios',
        description: 'Aun no hay usuarios registrados en el sistema',
        icon: Icons.people_outline,
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
                  '${usuarios.length} usuario${usuarios.length != 1 ? 's' : ''}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                if (busquedaActual != null && busquedaActual!.isNotEmpty) ...[
                  const SizedBox(width: DesignTokens.spacingS),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.spacingS,
                      vertical: DesignTokens.spacingXxs,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                    ),
                    child: Text(
                      'Filtrado',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Lista de usuarios
          Expanded(
            child: Stack(
              children: [
                ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.spacingS,
                    vertical: DesignTokens.spacingXs,
                  ),
                  itemCount: usuarios.length,
                  itemBuilder: (context, index) {
                    final usuario = usuarios[index];
                    final isCurrentUser = usuario.id == currentUserId;
                    final isLoadingRol = usuarioIdCambiando == usuario.id;

                    return UsuarioCard(
                      usuario: usuario,
                      isCurrentUser: isCurrentUser,
                      isLoading: isLoadingRol,
                      onCambiarRol: () => onCambiarRol(context, usuario),
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
}

// ============================================
// VISTA DESKTOP - CRM Style con 3 Columnas
// ============================================

class _DesktopUsuariosView extends StatelessWidget {
  final List<UsuarioAdminModel> usuarios;
  final int totalUsuarios;
  final String? busquedaActual;
  final bool isLoading;
  final bool hasError;
  final String? errorMessage;
  final String? usuarioIdCambiando;
  final Map<String, int> metricas;
  final String filtroEstado;
  final TextEditingController searchController;
  final void Function(String) onSearch;
  final VoidCallback onClearSearch;
  final VoidCallback onRefresh;
  final Future<void> Function(BuildContext, UsuarioAdminModel) onCambiarRol;
  final void Function(String) onCambiarFiltroEstado;
  // Paginacion
  final int currentPage;
  final int totalPages;
  final int itemsPerPage;
  final List<int> itemsPerPageOptions;
  final int startIndex;
  final int endIndex;
  final void Function(int) onPageChanged;
  final void Function(int) onItemsPerPageChanged;

  const _DesktopUsuariosView({
    required this.usuarios,
    required this.totalUsuarios,
    required this.busquedaActual,
    required this.isLoading,
    required this.hasError,
    required this.errorMessage,
    required this.usuarioIdCambiando,
    required this.metricas,
    required this.filtroEstado,
    required this.searchController,
    required this.onSearch,
    required this.onClearSearch,
    required this.onRefresh,
    required this.onCambiarRol,
    required this.onCambiarFiltroEstado,
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
      currentRoute: '/admin/usuarios',
      title: 'Gestion de Usuarios',
      breadcrumbs: const ['Inicio', 'Administracion', 'Usuarios'],
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
              filtroEstado: filtroEstado,
              searchController: searchController,
              onSearch: onSearch,
              onClearSearch: onClearSearch,
              onCambiarFiltroEstado: onCambiarFiltroEstado,
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
              usuarios: usuarios,
              totalUsuarios: totalUsuarios,
              busquedaActual: busquedaActual,
              isLoading: isLoading,
              hasError: hasError,
              errorMessage: errorMessage,
              usuarioIdCambiando: usuarioIdCambiando,
              onRefresh: onRefresh,
              onClearSearch: onClearSearch,
              onCambiarRol: onCambiarRol,
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
  final String filtroEstado;
  final TextEditingController searchController;
  final void Function(String) onSearch;
  final VoidCallback onClearSearch;
  final void Function(String) onCambiarFiltroEstado;

  const _FilterPanel({
    required this.metricas,
    required this.filtroEstado,
    required this.searchController,
    required this.onSearch,
    required this.onClearSearch,
    required this.onCambiarFiltroEstado,
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
            'Gestion de Usuarios',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: DesignTokens.fontWeightSemiBold,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingXs),
          Text(
            'Administra los usuarios y sus roles',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: DesignTokens.spacingL),

          // Campo de busqueda (CA-005)
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Buscar por nombre o email...',
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
              fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
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
                        label: 'Admins',
                        value: metricas['admins'] ?? 0,
                        icon: Icons.admin_panel_settings,
                        color: DesignTokens.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.spacingS),
                Row(
                  children: [
                    Expanded(
                      child: _MetricTile(
                        label: 'Jugadores',
                        value: metricas['jugadores'] ?? 0,
                        icon: Icons.person,
                        color: colorScheme.tertiary,
                      ),
                    ),
                    const SizedBox(width: DesignTokens.spacingS),
                    Expanded(
                      child: _MetricTile(
                        label: 'Pendientes',
                        value: metricas['pendientes'] ?? 0,
                        icon: Icons.pending,
                        color: DesignTokens.accentColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: DesignTokens.spacingL),

          // Filtros por chips de estado
          Text(
            'ESTADO',
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
                isSelected: filtroEstado == 'todos',
                onTap: () => onCambiarFiltroEstado('todos'),
              ),
              _FilterChip(
                label: 'Aprobados',
                isSelected: filtroEstado == 'aprobado',
                onTap: () => onCambiarFiltroEstado('aprobado'),
                color: DesignTokens.successColor,
              ),
              _FilterChip(
                label: 'Pendientes',
                isSelected: filtroEstado == 'pendiente',
                onTap: () => onCambiarFiltroEstado('pendiente'),
                color: DesignTokens.accentColor,
              ),
            ],
          ),

          const SizedBox(height: DesignTokens.spacingL),

          // Filtros por rol
          Text(
            'ROL',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: DesignTokens.fontWeightSemiBold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingS),
          _RolLegend(),
        ],
      ),
    );
  }
}

// ============================================
// PANEL DE DATOS (Tabla con Paginacion)
// ============================================

class _DataTablePanel extends StatelessWidget {
  final List<UsuarioAdminModel> usuarios;
  final int totalUsuarios;
  final String? busquedaActual;
  final bool isLoading;
  final bool hasError;
  final String? errorMessage;
  final String? usuarioIdCambiando;
  final VoidCallback onRefresh;
  final VoidCallback onClearSearch;
  final Future<void> Function(BuildContext, UsuarioAdminModel) onCambiarRol;
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
    required this.usuarios,
    required this.totalUsuarios,
    required this.busquedaActual,
    required this.isLoading,
    required this.hasError,
    required this.errorMessage,
    required this.usuarioIdCambiando,
    required this.onRefresh,
    required this.onClearSearch,
    required this.onCambiarRol,
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

  /// Formatea fecha como "15 Ene 2026" o "Hace X dias" si es reciente
  String _formatMiembroDesde(DateTime? fecha) {
    if (fecha == null) return '-';

    final now = DateTime.now();
    final difference = now.difference(fecha);

    if (difference.inDays == 0) {
      return 'Hoy';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} dias';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'Hace $weeks sem.';
    } else {
      // Formato: "15 Ene 2026"
      final formatter = DateFormat("dd MMM yyyy", 'es_PE');
      return formatter.format(fecha);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Obtener ID del usuario actual
    final sessionState = context.read<SessionBloc>().state;
    String? currentUserId;
    if (sessionState is SessionAuthenticated) {
      currentUserId = sessionState.usuarioId;
    }

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
                      'Listado de Usuarios',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: DesignTokens.fontWeightSemiBold,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spacingXxs),
                    Text(
                      'Gestiona roles y permisos de los usuarios del sistema',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Contador de registros
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
                      '$totalUsuarios registro${totalUsuarios != 1 ? 's' : ''}',
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
        if (totalUsuarios > 0)
          _PaginationControls(
            currentPage: currentPage,
            totalPages: totalPages,
            itemsPerPage: itemsPerPage,
            itemsPerPageOptions: itemsPerPageOptions,
            startIndex: startIndex,
            endIndex: endIndex,
            totalItems: totalUsuarios,
            onPageChanged: onPageChanged,
            onItemsPerPageChanged: onItemsPerPageChanged,
          ),

        // Contenido de la tabla
        Expanded(
          child: _buildTableContent(context, currentUserId),
        ),
      ],
    );
  }

  Widget _buildTableContent(BuildContext context, String? currentUserId) {
    final colorScheme = Theme.of(context).colorScheme;

    // Estado de carga inicial
    if (isLoading && usuarios.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error sin datos previos
    if (hasError && usuarios.isEmpty) {
      return Center(
        child: EmptyStateWidget.error(
          title: 'Error al cargar usuarios',
          description: errorMessage ?? 'Ocurrio un error inesperado',
          actionLabel: 'Reintentar',
          onAction: onRefresh,
        ),
      );
    }

    // Estado vacio
    if (usuarios.isEmpty) {
      if (busquedaActual != null && busquedaActual!.isNotEmpty) {
        return Center(
          child: EmptyStateWidget.noResults(
            description: 'No se encontraron usuarios para "$busquedaActual"',
            onAction: onClearSearch,
          ),
        );
      }
      return const Center(
        child: EmptyStateWidget.noData(
          title: 'No hay usuarios',
          description: 'Aun no hay usuarios registrados en el sistema',
          icon: Icons.people_outline,
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
              child: SizedBox(
                width: double.infinity,
                child: DataTable(
                  columnSpacing: DesignTokens.spacingM,
                  headingRowColor: WidgetStateProperty.all(
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  ),
                  columns: const [
                    DataColumn(label: Expanded(child: Text('Usuario'))),
                    DataColumn(label: SizedBox(width: 120, child: Text('Rol'))),
                    DataColumn(label: SizedBox(width: 120, child: Text('Estado'))),
                    DataColumn(label: SizedBox(width: 140, child: Text('Miembro desde'))),
                    DataColumn(label: SizedBox(width: 100, child: Text('Acciones'))),
                  ],
                  rows: usuarios.map((usuario) {
                    final isCurrentUser = usuario.id == currentUserId;
                    final isLoadingRol = usuarioIdCambiando == usuario.id;

                    return DataRow(
                      cells: [
                        // Columna: Usuario (Avatar + Nombre + Email)
                        DataCell(
                          Row(
                            children: [
                              _buildAvatar(usuario, colorScheme),
                              const SizedBox(width: DesignTokens.spacingM),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            usuario.nombreCompleto,
                                            style: const TextStyle(
                                              fontWeight: DesignTokens.fontWeightMedium,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (isCurrentUser) ...[
                                          const SizedBox(width: DesignTokens.spacingXs),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: DesignTokens.spacingS,
                                              vertical: DesignTokens.spacingXxs,
                                            ),
                                            decoration: BoxDecoration(
                                              color: colorScheme.primaryContainer,
                                              borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                                            ),
                                            child: Text(
                                              'Tu',
                                              style: TextStyle(
                                                fontSize: DesignTokens.fontSizeXs - 1,
                                                color: colorScheme.onPrimaryContainer,
                                                fontWeight: DesignTokens.fontWeightMedium,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: DesignTokens.spacingXxs),
                                    Text(
                                      usuario.email,
                                      style: TextStyle(
                                        fontSize: DesignTokens.fontSizeXs,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Columna: Rol (Chip con color)
                        DataCell(
                          SizedBox(
                            width: 120,
                            child: _buildRolChip(usuario),
                          ),
                        ),

                        // Columna: Estado (Chip con indicador)
                        DataCell(
                          SizedBox(
                            width: 120,
                            child: _buildEstadoChip(usuario),
                          ),
                        ),

                        // Columna: Miembro desde
                        DataCell(
                          SizedBox(
                            width: 140,
                            child: Text(
                              _formatMiembroDesde(usuario.createdAt),
                              style: TextStyle(
                                fontSize: DesignTokens.fontSizeXs,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),

                        // Columna: Acciones (IconButtons)
                        DataCell(
                          SizedBox(
                            width: 100,
                            child: _buildAcciones(
                              context,
                              usuario,
                              isCurrentUser,
                              isLoadingRol,
                              colorScheme,
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
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

  Widget _buildAvatar(UsuarioAdminModel usuario, ColorScheme colorScheme) {
    final inicial = usuario.nombreCompleto.isNotEmpty
        ? usuario.nombreCompleto[0].toUpperCase()
        : '?';

    Color avatarColor;
    switch (usuario.rol) {
      case 'admin':
        avatarColor = DesignTokens.primaryColor;
        break;
      case 'entrenador':
        avatarColor = DesignTokens.secondaryColor;
        break;
      case 'arbitro':
        avatarColor = DesignTokens.accentColor;
        break;
      default:
        avatarColor = colorScheme.tertiary;
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

  Widget _buildRolChip(UsuarioAdminModel usuario) {
    Color bgColor;
    IconData icon;

    switch (usuario.rol) {
      case 'admin':
        bgColor = DesignTokens.primaryColor;
        icon = Icons.admin_panel_settings;
        break;
      case 'entrenador':
        bgColor = DesignTokens.secondaryColor;
        icon = Icons.sports;
        break;
      case 'arbitro':
        bgColor = DesignTokens.accentColor;
        icon = Icons.gavel;
        break;
      default:
        bgColor = const Color(0xFF64748B);
        icon = Icons.person;
    }

    return StatusBadge(
      label: usuario.rolFormateado,
      backgroundColor: bgColor,
      size: StatusBadgeSize.small,
      icon: icon,
    );
  }

  Widget _buildEstadoChip(UsuarioAdminModel usuario) {
    StatusBadgeType type;
    switch (usuario.estado) {
      case 'aprobado':
        type = StatusBadgeType.activo;
        break;
      case 'pendiente':
        type = StatusBadgeType.enCurso;
        break;
      case 'rechazado':
        type = StatusBadgeType.derrota;
        break;
      default:
        type = StatusBadgeType.inactivo;
    }

    return StatusBadge(
      label: usuario.estadoFormateado,
      type: type,
      size: StatusBadgeSize.small,
    );
  }

  Widget _buildAcciones(
    BuildContext context,
    UsuarioAdminModel usuario,
    bool isCurrentUser,
    bool isLoadingRol,
    ColorScheme colorScheme,
  ) {
    if (isLoadingRol) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Boton editar rol (CA-002, CA-004)
        Tooltip(
          message: isCurrentUser
              ? 'No puedes cambiar tu propio rol'
              : 'Cambiar rol',
          child: IconButton(
            onPressed: isCurrentUser ? null : () => onCambiarRol(context, usuario),
            icon: Icon(
              Icons.edit_outlined,
              color: isCurrentUser
                  ? colorScheme.onSurface.withValues(alpha: DesignTokens.opacityDisabled)
                  : colorScheme.primary,
            ),
            iconSize: DesignTokens.iconSizeS + 2,
          ),
        ),
      ],
    );
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
          hintText: 'Buscar por nombre o email...',
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

/// Leyenda de roles
class _RolLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        _RolLegendItem(
          icon: Icons.admin_panel_settings,
          label: 'Administrador',
          color: DesignTokens.primaryColor,
        ),
        const SizedBox(height: DesignTokens.spacingXs),
        _RolLegendItem(
          icon: Icons.sports,
          label: 'Entrenador',
          color: DesignTokens.secondaryColor,
        ),
        const SizedBox(height: DesignTokens.spacingXs),
        _RolLegendItem(
          icon: Icons.person,
          label: 'Jugador',
          color: colorScheme.tertiary,
        ),
        const SizedBox(height: DesignTokens.spacingXs),
        _RolLegendItem(
          icon: Icons.gavel,
          label: 'Arbitro',
          color: DesignTokens.accentColor,
        ),
      ],
    );
  }
}

class _RolLegendItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _RolLegendItem({
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
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
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
