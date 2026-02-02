import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/dashboard_shell.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../auth/presentation/bloc/session/session.dart';
import '../../../partidos/data/models/jugador_partido_model.dart';
import '../../../partidos/data/models/partido_model.dart';
import '../../../partidos/presentation/bloc/finalizar_partido/finalizar_partido.dart';
import '../../../partidos/presentation/bloc/goles/goles.dart';
import '../../../partidos/presentation/bloc/lista_partidos/lista_partidos.dart';
import '../../../partidos/presentation/bloc/partido/partido.dart';
import '../../../partidos/presentation/widgets/widgets.dart';
import '../../data/models/color_equipo.dart';
import '../../data/models/fecha_detalle_model.dart';
import '../../data/models/fecha_model.dart';
import '../../data/models/jugador_asignacion_model.dart';
import '../../data/models/obtener_asignaciones_response_model.dart';
import '../bloc/asignaciones/asignaciones_bloc.dart';
import '../bloc/asignaciones/asignaciones_event.dart';
import '../bloc/asignaciones/asignaciones_state.dart';
import '../bloc/inscripcion/inscripcion.dart';
import '../widgets/widgets.dart';

/// Pagina de detalle de fecha con opcion de inscripcion y edicion
/// E003-HU-002: Inscribirse a Fecha
/// CA-001: Mostrar todos los detalles de la fecha
/// CA-002: Boton "Anotarme" visible cuando no esta inscrito
/// CA-003: Dialogo de confirmacion al presionar "Anotarme"
/// CA-004: Indicador "Ya estas anotado" cuando inscrito
/// CA-005: Mensaje "Inscripciones cerradas" si fecha no es abierta
/// CA-006: Lista de jugadores inscritos con contador
///
/// E003-HU-003: Ver Inscritos (Integrado)
/// CA-001: Acceso a lista de inscritos
/// CA-002: Informacion de cada inscrito (foto, apodo, posicion)
/// CA-003: Header con contador
/// CA-004: Estado vacio
/// CA-005: Indicador "(Tu)" para usuario actual
/// CA-006: Actualizacion en tiempo real
///
/// E003-HU-004: Cerrar Inscripciones
/// CA-001: Boton "Cerrar inscripciones" visible para admin si estado = 'abierta'
/// CA-006: Boton "Reabrir inscripciones" visible para admin si estado = 'cerrada'
///
/// E003-HU-008: Editar Fecha
/// CA-001: Boton "Editar" solo visible para admin
/// CA-002: Solo habilitado si fecha estado = 'abierta'
///
/// E003-HU-012: Iniciar Fecha
/// CA-001: Boton "Iniciar Pichanga" visible solo en estado 'cerrada'
/// CA-002: Dialogo de confirmacion con resumen
/// CA-003: Warning si no hay equipos asignados
/// Usa ResponsiveLayout: Mobile App Style + Desktop Dashboard Style
class FechaDetallePage extends StatelessWidget {
  /// ID de la fecha a mostrar
  final String fechaId;

  const FechaDetallePage({
    super.key,
    required this.fechaId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InscripcionBloc, InscripcionState>(
      listener: (context, state) {
        // CA-003: Mensaje de exito al inscribirse
        if (state is InscripcionExitosa) {
          _mostrarSnackBarExito(
            context,
            state.message.isNotEmpty
                ? state.message
                : 'Te anotaste para la pichanga',
          );
          // Recargar detalle para actualizar lista
          if (state.fechaDetalle != null) {
            // El estado ya tiene la fecha actualizada
          }
        }

        // CA-004: Mensaje de exito al cancelar
        if (state is CancelacionExitosa) {
          _mostrarSnackBarExito(
            context,
            state.message.isNotEmpty
                ? state.message
                : 'Has cancelado tu inscripcion. La deuda ha sido anulada.',
          );
        }

        // Error
        if (state is InscripcionError) {
          _mostrarSnackBarError(context, state.message);
        }
      },
      builder: (context, state) {
        // Obtener datos del estado
        final fechaDetalle = _obtenerFechaDetalle(state);
        final isLoading = state is InscripcionLoading;
        final isProcesando = state is InscripcionProcesando;
        final hasError = state is InscripcionError && fechaDetalle == null;
        final errorMessage = hasError ? state.message : null;

        // Siempre mostrar el layout, el loading/error va dentro del contenido
        return ResponsiveLayout(
          mobileBody: _MobileDetalleView(
            fechaId: fechaId,
            fechaDetalle: fechaDetalle,
            isLoading: isLoading,
            isProcesando: isProcesando,
            hasError: hasError,
            errorMessage: errorMessage,
          ),
          desktopBody: _DesktopDetalleView(
            fechaId: fechaId,
            fechaDetalle: fechaDetalle,
            isLoading: isLoading,
            isProcesando: isProcesando,
            hasError: hasError,
            errorMessage: errorMessage,
          ),
        );
      },
    );
  }

  FechaDetalleModel? _obtenerFechaDetalle(InscripcionState state) {
    if (state is InscripcionFechaDetalleCargado) return state.fechaDetalle;
    if (state is InscripcionProcesando) return state.fechaDetalle;
    if (state is InscripcionExitosa) return state.fechaDetalle;
    if (state is CancelacionExitosa) return state.fechaDetalle;
    if (state is InscripcionError) return state.fechaDetalle;
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
// VISTA MOBILE - App Style
// ============================================

class _MobileDetalleView extends StatefulWidget {
  final String fechaId;
  final FechaDetalleModel? fechaDetalle;
  final bool isLoading;
  final bool isProcesando;
  final bool hasError;
  final String? errorMessage;

  const _MobileDetalleView({
    required this.fechaId,
    this.fechaDetalle,
    required this.isLoading,
    required this.isProcesando,
    this.hasError = false,
    this.errorMessage,
  });

  @override
  State<_MobileDetalleView> createState() => _MobileDetalleViewState();
}

class _MobileDetalleViewState extends State<_MobileDetalleView> {
  /// BLoC de partido - se crea una sola vez y se reutiliza
  PartidoBloc? _partidoBloc;

  /// BLoC de goles - para registrar goles
  GolesBloc? _golesBloc;

  /// BLoC de finalizar partido - para terminar partidos
  FinalizarPartidoBloc? _finalizarPartidoBloc;

  /// BLoC de lista de partidos
  ListaPartidosBloc? _listaPartidosBloc;

  /// Flag para evitar cargas duplicadas del partido
  bool _partidoCargado = false;

  /// Getter para acceder a los datos del widget
  String get fechaId => widget.fechaId;
  FechaDetalleModel? get fechaDetalle => widget.fechaDetalle;
  bool get isLoading => widget.isLoading;
  bool get isProcesando => widget.isProcesando;
  bool get hasError => widget.hasError;
  String? get errorMessage => widget.errorMessage;

  @override
  void dispose() {
    // Cerrar los blocs si fueron creados
    _partidoBloc?.close();
    _golesBloc?.close();
    _finalizarPartidoBloc?.close();
    _listaPartidosBloc?.close();
    super.dispose();
  }

  /// Obtiene o crea el PartidoBloc (singleton por vista)
  PartidoBloc _getOrCreatePartidoBloc() {
    if (_partidoBloc == null) {
      _partidoBloc = PartidoBloc(repository: sl());
      // Solo cargar una vez
      if (!_partidoCargado) {
        _partidoCargado = true;
        _partidoBloc!.add(CargarPartidoActivoEvent(fechaId: fechaId));
      }
    }
    return _partidoBloc!;
  }

  /// Obtiene o crea el GolesBloc (singleton por vista)
  GolesBloc _getOrCreateGolesBloc() {
    _golesBloc ??= GolesBloc(repository: sl());
    return _golesBloc!;
  }

  /// Obtiene o crea el FinalizarPartidoBloc (singleton por vista)
  FinalizarPartidoBloc _getOrCreateFinalizarPartidoBloc() {
    _finalizarPartidoBloc ??= FinalizarPartidoBloc(repository: sl());
    return _finalizarPartidoBloc!;
  }

  /// Obtiene o crea el ListaPartidosBloc (singleton por vista)
  ListaPartidosBloc _getOrCreateListaPartidosBloc() {
    if (_listaPartidosBloc == null) {
      _listaPartidosBloc = ListaPartidosBloc(repository: sl());
      _listaPartidosBloc!.add(CargarPartidosEvent(fechaId: fechaId));
    }
    return _listaPartidosBloc!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Pichanga'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          // E003-HU-012: Boton "Iniciar Pichanga" visible para admin si estado = 'cerrada'
          if (fechaDetalle != null)
            _buildIniciarPichangaButton(context),
          // E003-HU-005: Boton "Asignar Equipos" visible para admin si estado = 'cerrada'
          if (fechaDetalle != null)
            _buildAsignarEquiposButton(context),
          // E003-HU-004 CA-001/CA-006: Boton cerrar/reabrir inscripciones (admin)
          if (fechaDetalle != null)
            _buildCerrarReabrirButton(context),
          // E003-HU-008 CA-001: Boton "Editar" solo visible para admin
          if (fechaDetalle != null)
            _buildEditarButton(context),
          // E003-HU-010: Boton "Finalizar" visible para admin si estado = 'cerrada' o 'en_juego'
          if (fechaDetalle != null)
            _buildFinalizarButton(context),
        ],
      ),
      body: _buildContent(context),
      bottomNavigationBar: fechaDetalle != null
          ? _buildBottomBar(context)
          : null,
    );
  }

