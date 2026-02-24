import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../grupos/presentation/cubit/grupo_actual_cubit.dart';
import '../../data/models/inscribir_jugador_admin_response_model.dart';
import '../../domain/repositories/fechas_repository.dart';
import '../bloc/inscribir_jugador_admin/inscribir_jugador_admin.dart';

/// Bottom sheet para agregar jugador tardio durante en_juego
/// Dos opciones:
/// 1. "Jugador del grupo" - lista de miembros no inscritos, tap = inscribir
/// 2. "Nuevo invitado" - campo nombre + confirmar
class AgregarJugadorEnJuegoBottomSheet extends StatefulWidget {
  /// ID de la fecha
  final String fechaId;

  /// Callback de exito (para refrescar listas)
  final VoidCallback? onSuccess;

  const AgregarJugadorEnJuegoBottomSheet({
    super.key,
    required this.fechaId,
    this.onSuccess,
  });

  /// Muestra el bottom sheet
  static Future<void> show(
    BuildContext context, {
    required String fechaId,
    VoidCallback? onSuccess,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => BlocProvider(
        create: (_) => sl<InscribirJugadorAdminBloc>()
          ..add(CargarJugadoresDisponiblesEvent(fechaId: fechaId)),
        child: AgregarJugadorEnJuegoBottomSheet(
          fechaId: fechaId,
          onSuccess: onSuccess,
        ),
      ),
    );
  }

  @override
  State<AgregarJugadorEnJuegoBottomSheet> createState() =>
      _AgregarJugadorEnJuegoBottomSheetState();
}

