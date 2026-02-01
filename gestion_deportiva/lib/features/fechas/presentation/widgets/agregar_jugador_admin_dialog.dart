import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../data/models/inscribir_jugador_admin_response_model.dart';
import '../bloc/inscribir_jugador_admin/inscribir_jugador_admin.dart';

/// E003-HU-011: Dialog para agregar jugador como admin
/// CA-001: Acceso exclusivo admin/organizador
/// CA-002: Selector de jugadores buscable con seleccion multiple
/// CA-003: Validacion jugador no inscrito
/// CA-004: Confirmacion de inscripcion exitosa
/// CA-007: Respeto al limite de cupos
/// CA-008: Solo fechas abiertas
class AgregarJugadorAdminDialog extends StatefulWidget {
  final String fechaId;
  final VoidCallback? onSuccess;

  const AgregarJugadorAdminDialog({
    super.key,
    required this.fechaId,
    this.onSuccess,
  });

  /// Muestra el dialog
  static Future<void> show(
    BuildContext context, {
    required String fechaId,
    VoidCallback? onSuccess,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider(
        create: (_) => sl<InscribirJugadorAdminBloc>()
          ..add(CargarJugadoresDisponiblesEvent(fechaId: fechaId)),
        child: AgregarJugadorAdminDialog(
          fechaId: fechaId,
          onSuccess: onSuccess,
        ),
      ),
    );
  }

  @override
  State<AgregarJugadorAdminDialog> createState() =>
      _AgregarJugadorAdminDialogState();
}

