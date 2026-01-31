import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../fechas/data/models/color_equipo.dart';
import '../../data/models/jugador_partido_model.dart';
import '../bloc/goles/goles.dart';

/// Dialog para registrar un gol
/// E004-HU-003: Registrar Gol
/// CA-002: Seleccionar goleador (lista de jugadores del equipo)
/// CA-004: Gol en contra (toggle autogol)
/// CA-007: Gol sin asignar jugador
class RegistrarGolDialog extends StatefulWidget {
  /// ID del partido
  final String partidoId;

  /// Color del equipo que anota (recibe el punto)
  final ColorEquipo equipoAnotador;

  /// Color del equipo contrario (para autogol)
  final ColorEquipo equipoContrario;

  /// Lista de jugadores del equipo anotador
  final List<JugadorPartidoModel> jugadores;

  /// Indica si es el equipo local
  final bool esEquipoLocal;

  /// BLoC de goles (pasado desde el contexto padre)
  final GolesBloc golesBloc;

  const RegistrarGolDialog({
    super.key,
    required this.partidoId,
    required this.equipoAnotador,
    required this.equipoContrario,
    required this.jugadores,
    required this.esEquipoLocal,
    required this.golesBloc,
  });

  @override
  State<RegistrarGolDialog> createState() => _RegistrarGolDialogState();
}

class _RegistrarGolDialogState extends State<RegistrarGolDialog> {
  /// Jugador seleccionado (null = sin asignar)
  JugadorPartidoModel? _jugadorSeleccionado;

  /// Es autogol
  bool _esAutogol = false;

  /// Esta procesando
  bool _isProcesando = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // El equipo que realmente anota depende de si es autogol
    // Si es autogol: el gol va para el equipo contrario
    // Si no es autogol: el gol va para el equipo anotador
    final equipoQueSuma = _esAutogol ? widget.equipoContrario : widget.equipoAnotador;

    return BlocProvider.value(
      value: widget.golesBloc,
      child: BlocListener<GolesBloc, GolesState>(
        listener: (context, state) {
          if (state is GolRegistrado) {
            // Cerrar dialog y mostrar snackbar de exito
            Navigator.of(context).pop();
            _mostrarSnackbarGol(context, state);
          } else if (state is GolesError) {
            // Mostrar error pero mantener dialog abierto
            setState(() => _isProcesando = false);
            _mostrarSnackbarError(context, state.message);
          } else if (state is GolesProcesando) {
            setState(() => _isProcesando = true);
          }
        },
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusL),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 400,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header con color del equipo
                _DialogHeader(
                  equipo: equipoQueSuma,
                  esAutogol: _esAutogol,
                  onClose: () => Navigator.of(context).pop(),
                ),

                // Contenido scrolleable
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(DesignTokens.spacingM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // CA-004: Toggle de autogol
                        _AutogolToggle(
                          esAutogol: _esAutogol,
                          equipoAnotador: widget.equipoAnotador,
                          equipoContrario: widget.equipoContrario,
                          onChanged: (value) {
                            setState(() {
                              _esAutogol = value;
                              // Limpiar seleccion de jugador al cambiar
                              _jugadorSeleccionado = null;
                            });
                          },
                        ),

                        const SizedBox(height: DesignTokens.spacingM),

                        // Titulo de seccion
                        Text(
                          _esAutogol
                              ? 'Jugador que cometio el autogol'
                              : 'Quien anoto el gol?',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: DesignTokens.fontWeightSemiBold,
                          ),
                        ),
                        const SizedBox(height: DesignTokens.spacingS),

                        // Mensaje si es autogol
                        if (_esAutogol)
                          Container(
                            padding: const EdgeInsets.all(DesignTokens.spacingS),
                            margin: const EdgeInsets.only(bottom: DesignTokens.spacingS),
                            decoration: BoxDecoration(
                              color: DesignTokens.accentColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                              border: Border.all(
                                color: DesignTokens.accentColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: DesignTokens.accentColor,
                                ),
                                const SizedBox(width: DesignTokens.spacingS),
                                Expanded(
                                  child: Text(
                                    'El gol sumara para ${widget.equipoContrario.displayName}',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: DesignTokens.accentColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // CA-002: Lista de jugadores
                        _ListaJugadores(
                          jugadores: widget.jugadores,
                          jugadorSeleccionado: _jugadorSeleccionado,
                          equipoColor: widget.equipoAnotador,
                          onJugadorSeleccionado: (jugador) {
                            setState(() => _jugadorSeleccionado = jugador);
                          },
                        ),

                        const SizedBox(height: DesignTokens.spacingS),

                        // CA-007: Opcion "Gol sin asignar"
                        _OpcionSinAsignar(
                          seleccionado: _jugadorSeleccionado == null,
                          onTap: () {
                            setState(() => _jugadorSeleccionado = null);
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Footer con botones
                _DialogFooter(
                  equipoColor: equipoQueSuma,
                  isProcesando: _isProcesando,
                  onCancel: () => Navigator.of(context).pop(),
                  onConfirm: _confirmarGol,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// CA-003: Registro rapido - Confirmar gol
  void _confirmarGol() {
    // Determinar equipo que suma el gol
    // Si es autogol: el gol suma al equipo CONTRARIO
    final equipoQueSuma = _esAutogol
        ? widget.equipoContrario.name
        : widget.equipoAnotador.name;

    widget.golesBloc.add(
      RegistrarGolEvent(
        partidoId: widget.partidoId,
        equipoAnotador: equipoQueSuma,
        jugadorId: _jugadorSeleccionado?.id,
        esAutogol: _esAutogol,
      ),
    );
  }

  void _mostrarSnackbarGol(BuildContext context, GolRegistrado state) {
    final colorEquipo = ColorEquipo.fromString(state.gol.equipoAnotador) ??
        widget.equipoAnotador;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.sports_soccer, color: Colors.white),
            const SizedBox(width: DesignTokens.spacingS),
            Expanded(
              child: Text(
                'GOL! ${state.gol.jugadorNombre ?? "Sin asignar"} - ${colorEquipo.displayName}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: colorEquipo.color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        ),
      ),
    );

    // Mostrar advertencia si hay
    if (state.tieneAdvertencia) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.warning_amber, color: Colors.white),
                  const SizedBox(width: DesignTokens.spacingS),
                  Expanded(child: Text(state.advertencia!)),
                ],
              ),
              backgroundColor: DesignTokens.accentColor,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      });
    }
  }

  void _mostrarSnackbarError(BuildContext context, String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: DesignTokens.spacingS),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: DesignTokens.errorColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}

/// Header del dialog con color del equipo
class _DialogHeader extends StatelessWidget {
  final ColorEquipo equipo;
  final bool esAutogol;
  final VoidCallback onClose;

