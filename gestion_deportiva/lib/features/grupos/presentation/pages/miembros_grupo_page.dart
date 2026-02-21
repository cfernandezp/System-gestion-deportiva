import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../data/models/miembro_grupo_model.dart';
import '../bloc/miembros_grupo/miembros_grupo_bloc.dart';
import '../bloc/miembros_grupo/miembros_grupo_event.dart';
import '../bloc/miembros_grupo/miembros_grupo_state.dart';

/// E002-HU-005: Ver Miembros del Grupo
/// CA-001 a CA-005, RN-001 a RN-005
/// Patron mobile: ListView con Cards, busqueda, filtros por rol, privacidad celular
class MiembrosGrupoPage extends StatefulWidget {
  final String grupoId;
  final bool esAdminOCoadmin;

  const MiembrosGrupoPage({
    super.key,
    required this.grupoId,
    required this.esAdminOCoadmin,
  });

  @override
  State<MiembrosGrupoPage> createState() => _MiembrosGrupoPageState();
}

class _MiembrosGrupoPageState extends State<MiembrosGrupoPage> {
  final _searchController = TextEditingController();

  /// RN-002: Celular del usuario actual para identificar "soy yo"
  String _currentUserPhone = '';

  @override
  void initState() {
    super.initState();
    // Obtener celular del usuario actual desde Supabase Auth
    final phone = Supabase.instance.client.auth.currentUser?.phone ?? '';
    // Normalizar: quitar prefijo +51 si existe (Peru)
    _currentUserPhone = phone.replaceFirst('+51', '');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// RN-002: Determina si un miembro es el usuario actual
  bool _esMiembro(MiembroGrupoModel miembro) {
    return miembro.celular == _currentUserPhone;
  }

  /// RN-002: Determina si se muestra el celular completo
  /// Admin/coadmin ven todos los celulares completos
  /// Cada miembro ve su propio celular completo
  bool _mostrarCelularCompleto(MiembroGrupoModel miembro) {
    return widget.esAdminOCoadmin || _esMiembro(miembro);
  }

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
                          .add(CargarMiembrosGrupoEvent(grupoId: widget.grupoId)),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is MiembrosGrupoLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                context
                    .read<MiembrosGrupoBloc>()
                    .add(CargarMiembrosGrupoEvent(grupoId: widget.grupoId));
              },
              child: Column(
                children: [
                  // Header con conteo
                  _buildHeader(state, colorScheme, textTheme),

                  // CA-004 / RN-005: Barra de busqueda
                  _buildSearchBar(colorScheme),

                  // CA-003 / RN-004: Filtros por rol
                  _buildFilterChips(state, colorScheme),

                  // CA-005: Mensaje si es el unico miembro
                  if (state.esUnicoMiembro)
                    _buildSoloMemberMessage(colorScheme, textTheme),

                  // Lista de miembros filtrados
                  Expanded(
                    child: _buildMemberList(state, textTheme),
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
      // Solo admin/coadmin pueden invitar
      floatingActionButton: widget.esAdminOCoadmin
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/grupos/${widget.grupoId}/invitar'),
              icon: const Icon(Icons.person_add),
              label: const Text('Invitar'),
            )
          : null,
    );
  }

