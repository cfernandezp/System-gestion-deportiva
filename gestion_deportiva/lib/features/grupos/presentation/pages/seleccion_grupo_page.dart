import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../data/models/mi_grupo_model.dart';
import '../cubit/grupo_actual_cubit.dart';
import '../bloc/seleccion_grupo/seleccion_grupo_bloc.dart';
import '../bloc/seleccion_grupo/seleccion_grupo_event.dart';
import '../bloc/seleccion_grupo/seleccion_grupo_state.dart';

/// E001-HU-003: Pantalla de Seleccion de Grupo Post-Login
/// E002-HU-007: Cambiar de Grupo Activo
/// CA-001: Muestra lista de grupos con logo, nombre y rol
/// CA-002: Seleccionar grupo para acceder / E002-HU-007 CA-002: Grupo activo identificable
/// CA-003: Auto-skip con 1 solo grupo (solo en login, no en cambio)
/// CA-004: Ultimo grupo seleccionado destacado (primero en lista)
/// CA-005: Accesible para cambiar de grupo durante sesion
class SeleccionGrupoPage extends StatelessWidget {
  /// E002-HU-007: Si true, viene del flujo "cambiar grupo"
  /// (muestra AppBar con back, no auto-skip con 1 grupo)
  final bool forzarSeleccion;

  const SeleccionGrupoPage({super.key, this.forzarSeleccion = false});