  const _DialogHeader({
    required this.equipo,
    required this.esAutogol,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: equipo.color,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(DesignTokens.radiusL),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.sports_soccer,
            color: equipo.textColor,
            size: 28,
          ),
          const SizedBox(width: DesignTokens.spacingS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  esAutogol ? 'Registrar Autogol' : 'Registrar Gol',
                  style: textTheme.titleMedium?.copyWith(
                    color: equipo.textColor,
                    fontWeight: DesignTokens.fontWeightBold,
                  ),
                ),
                Text(
                  'Gol para ${equipo.displayName}',
                  style: textTheme.bodySmall?.copyWith(
                    color: equipo.textColor.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: Icon(Icons.close, color: equipo.textColor),
            tooltip: 'Cerrar',
          ),
        ],
      ),
    );
  }
}

/// Toggle para marcar como autogol
class _AutogolToggle extends StatelessWidget {
  final bool esAutogol;
  final ColorEquipo equipoAnotador;
  final ColorEquipo equipoContrario;
  final ValueChanged<bool> onChanged;

  const _AutogolToggle({
    required this.esAutogol,
    required this.equipoAnotador,
    required this.equipoContrario,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: esAutogol
            ? DesignTokens.errorColor.withValues(alpha: 0.1)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: esAutogol
              ? DesignTokens.errorColor.withValues(alpha: 0.3)
              : colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Icon(
            esAutogol ? Icons.sports_soccer : Icons.sports_soccer_outlined,
            color: esAutogol ? DesignTokens.errorColor : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: DesignTokens.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Es autogol (gol en contra)',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: DesignTokens.fontWeightMedium,
                    color: esAutogol
                        ? DesignTokens.errorColor
                        : colorScheme.onSurface,
                  ),
                ),
                Text(
                  esAutogol
                      ? 'Un jugador de ${equipoAnotador.displayName} metio en su propia porteria'
                      : 'El gol fue normal (no en contra)',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: esAutogol,
            onChanged: onChanged,
            activeColor: DesignTokens.errorColor,
          ),
        ],
      ),
    );
  }
}

/// Lista de jugadores para seleccionar
class _ListaJugadores extends StatelessWidget {
  final List<JugadorPartidoModel> jugadores;
  final JugadorPartidoModel? jugadorSeleccionado;
  final ColorEquipo equipoColor;
  final ValueChanged<JugadorPartidoModel> onJugadorSeleccionado;

