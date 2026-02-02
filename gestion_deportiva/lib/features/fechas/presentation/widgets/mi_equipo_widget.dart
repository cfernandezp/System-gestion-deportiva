import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../data/models/mi_equipo_model.dart';
import '../../data/models/equipos_fecha_model.dart';
import '../../data/models/color_equipo.dart';
import '../bloc/mi_equipo/mi_equipo.dart';

/// Widget para mostrar "Mi Equipo" en la pagina de detalle de fecha
/// E003-HU-006: Ver Mi Equipo
/// CA-001: Ver mi equipo asignado
/// CA-002: Color visual destacado
/// CA-003: Lista de companeros
/// CA-004: Ver todos los equipos
/// CA-005: Equipos no asignados aun
/// CA-006: No inscrito (no muestra nada)
/// CA-007: Cambio de equipo notificado (realtime)
/// RN-004: Actualizacion en tiempo real
/// RN-005: Codigo de color consistente
class MiEquipoWidget extends StatefulWidget {
  final String fechaId;
  final bool habilitarRealtime;
  final bool mostrarTodosEquipos;

  const MiEquipoWidget({
    super.key,
    required this.fechaId,
    this.habilitarRealtime = true,
    this.mostrarTodosEquipos = false,
  });

  @override
  State<MiEquipoWidget> createState() => _MiEquipoWidgetState();
}

class _MiEquipoWidgetState extends State<MiEquipoWidget> {
  bool _expandido = false;

  /// Flag para evitar cargas duplicadas
  bool _datosCargados = false;

  /// Flag para evitar detener realtime despues de dispose
  bool _realtimeIniciado = false;

