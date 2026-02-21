import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../data/models/miembro_grupo_model.dart';
import '../bloc/miembros_grupo/miembros_grupo_bloc.dart';
import '../bloc/miembros_grupo/miembros_grupo_event.dart';
import '../bloc/miembros_grupo/miembros_grupo_state.dart';

/// E001-HU-004 CA-005: Ver lista de jugadores del grupo con estado
/// Patron mobile: ListView con Cards, FAB para invitar
class MiembrosGrupoPage extends StatelessWidget {
  final String grupoId;
  final bool esAdminOCoadmin;

  const MiembrosGrupoPage({
    super.key,
    required this.grupoId,
    required this.esAdminOCoadmin,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Miembros del Grupo'),
        centerTitle: true,
      ),
      body: BlocBuilder<MiembrosGrupoBloc, MiembrosGrupoState>(
        builder: (context, state) {
          if (state is MiembrosGrupoLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is MiembrosGrupoError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(DesignTokens.spacingL),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                    const SizedBox(height: DesignTokens.spacingM),
                    Text(state.message, textAlign: TextAlign.center),
                    const SizedBox(height: DesignTokens.spacingM),
                    FilledButton.icon(
                      onPressed: () => context
                          .read<MiembrosGrupoBloc>()
                          .add(CargarMiembrosGrupoEvent(grupoId: grupoId)),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is MiembrosGrupoLoaded) {
            if (state.miembros.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.group_off, size: 64, color: colorScheme.onSurfaceVariant),
                    const SizedBox(height: DesignTokens.spacingM),
                    Text(
                      'No hay miembros en este grupo',
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context
                    .read<MiembrosGrupoBloc>()
                    .add(CargarMiembrosGrupoEvent(grupoId: grupoId));
              },
              child: Column(
                children: [
                  // Header con conteo
                  Padding(
                    padding: const EdgeInsets.all(DesignTokens.spacingM),
                    child: Row(
                      children: [
                        Icon(Icons.people, size: 20, color: colorScheme.primary),
                        const SizedBox(width: DesignTokens.spacingS),
                        Text(
                          '${state.total} miembros',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: DesignTokens.fontWeightSemiBold,
                          ),
                        ),
                        if (state.pendientes.isNotEmpty) ...[
                          const SizedBox(width: DesignTokens.spacingS),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: DesignTokens.spacingS,
                              vertical: DesignTokens.spacingXxs,
                            ),
                            decoration: BoxDecoration(
                              color: DesignTokens.accentColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                            ),
                            child: Text(
                              '${state.pendientes.length} pendientes',
                              style: textTheme.labelSmall?.copyWith(
                                color: DesignTokens.accentColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Lista de miembros
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.spacingM,
                      ),
                      itemCount: state.miembros.length,
                      itemBuilder: (context, index) {
                        return _MiembroCard(miembro: state.miembros[index]);
                      },
                    ),
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
      // RN-001: Solo admin/coadmin pueden invitar
      floatingActionButton: esAdminOCoadmin
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/grupos/$grupoId/invitar'),
              icon: const Icon(Icons.person_add),
              label: const Text('Invitar'),
            )
          : null,
    );
  }
}

/// Card de miembro individual
/// CA-005: Nombre o celular + estado
class _MiembroCard extends StatelessWidget {
  final MiembroGrupoModel miembro;

  const _MiembroCard({required this.miembro});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: DesignTokens.spacingS),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getRolColor(miembro.rol).withValues(alpha: 0.1),
          backgroundImage: miembro.fotoUrl != null
              ? NetworkImage(miembro.fotoUrl!)
              : null,
          child: miembro.fotoUrl == null
              ? Text(
                  miembro.displayName.isNotEmpty
                      ? miembro.displayName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: _getRolColor(miembro.rol),
                    fontWeight: DesignTokens.fontWeightBold,
                  ),
                )
              : null,
        ),
        title: Text(
          miembro.displayName,
          style: textTheme.bodyLarge?.copyWith(
            fontWeight: DesignTokens.fontWeightMedium,
          ),
        ),
        subtitle: Row(
          children: [
            // Rol badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingXs,
                vertical: 1,
              ),
              decoration: BoxDecoration(
                color: _getRolColor(miembro.rol).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DesignTokens.radiusXs),
              ),
              child: Text(
                miembro.rolFormateado,
                style: textTheme.labelSmall?.copyWith(
                  color: _getRolColor(miembro.rol),
                  fontWeight: DesignTokens.fontWeightMedium,
                ),
              ),
            ),
            const SizedBox(width: DesignTokens.spacingS),
            // Estado
            Text(
              miembro.estadoFormateado,
              style: textTheme.labelSmall?.copyWith(
                color: miembro.estaPendiente
                    ? DesignTokens.accentColor
                    : DesignTokens.successColor,
              ),
            ),
          ],
        ),
        trailing: miembro.estaPendiente
            ? Icon(
                Icons.schedule,
                size: DesignTokens.iconSizeS,
                color: DesignTokens.accentColor,
              )
            : Icon(
                Icons.check_circle,
                size: DesignTokens.iconSizeS,
                color: DesignTokens.successColor,
              ),
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
}