  const _ListaJugadores({
    required this.jugadores,
    required this.jugadorSeleccionado,
    required this.equipoColor,
    required this.onJugadorSeleccionado,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (jugadores.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(DesignTokens.spacingL),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        ),
        child: Column(
          children: [
            Icon(
              Icons.people_outline,
              size: 48,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: DesignTokens.spacingS),
            Text(
              'No hay jugadores asignados',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: DesignTokens.spacingXs),
            Text(
              'Puedes registrar el gol como "Sin asignar"',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: jugadores.map((jugador) {
        final seleccionado = jugadorSeleccionado?.id == jugador.id;

        return Padding(
          padding: const EdgeInsets.only(bottom: DesignTokens.spacingXs),
          child: Material(
            color: seleccionado
                ? equipoColor.color.withValues(alpha: 0.15)
                : colorScheme.surface,
            borderRadius: BorderRadius.circular(DesignTokens.radiusS),
            child: InkWell(
              onTap: () => onJugadorSeleccionado(jugador),
              borderRadius: BorderRadius.circular(DesignTokens.radiusS),
              child: Container(
                padding: const EdgeInsets.all(DesignTokens.spacingM),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                  border: Border.all(
                    color: seleccionado
                        ? equipoColor.color
                        : colorScheme.outlineVariant,
                    width: seleccionado ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Avatar con inicial
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: seleccionado
                            ? equipoColor.color
                            : colorScheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          jugador.displayName[0].toUpperCase(),
                          style: textTheme.titleMedium?.copyWith(
                            color: seleccionado
                                ? equipoColor.textColor
                                : colorScheme.onSurfaceVariant,
                            fontWeight: DesignTokens.fontWeightBold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: DesignTokens.spacingM),
                    // Nombre
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            jugador.displayName,
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: seleccionado
                                  ? DesignTokens.fontWeightSemiBold
                                  : DesignTokens.fontWeightRegular,
                              color: seleccionado
                                  ? equipoColor.color
                                  : colorScheme.onSurface,
                            ),
                          ),
                          if (jugador.apodo != null &&
                              jugador.apodo != jugador.nombreCompleto)
                            Text(
                              jugador.nombreCompleto,
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Check si seleccionado
                    if (seleccionado)
                      Icon(
                        Icons.check_circle,
                        color: equipoColor.color,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Opcion para registrar gol sin asignar jugador
class _OpcionSinAsignar extends StatelessWidget {
  final bool seleccionado;
  final VoidCallback onTap;

  const _OpcionSinAsignar({
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: seleccionado
          ? colorScheme.primaryContainer
          : colorScheme.surface,
      borderRadius: BorderRadius.circular(DesignTokens.radiusS),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
        child: Container(
          padding: const EdgeInsets.all(DesignTokens.spacingM),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DesignTokens.radiusS),
            border: Border.all(
              color: seleccionado
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
              width: seleccionado ? 2 : 1,
              style: seleccionado ? BorderStyle.solid : BorderStyle.solid,
            ),
          ),
          child: Row(
            children: [
              // Icono
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: seleccionado
                      ? colorScheme.primary
                      : colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.help_outline,
                    color: seleccionado
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: DesignTokens.spacingM),
              // Texto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gol sin asignar',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: seleccionado
                            ? DesignTokens.fontWeightSemiBold
                            : DesignTokens.fontWeightRegular,
                        color: seleccionado
                            ? colorScheme.primary
                            : colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'No se identifico al autor',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Check si seleccionado
              if (seleccionado)
                Icon(
                  Icons.check_circle,
                  color: colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Footer del dialog con botones
class _DialogFooter extends StatelessWidget {
  final ColorEquipo equipoColor;
  final bool isProcesando;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const _DialogFooter({
    required this.equipoColor,
    required this.isProcesando,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: isProcesando ? null : onCancel,
            child: const Text('Cancelar'),
          ),
          const SizedBox(width: DesignTokens.spacingM),
          FilledButton.icon(
            onPressed: isProcesando ? null : onConfirm,
            style: FilledButton.styleFrom(
              backgroundColor: equipoColor.color,
              foregroundColor: equipoColor.textColor,
            ),
            icon: isProcesando
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: equipoColor.textColor,
                    ),
                  )
                : const Icon(Icons.sports_soccer),
            label: const Text('Confirmar Gol'),
          ),
        ],
      ),
    );
  }
}