  /// E003-HU-005: Boton para asignar equipos
  /// Solo visible para admin si estado = 'cerrada'
  Widget _buildAsignarEquiposButton(BuildContext context) {
    return BlocBuilder<SessionBloc, SessionState>(
      builder: (context, sessionState) {
        // Solo mostrar si es admin
        if (sessionState is! SessionAuthenticated) {
          return const SizedBox.shrink();
        }

        final isAdmin = sessionState.rol.toLowerCase() == 'admin' ||
            sessionState.rol.toLowerCase() == 'administrador';

        if (!isAdmin) {
          return const SizedBox.shrink();
        }

        final estado = fechaDetalle!.fecha.estado;

        // Solo mostrar si estado = 'cerrada'
        if (estado != EstadoFecha.cerrada) {
          return const SizedBox.shrink();
        }

        return IconButton(
          onPressed: () => context.go('/fechas/$fechaId/equipos'),
          icon: Icon(
            Icons.groups,
            color: Theme.of(context).colorScheme.primary,
          ),
          tooltip: 'Asignar equipos',
        );
      },
    );
  }

  /// E003-HU-004: Boton cerrar/reabrir inscripciones para admin
  /// CA-001: Solo visible para admin si estado = 'abierta'
  /// CA-006: Solo visible para admin si estado = 'cerrada'
  Widget _buildCerrarReabrirButton(BuildContext context) {
    return BlocBuilder<SessionBloc, SessionState>(
      builder: (context, sessionState) {
        // Solo mostrar si es admin
        if (sessionState is! SessionAuthenticated) {
          return const SizedBox.shrink();
        }

        final isAdmin = sessionState.rol.toLowerCase() == 'admin' ||
            sessionState.rol.toLowerCase() == 'administrador';

        if (!isAdmin) {
          return const SizedBox.shrink();
        }

        final estado = fechaDetalle!.fecha.estado;

        // CA-001: Si estado = 'abierta', mostrar "Cerrar inscripciones"
        if (estado == EstadoFecha.abierta) {
          return IconButton(
            onPressed: () => _abrirCerrarInscripcionesDialog(context),
            icon: Icon(
              Icons.lock,
              color: Theme.of(context).colorScheme.primary,
            ),
            tooltip: 'Cerrar inscripciones',
          );
        }

        // CA-006: Si estado = 'cerrada', mostrar "Reabrir inscripciones"
        if (estado == EstadoFecha.cerrada) {
          return IconButton(
            onPressed: () => _abrirReabrirInscripcionesDialog(context),
            icon: Icon(
              Icons.lock_open,
              color: Theme.of(context).colorScheme.primary,
            ),
            tooltip: 'Reabrir inscripciones',
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  /// Abre el dialog de cerrar inscripciones
  void _abrirCerrarInscripcionesDialog(BuildContext context) {
    CerrarInscripcionesDialog.show(
      context,
      fechaDetalle: fechaDetalle!,
      onSuccess: () {
        // Recargar detalle despues de cerrar
        context.read<InscripcionBloc>().add(
          CargarFechaDetalleEvent(fechaId: fechaId),
        );
      },
    );
  }

  /// Abre el dialog de reabrir inscripciones
  void _abrirReabrirInscripcionesDialog(BuildContext context) {
    ReabrirInscripcionesDialog.show(
      context,
      fechaDetalle: fechaDetalle!,
      onSuccess: () {
        // Recargar detalle despues de reabrir
        context.read<InscripcionBloc>().add(
          CargarFechaDetalleEvent(fechaId: fechaId),
        );
      },
    );
  }

  /// E003-HU-008: Boton de editar para admin
  /// CA-001: Solo visible para admin
  /// CA-002: Solo habilitado si fecha estado = 'abierta'
  Widget _buildEditarButton(BuildContext context) {
    return BlocBuilder<SessionBloc, SessionState>(
      builder: (context, sessionState) {
        // CA-001: Solo mostrar si es admin
        if (sessionState is! SessionAuthenticated) {
          return const SizedBox.shrink();
        }

        final isAdmin = sessionState.rol.toLowerCase() == 'admin' ||
            sessionState.rol.toLowerCase() == 'administrador';

        if (!isAdmin) {
          return const SizedBox.shrink();
        }

        // CA-002: Verificar si la fecha es editable
        final esEditable = fechaDetalle!.fecha.estado == EstadoFecha.abierta;

        return IconButton(
          onPressed: esEditable
              ? () => _abrirDialogoEditar(context)
              : () => _mostrarMensajeNoEditable(context),
          icon: Icon(
            Icons.edit,
            color: esEditable
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          tooltip: esEditable
              ? 'Editar fecha'
              : 'No se puede editar (${fechaDetalle!.fecha.estado.displayName})',
        );
      },
    );
  }

  /// Abre el dialogo de edicion
  void _abrirDialogoEditar(BuildContext context) {
    EditarFechaDialog.show(
      context,
      fechaDetalle: fechaDetalle!,
      onSuccess: () {
        // Recargar detalle despues de editar
        context.read<InscripcionBloc>().add(
          CargarFechaDetalleEvent(fechaId: fechaId),
        );
      },
    );
  }

  /// Muestra mensaje cuando la fecha no es editable
  void _mostrarMensajeNoEditable(BuildContext context) {
    final estado = fechaDetalle!.fecha.estado;
    String mensaje;

    switch (estado) {
      case EstadoFecha.cerrada:
        mensaje = 'No se puede editar: las inscripciones estan cerradas.';
        break;
      case EstadoFecha.enJuego:
        mensaje = 'No se puede editar: la pichanga esta en curso.';
        break;
      case EstadoFecha.finalizada:
        mensaje = 'No se puede editar: la pichanga ya termino.';
        break;
      case EstadoFecha.cancelada:
        mensaje = 'No se puede editar: la pichanga fue cancelada.';
        break;
      default:
        mensaje = 'No se puede editar esta fecha.';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: DesignTokens.spacingS),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// E003-HU-010: Boton para finalizar fecha
  /// Solo visible para admin si estado = 'cerrada' o 'en_juego'
  Widget _buildFinalizarButton(BuildContext context) {
    return BlocBuilder<SessionBloc, SessionState>(
      builder: (context, sessionState) {
        // Solo mostrar si es admin
        if (sessionState is! SessionAuthenticated) {
          return const SizedBox.shrink();
        }

        final isAdmin = sessionState.rol.toLowerCase() == 'admin' ||
            sessionState.rol.toLowerCase() == 'administrador';

        if (!isAdmin) {
          return const SizedBox.shrink();
        }

        final estado = fechaDetalle!.fecha.estado;

        // Solo mostrar si estado = 'cerrada' o 'en_juego'
        if (estado != EstadoFecha.cerrada && estado != EstadoFecha.enJuego) {
          return const SizedBox.shrink();
        }

        return IconButton(
          onPressed: () => _abrirFinalizarDialog(context),
          icon: const Icon(
            Icons.check_circle,
            color: Color(0xFF9E9E9E),
          ),
          tooltip: 'Finalizar pichanga',
        );
      },
    );
  }

  /// Abre el dialog de finalizar fecha
  void _abrirFinalizarDialog(BuildContext context) {
    FinalizarFechaDialog.show(
      context,
      fechaDetalle: fechaDetalle!,
      onSuccess: () {
        // Recargar detalle despues de finalizar
        context.read<InscripcionBloc>().add(
          CargarFechaDetalleEvent(fechaId: fechaId),
        );
      },
    );
  }

  /// E003-HU-012: Boton para iniciar pichanga
  /// CA-001: Solo visible para admin si estado = 'cerrada'
  Widget _buildIniciarPichangaButton(BuildContext context) {
    return BlocBuilder<SessionBloc, SessionState>(
      builder: (context, sessionState) {
        // Solo mostrar si es admin
        if (sessionState is! SessionAuthenticated) {
          return const SizedBox.shrink();
        }

        final isAdmin = sessionState.rol.toLowerCase() == 'admin' ||
            sessionState.rol.toLowerCase() == 'administrador';

        if (!isAdmin) {
          return const SizedBox.shrink();
        }

        final estado = fechaDetalle!.fecha.estado;

        // CA-001: Solo mostrar si estado = 'cerrada'
        if (estado != EstadoFecha.cerrada) {
          return const SizedBox.shrink();
        }

        return IconButton(
          onPressed: () => _abrirIniciarPichangaDialog(context),
          icon: Icon(
            Icons.play_circle,
            color: DesignTokens.successColor,
          ),
          tooltip: 'Iniciar pichanga',
        );
      },
    );
  }

  /// Abre el dialog de iniciar pichanga
  void _abrirIniciarPichangaDialog(BuildContext context) {
    // Mostrar dialogo de iniciar pichanga
    // El resumen de equipos se obtiene de los datos basicos del detalle
    IniciarFechaDialog.show(
      context,
      fechaDetalle: fechaDetalle!,
      onSuccess: () {
        // Recargar detalle despues de iniciar
        context.read<InscripcionBloc>().add(
          CargarFechaDetalleEvent(fechaId: fechaId),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    // Estado de carga
    if (isLoading && fechaDetalle == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Estado de error
    if (hasError && fechaDetalle == null) {
      return _buildErrorContent(context);
    }

    // Sin datos
    if (fechaDetalle == null) {
      return const Center(child: Text('No se encontro la fecha'));
    }

    // Contenido con datos
    return RefreshIndicator(
      onRefresh: () async {
        context.read<InscripcionBloc>().add(
          CargarFechaDetalleEvent(fechaId: fechaId),
        );
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(DesignTokens.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card de informacion principal
            _buildInfoCard(context),

            const SizedBox(height: DesignTokens.spacingM),

            // E003-HU-003: Lista de inscritos con realtime
            // CA-001 a CA-006: Widget dedicado con BLoC propio
            // E003-HU-011: Boton agregar jugador (admin, fecha abierta)
            // Solo mostrar lista de inscritos cuando inscripciones abiertas
            // Cuando hay equipos (cerrada/en_juego/finalizada), los equipos ya muestran los jugadores
            if (fechaDetalle!.fecha.estado == EstadoFecha.abierta)
              InscritosListWidget(
                fechaId: fechaId,
                habilitarRealtime: true,
                capacidadMaxima: fechaDetalle!.capacidadMaxima > 0
                    ? fechaDetalle!.capacidadMaxima
                    : null,
                fechaAbierta: fechaDetalle!.inscripcionesAbiertas,
              ),

            if (fechaDetalle!.fecha.estado == EstadoFecha.abierta)
              const SizedBox(height: DesignTokens.spacingM),

            // E004-HU-001: Lista de partidos en area principal
            // Solo mostrar si estado = en_juego o finalizada
            if (fechaDetalle!.fecha.estado == EstadoFecha.enJuego ||
                fechaDetalle!.fecha.estado == EstadoFecha.finalizada)
              _buildPartidoSection(context),

            const SizedBox(height: DesignTokens.spacingL),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final fecha = fechaDetalle!.fecha;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fecha y hora
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(DesignTokens.spacingM),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                  ),
                  child: Icon(
                    Icons.calendar_month,
                    color: colorScheme.primary,
                    size: DesignTokens.iconSizeL,
                  ),
                ),
                const SizedBox(width: DesignTokens.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${fecha.fechaFormato} - ${fecha.horaFormato.isNotEmpty ? fecha.horaFormato : "Por definir"}',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: DesignTokens.fontWeightBold,
                        ),
                      ),
                      Text(
                        '${fecha.duracionHoras} hora${fecha.duracionHoras != 1 ? 's' : ''} de juego',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildEstadoBadge(context),
              ],
            ),

            const Divider(height: DesignTokens.spacingL * 2),

            // Lugar
            _buildInfoRow(
              context,
              icon: Icons.location_on,
              label: 'Lugar',
              value: fecha.lugar,
            ),

            const SizedBox(height: DesignTokens.spacingM),

            // Formato
            _buildInfoRow(
              context,
              icon: Icons.groups,
              label: 'Formato',
              value: fecha.formatoJuego,
            ),

            const SizedBox(height: DesignTokens.spacingM),

            // Costo - CA-001: Mostrar costo a pagar
            _buildInfoRow(
              context,
              icon: Icons.attach_money,
              label: 'Debes pagar',
              value: fecha.costoFormato,
              destacado: true,
            ),

            const SizedBox(height: DesignTokens.spacingM),

            // Organizador
            _buildInfoRow(
              context,
              icon: Icons.person,
              label: 'Organizado por',
              value: fecha.createdByNombre,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadoBadge(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Construir lista de badges
    final List<Widget> badges = [];

    // CA-004: Badge "Anotado" si inscrito
    if (fechaDetalle!.usuarioInscrito) {
      badges.add(
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingM,
            vertical: DesignTokens.spacingS,
          ),
          decoration: BoxDecoration(
            color: DesignTokens.successColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
            border: Border.all(
              color: DesignTokens.successColor.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                size: DesignTokens.iconSizeS,
                color: DesignTokens.successColor,
              ),
              const SizedBox(width: DesignTokens.spacingXs),
              Text(
                'Anotado',
                style: textTheme.labelMedium?.copyWith(
                  color: DesignTokens.successColor,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Badge de estado de fecha (solo si no esta inscrito o si esta cerrada/en_juego/finalizada)
    if (!fechaDetalle!.inscripcionesAbiertas) {
      final estadoColor = _getEstadoColor(fechaDetalle!.fecha.estado, colorScheme);
      badges.add(
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingS,
            vertical: DesignTokens.spacingXs,
          ),
          decoration: BoxDecoration(
            color: estadoColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
          ),
          child: Text(
            fechaDetalle!.fecha.estado.displayName,
            style: textTheme.labelSmall?.copyWith(
              color: estadoColor,
              fontWeight: DesignTokens.fontWeightMedium,
            ),
          ),
        ),
      );
    } else if (!fechaDetalle!.usuarioInscrito) {
      // Si esta abierta y no esta inscrito, mostrar badge "Abierta"
      badges.add(
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingM,
            vertical: DesignTokens.spacingS,
          ),
          decoration: BoxDecoration(
            color: DesignTokens.successColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
          ),
          child: Text(
            'Abierta',
            style: textTheme.labelMedium?.copyWith(
              color: DesignTokens.successColor,
              fontWeight: DesignTokens.fontWeightMedium,
            ),
          ),
        ),
      );
    }

    // Si hay multiples badges, mostrarlos en columna compacta
    if (badges.length > 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < badges.length; i++) ...[
            badges[i],
            if (i < badges.length - 1)
              const SizedBox(height: DesignTokens.spacingXs),
          ],
        ],
      );
    }

    return badges.isNotEmpty ? badges.first : const SizedBox.shrink();
  }

  /// Obtiene el color segun el estado de la fecha
  Color _getEstadoColor(EstadoFecha estado, ColorScheme colorScheme) {
    switch (estado) {
      case EstadoFecha.abierta:
        return DesignTokens.successColor;
      case EstadoFecha.cerrada:
        return DesignTokens.accentColor;
      case EstadoFecha.enJuego:
        return DesignTokens.primaryColor;
      case EstadoFecha.finalizada:
        return colorScheme.onSurfaceVariant;
      case EstadoFecha.cancelada:
        return colorScheme.error;
    }
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool destacado = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Icon(
          icon,
          size: DesignTokens.iconSizeM,
          color: destacado ? colorScheme.primary : colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: DesignTokens.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: destacado
                      ? DesignTokens.fontWeightBold
                      : DesignTokens.fontWeightMedium,
                  color: destacado ? colorScheme.primary : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Barra inferior con botones de accion
  Widget _buildBottomBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
        child: _buildActionButton(context),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // CA-005: Inscripciones cerradas - solo mostrar si NO esta inscrito
    // Si esta inscrito, el badge ya indica que esta anotado
    if (!fechaDetalle!.inscripcionesAbiertas && !fechaDetalle!.usuarioInscrito) {
      // Texto compacto sin card redundante (el estado ya se muestra en el header)
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outlined,
            color: colorScheme.onSurfaceVariant,
            size: DesignTokens.iconSizeS,
          ),
          const SizedBox(width: DesignTokens.spacingXs),
          Text(
            fechaDetalle!.mensajeEstado ?? 'Inscripciones cerradas',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    // CA-004: Ya inscrito - mostrar boton cancelar (solo si inscripciones abiertas)
    if (fechaDetalle!.usuarioInscrito && fechaDetalle!.inscripcionesAbiertas) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: isProcesando
              ? null
              : () => _confirmarCancelacion(context),
          style: OutlinedButton.styleFrom(
            foregroundColor: colorScheme.error,
            side: BorderSide(color: colorScheme.error),
            padding: const EdgeInsets.all(DesignTokens.spacingM),
          ),
          icon: isProcesando
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.close),
          label: const Text('Cancelar inscripcion'),
        ),
      );
    }

    // Inscrito pero inscripciones cerradas - mostrar texto informativo
    if (fechaDetalle!.usuarioInscrito && !fechaDetalle!.inscripcionesAbiertas) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outlined,
            color: colorScheme.onSurfaceVariant,
            size: DesignTokens.iconSizeS,
          ),
          const SizedBox(width: DesignTokens.spacingXs),
          Flexible(
            child: Text(
              'Recuerda pagar ${fechaDetalle!.fecha.costoFormato}',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }

    // CA-002: Boton "Anotarme"
    if (fechaDetalle!.puedeInscribirse) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: isProcesando
              ? null
              : () => _confirmarInscripcion(context),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.all(DesignTokens.spacingM),
          ),
          icon: isProcesando
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.sports_soccer),
          label: const Text('Anotarme'),
        ),
      );
    }

    // Fecha llena
    if (fechaDetalle!.estaLleno) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group,
            color: DesignTokens.accentColor,
            size: DesignTokens.iconSizeS,
          ),
          const SizedBox(width: DesignTokens.spacingXs),
          Text(
            'Fecha completa - ${fechaDetalle!.totalInscritos} inscritos',
            style: textTheme.bodyMedium?.copyWith(
              color: DesignTokens.accentColor,
              fontWeight: DesignTokens.fontWeightMedium,
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  /// CA-003: Dialogo de confirmacion para inscribirse
  void _confirmarInscripcion(BuildContext context) {
    final fecha = fechaDetalle!.fecha;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          Icons.sports_soccer,
          color: Theme.of(context).colorScheme.primary,
          size: 48,
        ),
        title: const Text('Confirmar inscripcion'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Te anotaras para la pichanga:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: DesignTokens.spacingM),
            _DialogInfoRow(icon: Icons.calendar_today, text: '${fecha.fechaFormato} - ${fecha.horaFormato}'),
            _DialogInfoRow(icon: Icons.location_on, text: fecha.lugar),
            _DialogInfoRow(
              icon: Icons.attach_money,
              text: 'Debes pagar: ${fecha.costoFormato}',
              destacado: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<InscripcionBloc>().add(
                InscribirseEvent(fechaId: fechaId),
              );
            },
            child: const Text('Anotarme'),
          ),
        ],
      ),
    );
  }

  /// E003-HU-007: Dialogo de confirmacion para cancelar inscripcion
  /// CA-001: Visible solo si usuario esta inscrito
  /// CA-002: Mensaje de confirmacion
  /// CA-005: Si fecha cerrada, mostrar mensaje
  void _confirmarCancelacion(BuildContext context) {
    CancelarInscripcionDialog.show(
      context,
      fechaDetalle: fechaDetalle!,
      onSuccess: () {
        // Recargar detalle despues de cancelar
        context.read<InscripcionBloc>().add(
          CargarFechaDetalleEvent(fechaId: fechaId),
        );
      },
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
              errorMessage ?? 'Error al cargar detalle de la fecha',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.spacingL),
            FilledButton.icon(
              onPressed: () {
                context.read<InscripcionBloc>().add(
                  CargarFechaDetalleEvent(fechaId: fechaId),
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

  /// E004-HU-001: Seccion de partido en vivo y lista de partidos
  /// Muestra widget de partido activo, lista de partidos y boton para crear
  /// NOTA: Usa MultiBlocProvider para inyectar blocs de partido, goles, finalizar y lista
  Widget _buildPartidoSection(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _getOrCreatePartidoBloc()),
        BlocProvider.value(value: _getOrCreateGolesBloc()),
        BlocProvider.value(value: _getOrCreateFinalizarPartidoBloc()),
        BlocProvider.value(value: _getOrCreateListaPartidosBloc()),
      ],
      child: BlocBuilder<SessionBloc, SessionState>(
        builder: (context, sessionState) {
          final isAdmin = sessionState is SessionAuthenticated &&
              (sessionState.rol.toLowerCase() == 'admin' ||
                  sessionState.rol.toLowerCase() == 'administrador');

          return BlocListener<FinalizarPartidoBloc, FinalizarPartidoState>(
            listener: (context, state) {
              if (state is FinalizarPartidoSuccess) {
                // Recargar partido activo y lista de partidos
                _getOrCreatePartidoBloc().add(CargarPartidoActivoEvent(fechaId: fechaId));
                _getOrCreateListaPartidosBloc().add(RefrescarPartidosEvent(fechaId: fechaId));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.response.message.isNotEmpty
                        ? state.response.message
                        : 'Partido finalizado'),
                    backgroundColor: DesignTokens.successColor,
                  ),
                );
              } else if (state is FinalizarPartidoRequiereConfirmacion) {
                _mostrarDialogoConfirmacionFinalizar(context, state.partidoId, state.message);
              } else if (state is FinalizarPartidoError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: DesignTokens.errorColor,
                  ),
                );
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Widget de partido en vivo con callbacks para admin
                PartidoEnVivoWidget(
                  esAdmin: isAdmin,
                  onPantallaCompleta: (partido) => _abrirPantallaCompleta(context, partido, isAdmin),
                  onAnotarGol: isAdmin ? (partido) => _mostrarDialogoAnotarGol(context, partido) : null,
                  onFinalizarPartido: isAdmin ? (partido) => _onFinalizarPartido(context, partido) : null,
                ),

                const SizedBox(height: DesignTokens.spacingM),

                // Lista de partidos con opcion de crear nuevo
                if (fechaDetalle != null)
                  ListaPartidosWidget(
                    fechaDetalle: fechaDetalle!,
                    esAdmin: isAdmin,
                    onPartidoCreado: () {
                      // Refrescar partido activo y lista
                      _getOrCreatePartidoBloc().add(CargarPartidoActivoEvent(fechaId: fechaId));
                      _getOrCreateListaPartidosBloc().add(RefrescarPartidosEvent(fechaId: fechaId));
                    },
                  ),

                const SizedBox(height: DesignTokens.spacingM),
              ],
            ),
          );
        },
      ),
    );
  }

  /// E004-HU-002 CA-009: Abre el temporizador en pantalla completa
  void _abrirPantallaCompleta(BuildContext context, PartidoModel partido, bool esAdmin) {
    TemporizadorFullscreen.show(
      context,
      partido: partido,
      esAdmin: esAdmin,
      golesLocal: partido.golesLocal,
      golesVisitante: partido.golesVisitante,
      onPausar: () {
        _getOrCreatePartidoBloc().add(PausarPartidoEvent(partidoId: partido.id));
      },
      onReanudar: () {
        _getOrCreatePartidoBloc().add(ReanudarPartidoEvent(partidoId: partido.id));
      },
      onGolLocal: () {
        // Abrir dialogo para registrar gol del equipo local
        Navigator.of(context).pop(); // Cerrar pantalla completa
        _abrirRegistrarGolDialog(
          context,
          partido,
          partido.equipoLocal.color,
          partido.equipoVisitante.color,
          partido.equipoLocal.jugadores,
          true,
        );
      },
      onGolVisitante: () {
        // Abrir dialogo para registrar gol del equipo visitante
        Navigator.of(context).pop(); // Cerrar pantalla completa
        _abrirRegistrarGolDialog(
          context,
          partido,
          partido.equipoVisitante.color,
          partido.equipoLocal.color,
          partido.equipoVisitante.jugadores,
          false,
        );
      },
      onFinalizar: () {
        Navigator.of(context).pop(); // Cerrar pantalla completa
        _onFinalizarPartido(context, partido);
      },
    );
  }

  /// Muestra dialogo para seleccionar equipo que anota
  void _mostrarDialogoAnotarGol(BuildContext context, PartidoModel partido) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Quien anoto?'),
        content: const Text('Selecciona el equipo que anoto el gol'),
        actions: [
          // Boton equipo local
          FilledButton.icon(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _abrirRegistrarGolDialog(
                context,
                partido,
                partido.equipoLocal.color,
                partido.equipoVisitante.color,
                partido.equipoLocal.jugadores,
                true,
              );
            },
            icon: Icon(Icons.sports_soccer, color: partido.equipoLocal.color.textColor),
            label: Text(partido.equipoLocal.color.displayName.toUpperCase()),
            style: FilledButton.styleFrom(
              backgroundColor: partido.equipoLocal.color.color,
              foregroundColor: partido.equipoLocal.color.textColor,
            ),
          ),
          const SizedBox(width: DesignTokens.spacingS),
          // Boton equipo visitante
          FilledButton.icon(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _abrirRegistrarGolDialog(
                context,
                partido,
                partido.equipoVisitante.color,
                partido.equipoLocal.color,
                partido.equipoVisitante.jugadores,
                false,
              );
            },
            icon: Icon(Icons.sports_soccer, color: partido.equipoVisitante.color.textColor),
            label: Text(partido.equipoVisitante.color.displayName.toUpperCase()),
            style: FilledButton.styleFrom(
              backgroundColor: partido.equipoVisitante.color.color,
              foregroundColor: partido.equipoVisitante.color.textColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Abre el dialog para registrar gol con el equipo seleccionado
  void _abrirRegistrarGolDialog(
    BuildContext context,
    PartidoModel partido,
    ColorEquipo equipoAnotador,
    ColorEquipo equipoContrario,
    List<JugadorPartidoModel> jugadores,
    bool esEquipoLocal,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => RegistrarGolDialog(
        partidoId: partido.id,
        equipoAnotador: equipoAnotador,
        equipoContrario: equipoContrario,
        jugadores: jugadores,
        esEquipoLocal: esEquipoLocal,
        golesBloc: _getOrCreateGolesBloc(),
      ),
    );
  }

  /// Solicita finalizar el partido
  void _onFinalizarPartido(BuildContext context, PartidoModel partido) {
    _getOrCreateFinalizarPartidoBloc().add(
      FinalizarPartidoRequested(
        partidoId: partido.id,
        tiempoTerminado: partido.tiempoTerminado,
      ),
    );
  }

  /// Muestra dialogo de confirmacion para finalizar anticipadamente
  void _mostrarDialogoConfirmacionFinalizar(BuildContext context, String partidoId, String mensaje) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar finalizacion'),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _getOrCreateFinalizarPartidoBloc().add(const CancelarFinalizacion());
            },
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _getOrCreateFinalizarPartidoBloc().add(
                ConfirmarFinalizacionAnticipada(partidoId: partidoId),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: DesignTokens.errorColor,
            ),
            child: const Text('Finalizar de todos modos'),
          ),
        ],
      ),
    );
  }
}

