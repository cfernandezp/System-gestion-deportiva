import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../data/models/miembro_grupo_model.dart';
import '../bloc/miembros_grupo/miembros_grupo_bloc.dart';
import '../bloc/miembros_grupo/miembros_grupo_event.dart';
import '../bloc/miembros_grupo/miembros_grupo_state.dart';

/// E002-HU-005: Ver Miembros del Grupo
/// CA-001 a CA-005, RN-001 a RN-005
/// E002-HU-006: Eliminar Jugador del Grupo
/// E002-HU-004: Nombrar y Quitar Co-Administradores
/// Patron mobile: ListView con Cards, busqueda, filtros por rol, privacidad celular
class MiembrosGrupoPage extends StatefulWidget {
  final String grupoId;
  final bool esAdminOCoadmin;
  final String miRol; // 'admin', 'coadmin', 'jugador', 'invitado'

  const MiembrosGrupoPage({
    super.key,
    required this.grupoId,
    required this.esAdminOCoadmin,
    this.miRol = 'jugador',
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

  /// E002-HU-006: Determina si se puede eliminar un miembro segun permisos
  bool _puedeEliminar(MiembroGrupoModel miembro) {
    // Solo admin/coadmin pueden eliminar (RN-001)
    if (!widget.esAdminOCoadmin) return false;
    // No te puedes eliminar a ti mismo
    if (_esMiembro(miembro)) return false;
    // RN-002: Admin creador (rol 'admin') NO puede ser eliminado
    if (miembro.rol == 'admin') return false;
    // RN-003: Coadmin solo puede eliminar jugadores e invitados
    if (widget.miRol == 'coadmin') {
      return miembro.rol == 'jugador' || miembro.rol == 'invitado';
    }
    // RN-004: Admin puede eliminar coadmins, jugadores e invitados
    return true;
  }

  /// E002-HU-004 CA-001/RN-003: Determina si se puede promover un miembro a co-admin
  /// Solo el admin creador puede, solo jugadores activos
  bool _puedePromover(MiembroGrupoModel miembro) {
    // RN-001: Solo admin creador puede gestionar co-admins
    if (widget.miRol != 'admin') return false;
    // No promover a ti mismo
    if (_esMiembro(miembro)) return false;
    // RN-003: Solo jugadores activos
    if (miembro.rol != 'jugador') return false;
    // No promover pendientes
    if (miembro.estaPendiente) return false;
    if (!miembro.activo) return false;
    return true;
  }

  /// E002-HU-004 CA-002: Determina si se puede degradar un co-admin
  /// Solo el admin creador puede
  bool _puedeDegrada(MiembroGrupoModel miembro) {
    // RN-001: Solo admin creador puede gestionar co-admins
    if (widget.miRol != 'admin') return false;
    // No degradar a ti mismo
    if (_esMiembro(miembro)) return false;
    // Solo degradar co-admins
    if (miembro.rol != 'coadmin') return false;
    return true;
  }

  /// E002-HU-004 CA-001/RN-006: Dialogo de confirmacion para promover a co-admin
  Future<void> _mostrarDialogoPromover(MiembroGrupoModel miembro) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Promover a Co-Admin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Promover a "${miembro.displayName}" como co-administrador?'),
            const SizedBox(height: DesignTokens.spacingM),
            Text(
              'Un co-administrador puede editar el grupo, gestionar miembros y crear fechas, pero NO puede eliminar el grupo ni gestionar otros co-admins.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Promover'),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      context.read<MiembrosGrupoBloc>().add(PromoverACoadminEvent(
        grupoId: widget.grupoId,
        miembroId: miembro.miembroId,
        nombreJugador: miembro.displayName,
      ));
    }
  }

  /// E002-HU-004 CA-002/RN-006: Dialogo de confirmacion para degradar co-admin
  Future<void> _mostrarDialogoDegrada(MiembroGrupoModel miembro) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quitar Co-Admin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quitar el rol de co-administrador a "${miembro.displayName}"?'),
            const SizedBox(height: DesignTokens.spacingM),
            Text(
              'El miembro conservara su membresia en el grupo y pasara a ser jugador regular.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: DesignTokens.accentColor,
            ),
            child: const Text('Quitar Co-Admin'),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      context.read<MiembrosGrupoBloc>().add(DegradarCoadminEvent(
        grupoId: widget.grupoId,
        miembroId: miembro.miembroId,
        nombreJugador: miembro.displayName,
      ));
    }
  }

  /// E002-HU-006 CA-005/RN-006: Dialogo de confirmacion antes de eliminar
  Future<void> _mostrarDialogoEliminar(MiembroGrupoModel miembro) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar del grupo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Eliminar a "${miembro.displayName}" del grupo?'),
            const SizedBox(height: DesignTokens.spacingM),
            Text(
              'Esta accion eliminara al jugador de este grupo pero no afectara su cuenta ni su participacion en otros grupos.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: DesignTokens.errorColor,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      context.read<MiembrosGrupoBloc>().add(EliminarJugadorEvent(
        grupoId: widget.grupoId,
        miembroId: miembro.miembroId,
        nombreJugador: miembro.displayName,
      ));
    }
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
      body: BlocConsumer<MiembrosGrupoBloc, MiembrosGrupoState>(
        listener: (context, state) {
          // E002-HU-006: Notificar exito y recargar miembros
          if (state is EliminarJugadorSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '"${state.nombreJugador}" fue eliminado del grupo',
                ),
                backgroundColor: DesignTokens.successColor,
              ),
            );
            // Recargar lista de miembros
            context
                .read<MiembrosGrupoBloc>()
                .add(CargarMiembrosGrupoEvent(grupoId: widget.grupoId));
          }

          // E002-HU-004 CA-001: Promover a co-admin exitoso
          if (state is PromoverCoadminSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '"${state.nombreJugador}" fue promovido a co-administrador',
                ),
                backgroundColor: DesignTokens.successColor,
              ),
            );
            // Recargar lista de miembros
            context
                .read<MiembrosGrupoBloc>()
                .add(CargarMiembrosGrupoEvent(grupoId: widget.grupoId));
          }

          // E002-HU-004 CA-002: Degradar co-admin exitoso
          if (state is DegradarCoadminSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '"${state.nombreJugador}" fue degradado a jugador',
                ),
                backgroundColor: DesignTokens.successColor,
              ),
            );
            // Recargar lista de miembros
            context
                .read<MiembrosGrupoBloc>()
                .add(CargarMiembrosGrupoEvent(grupoId: widget.grupoId));
          }
        },
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
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 2),
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
          puedeEliminar: _puedeEliminar(miembro),
          puedePromover: _puedePromover(miembro),
          puedeDegrada: _puedeDegrada(miembro),
          esSiMismo: _esMiembro(miembro),
          onEliminar: _puedeEliminar(miembro)
              ? () => _mostrarDialogoEliminar(miembro)
              : null,
          onPromover: _puedePromover(miembro)
              ? () => _mostrarDialogoPromover(miembro)
              : null,
          onDegrada: _puedeDegrada(miembro)
              ? () => _mostrarDialogoDegrada(miembro)
              : null,
        );
      },
    );
  }
}

