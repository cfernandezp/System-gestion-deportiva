import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/dashboard_shell.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_shimmer.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../auth/presentation/bloc/session/session_bloc.dart';
import '../../../auth/presentation/bloc/session/session_state.dart';
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
/// Usa ResponsiveLayout: Mobile App Style + Desktop Dashboard Style
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
        return ResponsiveLayout(
          mobileBody: _MobileUsuariosView(
            state: state,
            searchController: _searchController,
            debouncer: _debouncer,
            onSearch: _onSearch,
            onClearSearch: _onClearSearch,
            onRefresh: _onRefresh,
            onCambiarRol: _showCambiarRolDialog,
          ),
          desktopBody: _DesktopUsuariosView(
            state: state,
            searchController: _searchController,
            debouncer: _debouncer,
            onSearch: _onSearch,
            onClearSearch: _onClearSearch,
            onRefresh: _onRefresh,
            onCambiarRol: _showCambiarRolDialog,
          ),
        );
      },
    );
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
      // Limpiar mensaje despues de mostrar
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
    setState(() {}); // Para actualizar el icono de limpiar
    // CA-005: Busqueda con debounce
    _debouncer.run(() {
      context.read<UsuariosBloc>().add(BuscarUsuariosEvent(query: value));
    });
  }

  void _onClearSearch() {
    _searchController.clear();
    context.read<UsuariosBloc>().add(const CargarUsuariosEvent());
    setState(() {});
  }

  void _onRefresh() {
    _searchController.clear();
    context.read<UsuariosBloc>().add(const CargarUsuariosEvent());
  }

  Future<void> _showCambiarRolDialog(BuildContext context, dynamic usuario) async {
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
// VISTA MOBILE - App Style
// ============================================

class _MobileUsuariosView extends StatelessWidget {
  final UsuariosState state;
  final TextEditingController searchController;
  final _Debouncer debouncer;
  final void Function(String) onSearch;
  final VoidCallback onClearSearch;
  final VoidCallback onRefresh;
  final Future<void> Function(BuildContext, dynamic) onCambiarRol;

  const _MobileUsuariosView({
    required this.state,
    required this.searchController,
    required this.debouncer,
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
          // Boton de refrescar
          IconButton(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar lista',
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de busqueda (CA-005)
          _SearchBar(
            controller: searchController,
            colorScheme: colorScheme,
            onSearch: onSearch,
            onClear: onClearSearch,
          ),

          // Contenido principal
          Expanded(
            child: _UsuariosContent(
              state: state,
              searchController: searchController,
              onRefresh: onRefresh,
              onCambiarRol: onCambiarRol,
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 3),
    );
  }
}

// ============================================
// VISTA DESKTOP - Dashboard Style
// ============================================

class _DesktopUsuariosView extends StatelessWidget {
  final UsuariosState state;
  final TextEditingController searchController;
  final _Debouncer debouncer;
  final void Function(String) onSearch;
  final VoidCallback onClearSearch;
  final VoidCallback onRefresh;
  final Future<void> Function(BuildContext, dynamic) onCambiarRol;

  const _DesktopUsuariosView({
    required this.state,
    required this.searchController,
    required this.debouncer,
    required this.onSearch,
    required this.onClearSearch,
    required this.onRefresh,
    required this.onCambiarRol,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
      child: Column(
        children: [
          // Barra de busqueda (CA-005) - version desktop con mas espacio
          _DesktopSearchBar(
            controller: searchController,
            colorScheme: colorScheme,
            onSearch: onSearch,
            onClear: onClearSearch,
          ),

          // Contenido principal
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(DesignTokens.spacingL),
              child: _UsuariosContent(
                state: state,
                searchController: searchController,
                onRefresh: onRefresh,
                onCambiarRol: onCambiarRol,
                isDesktop: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// WIDGETS COMPARTIDOS
// ============================================

/// Barra de busqueda para mobile
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ColorScheme colorScheme;
  final void Function(String) onSearch;
  final VoidCallback onClear;

  const _SearchBar({
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
      child: Row(
        children: [
          Expanded(
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
          ),
        ],
      ),
    );
  }
}

/// Barra de busqueda para desktop - con layout horizontal
class _DesktopSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ColorScheme colorScheme;
  final void Function(String) onSearch;
  final VoidCallback onClear;

  const _DesktopSearchBar({
    required this.controller,
    required this.colorScheme,
    required this.onSearch,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
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
          // Barra de busqueda (CA-005)
          Expanded(
            flex: 2,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
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
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

/// Contenido principal de la lista de usuarios
class _UsuariosContent extends StatelessWidget {
  final UsuariosState state;
  final TextEditingController searchController;
  final VoidCallback onRefresh;
  final Future<void> Function(BuildContext, dynamic) onCambiarRol;
  final bool isDesktop;

  const _UsuariosContent({
    required this.state,
    required this.searchController,
    required this.onRefresh,
    required this.onCambiarRol,
    this.isDesktop = false,
  });

  @override
  Widget build(BuildContext context) {
    // Estado de carga inicial
    if (state is UsuariosLoading) {
      return _buildLoadingState();
    }

    // Estado de error sin datos previos
    if (state is UsuariosError && (state as UsuariosError).usuariosPrevios == null) {
      return _buildErrorState(context, state as UsuariosError);
    }

    // Estado cargando rol (muestra lista con loading parcial)
    if (state is UsuariosCambiandoRol) {
      final s = state as UsuariosCambiandoRol;
      return _buildUsuariosList(
        context: context,
        usuarios: s.usuarios,
        total: s.total,
        busquedaActual: s.busquedaActual,
        usuarioIdCambiando: s.usuarioIdCambiando,
      );
    }

    // Estado cargado
    if (state is UsuariosLoaded) {
      final s = state as UsuariosLoaded;
      if (s.usuarios.isEmpty) {
        return _buildEmptyState(context, s.busquedaActual);
      }
      return _buildUsuariosList(
        context: context,
        usuarios: s.usuarios,
        total: s.total,
        busquedaActual: s.busquedaActual,
      );
    }

    // Estado error con datos previos
    if (state is UsuariosError && (state as UsuariosError).usuariosPrevios != null) {
      final s = state as UsuariosError;
      return _buildUsuariosList(
        context: context,
        usuarios: s.usuariosPrevios!,
        total: s.totalPrevio ?? 0,
        busquedaActual: s.busquedaActual,
      );
    }

    // Estado inicial - mostrar cargando
    return _buildLoadingState();
  }

  Widget _buildLoadingState() {
    return const Padding(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      child: ShimmerList(
        itemCount: 5,
        itemHeight: 100,
        hasAvatar: true,
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, UsuariosError state) {
    // Error especifico de permisos (CA-006)
    if (state.errorType == UsuariosErrorType.sinPermisos) {
      return EmptyStateWidget(
        title: 'Acceso restringido',
        description: state.message,
        icon: Icons.lock_outline,
        actionLabel: 'Volver',
        onAction: () => Navigator.of(context).pop(),
      );
    }

    return EmptyStateWidget.error(
      title: 'Error al cargar usuarios',
      description: state.message,
      actionLabel: 'Reintentar',
      onAction: onRefresh,
    );
  }

  Widget _buildEmptyState(BuildContext context, String? busquedaActual) {
    if (busquedaActual != null && busquedaActual.isNotEmpty) {
      return EmptyStateWidget.noResults(
        description: 'No se encontraron usuarios para "$busquedaActual"',
        onAction: () {
          searchController.clear();
          onRefresh();
        },
      );
    }

    return const EmptyStateWidget.noData(
      title: 'No hay usuarios',
      description: 'Aun no hay usuarios registrados en el sistema',
      icon: Icons.people_outline,
    );
  }

  Widget _buildUsuariosList({
    required BuildContext context,
    required List usuarios,
    required int total,
    String? busquedaActual,
    String? usuarioIdCambiando,
  }) {
    // Obtener ID del usuario actual para CA-004
    final sessionState = context.read<SessionBloc>().state;
    String? currentUserId;
    if (sessionState is SessionAuthenticated) {
      currentUserId = sessionState.usuarioId;
    }

    return Column(
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
                '$total usuario${total != 1 ? 's' : ''}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              if (busquedaActual != null && busquedaActual.isNotEmpty) ...[
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

        // Lista de usuarios - Grid en desktop, List en mobile
        Expanded(
          child: isDesktop
              ? _buildDesktopGrid(context, usuarios, currentUserId, usuarioIdCambiando)
              : _buildMobileList(context, usuarios, currentUserId, usuarioIdCambiando),
        ),
      ],
    );
  }

  Widget _buildMobileList(
    BuildContext context,
    List usuarios,
    String? currentUserId,
    String? usuarioIdCambiando,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingS,
        vertical: DesignTokens.spacingXs,
      ),
      itemCount: usuarios.length,
      itemBuilder: (context, index) {
        final usuario = usuarios[index];
        final isCurrentUser = usuario.id == currentUserId;
        final isLoading = usuarioIdCambiando == usuario.id;

        return UsuarioCard(
          usuario: usuario,
          isCurrentUser: isCurrentUser,
          isLoading: isLoading,
          onCambiarRol: () => onCambiarRol(context, usuario),
        );
      },
    );
  }

  Widget _buildDesktopGrid(
    BuildContext context,
    List usuarios,
    String? currentUserId,
    String? usuarioIdCambiando,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calcular columnas basado en el ancho disponible
        final columns = (constraints.maxWidth / 400).floor().clamp(1, 3);

        return GridView.builder(
          padding: const EdgeInsets.all(DesignTokens.spacingXs),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: DesignTokens.spacingM,
            crossAxisSpacing: DesignTokens.spacingM,
            mainAxisExtent: 100, // Altura fija del card
          ),
          itemCount: usuarios.length,
          itemBuilder: (context, index) {
            final usuario = usuarios[index];
            final isCurrentUser = usuario.id == currentUserId;
            final isLoading = usuarioIdCambiando == usuario.id;

            return UsuarioCard(
              usuario: usuario,
              isCurrentUser: isCurrentUser,
              isLoading: isLoading,
              onCambiarRol: () => onCambiarRol(context, usuario),
            );
          },
        );
      },
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