// ============================================
// VISTA DESKTOP - Dashboard Style con CRM Layout
// Panel izquierdo (320px) + Contenido principal (expandido)
// ============================================

class _DesktopDetalleView extends StatefulWidget {
  final String fechaId;
  final FechaDetalleModel? fechaDetalle;
  final bool isLoading;
  final bool isProcesando;
  final bool hasError;
  final String? errorMessage;

  const _DesktopDetalleView({
    required this.fechaId,
    this.fechaDetalle,
    required this.isLoading,
    required this.isProcesando,
    this.hasError = false,
    this.errorMessage,
  });

  @override
  State<_DesktopDetalleView> createState() => _DesktopDetalleViewState();
}

class _DesktopDetalleViewState extends State<_DesktopDetalleView> {
  /// BLoC de partido - se crea una sola vez y se reutiliza
  PartidoBloc? _partidoBloc;

  /// BLoC de goles - para registrar goles
  GolesBloc? _golesBloc;

  /// BLoC de finalizar partido - para terminar partidos
  FinalizarPartidoBloc? _finalizarPartidoBloc;

  /// BLoC de lista de partidos
  ListaPartidosBloc? _listaPartidosBloc;

  /// Flag para evitar cargas duplicadas del partido
  bool _partidoCargado = false;

  /// Getters para acceder a los datos del widget
  String get fechaId => widget.fechaId;
  FechaDetalleModel? get fechaDetalle => widget.fechaDetalle;
  bool get isLoading => widget.isLoading;
  bool get isProcesando => widget.isProcesando;
  bool get hasError => widget.hasError;
  String? get errorMessage => widget.errorMessage;