  @override
  void initState() {
    super.initState();
    // Usar addPostFrameCallback para evitar llamar context.read durante build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_datosCargados) {
        _cargarDatos();
      }
    });
  }

  void _cargarDatos() {
    if (_datosCargados) return;
    _datosCargados = true;

    final bloc = context.read<MiEquipoBloc>();

    if (widget.mostrarTodosEquipos) {
      bloc.add(CargarEquiposFechaEvent(fechaId: widget.fechaId));
    } else {
      bloc.add(CargarMiEquipoEvent(fechaId: widget.fechaId));
    }

    if (widget.habilitarRealtime) {
      _realtimeIniciado = true;
      bloc.add(IniciarRealtimeEvent(fechaId: widget.fechaId));
    }
  }

  @override
  void dispose() {
    // Solo detener realtime si fue iniciado y el widget aun esta mounted
    if (_realtimeIniciado) {
      // Intentar detener realtime de forma segura
      try {
        context.read<MiEquipoBloc>().add(const DetenerRealtimeEvent());
      } catch (_) {
        // Ignorar errores si el bloc ya no esta disponible
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MiEquipoBloc, MiEquipoState>(
      listener: (context, state) {
        // Verificar que el widget siga montado antes de mostrar SnackBar
        if (!mounted) return;

        // CA-007: Mostrar indicador cuando se actualiza via realtime
        if (state is MiEquipoCargado && state.actualizadoRealtime) {
          _mostrarSnackBarActualizado(context);
        }
        if (state is EquiposFechaCargados && state.actualizadoRealtime) {
          _mostrarSnackBarActualizado(context);
        }
      },
      builder: (context, state) {
        // CA-006: No inscrito - no mostrar nada
        if (state is NoInscrito) {
          return const SizedBox.shrink();
        }

        // Loading
        if (state is MiEquipoLoading) {
          return _buildLoadingCard(context);
        }

        // CA-005: Equipos pendientes
        if (state is EquiposPendientes) {
          return _buildEquiposPendientes(context, state);
        }

        // CA-001, CA-002, CA-003: Mi equipo cargado
        if (state is MiEquipoCargado) {
          return _buildMiEquipoCard(context, state.data);
        }

        // CA-004: Todos los equipos
        if (state is EquiposFechaCargados) {
          return _buildTodosEquipos(context, state.data);
        }

        // Error
        if (state is MiEquipoError) {
          return _buildErrorCard(context, state.message);
        }

        return const SizedBox.shrink();
      },
    );
  }

  void _mostrarSnackBarActualizado(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.sync, color: Colors.white, size: 20),
            const SizedBox(width: DesignTokens.spacingS),
            const Expanded(child: Text('Equipos actualizados')),
          ],
        ),
        backgroundColor: DesignTokens.primaryColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildLoadingCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
          children: [
            const CircularProgressIndicator(strokeWidth: 2),
            const SizedBox(height: DesignTokens.spacingM),
            Text(
              'Cargando equipo...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  /// CA-005: Widget cuando los equipos no han sido asignados
  Widget _buildEquiposPendientes(BuildContext context, EquiposPendientes state) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        side: BorderSide(
          color: DesignTokens.accentColor.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingM),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(DesignTokens.spacingM),
              decoration: BoxDecoration(
                color: DesignTokens.accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              ),
              child: Icon(
                Icons.schedule,
                color: DesignTokens.accentColor,
                size: DesignTokens.iconSizeL,
              ),
            ),
            const SizedBox(width: DesignTokens.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mi Equipo',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: DesignTokens.fontWeightSemiBold,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spacingXs),
                  Text(
                    state.mensaje,
                    style: textTheme.bodyMedium?.copyWith(
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

  /// CA-001, CA-002, CA-003: Widget con mi equipo
  Widget _buildMiEquipoCard(BuildContext context, MiEquipoDataModel data) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (data.miEquipo == null) {
      return const SizedBox.shrink();
    }

    final equipo = data.miEquipo!;
    final colorEquipo = ColorEquipo.fromString(equipo.colorEquipo);
    final equipoColor = colorEquipo?.color ?? colorScheme.primary;
    final textColor = colorEquipo?.textColor ?? Colors.white;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        side: BorderSide(
          color: equipoColor.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Header con color del equipo (CA-001, CA-002)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(DesignTokens.spacingM),
            decoration: BoxDecoration(
              color: equipoColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(DesignTokens.radiusM - 2),
                topRight: Radius.circular(DesignTokens.radiusM - 2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.shield,
                  color: textColor,
                  size: DesignTokens.iconSizeL,
                ),
                const SizedBox(width: DesignTokens.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tu Equipo',
                        style: textTheme.labelMedium?.copyWith(
                          color: textColor.withValues(alpha: 0.8),
                        ),
                      ),
                      Text(
                        equipo.nombreEquipo,
                        style: textTheme.titleLarge?.copyWith(
                          color: textColor,
                          fontWeight: DesignTokens.fontWeightBold,
                        ),
                      ),
                    ],
                  ),
                ),
                // Boton expandir para ver companeros
                IconButton(
                  onPressed: () => setState(() => _expandido = !_expandido),
                  icon: Icon(
                    _expandido ? Icons.expand_less : Icons.expand_more,
                    color: textColor,
                  ),
                  tooltip: _expandido ? 'Ocultar companeros' : 'Ver companeros',
                ),
              ],
            ),
          ),

          // CA-003: Lista de companeros (expandible)
          if (_expandido && data.companeros.isNotEmpty)
            _buildListaCompaneros(context, data.companeros),
        ],
      ),
    );
  }

  /// CA-003: Lista de companeros de equipo
  Widget _buildListaCompaneros(BuildContext context, List<CompaneroModel> companeros) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Companeros de equipo (${companeros.length})',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: DesignTokens.fontWeightSemiBold,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingS),
          ...companeros.map((companero) => _buildCompaneroItem(context, companero)),
        ],
      ),
    );
  }

  Widget _buildCompaneroItem(BuildContext context, CompaneroModel companero) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.spacingXs),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: companero.esTu
                ? DesignTokens.primaryColor
                : colorScheme.surfaceContainerHighest,
            backgroundImage: companero.fotoUrl != null
                ? NetworkImage(companero.fotoUrl!)
                : null,
            child: companero.fotoUrl == null
                ? Text(
                    companero.nombre.isNotEmpty
                        ? companero.nombre[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: companero.esTu
                          ? Colors.white
                          : colorScheme.onSurfaceVariant,
                      fontWeight: DesignTokens.fontWeightSemiBold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: DesignTokens.spacingM),
          // Nombre
          Expanded(
            child: Text(
              companero.nombre,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: companero.esTu
                    ? DesignTokens.fontWeightSemiBold
                    : DesignTokens.fontWeightRegular,
              ),
            ),
          ),
          // Indicador "(Tu)"
          if (companero.esTu)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingS,
                vertical: DesignTokens.spacingXs,
              ),
              decoration: BoxDecoration(
                color: DesignTokens.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
              ),
              child: Text(
                'Tu',
                style: textTheme.labelSmall?.copyWith(
                  color: DesignTokens.primaryColor,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// CA-004: Widget con todos los equipos
  Widget _buildTodosEquipos(BuildContext context, EquiposFechaDataModel data) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(DesignTokens.spacingM),
            child: Row(
              children: [
                const Icon(Icons.groups, size: DesignTokens.iconSizeM),
                const SizedBox(width: DesignTokens.spacingS),
                Text(
                  'Equipos (${data.totalEquipos})',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: DesignTokens.fontWeightSemiBold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...data.equipos.map((equipo) => _buildEquipoResumen(context, equipo)),
        ],
      ),
    );
  }

  Widget _buildEquipoResumen(BuildContext context, EquipoCompletoModel equipo) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final colorEquipo = ColorEquipo.fromString(equipo.colorEquipo);
    final equipoColor = colorEquipo?.color ?? colorScheme.primary;
    final textColor = colorEquipo?.textColor ?? Colors.white;

    return Container(
      margin: const EdgeInsets.all(DesignTokens.spacingS),
      decoration: BoxDecoration(
        color: equipo.esMiEquipo
            ? equipoColor.withValues(alpha: 0.1)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
        border: Border.all(
          color: equipo.esMiEquipo
              ? equipoColor
              : colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: equipo.esMiEquipo ? 2 : 1,
        ),
      ),
      child: ExpansionTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: equipoColor,
            borderRadius: BorderRadius.circular(DesignTokens.radiusS),
          ),
          child: Center(
            child: Text(
              '${equipo.totalJugadores}',
              style: textTheme.titleMedium?.copyWith(
                color: textColor,
                fontWeight: DesignTokens.fontWeightBold,
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Text(
              equipo.nombreEquipo,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: DesignTokens.fontWeightSemiBold,
              ),
            ),
            if (equipo.esMiEquipo) ...[
              const SizedBox(width: DesignTokens.spacingS),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacingS,
                  vertical: DesignTokens.spacingXxs,
                ),
                decoration: BoxDecoration(
                  color: DesignTokens.primaryColor,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                ),
                child: Text(
                  'Tu equipo',
                  style: textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          '${equipo.totalJugadores} jugador${equipo.totalJugadores != 1 ? 'es' : ''}',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        children: equipo.jugadores
            .map((jugador) => _buildCompaneroItem(context, jugador))
            .toList(),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, String message) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        side: BorderSide(color: colorScheme.error.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingM),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: colorScheme.error),
            const SizedBox(width: DesignTokens.spacingM),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: colorScheme.error),
              ),
            ),
            IconButton(
              onPressed: _cargarDatos,
              icon: const Icon(Icons.refresh),
              tooltip: 'Reintentar',
            ),
          ],
        ),
      ),
    );
  }
}
