import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_card.dart';
import '../../data/models/mi_grupo_model.dart';
import '../bloc/mis_grupos/mis_grupos_bloc.dart';
import '../bloc/mis_grupos/mis_grupos_event.dart';
import '../bloc/mis_grupos/mis_grupos_state.dart';

/// E002-HU-002: Pantalla Ver Mis Grupos
/// CA-001: Lista con logo, nombre, rol, miembros
/// CA-002: Indicador visual de rol diferenciado
/// CA-003: Ordenados por ultimo acceso
/// CA-004: Tap para acceder al grupo
/// CA-005: Estado vacio con opcion de crear grupo
class MisGruposPage extends StatelessWidget {
  const MisGruposPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: const Text('Mis Grupos'),
        centerTitle: true,
      ),
      body: BlocBuilder<MisGruposBloc, MisGruposState>(
        builder: (context, state) {
          if (state is MisGruposLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is MisGruposError) {
            return _buildErrorView(context, state.message);
          }

          if (state is MisGruposEmpty) {
            return _buildEmptyView(context);
          }

          if (state is MisGruposLoaded) {
            return _buildGruposList(context, state.grupos);
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: BlocBuilder<MisGruposBloc, MisGruposState>(
        builder: (context, state) {
          if (state is MisGruposLoaded) {
            return FloatingActionButton(
              onPressed: () => context.push('/grupos/crear'),
              backgroundColor: DesignTokens.primaryColor,
              foregroundColor: Colors.white,
              child: const Icon(Icons.group_add),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  /// CA-001: Lista de grupos con scroll
  Widget _buildGruposList(BuildContext context, List<MiGrupoModel> grupos) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<MisGruposBloc>().add(const CargarMisGruposEvent());
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(DesignTokens.spacingM),
        itemCount: grupos.length,
        separatorBuilder: (_, __) =>
            const SizedBox(height: DesignTokens.spacingS),
        itemBuilder: (context, index) {
          return _GrupoCard(grupo: grupos[index]);
        },
      ),
    );
  }

  /// CA-005 / RN-004 / RN-005: Estado vacio
  Widget _buildEmptyView(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
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
              'Aun no perteneces a ningun grupo',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: DesignTokens.fontWeightSemiBold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.spacingS),
            Text(
              'Crea tu primer grupo deportivo para comenzar a organizar tus pichangas',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.spacingXl),
            // RN-004 / RN-005: Opcion para crear grupo
            FilledButton.icon(
              onPressed: () => context.push('/grupos/crear'),
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
    );
  }

  /// Vista de error con retry
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
                context.read<MisGruposBloc>().add(const CargarMisGruposEvent());
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

/// CA-001 + CA-002: Card individual de grupo
/// Muestra logo, nombre, rol con indicador visual, cantidad miembros
class _GrupoCard extends StatelessWidget {
  const _GrupoCard({required this.grupo});

  final MiGrupoModel grupo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
      variant: AppCardVariant.outlined,
      onTap: () {
        // CA-004: Registrar acceso y navegar al grupo
        context
            .read<MisGruposBloc>()
            .add(SeleccionarGrupoEvent(grupoId: grupo.grupoId));

        // TODO: Navegar al contexto del grupo (E001-HU-003)
        // Por ahora vuelve al home
        context.push('/');
      },
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      child: Row(
        children: [
          // Logo del grupo o indicador por defecto (RN-002)
          _buildLogo(colorScheme),
          const SizedBox(width: DesignTokens.spacingM),

          // Info del grupo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nombre del grupo
                Text(
                  grupo.nombre,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: DesignTokens.fontWeightSemiBold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
                Row(
                  children: [
                    // CA-002: Badge de rol con color diferenciado
                    _buildRolBadge(theme, colorScheme),
                    const SizedBox(width: DesignTokens.spacingS),
                    // Cantidad de miembros
                    Icon(
                      Icons.people_outline,
                      size: DesignTokens.iconSizeS,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: DesignTokens.spacingXxs),
                    Text(
                      '${grupo.cantidadMiembros}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Icono editar (solo admin/coadmin)
          if (grupo.esAdminOCoadmin)
            IconButton(
              onPressed: () =>
                  context.push('/grupos/${grupo.grupoId}/editar'),
              icon: Icon(
                Icons.edit_outlined,
                size: DesignTokens.iconSizeS,
                color: colorScheme.onSurfaceVariant,
              ),
              tooltip: 'Editar grupo',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
            ),

          // Flecha de navegacion
          Icon(
            Icons.chevron_right,
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  /// Logo del grupo o inicial como fallback (RN-002)
  Widget _buildLogo(ColorScheme colorScheme) {
    if (grupo.logoUrl != null && grupo.logoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        child: Image.network(
          grupo.logoUrl!,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildLogoPlaceholder(colorScheme),
        ),
      );
    }
    return _buildLogoPlaceholder(colorScheme);
  }

  Widget _buildLogoPlaceholder(ColorScheme colorScheme) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: _getRolColor(grupo.miRol).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
      ),
      child: Center(
        child: Text(
          grupo.nombre.isNotEmpty ? grupo.nombre[0].toUpperCase() : 'G',
          style: TextStyle(
            fontSize: 24,
            fontWeight: DesignTokens.fontWeightBold,
            color: _getRolColor(grupo.miRol),
          ),
        ),
      ),
    );
  }

  /// CA-002: Badge de rol con color diferenciado
  Widget _buildRolBadge(ThemeData theme, ColorScheme colorScheme) {
    final rolColor = _getRolColor(grupo.miRol);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingS,
        vertical: DesignTokens.spacingXxs,
      ),
      decoration: BoxDecoration(
        color: rolColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
        border: Border.all(
          color: rolColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getRolIcon(grupo.miRol),
            size: 12,
            color: rolColor,
          ),
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

  /// Color segun rol en grupo
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

  /// Icono segun rol en grupo
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