  @override
  void dispose() {
    // Cerrar los blocs si fueron creados
    _partidoBloc?.close();
    _golesBloc?.close();
    _finalizarPartidoBloc?.close();
    _listaPartidosBloc?.close();
    super.dispose();
  }

  /// Obtiene o crea el PartidoBloc (singleton por vista)
  PartidoBloc _getOrCreatePartidoBloc() {
    if (_partidoBloc == null) {
      _partidoBloc = PartidoBloc(repository: sl());
      // Solo cargar una vez
      if (!_partidoCargado) {
        _partidoCargado = true;
        _partidoBloc!.add(CargarPartidoActivoEvent(fechaId: fechaId));
      }
    }
    return _partidoBloc!;
  }

  /// Obtiene o crea el GolesBloc (singleton por vista)
  GolesBloc _getOrCreateGolesBloc() {
    _golesBloc ??= GolesBloc(repository: sl());
    return _golesBloc!;
  }

  /// Obtiene o crea el FinalizarPartidoBloc (singleton por vista)
  FinalizarPartidoBloc _getOrCreateFinalizarPartidoBloc() {
    _finalizarPartidoBloc ??= FinalizarPartidoBloc(repository: sl());
    return _finalizarPartidoBloc!;
  }

  /// Obtiene o crea el ListaPartidosBloc (singleton por vista)
  ListaPartidosBloc _getOrCreateListaPartidosBloc() {
    if (_listaPartidosBloc == null) {
      _listaPartidosBloc = ListaPartidosBloc(repository: sl());
      _listaPartidosBloc!.add(CargarPartidosEvent(fechaId: fechaId));
    }
    return _listaPartidosBloc!;
  }

