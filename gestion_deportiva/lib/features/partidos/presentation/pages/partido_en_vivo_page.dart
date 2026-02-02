import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/services/alarm_service.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../data/models/partido_model.dart';
import '../bloc/partido/partido.dart';
import '../widgets/partido_en_vivo_widget.dart';
import '../widgets/temporizador_fullscreen.dart';

/// Pagina de partido en vivo
/// E004-HU-001: Iniciar Partido
/// E004-HU-002: Temporizador con Alarma
///
/// Muestra el partido activo con temporizador y controles de admin.
/// Permite abrir pantalla completa para mejor visibilidad.
class PartidoEnVivoPage extends StatefulWidget {
  /// ID de la fecha del partido
  final String fechaId;

  /// Si el usuario es admin
  final bool esAdmin;

  const PartidoEnVivoPage({
    super.key,
    required this.fechaId,
    this.esAdmin = false,
  });

  @override
  State<PartidoEnVivoPage> createState() => _PartidoEnVivoPageState();
}

class _PartidoEnVivoPageState extends State<PartidoEnVivoPage> {
  late final AlarmService _alarmService;

  @override
  void initState() {
    super.initState();
    _alarmService = sl<AlarmService>();
    // Inicializar servicio de audio (requiere interaccion del usuario en web)
    _alarmService.initialize();
  }

  @override
  void dispose() {
    // Detener alarmas al salir
    _alarmService.stopEndAlarm();
    super.dispose();
  }

  /// CA-009: Abrir pantalla completa
  void _abrirPantallaCompleta(BuildContext context, PartidoModel partido) {
    // Obtener goles reales del partido
    final golesLocal = partido.golesLocal;
    final golesVisitante = partido.golesVisitante;

    TemporizadorFullscreen.show(
      context,
      partido: partido,
      esAdmin: widget.esAdmin,
      golesLocal: golesLocal,
      golesVisitante: golesVisitante,
      onPausar: () {
        context.read<PartidoBloc>().add(
              PausarPartidoEvent(partidoId: partido.id),
            );
      },
      onReanudar: () {
        context.read<PartidoBloc>().add(
              ReanudarPartidoEvent(partidoId: partido.id),
            );
      },
      onGolLocal: () {
        // TODO: Implementar registro de gol local (E004-HU-003)
      },
      onGolVisitante: () {
        // TODO: Implementar registro de gol visitante (E004-HU-003)
      },
      onFinalizar: () {
        // TODO: Implementar finalizar partido (E004-HU-005)
        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<PartidoBloc>()
        ..add(CargarPartidoActivoEvent(fechaId: widget.fechaId)),
      child: Builder(
        builder: (blocContext) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Partido en Vivo'),
              actions: [
                // Boton de recargar - usa blocContext para acceder al Bloc
                IconButton(
                  onPressed: () {
                    blocContext.read<PartidoBloc>().add(
                          CargarPartidoActivoEvent(fechaId: widget.fechaId),
                        );
                  },
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Recargar',
                ),
              ],
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(DesignTokens.spacingM),
                child: BlocBuilder<PartidoBloc, PartidoState>(
                  builder: (context, state) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Widget de partido en vivo
                        PartidoEnVivoWidget(
                          esAdmin: widget.esAdmin,
                          onPantallaCompleta: (partido) =>
                              _abrirPantallaCompleta(blocContext, partido),
                          onEstadoCambiado: () {
                            // Recargar datos si cambia el estado
                          },
                        ),

                        const SizedBox(height: DesignTokens.spacingL),

                        // Informacion adicional
                        if (state is PartidoEnCurso || state is PartidoPausado)
                          _buildInfoAdicional(context, state),
                      ],
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoAdicional(BuildContext context, PartidoState state) {
    final partido = state is PartidoEnCurso
        ? state.partido
        : (state as PartidoPausado).partido;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informacion del Partido',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: DesignTokens.fontWeightSemiBold,
              ),
            ),
            const SizedBox(height: DesignTokens.spacingM),

            // Hora de inicio
            if (partido.horaInicioFormato != null)
              _InfoRow(
                icon: Icons.play_circle_outline,
                label: 'Inicio',
                value: partido.horaInicioFormato!,
              ),

            // Hora estimada de fin
            if (partido.horaFinEstimadaFormato != null)
              _InfoRow(
                icon: Icons.flag_outlined,
                label: 'Fin estimado',
                value: partido.horaFinEstimadaFormato!,
              ),

            // Duracion
            _InfoRow(
              icon: Icons.timer_outlined,
              label: 'Duracion',
              value: '${partido.duracionMinutos} minutos',
            ),

            // Estado
            _InfoRow(
              icon: Icons.info_outline,
              label: 'Estado',
              value: partido.estado.displayName,
            ),
          ],
        ),
      ),
    );
  }
}

/// Fila de informacion
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.spacingS),
      child: Row(
        children: [
          Icon(
            icon,
            size: DesignTokens.iconSizeS,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: DesignTokens.spacingS),
          Text(
            '$label:',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: DesignTokens.spacingXs),
          Expanded(
            child: Text(
              value,
              style: textTheme.bodySmall?.copyWith(
                fontWeight: DesignTokens.fontWeightMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