class _AgregarJugadorAdminDialogState extends State<AgregarJugadorAdminDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  /// Set de IDs de jugadores seleccionados (seleccion multiple)
  final Set<String> _jugadoresSeleccionados = {};

  /// Mapa para acceso rapido a nombres por ID
  final Map<String, JugadorDisponibleModel> _jugadoresMap = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InscribirJugadorAdminBloc, InscribirJugadorAdminState>(
      listener: (context, state) {
        // CA-004: Mensaje de exito al inscribir (individual)
        if (state is InscripcionAdminExitosa) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: DesignTokens.spacingS),
                  Expanded(child: Text(state.message)),
                ],
              ),
              backgroundColor: DesignTokens.successColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
          widget.onSuccess?.call();
        }

        // Mensaje de exito al inscribir multiples
        if (state is InscripcionMultipleExitosa) {
          Navigator.of(context).pop();

          // Color segun resultado
          final color = state.todosExitosos
              ? DesignTokens.successColor
              : (state.totalInscritos > 0
                  ? Colors.orange
                  : DesignTokens.errorColor);

          final icon = state.todosExitosos
              ? Icons.check_circle
              : (state.totalInscritos > 0
                  ? Icons.warning_amber_rounded
                  : Icons.error_outline);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(icon, color: Colors.white),
                  const SizedBox(width: DesignTokens.spacingS),
                  Expanded(child: Text(state.message)),
                ],
              ),
              backgroundColor: color,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
          widget.onSuccess?.call();
        }

        // Error
        if (state is InscribirJugadorAdminError) {
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
            ),
          );
          // Recargar jugadores disponibles despues de error
          context.read<InscribirJugadorAdminBloc>().add(
                CargarJugadoresDisponiblesEvent(fechaId: widget.fechaId),
              );
        }

        // Guardar mapa de jugadores cuando se cargan
        if (state is JugadoresDisponiblesCargados) {
          _jugadoresMap.clear();
          for (final jugador in state.jugadores) {
            _jugadoresMap[jugador.id] = jugador;
          }
        }
      },
      builder: (context, state) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.group_add,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: DesignTokens.spacingS),
              const Text('Agregar jugadores'),
            ],
          ),
          content: SizedBox(
            width: 450,
            child: _buildContent(context, state),
          ),
          actions: _buildActions(context, state),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, InscribirJugadorAdminState state) {
    // Cargando
    if (state is JugadoresDisponiblesCargando) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Procesando inscripcion individual
    if (state is InscripcionAdminProcesando) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: DesignTokens.spacingM),
              Text('Inscribiendo a ${state.jugadorNombre}...'),
            ],
          ),
        ),
      );
    }

    // Procesando inscripcion multiple con progreso
    if (state is InscripcionMultipleProcesando) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(value: state.progreso),
              const SizedBox(height: DesignTokens.spacingM),
              Text(
                'Inscribiendo ${state.procesados + 1} de ${state.totalJugadores}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: DesignTokens.spacingS),
              Text(
                state.jugadorActual,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    // Jugadores cargados
    if (state is JugadoresDisponiblesCargados) {
      return _buildJugadoresList(context, state);
    }

    // Error
    if (state is InscribirJugadorAdminError) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: DesignTokens.spacingM),
              Text(
                state.message,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Estado inicial
    return const SizedBox(
      height: 200,
      child: Center(child: CircularProgressIndicator()),
    );
  }

  /// CA-002: Lista de jugadores con buscador y seleccion multiple
  Widget _buildJugadoresList(
    BuildContext context,
    JugadoresDisponiblesCargados state,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Filtrar jugadores segun busqueda
    final jugadoresFiltrados = _searchQuery.isEmpty
        ? state.jugadores
        : state.jugadores.where((j) {
            final query = _searchQuery.toLowerCase();
            return j.nombreDisplay.toLowerCase().contains(query) ||
                j.nombreCompleto.toLowerCase().contains(query) ||
                (j.apodo?.toLowerCase().contains(query) ?? false);
          }).toList();

    // Lista vacia
    if (state.estaVacio) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline,
                size: 48,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(height: DesignTokens.spacingM),
              Text(
                'No hay jugadores disponibles',
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: DesignTokens.spacingS),
              Text(
                'Todos los jugadores aprobados ya estan inscritos',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Campo de busqueda
        TextField(
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

        const SizedBox(height: DesignTokens.spacingM),

        // Contador y seleccion
        Row(
          children: [
            Expanded(
              child: Text(
                '${jugadoresFiltrados.length} jugadores disponibles',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            // Boton seleccionar/deseleccionar todos
            if (jugadoresFiltrados.isNotEmpty)
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    final allFilteredIds =
                        jugadoresFiltrados.map((j) => j.id).toSet();
                    final allSelected = allFilteredIds
                        .every((id) => _jugadoresSeleccionados.contains(id));

                    if (allSelected) {
                      // Deseleccionar todos los filtrados
                      _jugadoresSeleccionados.removeAll(allFilteredIds);
                    } else {
                      // Seleccionar todos los filtrados
                      _jugadoresSeleccionados.addAll(allFilteredIds);
                    }
                  });
                },
                icon: Icon(
                  jugadoresFiltrados.every(
                          (j) => _jugadoresSeleccionados.contains(j.id))
                      ? Icons.deselect
                      : Icons.select_all,
                  size: 18,
                ),
                label: Text(
                  jugadoresFiltrados.every(
                          (j) => _jugadoresSeleccionados.contains(j.id))
                      ? 'Deseleccionar'
                      : 'Seleccionar todos',
                  style: textTheme.bodySmall,
                ),
              ),
          ],
        ),

        const SizedBox(height: DesignTokens.spacingS),

        // Indicador de seleccionados
        if (_jugadoresSeleccionados.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingM,
              vertical: DesignTokens.spacingS,
            ),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(DesignTokens.radiusS),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 16,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: DesignTokens.spacingS),
                Text(
                  '${_jugadoresSeleccionados.length} seleccionados',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() => _jugadoresSeleccionados.clear());
                  },
                  child: Text(
                    'Limpiar',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: DesignTokens.spacingS),

        // Lista de jugadores con checkboxes
        SizedBox(
          height: 280,
          child: jugadoresFiltrados.isEmpty
              ? Center(
                  child: Text(
                    'No se encontraron jugadores',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: jugadoresFiltrados.length,
                  itemBuilder: (context, index) {
                    final jugador = jugadoresFiltrados[index];
                    final isSelected =
                        _jugadoresSeleccionados.contains(jugador.id);

                    return _JugadorCheckboxTile(
                      jugador: jugador,
                      isSelected: isSelected,
                      onChanged: (selected) {
                        setState(() {
                          if (selected) {
                            _jugadoresSeleccionados.add(jugador.id);
                          } else {
                            _jugadoresSeleccionados.remove(jugador.id);
                          }
                        });
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  List<Widget> _buildActions(
    BuildContext context,
    InscribirJugadorAdminState state,
  ) {
    final isProcesando = state is InscripcionAdminProcesando ||
        state is InscripcionMultipleProcesando;
    final isError = state is InscribirJugadorAdminError;
    final isLoaded = state is JugadoresDisponiblesCargados;

    final cantidadSeleccionados = _jugadoresSeleccionados.length;

    return [
      TextButton(
        onPressed: isProcesando ? null : () => Navigator.of(context).pop(),
        child: const Text('Cancelar'),
      ),
      if (isLoaded || isError)
        FilledButton(
          onPressed: cantidadSeleccionados == 0 || isProcesando
              ? null
              : () => _inscribirSeleccionados(context),
          child: Text(
            cantidadSeleccionados == 0
                ? 'Agregar'
                : 'Agregar ($cantidadSeleccionados)',
          ),
        ),
    ];
  }

  /// Inscribir todos los jugadores seleccionados
  void _inscribirSeleccionados(BuildContext context) {
    if (_jugadoresSeleccionados.isEmpty) return;

    // Convertir IDs seleccionados a lista de JugadorParaInscribir
    final jugadores = _jugadoresSeleccionados
        .where((id) => _jugadoresMap.containsKey(id))
        .map((id) {
      final jugador = _jugadoresMap[id]!;
      return JugadorParaInscribir(
        id: jugador.id,
        nombre: jugador.nombreDisplay,
      );
    }).toList();

    if (jugadores.isEmpty) return;

    // Usar inscripcion multiple si hay mas de 1 jugador
    if (jugadores.length == 1) {
      context.read<InscribirJugadorAdminBloc>().add(
            InscribirJugadorEvent(
              fechaId: widget.fechaId,
              jugadorId: jugadores.first.id,
              jugadorNombre: jugadores.first.nombre,
            ),
          );
    } else {
      context.read<InscribirJugadorAdminBloc>().add(
            InscribirJugadoresMultipleEvent(
              fechaId: widget.fechaId,
              jugadores: jugadores,
            ),
          );
    }
  }
}

/// Tile individual de jugador con checkbox
class _JugadorCheckboxTile extends StatelessWidget {
  final JugadorDisponibleModel jugador;
  final bool isSelected;
  final ValueChanged<bool> onChanged;

  const _JugadorCheckboxTile({
    required this.jugador,
    required this.isSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: () => onChanged(!isSelected),
      borderRadius: BorderRadius.circular(DesignTokens.radiusS),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingS,
          vertical: DesignTokens.spacingS,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer.withValues(alpha: 0.3)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(DesignTokens.radiusS),
          border: isSelected
              ? Border.all(color: colorScheme.primary, width: 2)
              : null,
        ),
        child: Row(
          children: [
            // Checkbox
            Checkbox(
              value: isSelected,
              onChanged: (value) => onChanged(value ?? false),
              activeColor: colorScheme.primary,
            ),

            // Avatar
            _buildAvatar(context),
            const SizedBox(width: DesignTokens.spacingM),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    jugador.nombreDisplay,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: isSelected
                          ? DesignTokens.fontWeightSemiBold
                          : DesignTokens.fontWeightMedium,
                      color: isSelected ? colorScheme.primary : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // Si tiene foto
    if (jugador.fotoUrl != null && jugador.fotoUrl!.isNotEmpty) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
          image: DecorationImage(
            image: NetworkImage(jugador.fotoUrl!),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    // Sin foto: inicial con gradiente
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: DesignTokens.primaryGradient,
        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
      ),
      child: Center(
        child: Text(
          jugador.inicial,
          style: textTheme.titleSmall?.copyWith(
            color: Colors.white,
            fontWeight: DesignTokens.fontWeightBold,
          ),
        ),
      ),
    );
  }
}
