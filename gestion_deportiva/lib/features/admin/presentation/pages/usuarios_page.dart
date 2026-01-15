import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_shimmer.dart';
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion de Usuarios'),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        actions: [
          // Boton de refrescar
          IconButton(
            onPressed: () {
              _searchController.clear();
              context.read<UsuariosBloc>().add(const CargarUsuariosEvent());
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar lista',
          ),
        ],
      ),
      body: BlocConsumer<UsuariosBloc, UsuariosState>(
        listener: _handleStateChanges,
        builder: (context, state) {
          return Column(
            children: [
              // Barra de busqueda (CA-005)
              _buildSearchBar(context, colorScheme),

              // Contenido principal
              Expanded(
                child: _buildContent(context, state),
              ),
            ],
          );
        },
      ),
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

  Widget _buildSearchBar(BuildContext context, ColorScheme colorScheme) {
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
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          context.read<UsuariosBloc>().add(const CargarUsuariosEvent());
                        },
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
              onChanged: (value) {
                setState(() {}); // Para actualizar el icono de limpiar
                // CA-005: Busqueda con debounce
                _debouncer.run(() {
                  context.read<UsuariosBloc>().add(BuscarUsuariosEvent(query: value));
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, UsuariosState state) {
    // Estado de carga inicial
    if (state is UsuariosLoading) {
      return _buildLoadingState();
    }

    // Estado de error sin datos previos
    if (state is UsuariosError && state.usuariosPrevios == null) {
      return _buildErrorState(context, state);
    }

    // Estado cargando rol (muestra lista con loading parcial)
    if (state is UsuariosCambiandoRol) {
      return _buildUsuariosList(
        context: context,
        usuarios: state.usuarios,
        total: state.total,
        busquedaActual: state.busquedaActual,
        usuarioIdCambiando: state.usuarioIdCambiando,
      );
    }

    // Estado cargado
    if (state is UsuariosLoaded) {
      if (state.usuarios.isEmpty) {
        return _buildEmptyState(context, state.busquedaActual);
      }
      return _buildUsuariosList(
        context: context,
        usuarios: state.usuarios,
        total: state.total,
        busquedaActual: state.busquedaActual,
      );
    }

    // Estado error con datos previos
    if (state is UsuariosError && state.usuariosPrevios != null) {
      return _buildUsuariosList(
        context: context,
        usuarios: state.usuariosPrevios!,
        total: state.totalPrevio ?? 0,
        busquedaActual: state.busquedaActual,
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
      onAction: () {
        context.read<UsuariosBloc>().add(const CargarUsuariosEvent());
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, String? busquedaActual) {
    if (busquedaActual != null && busquedaActual.isNotEmpty) {
      return EmptyStateWidget.noResults(
        description: 'No se encontraron usuarios para "$busquedaActual"',
        onAction: () {
          _searchController.clear();
          context.read<UsuariosBloc>().add(const CargarUsuariosEvent());
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

        // Lista de usuarios
        Expanded(
          child: ListView.builder(
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
                onCambiarRol: () => _showCambiarRolDialog(context, usuario),
              );
            },
          ),
        ),
      ],
    );
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