  @override
  Widget build(BuildContext context) {
    return DashboardShell(
      currentRoute: '/fechas/$fechaId',
      title: 'Detalle de Pichanga',
      breadcrumbs: const ['Inicio', 'Fechas', 'Detalle'],
      actions: [
        // Solo botones de navegacion en el header
        OutlinedButton.icon(
          onPressed: () {
            context.read<InscripcionBloc>().add(
              CargarFechaDetalleEvent(fechaId: fechaId),
            );
          },
          icon: const Icon(Icons.refresh),
          label: const Text('Actualizar'),
        ),
        const SizedBox(width: DesignTokens.spacingS),
        OutlinedButton.icon(
          onPressed: () => context.go('/fechas'),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Volver'),
        ),
      ],
      child: _buildContent(context),
    );
  }

  /// Abre el dialog de cerrar inscripciones
  void _abrirCerrarInscripcionesDialog(BuildContext context) {
    CerrarInscripcionesDialog.show(
      context,
      fechaDetalle: fechaDetalle!,
      onSuccess: () {
        // Recargar detalle despues de cerrar
        context.read<InscripcionBloc>().add(
          CargarFechaDetalleEvent(fechaId: fechaId),
        );
      },
    );
  }

  /// Abre el dialog de reabrir inscripciones
  void _abrirReabrirInscripcionesDialog(BuildContext context) {
    ReabrirInscripcionesDialog.show(
      context,
      fechaDetalle: fechaDetalle!,
      onSuccess: () {
        // Recargar detalle despues de reabrir
        context.read<InscripcionBloc>().add(
          CargarFechaDetalleEvent(fechaId: fechaId),
        );
      },
    );
  }

  /// Abre el dialogo de edicion
  void _abrirDialogoEditar(BuildContext context) {
    EditarFechaDialog.show(
      context,
      fechaDetalle: fechaDetalle!,
      onSuccess: () {
        // Recargar detalle despues de editar
        context.read<InscripcionBloc>().add(
          CargarFechaDetalleEvent(fechaId: fechaId),
        );
      },
    );
  }

  /// Abre el dialog de finalizar fecha
  void _abrirFinalizarDialog(BuildContext context) {
    FinalizarFechaDialog.show(
      context,
      fechaDetalle: fechaDetalle!,
      onSuccess: () {
        // Recargar detalle despues de finalizar
        context.read<InscripcionBloc>().add(
          CargarFechaDetalleEvent(fechaId: fechaId),
        );
      },
    );
  }