/// Card de miembro individual
/// CA-001: Nombre, celular (con privacidad), rol, estado
/// CA-002: Admin/coadmin ven celular completo y estado detallado
/// E002-HU-006: Boton eliminar si tiene permisos
/// E002-HU-004: Opciones promover/degradar co-admin
class _MiembroCard extends StatelessWidget {
  final MiembroGrupoModel miembro;
  final bool mostrarCelularCompleto;
  final bool esAdminOCoadmin;
  final bool puedeEliminar;
  final bool puedePromover;
  final bool puedeDegrada;
  final bool esSiMismo;
  final VoidCallback? onEliminar;
  final VoidCallback? onPromover;
  final VoidCallback? onDegrada;

  const _MiembroCard({
    required this.miembro,
    required this.mostrarCelularCompleto,
    required this.esAdminOCoadmin,
    this.puedeEliminar = false,
    this.puedePromover = false,
    this.puedeDegrada = false,
    this.esSiMismo = false,
    this.onEliminar,
    this.onPromover,
    this.onDegrada,
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
        trailing: esAdminOCoadmin
            ? _buildPopupMenu(context)
            : miembro.estaPendiente
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

  /// PopupMenuButton con acciones de admin/coadmin sobre el miembro
  /// E002-HU-004: Incluye promover/degradar co-admin (solo para admin creador)
  Widget _buildPopupMenu(BuildContext context) {
    // Determinar si hay items visibles para el menu
    final mostrarGenerarCodigo = miembro.rol != 'admin' && !esSiMismo;
    final mostrarEliminar = puedeEliminar;
    final mostrarPromover = puedePromover;
    final mostrarDegrada = puedeDegrada;

    // Si no hay acciones disponibles, mostrar icono de estado
    if (!mostrarGenerarCodigo && !mostrarEliminar && !mostrarPromover && !mostrarDegrada) {
      return miembro.estaPendiente
          ? const Icon(
              Icons.schedule,
              size: DesignTokens.iconSizeS,
              color: DesignTokens.accentColor,
            )
          : const Icon(
              Icons.check_circle,
              size: DesignTokens.iconSizeS,
              color: DesignTokens.successColor,
            );
    }

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) {
        switch (value) {
          case 'generar_codigo':
            context.push(
              '/admin/generar-codigo-recuperacion',
              extra: miembro.celular,
            );
            break;
          case 'promover':
            onPromover?.call();
            break;
          case 'degradar':
            onDegrada?.call();
            break;
          case 'eliminar':
            onEliminar?.call();
            break;
        }
      },
      itemBuilder: (context) => [
        // E002-HU-004 CA-001: Promover jugador a co-admin
        if (mostrarPromover)
          PopupMenuItem<String>(
            value: 'promover',
            child: ListTile(
              leading: Icon(
                Icons.admin_panel_settings_outlined,
                color: DesignTokens.secondaryColor,
              ),
              title: Text(
                'Promover a Co-Admin',
                style: TextStyle(color: DesignTokens.secondaryColor),
              ),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        // E002-HU-004 CA-002: Degradar co-admin a jugador
        if (mostrarDegrada)
          PopupMenuItem<String>(
            value: 'degradar',
            child: ListTile(
              leading: Icon(
                Icons.person_remove_outlined,
                color: DesignTokens.accentColor,
              ),
              title: Text(
                'Quitar Co-Admin',
                style: TextStyle(color: DesignTokens.accentColor),
              ),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        if (mostrarGenerarCodigo)
          const PopupMenuItem<String>(
            value: 'generar_codigo',
            child: ListTile(
              leading: Icon(Icons.vpn_key_outlined),
              title: Text('Generar codigo de recuperacion'),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        if (mostrarEliminar)
          PopupMenuItem<String>(
            value: 'eliminar',
            child: ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: DesignTokens.errorColor,
              ),
              title: Text(
                'Eliminar del grupo',
                style: TextStyle(color: DesignTokens.errorColor),
              ),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
      ],
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
