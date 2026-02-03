import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../data/models/resumen_jornada_model.dart';

/// Boton para compartir el resumen de jornada
/// E004-HU-007: Resumen de Jornada
/// CA-006: Compartir resumen en WhatsApp
/// RN-005: Formato legible con fecha, lugar, posiciones, goleador, marcadores
class CompartirResumenButton extends StatelessWidget {
  /// Resumen completo de la jornada
  final ResumenJornadaModel resumen;

  /// Si mostrar como boton expandido o solo icono
  final bool expandido;

  /// Callback opcional cuando se comparte exitosamente
  final VoidCallback? onCompartido;

  const CompartirResumenButton({
    super.key,
    required this.resumen,
    this.expandido = true,
    this.onCompartido,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (expandido) {
      return FilledButton.icon(
        onPressed: () => _compartir(context),
        icon: const Icon(Icons.share),
        label: const Text('Compartir'),
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.secondary,
          foregroundColor: colorScheme.onSecondary,
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingM,
            vertical: DesignTokens.spacingS,
          ),
        ),
      );
    }

    return IconButton(
      onPressed: () => _compartir(context),
      icon: const Icon(Icons.share),
      tooltip: 'Compartir resumen',
      style: IconButton.styleFrom(
        foregroundColor: colorScheme.primary,
      ),
    );
  }

  /// Genera el texto formateado para compartir
  /// RN-005: Incluir fecha, lugar, posiciones, goleador, marcadores
  String _generarTextoResumen() {
    final buffer = StringBuffer();

    // Header con lugar y fecha
    buffer.writeln(_generarHeader());
    buffer.writeln();

    // Tabla de posiciones (CA-002)
    if (resumen.tieneTabla) {
      buffer.writeln(_generarTablaPosiciones());
      buffer.writeln();
    }

    // Goleador de la fecha (CA-003)
    if (resumen.tieneGoleadorFecha) {
      buffer.writeln(_generarGoleadorFecha());
      buffer.writeln();
    }

    // Partidos con marcadores (CA-001)
    if (resumen.partidos.isNotEmpty) {
      buffer.writeln(_generarPartidos());
      buffer.writeln();
    }

    // Footer con marca de la app
    buffer.writeln('Gestion Deportiva App');

    return buffer.toString();
  }

  /// Genera header con lugar y fecha
  String _generarHeader() {
    final buffer = StringBuffer();

    // Lugar
    final lugar = resumen.fecha?.lugar ?? 'Pichanga';
    buffer.writeln('PICHANGA - $lugar');

    // Fecha formateada
    if (resumen.fecha != null) {
      final fechaFormateada = _formatearFecha(resumen.fecha!.fechaProgramada);
      buffer.write(fechaFormateada);
    }

    return buffer.toString();
  }

  /// Genera la tabla de posiciones
  String _generarTablaPosiciones() {
    final buffer = StringBuffer();
    buffer.writeln('TABLA DE POSICIONES');

    for (final posicion in resumen.tablaPosiciones) {
      final medalla = _getMedalla(posicion.posicion);
      final equipoCapitalizado = _capitalize(posicion.equipo);
      final statsCorto = 'PJ:${posicion.pj} PG:${posicion.pg} PE:${posicion.pe} PP:${posicion.pp}';

      buffer.writeln('$medalla $equipoCapitalizado - ${posicion.pts} pts ($statsCorto)');
    }

    return buffer.toString();
  }

  /// Genera la seccion del goleador de la fecha
  String _generarGoleadorFecha() {
    final buffer = StringBuffer();
    buffer.writeln('GOLEADOR DE LA FECHA');

    if (resumen.goleadorFecha != null && resumen.goleadorFecha!.isNotEmpty) {
      for (final goleador in resumen.goleadorFecha!) {
        final equipoCapitalizado = _capitalize(goleador.equipo);
        final golesTexto = goleador.goles == 1 ? 'gol' : 'goles';
        buffer.writeln(
          '${goleador.jugadorNombre} ($equipoCapitalizado) - ${goleador.goles} $golesTexto',
        );
      }
    }

    return buffer.toString();
  }

  /// Genera la lista de partidos con marcadores
  String _generarPartidos() {
    final buffer = StringBuffer();
    buffer.writeln('PARTIDOS');

    for (final partido in resumen.partidos) {
      final localCapitalizado = _capitalize(partido.equipoLocal);
      final visitanteCapitalizado = _capitalize(partido.equipoVisitante);

      buffer.writeln(
        '- $localCapitalizado ${partido.golesLocal}-${partido.golesVisitante} $visitanteCapitalizado',
      );
    }

    return buffer.toString();
  }

  /// Formatea la fecha en formato Peru
  String _formatearFecha(DateTime fecha) {
    try {
      final formato = DateFormat("dd/MM/yyyy HH:mm", 'es_PE');
      return formato.format(fecha.toLocal());
    } catch (_) {
      // Fallback si no se puede formatear
      return '${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}';
    }
  }

  /// Obtiene el emoji de medalla segun posicion
  String _getMedalla(int posicion) {
    switch (posicion) {
      case 1:
        return '1.';
      case 2:
        return '2.';
      case 3:
        return '3.';
      default:
        return '$posicion.';
    }
  }

  /// Capitaliza la primera letra
  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  /// Ejecuta la accion de compartir
  Future<void> _compartir(BuildContext context) async {
    final texto = _generarTextoResumen();

    try {
      final result = await Share.share(
        texto,
        subject: 'Resumen Pichanga',
      );

      if (result.status == ShareResultStatus.success) {
        onCompartido?.call();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Resumen compartido exitosamente'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al compartir: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
