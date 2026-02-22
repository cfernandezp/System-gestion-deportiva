import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/dashboard_shell.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../auth/presentation/bloc/session/session.dart';
import '../../data/models/color_equipo.dart';
import '../../data/models/jugador_asignacion_model.dart';
import '../../data/models/obtener_asignaciones_response_model.dart';
import '../bloc/asignaciones/asignaciones.dart';
import '../widgets/widgets.dart';

/// Pagina para asignar jugadores a equipos
/// E003-HU-005: Asignar Equipos
/// CA-001: Lista de inscritos a la izquierda, equipos a la derecha
/// CA-002: Equipos segun formato (2 o 3)
/// CA-003: Colores distintivos de equipos
/// CA-004: Drag-drop para asignacion (desktop)
/// CA-005: Selector para asignacion (mobile)
/// CA-006: Advertencia de desbalance
/// CA-007: Confirmar asignacion
/// CA-008: Modificar antes de iniciar
///
/// Usa ResponsiveLayout: Mobile App Style + Desktop Dashboard Style
class AsignarEquiposPage extends StatelessWidget {
  /// ID de la fecha para asignar equipos
  final String fechaId;

  const AsignarEquiposPage({
    super.key,
    required this.fechaId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AsignacionesBloc, AsignacionesState>(
      listener: (context, state) {
        // CA-007: Feedback al confirmar equipos
        if (state is EquiposConfirmados) {
          _mostrarSnackBarExito(context, state.message);
          // Navegar de vuelta al detalle
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else {
            context.go('/fechas');
          }
        }

        // Error al asignar
        if (state is AsignarEquipoError) {
          _mostrarSnackBarError(context, state.message);
        }

        // Error al desasignar
        if (state is DesasignarEquipoError) {
          _mostrarSnackBarError(context, state.message);
        }

        // Error al confirmar
        if (state is ConfirmarEquiposError) {
          _mostrarSnackBarError(context, state.message);
        }

        // Ausente marcado exitosamente
        if (state is AusenteMarcado) {
          _mostrarSnackBarExito(context, state.message);
        }

        // Error al marcar ausente
        if (state is MarcarAusenteError) {
          _mostrarSnackBarError(context, state.message);
        }

        // Jugador tardio inscrito exitosamente
        if (state is JugadorTardioInscrito) {
          _mostrarSnackBarExito(context, state.message);
        }

        // Error al inscribir tardio
        if (state is InscribirTardioError) {
          _mostrarSnackBarError(context, state.message);
        }
      },
      builder: (context, state) {
        // Obtener datos del estado
        final data = _obtenerData(state);
        final isLoading = state is AsignacionesLoading;
        final hasError = state is AsignacionesError;
        final errorMessage = hasError ? state.message : null;

        // Siempre mostrar el layout
        // En tablet: max-width 800px para aprovechar espacio
        return TabletSafeWrapper(
          maxWidth: 800,
          child: _MobileAsignarView(
            fechaId: fechaId,
            data: data,
            isLoading: isLoading,
            hasError: hasError,
            errorMessage: errorMessage,
          ),
        );
      },
    );
  }

  ObtenerAsignacionesDataModel? _obtenerData(AsignacionesState state) {
    if (state is AsignacionesLoaded) return state.data;
    if (state is AsignandoEquipo) return state.data;
    if (state is EquipoAsignado) return state.data;
    if (state is AsignarEquipoError) return state.data;
    if (state is DesasignandoEquipo) return state.data;
    if (state is EquipoDesasignado) return state.data;
    if (state is DesasignarEquipoError) return state.data;
    if (state is ConfirmandoEquipos) return state.data;
    if (state is ConfirmarEquiposError) return state.data;
    if (state is MarcandoAusente) return state.data;
    if (state is AusenteMarcado) return state.data;
    if (state is MarcarAusenteError) return state.data;
    if (state is InscribiendoTardio) return state.data;
    if (state is JugadorTardioInscrito) return state.data;
    if (state is InscribirTardioError) return state.data;
    return null;
  }

  void _mostrarSnackBarExito(BuildContext context, String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: DesignTokens.spacingS),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: DesignTokens.successColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _mostrarSnackBarError(BuildContext context, String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: DesignTokens.spacingS),
            Expanded(
              child: Text(
                mensaje,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: DesignTokens.errorColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ============================================
// VISTA MOBILE - App Style (Refactorizada para cancha)
// ============================================

class _MobileAsignarView extends StatefulWidget {
  final String fechaId;
  final ObtenerAsignacionesDataModel? data;
  final bool isLoading;
  final bool hasError;
  final String? errorMessage;

  const _MobileAsignarView({
    required this.fechaId,
    this.data,
    required this.isLoading,
    this.hasError = false,
    this.errorMessage,
  });

  @override
  State<_MobileAsignarView> createState() => _MobileAsignarViewState();
}

class _MobileAsignarViewState extends State<_MobileAsignarView> {
  /// Equipo seleccionado en modo rapido (null = OFF / modo normal)
  ColorEquipo? _equipoRapido;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asignar Equipos'),
        centerTitle: true,
        // Fix #1: Boton atras robusto
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/fechas');
            }
          },
        ),
        actions: [
          // Boton agregar jugador tardio (solo en_juego, admin/co-admin)
          if (widget.data?.fecha.estado == 'en_juego')
            _buildAgregarJugadorButton(context),
          // Boton refrescar
          IconButton(
            onPressed: () {
              context.read<AsignacionesBloc>().add(
                    CargarAsignacionesEvent(fechaId: widget.fechaId),
                  );
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _buildBody(context),
      // Fix #7: Bottom bar siempre visible fuera del scroll
      bottomNavigationBar: widget.data != null
          ? _buildBottomBar(context, colorScheme)
          : null,
    );
  }

  /// Boton para agregar jugador tardio (solo admin/co-admin durante en_juego)
  Widget _buildAgregarJugadorButton(BuildContext context) {
    return BlocBuilder<SessionBloc, SessionState>(
      builder: (context, sessionState) {
        if (sessionState is! SessionAuthenticated) {
          return const SizedBox.shrink();
        }

        final rol = sessionState.rol.toLowerCase();
        final isAdminOCoadmin = rol == 'admin' ||
            rol == 'administrador' ||
            rol == 'co-admin' ||
            rol == 'coadmin';

        if (!isAdminOCoadmin) {
          return const SizedBox.shrink();
        }

        return IconButton(
          onPressed: () {
            AgregarJugadorEnJuegoBottomSheet.show(
              context,
              fechaId: widget.fechaId,
              onSuccess: () {
                // Recargar asignaciones
                context.read<AsignacionesBloc>().add(
                      CargarAsignacionesEvent(fechaId: widget.fechaId),
                    );
              },
            );
          },
          icon: Icon(
            Icons.person_add,
            color: Theme.of(context).colorScheme.primary,
          ),
          tooltip: 'Agregar jugador',
        );
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    // Estado de carga
    if (widget.isLoading && widget.data == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Estado de error
    if (widget.hasError && widget.data == null) {
      return _buildErrorContent(context);
    }

    // Sin datos
    if (widget.data == null) {
      return const Center(child: Text('No se encontraron datos'));
    }

    final data = widget.data!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Layout principal: Column con header sticky + scroll + bottom bar
    return Column(
      children: [
        // Fix #3: Header sticky con progreso (NO scrolleable)
        _buildStickyProgressHeader(context, data, colorScheme, textTheme),

        // Fix #6: Modo rapido bar (NO scrolleable)
        _buildModoRapidoBar(context, data, colorScheme, textTheme),

        // Contenido scrolleable con secciones colapsables
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              context.read<AsignacionesBloc>().add(
                    CargarAsignacionesEvent(fechaId: widget.fechaId),
                  );
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingM,
                vertical: DesignTokens.spacingS,
              ),
              children: [
                // Fix #5: Sin asignar ARRIBA
                _buildSeccionSinAsignar(
                    context, data, colorScheme, textTheme),

                const SizedBox(height: DesignTokens.spacingM),

                // Fix #4 & #5: Equipos ABAJO, colapsables
                ...data.coloresDisponibles.map((color) {
                  final jugadoresEquipo = data.jugadoresDelEquipo(color);
                  return Padding(
                    padding: const EdgeInsets.only(
                        bottom: DesignTokens.spacingM),
                    child: EquipoContainerWidget(
                      equipo: color,
                      jugadores: jugadoresEquipo,
                      onJugadorRemover: (jugador) =>
                          _removerDeEquipo(context, jugador),
                      isMobile: true,
                      collapsible: true,
                      initiallyExpanded: true,
                    ),
                  );
                }),

                // Seccion Ausentes (colapsable, al final)
                if (data.ausentes.isNotEmpty)
                  _buildSeccionAusentes(context, data, colorScheme, textTheme),

                // Espacio inferior extra para que el scroll no tape contenido
                const SizedBox(height: DesignTokens.spacingL),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Seccion colapsable de jugadores ausentes
  Widget _buildSeccionAusentes(
    BuildContext context,
    ObtenerAsignacionesDataModel data,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.spacingM),
      child: Card(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        child: ExpansionTile(
          initiallyExpanded: false,
          leading: Icon(
            Icons.person_off,
            color: colorScheme.error.withValues(alpha: 0.7),
          ),
          title: Text(
            'Ausentes (${data.ausentes.length})',
            style: textTheme.titleSmall?.copyWith(
              color: colorScheme.error.withValues(alpha: 0.7),
            ),
          ),
          children: data.ausentes.map((ausente) {
            return ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: colorScheme.error.withValues(alpha: 0.2),
                child: Icon(
                  Icons.person_off,
                  size: 16,
                  color: colorScheme.error.withValues(alpha: 0.7),
                ),
              ),
              title: Text(
                ausente.displayName,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ============================================
  // Fix #3: Header sticky con progreso siempre visible
  // ============================================

  Widget _buildStickyProgressHeader(
    BuildContext context,
    ObtenerAsignacionesDataModel data,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final resumen = data.resumen;
    final progreso = resumen.totalInscritos > 0
        ? resumen.totalAsignados / resumen.totalInscritos
        : 0.0;
    final desbalance = _hayDesbalance();
    final completo = resumen.asignacionCompleta;
    final balanceado = !desbalance;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.spacingM,
        DesignTokens.spacingS,
        DesignTokens.spacingM,
        DesignTokens.spacingS,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Linea 1: X/Y asignados + barra de progreso
          Row(
            children: [
              Text(
                '${resumen.totalAsignados}/${resumen.totalInscritos} asignados',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: DesignTokens.fontWeightBold,
                ),
              ),
              const SizedBox(width: DesignTokens.spacingS),
              // Check verde si 100% y balanceado
              if (completo && balanceado)
                Icon(
                  Icons.check_circle,
                  color: DesignTokens.successColor,
                  size: DesignTokens.iconSizeM,
                ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacingXs),
          ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
            child: LinearProgressIndicator(
              value: progreso,
              minHeight: 6,
              backgroundColor: colorScheme.surfaceContainerHighest,
              color: completo
                  ? DesignTokens.successColor
                  : colorScheme.primary,
            ),
          ),

          const SizedBox(height: DesignTokens.spacingS),

          // Linea 2: Chips de equipo con conteo
          Row(
            children: data.coloresDisponibles.map((color) {
              final cantidad = data.jugadoresDelEquipo(color).length;
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(
                    vertical: DesignTokens.spacingXs,
                    horizontal: DesignTokens.spacingXs,
                  ),
                  decoration: BoxDecoration(
                    color: color.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                    border: Border.all(
                      color: color.color.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color.color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: color.borderColor,
                            width: 1,
                          ),
                        ),
                      ),
                      const SizedBox(width: DesignTokens.spacingXs),
                      Flexible(
                        child: Text(
                          '${color.shortLabel}: $cantidad',
                          style: textTheme.labelSmall?.copyWith(
                            fontWeight: DesignTokens.fontWeightBold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          // Linea 3 (condicional): Warning desbalance o check completado
          if (desbalance && data.resumen.totalAsignados > 0) ...[
            const SizedBox(height: DesignTokens.spacingXs),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: DesignTokens.spacingXs,
                horizontal: DesignTokens.spacingS,
              ),
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
                    Icons.warning_amber,
                    color: DesignTokens.accentColor,
                    size: 16,
                  ),
                  const SizedBox(width: DesignTokens.spacingXs),
                  Expanded(
                    child: Text(
                      'Equipos desbalanceados (diferencia > 1)',
                      style: textTheme.labelSmall?.copyWith(
                        color: DesignTokens.accentColor,
                        fontWeight: DesignTokens.fontWeightMedium,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================
  // Fix #6: Modo rapido bar
  // ============================================

  Widget _buildModoRapidoBar(
    BuildContext context,
    ObtenerAsignacionesDataModel data,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    // Solo mostrar si hay jugadores sin asignar
    if (data.jugadoresSinAsignar.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingM,
        vertical: DesignTokens.spacingS,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Rapido:',
            style: textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: DesignTokens.fontWeightMedium,
            ),
          ),
          const SizedBox(width: DesignTokens.spacingS),
          // Chips de equipos
          ...data.coloresDisponibles.map((color) {
            final isSelected = _equipoRapido == color;
            return Padding(
              padding: const EdgeInsets.only(right: DesignTokens.spacingXs),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _equipoRapido = isSelected ? null : color;
                  });
                },
                child: AnimatedContainer(
                  duration: DesignTokens.animFast,
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.spacingS,
                    vertical: DesignTokens.spacingXs,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.color
                        : color.color.withValues(alpha: 0.2),
                    borderRadius:
                        BorderRadius.circular(DesignTokens.radiusFull),
                    border: Border.all(
                      color: color.borderColor,
                      width: isSelected ? 2.5 : 1,
                    ),
                  ),
                  child: Text(
                    color.shortLabel,
                    style: textTheme.labelSmall?.copyWith(
                      color: isSelected
                          ? color.textColor
                          : colorScheme.onSurface,
                      fontWeight: DesignTokens.fontWeightBold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            );
          }),
          // Boton OFF
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _equipoRapido = null;
              });
            },
            child: AnimatedContainer(
              duration: DesignTokens.animFast,
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingS,
                vertical: DesignTokens.spacingXs,
              ),
              decoration: BoxDecoration(
                color: _equipoRapido == null
                    ? colorScheme.surfaceContainerHighest
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                border: Border.all(
                  color: _equipoRapido == null
                      ? colorScheme.outline
                      : colorScheme.outlineVariant,
                  width: _equipoRapido == null ? 2 : 1,
                ),
              ),
              child: Text(
                'OFF',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: DesignTokens.fontWeightBold,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // Fix #4 & #5: Seccion sin asignar (ExpansionTile, arriba)
  // ============================================

  Widget _buildSeccionSinAsignar(
    BuildContext context,
    ObtenerAsignacionesDataModel data,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final sinAsignar = data.jugadoresSinAsignar;

    if (sinAsignar.isEmpty) {
      // Todos asignados - mostrar feedback positivo compacto
      return Container(
        padding: const EdgeInsets.all(DesignTokens.spacingM),
        decoration: BoxDecoration(
          color: DesignTokens.successColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          border: Border.all(
            color: DesignTokens.successColor.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              color: DesignTokens.successColor,
              size: DesignTokens.iconSizeM,
            ),
            const SizedBox(width: DesignTokens.spacingS),
            Text(
              'Todos los jugadores asignados',
              style: textTheme.bodyMedium?.copyWith(
                color: DesignTokens.successColor,
                fontWeight: DesignTokens.fontWeightMedium,
              ),
            ),
          ],
        ),
      );
    }

    // ExpansionTile para jugadores sin asignar
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingM,
          ),
          childrenPadding: EdgeInsets.zero,
          collapsedShape: const RoundedRectangleBorder(),
          shape: const RoundedRectangleBorder(),
          title: Row(
            children: [
              Icon(
                Icons.person_outline,
                size: DesignTokens.iconSizeM,
                color: colorScheme.primary,
              ),
              const SizedBox(width: DesignTokens.spacingS),
              Text(
                'Sin asignar',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: DesignTokens.fontWeightSemiBold,
                ),
              ),
              const SizedBox(width: DesignTokens.spacingS),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacingS,
                  vertical: DesignTokens.spacingXxs,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius:
                      BorderRadius.circular(DesignTokens.radiusFull),
                ),
                child: Text(
                  '${sinAsignar.length}',
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: DesignTokens.fontWeightBold,
                  ),
                ),
              ),
            ],
          ),
          children: [
            const Divider(height: 1),
            ...sinAsignar.map(
              (jugador) => Padding(
                padding: const EdgeInsets.only(
                  left: DesignTokens.spacingS,
                  right: DesignTokens.spacingS,
                  top: DesignTokens.spacingXs,
                  bottom: DesignTokens.spacingXs,
                ),
                child: JugadorAsignacionTile(
                  jugador: jugador,
                  coloresDisponibles: data.coloresDisponibles,
                  onAsignar: (equipo) =>
                      _asignarEquipo(context, jugador, equipo),
                  isMobile: true,
                  equipoRapido: _equipoRapido,
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.spacingXs),
          ],
        ),
      ),
    );
  }

  // ============================================
  // Fix #7: Boton confirmar mejorado (bottom bar fijo)
  // ============================================

  Widget _buildBottomBar(BuildContext context, ColorScheme colorScheme) {
    final state = context.watch<AsignacionesBloc>().state;
    final isConfirmando = state is ConfirmandoEquipos;
    final asignacionCompleta =
        widget.data?.resumen.asignacionCompleta ?? false;
    final sinAsignar = widget.data?.resumen.sinAsignar ?? 0;
    final desbalance = _hayDesbalance();

    // Determinar estado del boton
    // Estado 1: Faltan por asignar (deshabilitado)
    // Estado 2: Todos asignados y balanceados (verde)
    // Estado 3: Todos asignados pero desbalanceados (naranja warning)
    final bool habilitado = asignacionCompleta && !isConfirmando;
    final Color? buttonColor;
    final String buttonText;
    final IconData buttonIcon;

    if (!asignacionCompleta) {
      // Estado 1: deshabilitado
      buttonText = 'Faltan $sinAsignar por asignar';
      buttonIcon = Icons.group_add;
      buttonColor = null; // usa color por defecto deshabilitado
    } else if (desbalance) {
      // Estado 3: todos asignados pero desbalanceados
      buttonText = 'Confirmar (desbalanceados)';
      buttonIcon = Icons.warning_amber;
      buttonColor = DesignTokens.accentColor;
    } else {
      // Estado 2: todos asignados y balanceados
      buttonText = 'Confirmar Equipos';
      buttonIcon = Icons.check;
      buttonColor = DesignTokens.successColor;
    }

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: FilledButton.icon(
          onPressed: habilitado
              ? () => _mostrarDialogConfirmacion(context)
              : null,
          icon: isConfirmando
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(buttonIcon),
          label: Text(buttonText),
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            backgroundColor: habilitado ? buttonColor : null,
          ),
        ),
      ),
    );
  }

  // ============================================
  // Acciones (reutilizan callbacks existentes)
  // ============================================

  /// Muestra confirmacion antes de marcar ausente
  void _confirmarMarcarAusente(
      BuildContext context, JugadorAsignacionModel jugador) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Marcar como ausente'),
        content: Text(
          'Se marcara a ${jugador.displayName} como ausente. '
          'Se eliminara su asignacion de equipo y no podra participar en partidos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<AsignacionesBloc>().add(
                    MarcarAusenteEvent(
                      fechaId: widget.fechaId,
                      inscripcionId: jugador.inscripcionId!,
                      jugadorNombre: jugador.displayName,
                    ),
                  );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  bool _hayDesbalance() {
    final data = widget.data;
    if (data == null || data.equipos.isEmpty) return false;
    final cantidades = data.equipos.map((e) => e.cantidad).toList();
    if (cantidades.isEmpty) return false;
    final max = cantidades.reduce((a, b) => a > b ? a : b);
    final min = cantidades.reduce((a, b) => a < b ? a : b);
    return (max - min) > 1;
  }

  void _asignarEquipo(
    BuildContext context,
    JugadorAsignacionModel jugador,
    ColorEquipo equipo,
  ) {
    context.read<AsignacionesBloc>().add(
          AsignarEquipoEvent(
            fechaId: widget.fechaId,
            usuarioId: jugador.usuarioId,
            equipo: equipo.toBackend(),
          ),
        );
  }

  // Fix #8: Reasignar jugador ya asignado via BottomSheet
  void _removerDeEquipo(
      BuildContext context, JugadorAsignacionModel jugador) {
    final esEnJuego = widget.data?.fecha.estado == 'en_juego';

    SelectorEquipoBottomSheet.show(
      context,
      jugador: jugador,
      coloresDisponibles: widget.data!.coloresDisponibles,
      onSeleccionar: (equipo) {
        context.read<AsignacionesBloc>().add(
              AsignarEquipoEvent(
                fechaId: widget.fechaId,
                usuarioId: jugador.usuarioId,
                equipo: equipo.toBackend(),
              ),
            );
      },
      onDesasignar: jugador.equipo != null
          ? () {
              context.read<AsignacionesBloc>().add(
                    DesasignarEquipoEvent(
                      fechaId: widget.fechaId,
                      usuarioId: jugador.usuarioId,
                    ),
                  );
            }
          : null,
      onMarcarAusente: esEnJuego && jugador.inscripcionId != null
          ? () => _confirmarMarcarAusente(context, jugador)
          : null,
    );
  }

  void _mostrarDialogConfirmacion(BuildContext context) {
    ConfirmarEquiposDialog.show(
      context,
      fechaId: widget.fechaId,
      data: widget.data!,
      hayDesbalance: _hayDesbalance(),
    );
  }

  Widget _buildErrorContent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: colorScheme.error),
            const SizedBox(height: DesignTokens.spacingM),
            Text(
              widget.errorMessage ?? 'Error al cargar asignaciones',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.spacingL),
            FilledButton.icon(
              onPressed: () {
                context.read<AsignacionesBloc>().add(
                      CargarAsignacionesEvent(fechaId: widget.fechaId),
                    );
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

// ============================================
// VISTA DESKTOP - Dashboard Style
// ============================================

class _DesktopAsignarView extends StatelessWidget {
  final String fechaId;
  final ObtenerAsignacionesDataModel? data;
  final bool isLoading;
  final bool hasError;
  final String? errorMessage;

  const _DesktopAsignarView({
    required this.fechaId,
    this.data,
    required this.isLoading,
    this.hasError = false,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AsignacionesBloc>().state;
    final isConfirmando = state is ConfirmandoEquipos;
    final asignacionCompleta = data?.resumen.asignacionCompleta ?? false;

    return DashboardShell(
      currentRoute: '/fechas/$fechaId/equipos',
      title: 'Asignar Equipos',
      breadcrumbs: const ['Inicio', 'Pichangas', 'Detalle', 'Asignar Equipos'],
      actions: [
        // CA-006: Indicador de desbalance
        if (data != null && _hayDesbalance())
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingM,
              vertical: DesignTokens.spacingS,
            ),
            decoration: BoxDecoration(
              color: DesignTokens.accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
              border: Border.all(
                color: DesignTokens.accentColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning_amber,
                  size: DesignTokens.iconSizeS,
                  color: DesignTokens.accentColor,
                ),
                const SizedBox(width: DesignTokens.spacingXs),
                Text(
                  'Desbalanceado',
                  style: TextStyle(
                    color: DesignTokens.accentColor,
                    fontWeight: DesignTokens.fontWeightMedium,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(width: DesignTokens.spacingS),
        // CA-007: Boton confirmar
        FilledButton.icon(
          onPressed: asignacionCompleta && !isConfirmando
              ? () => _mostrarDialogConfirmacion(context)
              : null,
          icon: isConfirmando
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.check),
          label: const Text('Confirmar Equipos'),
        ),
        const SizedBox(width: DesignTokens.spacingS),
        OutlinedButton.icon(
          onPressed: () {
            context.read<AsignacionesBloc>().add(
                  CargarAsignacionesEvent(fechaId: fechaId),
                );
          },
          icon: const Icon(Icons.refresh),
          label: const Text('Actualizar'),
        ),
        const SizedBox(width: DesignTokens.spacingS),
        OutlinedButton.icon(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Volver'),
        ),
      ],
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    // Estado de carga
    if (isLoading && data == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Estado de error
    if (hasError && data == null) {
      return _buildErrorContent(context);
    }

    // Sin datos
    if (data == null) {
      return const Center(child: Text('No se encontraron datos'));
    }

    // Layout de 2 columnas para desktop
    // CA-001: Lista de inscritos a la izquierda, equipos a la derecha
    return Padding(
      padding: const EdgeInsets.all(DesignTokens.spacingL),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Columna izquierda: Jugadores sin asignar
          SizedBox(
            width: 350,
            child: _buildPanelJugadoresSinAsignar(context),
          ),

          const SizedBox(width: DesignTokens.spacingL),

          // Columna derecha: Equipos (expandida)
          Expanded(
            child: _buildPanelEquipos(context),
          ),
        ],
      ),
    );
  }

  Widget _buildPanelJugadoresSinAsignar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final jugadoresSinAsignar = data!.jugadoresSinAsignar;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(DesignTokens.spacingM),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(DesignTokens.spacingS),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                  ),
                  child: Icon(
                    Icons.people_outline,
                    color: colorScheme.primary,
                    size: DesignTokens.iconSizeM,
                  ),
                ),
                const SizedBox(width: DesignTokens.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jugadores Sin Asignar',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: DesignTokens.fontWeightSemiBold,
                        ),
                      ),
                      Text(
                        '${jugadoresSinAsignar.length} jugador${jugadoresSinAsignar.length != 1 ? 'es' : ''}',
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

          const Divider(height: 1),

          // Lista de jugadores
          if (jugadoresSinAsignar.isEmpty)
            Padding(
              padding: const EdgeInsets.all(DesignTokens.spacingL),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: DesignTokens.iconSizeXl,
                      color: DesignTokens.successColor,
                    ),
                    const SizedBox(height: DesignTokens.spacingM),
                    Text(
                      'Todos asignados',
                      style: textTheme.titleSmall?.copyWith(
                        color: DesignTokens.successColor,
                        fontWeight: DesignTokens.fontWeightSemiBold,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spacingXs),
                    Text(
                      'Puedes confirmar los equipos',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: jugadoresSinAsignar.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
              itemBuilder: (context, index) {
                final jugador = jugadoresSinAsignar[index];
                // CA-004: Draggable para drag-drop en desktop
                return Draggable<JugadorAsignacionModel>(
                  data: jugador,
                  feedback: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                    child: Container(
                      width: 300,
                      padding: const EdgeInsets.all(DesignTokens.spacingM),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                        border: Border.all(
                          color: colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          _buildAvatar(jugador, colorScheme, textTheme, 40),
                          const SizedBox(width: DesignTokens.spacingM),
                          Text(
                            jugador.displayName,
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: DesignTokens.fontWeightMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.5,
                    child: JugadorAsignacionTile(
                      jugador: jugador,
                      coloresDisponibles: data!.coloresDisponibles,
                      onAsignar: (_) {},
                      isMobile: false,
                    ),
                  ),
                  child: JugadorAsignacionTile(
                    jugador: jugador,
                    coloresDisponibles: data!.coloresDisponibles,
                    onAsignar: (equipo) => _asignarEquipo(context, jugador, equipo),
                    isMobile: false,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPanelEquipos(BuildContext context) {
    final colores = data!.coloresDisponibles;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con progreso
          _buildProgresoHeader(context),

          const SizedBox(height: DesignTokens.spacingL),

          // Grid de equipos
          // CA-003: Colores distintivos
          Wrap(
            spacing: DesignTokens.spacingM,
            runSpacing: DesignTokens.spacingM,
            children: colores.map((color) {
              final jugadoresEquipo = data!.jugadoresDelEquipo(color);
              return SizedBox(
                width: colores.length == 2 ? 450 : 350,
                child: EquipoContainerWidget(
                  equipo: color,
                  jugadores: jugadoresEquipo,
                  onJugadorRemover: (jugador) => _removerDeEquipo(context, jugador),
                  onJugadorDrop: (jugador) => _asignarEquipo(context, jugador, color),
                  isMobile: false,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildProgresoHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final resumen = data!.resumen;

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            resumen.asignacionCompleta ? Icons.check_circle : Icons.groups,
            color: resumen.asignacionCompleta
                ? DesignTokens.successColor
                : colorScheme.primary,
            size: DesignTokens.iconSizeL,
          ),
          const SizedBox(width: DesignTokens.spacingM),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${resumen.totalAsignados} de ${resumen.totalInscritos} jugadores asignados',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: DesignTokens.fontWeightBold,
                ),
              ),
              Text(
                resumen.asignacionCompleta
                    ? 'Todos los jugadores tienen equipo. Puedes confirmar.'
                    : 'Faltan ${resumen.sinAsignar} jugador${resumen.sinAsignar != 1 ? 'es' : ''} por asignar.',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Barras de equipos
          Row(
            children: data!.coloresDisponibles.map((color) {
              final cantidad = data!.jugadoresDelEquipo(color).length;
              return Container(
                margin: const EdgeInsets.only(left: DesignTokens.spacingS),
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacingM,
                  vertical: DesignTokens.spacingS,
                ),
                decoration: BoxDecoration(
                  color: color.color,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      color.displayName,
                      style: textTheme.labelMedium?.copyWith(
                        color: color.textColor,
                        fontWeight: DesignTokens.fontWeightMedium,
                      ),
                    ),
                    const SizedBox(width: DesignTokens.spacingXs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.spacingS,
                        vertical: DesignTokens.spacingXxs,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                      ),
                      child: Text(
                        '$cantidad',
                        style: textTheme.labelMedium?.copyWith(
                          color: color.textColor,
                          fontWeight: DesignTokens.fontWeightBold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(
    JugadorAsignacionModel jugador,
    ColorScheme colorScheme,
    TextTheme textTheme,
    double size,
  ) {
    if (jugador.fotoUrl != null && jugador.fotoUrl!.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
          image: DecorationImage(
            image: NetworkImage(jugador.fotoUrl!),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    final inicial = jugador.displayName.isNotEmpty
        ? jugador.displayName[0].toUpperCase()
        : '?';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: DesignTokens.primaryGradient,
        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
      ),
      child: Center(
        child: Text(
          inicial,
          style: textTheme.titleSmall?.copyWith(
            color: Colors.white,
            fontWeight: DesignTokens.fontWeightBold,
          ),
        ),
      ),
    );
  }

  bool _hayDesbalance() {
    if (data == null || data!.equipos.isEmpty) return false;
    final cantidades = data!.equipos.map((e) => e.cantidad).toList();
    if (cantidades.isEmpty) return false;
    final max = cantidades.reduce((a, b) => a > b ? a : b);
    final min = cantidades.reduce((a, b) => a < b ? a : b);
    return (max - min) > 1;
  }

  void _asignarEquipo(
    BuildContext context,
    JugadorAsignacionModel jugador,
    ColorEquipo equipo,
  ) {
    context.read<AsignacionesBloc>().add(
          AsignarEquipoEvent(
            fechaId: fechaId,
            usuarioId: jugador.usuarioId,
            equipo: equipo.toBackend(),
          ),
        );
  }

  void _removerDeEquipo(BuildContext context, JugadorAsignacionModel jugador) {
    // En desktop, mostrar dropdown con colores disponibles y opcion Sin Asignar
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Reasignar ${jugador.displayName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Opcion Sin Asignar (solo si ya tiene equipo)
            if (jugador.equipo != null)
              ListTile(
                leading: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                    border: Border.all(color: colorScheme.outline),
                  ),
                  child: Icon(
                    Icons.person_remove,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                title: const Text('Sin Asignar'),
                subtitle: const Text('Devolver a lista de espera'),
                onTap: () {
                  Navigator.of(dialogContext).pop();
                  _desasignarEquipo(context, jugador);
                },
              ),
            if (jugador.equipo != null)
              const Divider(),
            // Opciones de equipos
            ...data!.coloresDisponibles.map((color) {
              return ListTile(
                leading: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: color.color,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                    border: Border.all(color: color.borderColor),
                  ),
                ),
                title: Text(color.displayName),
                selected: jugador.equipo == color,
                onTap: () {
                  Navigator.of(dialogContext).pop();
                  _asignarEquipo(context, jugador, color);
                },
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  void _desasignarEquipo(BuildContext context, JugadorAsignacionModel jugador) {
    context.read<AsignacionesBloc>().add(
          DesasignarEquipoEvent(
            fechaId: fechaId,
            usuarioId: jugador.usuarioId,
          ),
        );
  }

  void _mostrarDialogConfirmacion(BuildContext context) {
    ConfirmarEquiposDialog.show(
      context,
      fechaId: fechaId,
      data: data!,
      hayDesbalance: _hayDesbalance(),
    );
  }

  Widget _buildErrorContent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: colorScheme.error),
          const SizedBox(height: DesignTokens.spacingM),
          Text(
            errorMessage ?? 'Error al cargar asignaciones',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DesignTokens.spacingL),
          FilledButton.icon(
            onPressed: () {
              context.read<AsignacionesBloc>().add(
                    CargarAsignacionesEvent(fechaId: fechaId),
                  );
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
