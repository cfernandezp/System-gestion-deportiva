import 'package:intl/intl.dart';

/// Utilidades para manejo de fechas
/// IMPORTANTE: El servidor esta en Brasil (UTC-3) pero la app es para Peru (UTC-5)
/// La BD almacena en UTC, Flutter convierte a hora Peru para mostrar
class AppDateUtils {
  // Formatos de fecha para Peru
  static final DateFormat formatoFechaCorta = DateFormat('dd/MM/yyyy', 'es_PE');
  static final DateFormat formatoFechaLarga =
      DateFormat('dd \'de\' MMMM \'de\' yyyy', 'es_PE');
  static final DateFormat formatoFechaHora =
      DateFormat('dd/MM/yyyy HH:mm', 'es_PE');
  static final DateFormat formatoHora = DateFormat('HH:mm', 'es_PE');
  static final DateFormat formatoDiaSemana = DateFormat('EEEE', 'es_PE');

  /// Convierte fecha UTC (de BD) a hora local Peru para mostrar
  static DateTime utcToLocal(DateTime utcDate) {
    return utcDate.toLocal();
  }

  /// Convierte fecha local a UTC para enviar a BD
  static DateTime localToUtc(DateTime localDate) {
    return localDate.toUtc();
  }

  /// Parsea string ISO8601 de BD y convierte a local
  static DateTime parseFromDb(String isoString) {
    return DateTime.parse(isoString).toLocal();
  }

  /// Formatea DateTime a ISO8601 UTC para enviar a BD
  static String formatForDb(DateTime dateTime) {
    return dateTime.toUtc().toIso8601String();
  }

  /// Obtiene fecha/hora actual en UTC para enviar a BD
  static String nowForDb() {
    return DateTime.now().toUtc().toIso8601String();
  }

  /// Formatea fecha para mostrar en UI (formato corto)
  static String formatearFechaCorta(DateTime fecha) {
    return formatoFechaCorta.format(fecha);
  }

  /// Formatea fecha para mostrar en UI (formato largo)
  static String formatearFechaLarga(DateTime fecha) {
    return formatoFechaLarga.format(fecha);
  }

  /// Formatea fecha y hora para mostrar en UI
  static String formatearFechaHora(DateTime fecha) {
    return formatoFechaHora.format(fecha);
  }

  /// Formatea solo hora para mostrar en UI
  static String formatearHora(DateTime fecha) {
    return formatoHora.format(fecha);
  }

  /// Obtiene el nombre del dia de la semana
  static String obtenerDiaSemana(DateTime fecha) {
    return formatoDiaSemana.format(fecha);
  }

  /// Verifica si dos fechas son el mismo dia
  static bool esMismoDia(DateTime fecha1, DateTime fecha2) {
    return fecha1.year == fecha2.year &&
        fecha1.month == fecha2.month &&
        fecha1.day == fecha2.day;
  }

  /// Verifica si la fecha es hoy
  static bool esHoy(DateTime fecha) {
    return esMismoDia(fecha, DateTime.now());
  }

  /// Verifica si la fecha es manana
  static bool esManana(DateTime fecha) {
    final manana = DateTime.now().add(const Duration(days: 1));
    return esMismoDia(fecha, manana);
  }
}