  /// Abre el dialog de asignacion de equipos (Desktop)
  /// E003-HU-005: Dialog grande para asignar equipos sin navegar
  void _abrirAsignarEquiposDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider(
        create: (context) => AsignacionesBloc(
          repository: sl(),
        )..add(CargarAsignacionesEvent(fechaId: fechaId)),
        child: _AsignarEquiposDialog(
          fechaId: fechaId,
          onSuccess: () {
            // Recargar detalle despues de confirmar equipos
            context.read<InscripcionBloc>().add(
              CargarFechaDetalleEvent(fechaId: fechaId),
            );
          },
        ),
      ),
    );
  }

  /// E003-HU-012: Abre el dialog de iniciar pichanga (Desktop)
  void _abrirIniciarPichangaDialog(BuildContext context) {
    // Mostrar dialogo de iniciar pichanga
    IniciarFechaDialog.show(
      context,
      fechaDetalle: fechaDetalle!,
      onSuccess: () {
        // Recargar detalle despues de iniciar
        context.read<InscripcionBloc>().add(
          CargarFechaDetalleEvent(fechaId: fechaId),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Estado de carga
    if (isLoading && fechaDetalle == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Estado de error
    if (hasError && fechaDetalle == null) {
      return _buildErrorContent(context);
    }

    // Sin datos
    if (fechaDetalle == null) {
      return const Center(child: Text('No se encontro la fecha'));
    }

    // Layout CRM: Panel izquierdo (320px) + Contenido principal (expandido)
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Panel izquierdo: Info de la fecha (320px fijo)
        SizedBox(
          width: 320,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(DesignTokens.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoPanel(context),
                const SizedBox(height: DesignTokens.spacingM),
                _buildActionCard(context),
                // Seccion de acciones de administrador (en panel lateral)
                _buildAdminActionsPanel(context),
              ],
            ),
          ),
        ),

        // Separador vertical
        VerticalDivider(
          width: 1,
          thickness: 1,
          color: colorScheme.outlineVariant,
        ),

        // Panel derecho: Partidos e Inscritos (expandido)
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(DesignTokens.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // E003-HU-003: Widget dedicado con BLoC propio y realtime
                // E003-HU-011: Boton agregar jugador (admin, fecha abierta)
                // Solo mostrar lista de inscritos cuando inscripciones abiertas
                if (fechaDetalle!.fecha.estado == EstadoFecha.abierta) ...[
                  InscritosListWidget(
                    fechaId: fechaId,
                    habilitarRealtime: true,
                    expandible: false, // En desktop, siempre expandido
                    capacidadMaxima: fechaDetalle!.capacidadMaxima > 0
                        ? fechaDetalle!.capacidadMaxima
                        : null,
                    fechaAbierta: fechaDetalle!.inscripcionesAbiertas,
                  ),
                  const SizedBox(height: DesignTokens.spacingL),
                ],

                // E004-HU-001: Lista de partidos en area principal
                // Solo mostrar si estado = en_juego o finalizada
                if (fechaDetalle!.fecha.estado == EstadoFecha.enJuego ||
                    fechaDetalle!.fecha.estado == EstadoFecha.finalizada)
                  _buildPartidoSection(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Panel compacto de informacion de la fecha
  Widget _buildInfoPanel(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final fecha = fechaDetalle!.fecha;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header compacto
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(DesignTokens.spacingS),
                  decoration: BoxDecoration(
                    gradient: DesignTokens.primaryGradient,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                  ),
                  child: const Icon(
                    Icons.calendar_month,
                    color: Colors.white,
                    size: DesignTokens.iconSizeM,
                  ),
                ),
                const SizedBox(width: DesignTokens.spacingS),
                Expanded(
                  child: Text(
                    'Info de la Pichanga',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: DesignTokens.fontWeightSemiBold,
                    ),
                  ),
                ),
              ],
            ),

            const Divider(height: DesignTokens.spacingL),

            // Estado badge compacto
            _buildEstadoBadgeCompact(context),

            const SizedBox(height: DesignTokens.spacingM),

            // Fecha y hora
            _buildInfoItemCompact(
              context,
              icon: Icons.event,
              label: 'Fecha',
              value: fecha.fechaFormato,
            ),
            const SizedBox(height: DesignTokens.spacingS),

            _buildInfoItemCompact(
              context,
              icon: Icons.access_time,
              label: 'Hora',
              value: fecha.horaFormato.isNotEmpty ? fecha.horaFormato : 'Por definir',
            ),
            const SizedBox(height: DesignTokens.spacingS),

            _buildInfoItemCompact(
              context,
              icon: Icons.timer,
              label: 'Duracion',
              value: '${fecha.duracionHoras} hora${fecha.duracionHoras != 1 ? 's' : ''}',
            ),
            const SizedBox(height: DesignTokens.spacingS),

            _buildInfoItemCompact(
              context,
              icon: Icons.location_on,
              label: 'Lugar',
              value: fecha.lugar,
            ),
            const SizedBox(height: DesignTokens.spacingS),

            _buildInfoItemCompact(
              context,
              icon: Icons.groups,
              label: 'Formato',
              value: fecha.formatoJuego,
            ),
            const SizedBox(height: DesignTokens.spacingS),

            _buildInfoItemCompact(
              context,
              icon: Icons.attach_money,
              label: 'Costo',
              value: fecha.costoFormato,
              destacado: true,
            ),
            const SizedBox(height: DesignTokens.spacingS),

            _buildInfoItemCompact(
              context,
              icon: Icons.person,
              label: 'Organizador',
              value: fecha.createdByNombre,
            ),
          ],
        ),
      ),
    );
  }

  /// Item de informacion compacto para el panel lateral
  Widget _buildInfoItemCompact(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool destacado = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: DesignTokens.iconSizeS,
          color: destacado ? colorScheme.primary : colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: DesignTokens.spacingS),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: destacado
                      ? DesignTokens.fontWeightBold
                      : DesignTokens.fontWeightMedium,
                  color: destacado ? colorScheme.primary : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Badge de estado compacto
  Widget _buildEstadoBadgeCompact(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Color badgeColor;
    IconData badgeIcon;
    String badgeText;
    String? badgeSubtext;

    if (fechaDetalle!.usuarioInscrito) {
      badgeColor = DesignTokens.successColor;
      badgeIcon = Icons.check_circle;
      badgeText = 'Ya estas anotado';
      if (!fechaDetalle!.inscripcionesAbiertas) {
        badgeSubtext = 'Recuerda pagar ${fechaDetalle!.fecha.costoFormato}';
      }
    } else if (!fechaDetalle!.inscripcionesAbiertas) {
      badgeColor = colorScheme.onSurfaceVariant;
      badgeIcon = Icons.lock_outlined;
      badgeText = fechaDetalle!.fecha.estado.displayName;
      badgeSubtext = fechaDetalle!.mensajeEstado;
    } else if (fechaDetalle!.estaLleno) {
      badgeColor = DesignTokens.accentColor;
      badgeIcon = Icons.group;
      badgeText = 'Fecha completa';
      badgeSubtext = '${fechaDetalle!.totalInscritos} inscritos';
    } else {
      badgeColor = DesignTokens.successColor;
      badgeIcon = Icons.sports_soccer;
      badgeText = 'Inscripciones abiertas';
      final lugares = fechaDetalle!.lugaresDisponibles;
      if (lugares < 999) {
        badgeSubtext = '$lugares lugares disponibles';
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.spacingS),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(badgeIcon, color: badgeColor, size: DesignTokens.iconSizeS),
              const SizedBox(width: DesignTokens.spacingXs),
              Flexible(
                child: Text(
                  badgeText,
                  style: textTheme.labelMedium?.copyWith(
                    color: badgeColor,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          if (badgeSubtext != null) ...[
            const SizedBox(height: DesignTokens.spacingXxs),
            Text(
              badgeSubtext,
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Determinar si hay contenido para mostrar
    final tieneAccion = fechaDetalle!.puedeInscribirse ||
        (fechaDetalle!.usuarioInscrito && fechaDetalle!.inscripcionesAbiertas) ||
        (!fechaDetalle!.inscripcionesAbiertas && !fechaDetalle!.usuarioInscrito);

    // Si no hay accion relevante (inscrito + cerrada o fecha llena), no mostrar card
    if (!tieneAccion) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        side: BorderSide(
          color: fechaDetalle!.usuarioInscrito
              ? DesignTokens.successColor.withValues(alpha: 0.5)
              : colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: fechaDetalle!.usuarioInscrito ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingM),
        child: _buildActionContent(context),
      ),
    );
  }

  Widget _buildActionContent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // CA-005: Inscripciones cerradas y NO esta inscrito
    if (!fechaDetalle!.inscripcionesAbiertas && !fechaDetalle!.usuarioInscrito) {
      return Text(
        fechaDetalle!.mensajeEstado ?? 'Esta fecha ya no acepta nuevas inscripciones.',
        style: textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        textAlign: TextAlign.center,
      );
    }

    // CA-004: Ya inscrito y inscripciones abiertas - mostrar boton cancelar
    if (fechaDetalle!.usuarioInscrito && fechaDetalle!.inscripcionesAbiertas) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: isProcesando
              ? null
              : () => _confirmarCancelacion(context),
          style: OutlinedButton.styleFrom(
            foregroundColor: colorScheme.error,
            side: BorderSide(color: colorScheme.error),
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingM,
              vertical: DesignTokens.spacingS,
            ),
          ),
          icon: isProcesando
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.close, size: 18),
          label: const Text('Cancelar inscripcion'),
        ),
      );
    }

    // Ya inscrito pero inscripciones cerradas - no hay accion disponible
    if (fechaDetalle!.usuarioInscrito && !fechaDetalle!.inscripcionesAbiertas) {
      return const SizedBox.shrink();
    }

    // CA-002: Puede inscribirse
    if (fechaDetalle!.puedeInscribirse) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: isProcesando
              ? null
              : () => _confirmarInscripcion(context),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingM,
              vertical: DesignTokens.spacingS,
            ),
          ),
          icon: isProcesando
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.sports_soccer, size: 18),
          label: const Text('Anotarme'),
        ),
      );
    }

    // Fecha llena
    if (fechaDetalle!.estaLleno) {
      return const SizedBox.shrink();
    }

    return const SizedBox.shrink();
  }

  /// Panel de acciones de administrador en el panel lateral
  /// Muestra botones apilados verticalmente segun el estado de la fecha
  Widget _buildAdminActionsPanel(BuildContext context) {
    if (fechaDetalle == null) return const SizedBox.shrink();

    return BlocBuilder<SessionBloc, SessionState>(
      builder: (context, sessionState) {
        // Solo mostrar si es admin
        if (sessionState is! SessionAuthenticated) {
          return const SizedBox.shrink();
        }

        final isAdmin = sessionState.rol.toLowerCase() == 'admin' ||
            sessionState.rol.toLowerCase() == 'administrador';

        if (!isAdmin) {
          return const SizedBox.shrink();
        }

        final estado = fechaDetalle!.fecha.estado;
        final colorScheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;

        // Construir lista de botones segun el estado
        final List<Widget> actionButtons = [];

        // E003-HU-012: Iniciar Pichanga (solo si estado = 'cerrada')
        if (estado == EstadoFecha.cerrada) {
          actionButtons.add(
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _abrirIniciarPichangaDialog(context),
                style: FilledButton.styleFrom(
                  backgroundColor: DesignTokens.successColor,
                ),
                icon: const Icon(Icons.play_circle),
                label: const Text('Iniciar Pichanga'),
              ),
            ),
          );
        }

        // E003-HU-005: Asignar Equipos (solo si estado = 'cerrada')
        if (estado == EstadoFecha.cerrada) {
          actionButtons.add(
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _abrirAsignarEquiposDialog(context),
                icon: const Icon(Icons.groups),
                label: const Text('Asignar Equipos'),
              ),
            ),
          );
        }

        // E003-HU-004 CA-001: Cerrar inscripciones (si estado = 'abierta')
        if (estado == EstadoFecha.abierta) {
          actionButtons.add(
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _abrirCerrarInscripcionesDialog(context),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.secondary,
                ),
                icon: const Icon(Icons.lock),
                label: const Text('Cerrar Inscripciones'),
              ),
            ),
          );
        }

        // E003-HU-004 CA-006: Reabrir inscripciones (si estado = 'cerrada')
        if (estado == EstadoFecha.cerrada) {
          actionButtons.add(
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _abrirReabrirInscripcionesDialog(context),
                icon: const Icon(Icons.lock_open),
                label: const Text('Reabrir Inscripciones'),
              ),
            ),
          );
        }

        // E003-HU-008: Editar Fecha (solo si estado = 'abierta')
        if (estado == EstadoFecha.abierta) {
          actionButtons.add(
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _abrirDialogoEditar(context),
                icon: const Icon(Icons.edit),
                label: const Text('Editar Fecha'),
              ),
            ),
          );
        }

        // Badge "No editable" si no es abierta
        if (estado != EstadoFecha.abierta &&
            estado != EstadoFecha.finalizada &&
            estado != EstadoFecha.cancelada) {
          actionButtons.add(
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingM,
                vertical: DesignTokens.spacingS,
              ),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(DesignTokens.radiusS),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.edit_off,
                    size: DesignTokens.iconSizeS,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: DesignTokens.spacingXs),
                  Text(
                    'No editable (${estado.displayName})',
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // E003-HU-010: Finalizar Pichanga (si estado = 'cerrada' o 'en_juego')
        if (estado == EstadoFecha.cerrada || estado == EstadoFecha.enJuego) {
          actionButtons.add(
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _abrirFinalizarDialog(context),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF9E9E9E),
                ),
                icon: const Icon(Icons.check_circle),
                label: const Text('Finalizar Pichanga'),
              ),
            ),
          );
        }

        // Si no hay acciones, no mostrar nada
        if (actionButtons.isEmpty) {
          return const SizedBox.shrink();
        }

        // Construir el panel con titulo y botones
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: DesignTokens.spacingM),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                side: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(DesignTokens.spacingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Icon(
                          Icons.admin_panel_settings,
                          size: DesignTokens.iconSizeS,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: DesignTokens.spacingS),
                        Text(
                          'Acciones de Admin',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: DesignTokens.fontWeightSemiBold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: DesignTokens.spacingM),
                    // Botones apilados verticalmente con separacion
                    ...actionButtons.expand((button) => [
                      button,
                      const SizedBox(height: DesignTokens.spacingS),
                    ]).toList()
                      ..removeLast(), // Quitar el ultimo SizedBox
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _confirmarInscripcion(BuildContext context) {
    final fecha = fechaDetalle!.fecha;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          Icons.sports_soccer,
          color: Theme.of(context).colorScheme.primary,
          size: 48,
        ),
        title: const Text('Confirmar inscripcion'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Te anotaras para la pichanga:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: DesignTokens.spacingM),
            _DialogInfoRow(icon: Icons.calendar_today, text: '${fecha.fechaFormato} - ${fecha.horaFormato}'),
            _DialogInfoRow(icon: Icons.location_on, text: fecha.lugar),
            _DialogInfoRow(
              icon: Icons.attach_money,
              text: 'Debes pagar: ${fecha.costoFormato}',
              destacado: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<InscripcionBloc>().add(
                InscribirseEvent(fechaId: fechaId),
              );
            },
            child: const Text('Anotarme'),
          ),
        ],
      ),
    );
  }

  /// E003-HU-007: Dialogo de confirmacion para cancelar inscripcion (Desktop)
  void _confirmarCancelacion(BuildContext context) {
    CancelarInscripcionDialog.show(
      context,
      fechaDetalle: fechaDetalle!,
      onSuccess: () {
        // Recargar detalle despues de cancelar
        context.read<InscripcionBloc>().add(
          CargarFechaDetalleEvent(fechaId: fechaId),
        );
      },
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
            errorMessage ?? 'Error al cargar detalle de la fecha',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DesignTokens.spacingL),
          FilledButton.icon(
            onPressed: () {
              context.read<InscripcionBloc>().add(
                CargarFechaDetalleEvent(fechaId: fechaId),
              );
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  /// E004-HU-001: Seccion de partido en vivo y lista de partidos (Desktop)
  /// NOTA: Usa MultiBlocProvider para inyectar blocs de partido, goles, finalizar y lista
  Widget _buildPartidoSection(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _getOrCreatePartidoBloc()),
        BlocProvider.value(value: _getOrCreateGolesBloc()),
        BlocProvider.value(value: _getOrCreateFinalizarPartidoBloc()),
        BlocProvider.value(value: _getOrCreateListaPartidosBloc()),
      ],
      child: BlocBuilder<SessionBloc, SessionState>(
        builder: (context, sessionState) {
          final isAdmin = sessionState is SessionAuthenticated &&
              (sessionState.rol.toLowerCase() == 'admin' ||
                  sessionState.rol.toLowerCase() == 'administrador');

          return BlocListener<FinalizarPartidoBloc, FinalizarPartidoState>(
            listener: (context, state) {
              if (state is FinalizarPartidoSuccess) {
                // Recargar partido activo y lista de partidos
                _getOrCreatePartidoBloc().add(CargarPartidoActivoEvent(fechaId: fechaId));
                _getOrCreateListaPartidosBloc().add(RefrescarPartidosEvent(fechaId: fechaId));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.response.message.isNotEmpty
                        ? state.response.message
                        : 'Partido finalizado'),
                    backgroundColor: DesignTokens.successColor,
                  ),
                );
              } else if (state is FinalizarPartidoRequiereConfirmacion) {
                _mostrarDialogoConfirmacionFinalizar(context, state.partidoId, state.message);
              } else if (state is FinalizarPartidoError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: DesignTokens.errorColor,
                  ),
                );
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Widget de partido en vivo con callbacks para admin
                PartidoEnVivoWidget(
                  esAdmin: isAdmin,
                  onPantallaCompleta: (partido) => _abrirPantallaCompleta(context, partido, isAdmin),
                  onAnotarGol: isAdmin ? (partido) => _mostrarDialogoAnotarGol(context, partido) : null,
                  onFinalizarPartido: isAdmin ? (partido) => _onFinalizarPartido(context, partido) : null,
                ),

                const SizedBox(height: DesignTokens.spacingM),

                // Lista de partidos con opcion de crear nuevo
                if (fechaDetalle != null)
                  ListaPartidosWidget(
                    fechaDetalle: fechaDetalle!,
                    esAdmin: isAdmin,
                    onPartidoCreado: () {
                      // Refrescar partido activo y lista
                      _getOrCreatePartidoBloc().add(CargarPartidoActivoEvent(fechaId: fechaId));
                      _getOrCreateListaPartidosBloc().add(RefrescarPartidosEvent(fechaId: fechaId));
                    },
                  ),

                const SizedBox(height: DesignTokens.spacingM),
              ],
            ),
          );
        },
      ),
    );
  }

  /// E004-HU-002 CA-009: Abre el temporizador en pantalla completa (Desktop)
  void _abrirPantallaCompleta(BuildContext context, PartidoModel partido, bool esAdmin) {
    TemporizadorFullscreen.show(
      context,
      partido: partido,
      esAdmin: esAdmin,
      golesLocal: partido.golesLocal,
      golesVisitante: partido.golesVisitante,
      onPausar: () {
        _getOrCreatePartidoBloc().add(PausarPartidoEvent(partidoId: partido.id));
      },
      onReanudar: () {
        _getOrCreatePartidoBloc().add(ReanudarPartidoEvent(partidoId: partido.id));
      },
      onGolLocal: () {
        // Abrir dialogo para registrar gol del equipo local
        Navigator.of(context).pop(); // Cerrar pantalla completa
        _abrirRegistrarGolDialog(
          context,
          partido,
          partido.equipoLocal.color,
          partido.equipoVisitante.color,
          partido.equipoLocal.jugadores,
          true,
        );
      },
      onGolVisitante: () {
        // Abrir dialogo para registrar gol del equipo visitante
        Navigator.of(context).pop(); // Cerrar pantalla completa
        _abrirRegistrarGolDialog(
          context,
          partido,
          partido.equipoVisitante.color,
          partido.equipoLocal.color,
          partido.equipoVisitante.jugadores,
          false,
        );
      },
      onFinalizar: () {
        Navigator.of(context).pop(); // Cerrar pantalla completa
        _onFinalizarPartido(context, partido);
      },
    );
  }

  /// Muestra dialogo para seleccionar equipo que anota (Desktop)
  void _mostrarDialogoAnotarGol(BuildContext context, PartidoModel partido) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Quien anoto?'),
        content: const Text('Selecciona el equipo que anoto el gol'),
        actions: [
          // Boton equipo local
          FilledButton.icon(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _abrirRegistrarGolDialog(
                context,
                partido,
                partido.equipoLocal.color,
                partido.equipoVisitante.color,
                partido.equipoLocal.jugadores,
                true,
              );
            },
            icon: Icon(Icons.sports_soccer, color: partido.equipoLocal.color.textColor),
            label: Text(partido.equipoLocal.color.displayName.toUpperCase()),
            style: FilledButton.styleFrom(
              backgroundColor: partido.equipoLocal.color.color,
              foregroundColor: partido.equipoLocal.color.textColor,
            ),
          ),
          const SizedBox(width: DesignTokens.spacingS),
          // Boton equipo visitante
          FilledButton.icon(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _abrirRegistrarGolDialog(
                context,
                partido,
                partido.equipoVisitante.color,
                partido.equipoLocal.color,
                partido.equipoVisitante.jugadores,
                false,
              );
            },
            icon: Icon(Icons.sports_soccer, color: partido.equipoVisitante.color.textColor),
            label: Text(partido.equipoVisitante.color.displayName.toUpperCase()),
            style: FilledButton.styleFrom(
              backgroundColor: partido.equipoVisitante.color.color,
              foregroundColor: partido.equipoVisitante.color.textColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Abre el dialog para registrar gol con el equipo seleccionado (Desktop)
  void _abrirRegistrarGolDialog(
    BuildContext context,
    PartidoModel partido,
    ColorEquipo equipoAnotador,
    ColorEquipo equipoContrario,
    List<JugadorPartidoModel> jugadores,
    bool esEquipoLocal,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => RegistrarGolDialog(
        partidoId: partido.id,
        equipoAnotador: equipoAnotador,
        equipoContrario: equipoContrario,
        jugadores: jugadores,
        esEquipoLocal: esEquipoLocal,
        golesBloc: _getOrCreateGolesBloc(),
      ),
    );
  }

  /// Solicita finalizar el partido (Desktop)
  void _onFinalizarPartido(BuildContext context, PartidoModel partido) {
    _getOrCreateFinalizarPartidoBloc().add(
      FinalizarPartidoRequested(
        partidoId: partido.id,
        tiempoTerminado: partido.tiempoTerminado,
      ),
    );
  }

  /// Muestra dialogo de confirmacion para finalizar anticipadamente (Desktop)
  void _mostrarDialogoConfirmacionFinalizar(BuildContext context, String partidoId, String mensaje) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar finalizacion'),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _getOrCreateFinalizarPartidoBloc().add(const CancelarFinalizacion());
            },
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _getOrCreateFinalizarPartidoBloc().add(
                ConfirmarFinalizacionAnticipada(partidoId: partidoId),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: DesignTokens.errorColor,
            ),
            child: const Text('Finalizar de todos modos'),
          ),
        ],
      ),
    );
  }
}