class _AgregarJugadorEnJuegoBottomSheetState
    extends State<AgregarJugadorEnJuegoBottomSheet> {
  /// 0 = menu principal, 1 = jugador del grupo, 2 = nuevo invitado
  int _vistaActual = 0;

  /// Controller para nombre de invitado
  final TextEditingController _nombreController = TextEditingController();

  /// Controller para busqueda de jugador
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  /// Estado de carga para registro de invitado
  bool _registrandoInvitado = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(DesignTokens.radiusL),
        ),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: DesignTokens.spacingM),
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius:
                      BorderRadius.circular(DesignTokens.radiusFull),
                ),
              ),

              // Header
              _buildHeader(context),

              const Divider(height: 1),

              // Content
              Expanded(
                child: _buildContent(context, scrollController),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    String titulo;
    switch (_vistaActual) {
      case 1:
        titulo = 'Jugador del grupo';
        break;
      case 2:
        titulo = 'Nuevo invitado';
        break;
      default:
        titulo = 'Agregar jugador';
    }

    return Padding(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      child: Row(
        children: [
          if (_vistaActual > 0)
            IconButton(
              onPressed: () => setState(() {
                _vistaActual = 0;
                _searchQuery = '';
                _searchController.clear();
              }),
              icon: const Icon(Icons.arrow_back),
            ),
          Expanded(
            child: Text(
              titulo,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: DesignTokens.fontWeightBold,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, ScrollController scrollController) {
    switch (_vistaActual) {
      case 1:
        return _buildJugadorDelGrupo(context, scrollController);
      case 2:
        return _buildNuevoInvitado(context);
      default:
        return _buildMenuPrincipal(context);
    }
  }

  /// Menu principal con 2 opciones
  Widget _buildMenuPrincipal(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selecciona como agregar al jugador:',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingL),

          // Opcion 1: Jugador del grupo
          _buildOpcionTile(
            context,
            icon: Icons.group,
            titulo: 'Jugador del grupo',
            subtitulo: 'Miembros no inscritos en la pichanga',
            color: colorScheme.primary,
            onTap: () => setState(() => _vistaActual = 1),
          ),

          const SizedBox(height: DesignTokens.spacingM),

          // Opcion 2: Nuevo invitado
          _buildOpcionTile(
            context,
            icon: Icons.person_add,
            titulo: 'Nuevo invitado',
            subtitulo: 'Registro rapido con solo nombre',
            color: DesignTokens.accentColor,
            onTap: () => setState(() => _vistaActual = 2),
          ),
        ],
      ),
    );
  }

  Widget _buildOpcionTile(
    BuildContext context, {
    required IconData icon,
    required String titulo,
    required String subtitulo,
    required Color color,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DesignTokens.radiusM),
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.spacingM),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(DesignTokens.spacingM),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              ),
              child: Icon(icon, color: color, size: DesignTokens.iconSizeL),
            ),
            const SizedBox(width: DesignTokens.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: DesignTokens.fontWeightSemiBold,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spacingXxs),
                  Text(
                    subtitulo,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  /// Vista: Jugador del grupo (lista de miembros no inscritos)
  Widget _buildJugadorDelGrupo(
      BuildContext context, ScrollController scrollController) {
    return BlocConsumer<InscribirJugadorAdminBloc, InscribirJugadorAdminState>(
      listener: (context, state) {
        if (state is InscripcionAdminExitosa) {
          Navigator.of(context).pop();
          widget.onSuccess?.call();
          _mostrarSnackBar(
            context,
            state.message,
            DesignTokens.successColor,
          );
        }
        if (state is InscribirJugadorAdminError) {
          _mostrarSnackBar(
            context,
            state.message,
            DesignTokens.errorColor,
          );
          // Recargar lista
          context.read<InscribirJugadorAdminBloc>().add(
                CargarJugadoresDisponiblesEvent(fechaId: widget.fechaId),
              );
        }
      },
      builder: (context, state) {
        // Loading
        if (state is JugadoresDisponiblesCargando) {
          return const Center(child: CircularProgressIndicator());
        }

        // Procesando inscripcion
        if (state is InscripcionAdminProcesando) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: DesignTokens.spacingM),
                Text('Inscribiendo a ${state.jugadorNombre}...'),
              ],
            ),
          );
        }

        // Jugadores cargados
        if (state is JugadoresDisponiblesCargados) {
          return _buildListaJugadores(context, state, scrollController);
        }

        // Error
        if (state is InscribirJugadorAdminError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline,
                    size: 48, color: Theme.of(context).colorScheme.error),
                const SizedBox(height: DesignTokens.spacingM),
                Text(state.message, textAlign: TextAlign.center),
              ],
            ),
          );
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildListaJugadores(
    BuildContext context,
    JugadoresDisponiblesCargados state,
    ScrollController scrollController,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (state.estaVacio) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline,
                size: 48,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
            const SizedBox(height: DesignTokens.spacingM),
            Text(
              'No hay jugadores disponibles',
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: DesignTokens.spacingS),
            Text(
              'Todos los miembros ya estan inscritos',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    // Filtrar jugadores por busqueda
    final jugadoresFiltrados = _searchQuery.isEmpty
        ? state.jugadores
        : state.jugadores.where((j) {
            final query = _searchQuery.toLowerCase();
            return j.nombreDisplay.toLowerCase().contains(query) ||
                j.nombreCompleto.toLowerCase().contains(query) ||
                (j.apodo?.toLowerCase().contains(query) ?? false);
          }).toList();

    // Separar en jugadores e invitados
    final jugadoresGrupo =
        jugadoresFiltrados.where((j) => !j.esInvitado).toList();
    final invitadosGrupo =
        jugadoresFiltrados.where((j) => j.esInvitado).toList();

    return Column(
      children: [
        // Buscador
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingM,
            vertical: DesignTokens.spacingS,
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar jugador...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingM,
                vertical: DesignTokens.spacingS,
              ),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),

        // Info
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingM,
          ),
          child: Text(
            '${jugadoresFiltrados.length} disponibles - toca para inscribir',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),

        const SizedBox(height: DesignTokens.spacingS),

        // Lista de jugadores agrupada por seccion
        Expanded(
          child: ListView(
            controller: scrollController,
            children: [
              // Seccion Jugadores
              if (jugadoresGrupo.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(
                    'Jugadores (${jugadoresGrupo.length})',
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: DesignTokens.fontWeightSemiBold,
                    ),
                  ),
                ),
                ...jugadoresGrupo.map((j) => _buildJugadorTile(context, j)),
              ],

              // Seccion Invitados
              if (invitadosGrupo.isNotEmpty) ...[
                const Divider(height: 16),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(
                    'Invitados (${invitadosGrupo.length})',
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: DesignTokens.fontWeightSemiBold,
                    ),
                  ),
                ),
                ...invitadosGrupo.map((j) => _buildJugadorTile(context, j)),
              ],

              // Sin resultados de busqueda
              if (jugadoresFiltrados.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(DesignTokens.spacingL),
                  child: Center(
                    child: Text(
                      'No se encontraron jugadores',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildJugadorTile(
      BuildContext context, JugadorDisponibleModel jugador) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: () => _inscribirJugador(context, jugador),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingM,
          vertical: DesignTokens.spacingS,
        ),
        child: Row(
          children: [
            // Avatar diferenciado por rol
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: jugador.esInvitado ? null : DesignTokens.primaryGradient,
                color: jugador.esInvitado
                    ? DesignTokens.accentColor.withValues(alpha: 0.15)
                    : null,
                borderRadius:
                    BorderRadius.circular(DesignTokens.radiusFull),
                border: jugador.esInvitado
                    ? Border.all(
                        color: DesignTokens.accentColor.withValues(alpha: 0.5),
                      )
                    : null,
              ),
              child: Center(
                child: Text(
                  jugador.inicial,
                  style: textTheme.titleSmall?.copyWith(
                    color: jugador.esInvitado
                        ? DesignTokens.accentColor
                        : Colors.white,
                    fontWeight: DesignTokens.fontWeightBold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: DesignTokens.spacingM),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    jugador.nombreDisplay,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: DesignTokens.fontWeightMedium,
                    ),
                  ),
                  if (jugador.posicionPreferida != null &&
                      jugador.posicionPreferida!.isNotEmpty)
                    Text(
                      jugador.posicionPreferida!,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            // Badge invitado
            if (jugador.esInvitado)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacingS,
                  vertical: DesignTokens.spacingXs,
                ),
                decoration: BoxDecoration(
                  color: DesignTokens.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                  border: Border.all(
                    color: DesignTokens.accentColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  'Invitado',
                  style: textTheme.labelSmall?.copyWith(
                    color: DesignTokens.accentColor,
                    fontWeight: DesignTokens.fontWeightMedium,
                  ),
                ),
              ),
            if (jugador.esInvitado) const SizedBox(width: DesignTokens.spacingS),
            // Icono de agregar
            Icon(
              Icons.add_circle_outline,
              color: colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  void _inscribirJugador(
      BuildContext context, JugadorDisponibleModel jugador) {
    context.read<InscribirJugadorAdminBloc>().add(
          InscribirJugadorEvent(
            fechaId: widget.fechaId,
            jugadorId: jugador.id,
            jugadorNombre: jugador.nombreDisplay,
          ),
        );
  }

  /// Vista: Nuevo invitado (campo nombre + confirmar)
  Widget _buildNuevoInvitado(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_registrandoInvitado) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: DesignTokens.spacingM),
            Text(
              'Registrando invitado...',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ingresa el nombre del invitado:',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingM),
          TextField(
            controller: _nombreController,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'Nombre completo',
              prefixIcon: const Icon(Icons.person_add),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              ),
            ),
            onSubmitted: (_) => _registrarInvitado(context),
          ),
          const SizedBox(height: DesignTokens.spacingS),
          Text(
            'El invitado sera registrado y anotado a la pichanga automaticamente.',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: DesignTokens.spacingL),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _registrarInvitado(context),
              icon: const Icon(Icons.person_add),
              label: const Text('Registrar e inscribir'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.all(DesignTokens.spacingM),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _registrarInvitado(BuildContext context) async {
    final nombre = _nombreController.text.trim();
    if (nombre.isEmpty) {
      _mostrarSnackBar(
        context,
        'Ingresa el nombre del invitado',
        DesignTokens.errorColor,
      );
      return;
    }

    final grupoId = sl<GrupoActualCubit>().grupoActual?.grupoId;
    if (grupoId == null) {
      _mostrarSnackBar(
        context,
        'No se pudo identificar el grupo activo',
        DesignTokens.errorColor,
      );
      return;
    }

    setState(() => _registrandoInvitado = true);

    // Usar el repository directamente para registrar invitado
    final repository = sl<FechasRepository>();
    final result = await repository.registrarInvitadoYInscribir(
      grupoId: grupoId,
      fechaId: widget.fechaId,
      nombre: nombre,
    );

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() => _registrandoInvitado = false);
        _mostrarSnackBar(
          context,
          failure.message,
          DesignTokens.errorColor,
        );
      },
      (response) {
        Navigator.of(context).pop();
        _mostrarSnackBar(
          context,
          response.message.isNotEmpty
              ? response.message
              : 'Invitado $nombre registrado e inscrito',
          DesignTokens.successColor,
        );
        widget.onSuccess?.call();
      },
    );
  }

  void _mostrarSnackBar(BuildContext context, String mensaje, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