  @override
  Widget build(BuildContext context) {
    // E002-HU-007 CA-002: ID del grupo activo para identificarlo en la lista
    final grupoActivoId = sl<GrupoActualCubit>().grupoActual?.grupoId;

    return Scaffold(
      // E002-HU-007: AppBar con back solo en modo "cambiar grupo"
      appBar: forzarSeleccion
          ? AppBar(
              title: const Text('Cambiar grupo'),
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/'),
              ),
            )
          : null,
      body: BlocConsumer<SeleccionGrupoBloc, SeleccionGrupoState>(
        listener: (context, state) {
          if (state is SeleccionGrupoAutoSeleccionado) {
            // CA-003: Auto-skip, ir directo al home
            context.go('/');
          } else if (state is SeleccionGrupoCompletada) {
            // CA-002: Grupo seleccionado, ir al home
            context.go('/');
          }
        },
        builder: (context, state) {
          if (state is SeleccionGrupoLoading ||
              state is SeleccionGrupoAutoSeleccionado) {
            return _buildLoadingView(context);
          }

          if (state is SeleccionGrupoError) {
            return _buildErrorView(context, state.message);
          }

          if (state is SeleccionGrupoSinGrupos) {
            return _buildSinGruposView(context);
          }

          if (state is SeleccionGrupoLista) {
            return _buildListaGrupos(context, state.grupos, grupoActivoId);
          }

          return _buildLoadingView(context);
        },
      ),
    );
  }

  /// Loading / auto-skip view
  Widget _buildLoadingView(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.sports_soccer,
              size: DesignTokens.iconSizeXl,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingL),
          const CircularProgressIndicator(),
          const SizedBox(height: DesignTokens.spacingM),
          Text(
            'Cargando tus grupos...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  /// CA-001: Lista de grupos para seleccion
  /// E002-HU-007 CA-002: grupoActivoId para identificar grupo activo
  Widget _buildListaGrupos(
    BuildContext context,
    List<MiGrupoModel> grupos,
    String? grupoActivoId,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header (solo si no hay AppBar, es decir modo login)
            if (!forzarSeleccion) ...[
              const SizedBox(height: DesignTokens.spacingXl),
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: DesignTokens.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.sports_soccer,
                    size: DesignTokens.iconSizeL,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: DesignTokens.spacingL),
              Center(
                child: Text(
                  'Selecciona un grupo',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: DesignTokens.fontWeightBold,
                  ),
                ),
              ),
              const SizedBox(height: DesignTokens.spacingS),
              Center(
                child: Text(
                  'Elige el grupo deportivo al que quieres acceder',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: DesignTokens.spacingXl),
            ],

            // Lista de grupos
            Expanded(
              child: ListView.separated(
                itemCount: grupos.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: DesignTokens.spacingS),
                itemBuilder: (context, index) {
                  final grupo = grupos[index];
                  // E002-HU-007 CA-002: Identificar grupo activo
                  final esActivo = grupo.grupoId == grupoActivoId;
                  // CA-004 / RN-003: El primer grupo es el mas reciente
                  final esReciente = index == 0 && !esActivo;
                  return _GrupoSeleccionCard(
                    grupo: grupo,
                    esActivo: esActivo,
                    destacado: esReciente,
                  );
                },
              ),
            ),

            // Boton crear grupo
            const SizedBox(height: DesignTokens.spacingM),
            Center(
              child: TextButton.icon(
                onPressed: () => context.go('/grupos/crear'),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Crear nuevo grupo'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Sin grupos: estado vacio
  Widget _buildSinGruposView(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.spacingXl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.groups_outlined,
                  size: DesignTokens.iconSizeXl,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: DesignTokens.spacingL),
              Text(
                'Bienvenido',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: DesignTokens.fontWeightBold,
                ),
              ),
              const SizedBox(height: DesignTokens.spacingS),
              Text(
                'Aun no perteneces a ningun grupo deportivo.\nCrea tu primer grupo para comenzar.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: DesignTokens.spacingXl),
              FilledButton.icon(
                onPressed: () => context.go('/grupos/crear'),
                icon: const Icon(Icons.group_add_outlined),
                label: const Text('Crear Grupo'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.spacingL,
                    vertical: DesignTokens.spacingM,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Error con retry
  Widget _buildErrorView(BuildContext context, String message) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: DesignTokens.iconSizeXl,
              color: DesignTokens.errorColor,
            ),
            const SizedBox(height: DesignTokens.spacingM),
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.spacingL),
            OutlinedButton.icon(
              onPressed: () {
                context
                    .read<SeleccionGrupoBloc>()
                    .add(const CargarGruposParaSeleccionEvent());
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card de grupo para seleccion
/// CA-001: Logo, nombre, rol
/// CA-002: Tap para seleccionar
/// CA-004: Destacado si es el mas reciente
/// E002-HU-007 CA-002/CA-004: Badge "Grupo activo" cuando es el actual
class _GrupoSeleccionCard extends StatelessWidget {
  const _GrupoSeleccionCard({
    required this.grupo,
    this.esActivo = false,
    this.destacado = false,
  });

  final MiGrupoModel grupo;
  final bool esActivo;
  final bool destacado;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final rolColor = _getRolColor(grupo.miRol);
    // E002-HU-007: Grupo activo tiene prioridad visual sobre "Reciente"
    final tieneDestaque = esActivo || destacado;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          context
              .read<SeleccionGrupoBloc>()
              .add(GrupoSeleccionadoEvent(grupo: grupo));
        },
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        child: Container(
          padding: const EdgeInsets.all(DesignTokens.spacingM),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(DesignTokens.radiusL),
            border: Border.all(
              color: esActivo
                  ? DesignTokens.successColor.withValues(alpha: 0.6)
                  : tieneDestaque
                      ? colorScheme.primary.withValues(alpha: 0.5)
                      : colorScheme.outlineVariant,
              width: tieneDestaque ? 2 : 1,
            ),
            boxShadow: tieneDestaque ? DesignTokens.shadowMd : DesignTokens.shadowSm,
          ),
          child: Row(
            children: [
              // Logo
              _buildLogo(colorScheme, rolColor),
              const SizedBox(width: DesignTokens.spacingM),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre + badge activo/reciente
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            grupo.nombre,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: DesignTokens.fontWeightSemiBold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // E002-HU-007 CA-002/CA-004: Badge "Grupo activo"
                        if (esActivo)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: DesignTokens.spacingS,
                              vertical: DesignTokens.spacingXxs,
                            ),
                            decoration: BoxDecoration(
                              color: DesignTokens.successColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                  DesignTokens.radiusFull),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 12,
                                  color: DesignTokens.successColor,
                                ),
                                const SizedBox(width: DesignTokens.spacingXxs),
                                Text(
                                  'Activo',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: DesignTokens.successColor,
                                    fontWeight: DesignTokens.fontWeightSemiBold,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (destacado)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: DesignTokens.spacingS,
                              vertical: DesignTokens.spacingXxs,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                  DesignTokens.radiusFull),
                            ),
                            child: Text(
                              'Reciente',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: DesignTokens.fontWeightSemiBold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (grupo.lema != null && grupo.lema!.isNotEmpty) ...[
                      const SizedBox(height: DesignTokens.spacingXxs),
                      Text(
                        grupo.lema!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: DesignTokens.spacingS),
                    // RN-002: Rol + miembros
                    Row(
                      children: [
                        _buildRolBadge(theme, rolColor),
                        const SizedBox(width: DesignTokens.spacingS),
                        Icon(
                          Icons.people_outline,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: DesignTokens.spacingXxs),
                        Text(
                          '${grupo.cantidadMiembros} miembros',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: DesignTokens.spacingS),
              Icon(
                esActivo ? Icons.check_circle : Icons.arrow_forward_ios,
                size: esActivo ? 20 : 16,
                color: esActivo
                    ? DesignTokens.successColor
                    : tieneDestaque
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(ColorScheme colorScheme, Color rolColor) {
    if (grupo.logoUrl != null && grupo.logoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        child: Image.network(
          grupo.logoUrl!,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              _buildLogoPlaceholder(colorScheme, rolColor),
        ),
      );
    }
    return _buildLogoPlaceholder(colorScheme, rolColor);
  }

  Widget _buildLogoPlaceholder(ColorScheme colorScheme, Color rolColor) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: rolColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
      ),
      child: Center(
        child: Text(
          grupo.nombre.isNotEmpty ? grupo.nombre[0].toUpperCase() : 'G',
          style: TextStyle(
            fontSize: 24,
            fontWeight: DesignTokens.fontWeightBold,
            color: rolColor,
          ),
        ),
      ),
    );
  }

  Widget _buildRolBadge(ThemeData theme, Color rolColor) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingS,
        vertical: DesignTokens.spacingXxs,
      ),
      decoration: BoxDecoration(
        color: rolColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
        border: Border.all(color: rolColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getRolIcon(grupo.miRol), size: 12, color: rolColor),
          const SizedBox(width: DesignTokens.spacingXxs),
          Text(
            grupo.rolFormateado,
            style: theme.textTheme.labelSmall?.copyWith(
              color: rolColor,
              fontWeight: DesignTokens.fontWeightSemiBold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRolColor(String rol) {
    switch (rol) {
      case 'admin':
        return DesignTokens.secondaryColor;
      case 'coadmin':
        return DesignTokens.accentColor;
      case 'jugador':
        return DesignTokens.primaryColor;
      case 'invitado':
        return const Color(0xFF8B5CF6);
      default:
        return DesignTokens.primaryColor;
    }
  }

  IconData _getRolIcon(String rol) {
    switch (rol) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'coadmin':
        return Icons.manage_accounts;
      case 'jugador':
        return Icons.sports_soccer;
      case 'invitado':
        return Icons.person_outline;
      default:
        return Icons.person_outline;
    }
  }
}