// ============================================
// WIDGETS AUXILIARES
// ============================================

/// Fila de info para dialogos
class _DialogInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool destacado;

  const _DialogInfoRow({
    required this.icon,
    required this.text,
    this.destacado = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.spacingXs),
      child: Row(
        children: [
          Icon(
            icon,
            size: DesignTokens.iconSizeS,
            color: destacado ? colorScheme.primary : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: DesignTokens.spacingS),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: destacado
                    ? DesignTokens.fontWeightBold
                    : DesignTokens.fontWeightRegular,
                color: destacado ? colorScheme.primary : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// DIALOG ASIGNAR EQUIPOS (Desktop)
// E003-HU-005: Dialog grande para asignacion de equipos
// ============================================

/// Dialog de asignacion de equipos para desktop
/// Contiene la misma funcionalidad que AsignarEquiposPage pero en un dialog
class _AsignarEquiposDialog extends StatelessWidget {
  final String fechaId;
  final VoidCallback onSuccess;

  const _AsignarEquiposDialog({
    required this.fechaId,
    required this.onSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AsignacionesBloc, AsignacionesState>(
      listener: (context, state) {
        // CA-007: Feedback al confirmar equipos
        if (state is EquiposConfirmados) {
          _mostrarSnackBarExito(context, state.message);
          Navigator.of(context).pop();
          onSuccess();
        }

        // Errores
        if (state is AsignarEquipoError) {
          _mostrarSnackBarError(context, state.message);
        }
        if (state is DesasignarEquipoError) {
          _mostrarSnackBarError(context, state.message);
        }
        if (state is ConfirmarEquiposError) {
          _mostrarSnackBarError(context, state.message);
        }
      },
      builder: (context, state) {
        final data = _obtenerData(state);
        final isLoading = state is AsignacionesLoading;
        final hasError = state is AsignacionesError;
        final errorMessage = hasError ? state.message : null;
        final isConfirmando = state is ConfirmandoEquipos;
        final asignacionCompleta = data?.resumen.asignacionCompleta ?? false;

        return Dialog(
          insetPadding: const EdgeInsets.all(24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.radiusL),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 1200,
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              child: Scaffold(
                appBar: AppBar(
                  title: const Text('Asignar Equipos'),
                  leading: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  actions: [
                    // CA-006: Indicador de desbalance
                    if (data != null && _hayDesbalance(data))
                      Container(
                        margin: const EdgeInsets.only(right: DesignTokens.spacingS),
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
                    // Boton refrescar
                    IconButton(
                      onPressed: () {
                        context.read<AsignacionesBloc>().add(
                              CargarAsignacionesEvent(fechaId: fechaId),
                            );
                      },
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Actualizar',
                    ),
                    const SizedBox(width: DesignTokens.spacingS),
                    // CA-007: Boton confirmar
                    Padding(
                      padding: const EdgeInsets.only(right: DesignTokens.spacingM),
                      child: FilledButton.icon(
                        onPressed: asignacionCompleta && !isConfirmando
                            ? () => _mostrarDialogConfirmacion(context, data!)
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
                    ),
                  ],
                ),
                body: _buildContent(
                  context,
                  data: data,
                  isLoading: isLoading,
                  hasError: hasError,
                  errorMessage: errorMessage,
                ),
              ),
            ),
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
    return null;
  }

  bool _hayDesbalance(ObtenerAsignacionesDataModel data) {
    if (data.equipos.isEmpty) return false;
    final cantidades = data.equipos.map((e) => e.cantidad).toList();
    if (cantidades.isEmpty) return false;
    final max = cantidades.reduce((a, b) => a > b ? a : b);
    final min = cantidades.reduce((a, b) => a < b ? a : b);
    return (max - min) > 1;
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

  Widget _buildContent(
    BuildContext context, {
    required ObtenerAsignacionesDataModel? data,
    required bool isLoading,
    required bool hasError,
    required String? errorMessage,
  }) {
    // Estado de carga
    if (isLoading && data == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Estado de error
    if (hasError && data == null) {
      return _buildErrorContent(context, errorMessage);
    }

    // Sin datos
    if (data == null) {
      return const Center(child: Text('No se encontraron datos'));
    }

    // Layout de 2 columnas para el dialog
    return Padding(
      padding: const EdgeInsets.all(DesignTokens.spacingL),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Columna izquierda: Jugadores sin asignar
          SizedBox(
            width: 350,
            child: _buildPanelJugadoresSinAsignar(context, data),
          ),

          const SizedBox(width: DesignTokens.spacingL),

          // Columna derecha: Equipos (expandida)
          Expanded(
            child: _buildPanelEquipos(context, data),
          ),
        ],
      ),
    );
  }

  Widget _buildPanelJugadoresSinAsignar(
    BuildContext context,
    ObtenerAsignacionesDataModel data,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final jugadoresSinAsignar = data.jugadoresSinAsignar;

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
        mainAxisSize: MainAxisSize.min,
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
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
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
                        coloresDisponibles: data.coloresDisponibles,
                        onAsignar: (_) {},
                        isMobile: false,
                      ),
                    ),
                    child: JugadorAsignacionTile(
                      jugador: jugador,
                      coloresDisponibles: data.coloresDisponibles,
                      onAsignar: (equipo) => _asignarEquipo(context, data, jugador, equipo),
                      isMobile: false,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPanelEquipos(BuildContext context, ObtenerAsignacionesDataModel data) {
    final colores = data.coloresDisponibles;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con progreso
          _buildProgresoHeader(context, data),

          const SizedBox(height: DesignTokens.spacingL),

          // Grid de equipos
          Wrap(
            spacing: DesignTokens.spacingM,
            runSpacing: DesignTokens.spacingM,
            children: colores.map((color) {
              final jugadoresEquipo = data.jugadoresDelEquipo(color);
              return SizedBox(
                width: colores.length == 2 ? 400 : 320,
                child: EquipoContainerWidget(
                  equipo: color,
                  jugadores: jugadoresEquipo,
                  onJugadorRemover: (jugador) => _removerDeEquipo(context, data, jugador),
                  onJugadorDrop: (jugador) => _asignarEquipo(context, data, jugador, color),
                  isMobile: false,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildProgresoHeader(BuildContext context, ObtenerAsignacionesDataModel data) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final resumen = data.resumen;

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
            children: data.coloresDisponibles.map((color) {
              final cantidad = data.jugadoresDelEquipo(color).length;
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

  void _asignarEquipo(
    BuildContext context,
    ObtenerAsignacionesDataModel data,
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

  void _removerDeEquipo(
    BuildContext context,
    ObtenerAsignacionesDataModel data,
    JugadorAsignacionModel jugador,
  ) {
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
            ...data.coloresDisponibles.map((color) {
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
                  _asignarEquipo(context, data, jugador, color);
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

  void _mostrarDialogConfirmacion(
    BuildContext context,
    ObtenerAsignacionesDataModel data,
  ) {
    ConfirmarEquiposDialog.show(
      context,
      fechaId: fechaId,
      data: data,
      hayDesbalance: _hayDesbalance(data),
    );
  }

  Widget _buildErrorContent(BuildContext context, String? errorMessage) {
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