  /// Header con conteo total y pendientes
  Widget _buildHeader(
    MiembrosGrupoLoaded state,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.spacingM,
        DesignTokens.spacingM,
        DesignTokens.spacingM,
        DesignTokens.spacingS,
      ),
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
    );
  }

  /// CA-004 / RN-005: Barra de busqueda por nombre
  Widget _buildSearchBar(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingM,
        vertical: DesignTokens.spacingXs,
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar por nombre...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    context
                        .read<MiembrosGrupoBloc>()
                        .add(const BuscarMiembroEvent(query: ''));
                  },
                )
              : null,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            vertical: DesignTokens.spacingS,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
            borderSide: BorderSide(color: colorScheme.outline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
            borderSide: BorderSide(color: colorScheme.outlineVariant),
          ),
        ),
        onChanged: (value) {
          context
              .read<MiembrosGrupoBloc>()
              .add(BuscarMiembroEvent(query: value));
          // Rebuild para mostrar/ocultar boton clear
          setState(() {});
        },
      ),
    );
  }

  /// CA-003 / RN-004: Chips de filtro por rol
  Widget _buildFilterChips(MiembrosGrupoLoaded state, ColorScheme colorScheme) {
    final roles = [
      {'value': 'admin', 'label': 'Admin'},
      {'value': 'coadmin', 'label': 'Co-Admin'},
      {'value': 'jugador', 'label': 'Jugador'},
      {'value': 'invitado', 'label': 'Invitado'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingM,
        vertical: DesignTokens.spacingXs,
      ),
      child: SizedBox(
        height: 36,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            // Chip "Todos"
            Padding(
              padding: const EdgeInsets.only(right: DesignTokens.spacingS),
              child: FilterChip(
                label: const Text('Todos'),
                selected: state.filtroRol == null,
                onSelected: (_) {
                  context
                      .read<MiembrosGrupoBloc>()
                      .add(const FiltrarPorRolEvent());
                },
                selectedColor: colorScheme.primaryContainer,
                showCheckmark: false,
              ),
            ),
            // Chips por rol
            ...roles.map((rol) => Padding(
                  padding: const EdgeInsets.only(right: DesignTokens.spacingS),
                  child: FilterChip(
                    label: Text(rol['label']!),
                    selected: state.filtroRol == rol['value'],
                    onSelected: (_) {
                      final nuevoRol = state.filtroRol == rol['value']
                          ? null
                          : rol['value'];
                      context
                          .read<MiembrosGrupoBloc>()
                          .add(FiltrarPorRolEvent(rol: nuevoRol));
                    },
                    selectedColor: colorScheme.primaryContainer,
                    showCheckmark: false,
                  ),
                )),
          ],
        ),
      ),
    );
  }

  /// CA-005: Mensaje cuando el admin es el unico miembro
  Widget _buildSoloMemberMessage(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingM,
        vertical: DesignTokens.spacingS,
      ),
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: colorScheme.primary, size: 20),
          const SizedBox(width: DesignTokens.spacingS),
          Expanded(
            child: Text(
              'Aun no hay otros miembros en el grupo. Invita jugadores para comenzar.',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Lista de miembros filtrados
  Widget _buildMemberList(MiembrosGrupoLoaded state, TextTheme textTheme) {
    final filtrados = state.miembrosFiltrados;

    // RN-004 / RN-005: Sin resultados con filtro o busqueda
    if (filtrados.isEmpty && state.tieneFiltrosActivos) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.spacingL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: DesignTokens.spacingM),
              Text(
                state.busqueda.isNotEmpty
                    ? 'No se encontraron miembros con ese nombre'
                    : 'No hay miembros con el rol seleccionado',
                style: textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingM,
      ),
      itemCount: filtrados.length,
      itemBuilder: (context, index) {
        final miembro = filtrados[index];
        return _MiembroCard(
          miembro: miembro,
          mostrarCelularCompleto: _mostrarCelularCompleto(miembro),
          esAdminOCoadmin: widget.esAdminOCoadmin,
        );
      },
    );
  }
}

/// Card de miembro individual
/// CA-001: Nombre, celular (con privacidad), rol, estado
/// CA-002: Admin/coadmin ven celular completo y estado detallado
class _MiembroCard extends StatelessWidget {
  final MiembroGrupoModel miembro;
  final bool mostrarCelularCompleto;
  final bool esAdminOCoadmin;

  const _MiembroCard({
    required this.miembro,
    required this.mostrarCelularCompleto,
    required this.esAdminOCoadmin,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

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
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: DesignTokens.spacingXxs),
            // RN-002: Celular con privacidad segun rol
            Text(
              mostrarCelularCompleto
                  ? miembro.celular
                  : miembro.celularEnmascarado,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: DesignTokens.spacingXs),
            // Rol badge + estado
            Row(
              children: [
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
          ],
        ),
        isThreeLine: true,
        trailing: miembro.estaPendiente
            ? const Icon(
                Icons.schedule,
                size: DesignTokens.iconSizeS,
                color: DesignTokens.accentColor,
              )
            : const Icon(
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
