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

  /// Parsea un string de fecha/hora asumiendo UTC si no tiene zona horaria.
  ///
  /// Supabase retorna timestamptz sin indicador de zona en json_build_object,
  /// por ejemplo: "2026-02-28T02:00:00" en vez de "2026-02-28T02:00:00Z".
  /// DateTime.parse() interpreta esto como hora local del dispositivo,
  /// causando que .toLocal() sea un no-op y la hora quede como UTC
  /// pensando que es local (5 horas atrasada para Peru UTC-5).
  ///
  /// Esta funcion detecta si el string NO tiene indicador de zona (Z o +)
  /// y lo fuerza como UTC antes de convertir a local.
  ///
  /// Retorna [DateTime.now()] si [value] es null.
  static DateTime parseUtcToLocal(dynamic value) {
    if (value == null) return DateTime.now();
    final str = value.toString();
    final dt = DateTime.parse(str);
    // Si no tiene zona (isUtc=false y no termina en Z ni contiene +), forzar UTC
    if (!dt.isUtc && !str.endsWith('Z') && !str.contains('+')) {
      return DateTime.utc(
        dt.year,
        dt.month,
        dt.day,
        dt.hour,
        dt.minute,
        dt.second,
        dt.millisecond,
        dt.microsecond,
      ).toLocal();
    }
    return dt.toLocal();
  }

  /// Variante nullable de [parseUtcToLocal].
  /// Retorna null si [value] es null.
  static DateTime? tryParseUtcToLocal(dynamic value) {
    if (value == null) return null;
    return parseUtcToLocal(value);
  }

  /// Parsea string ISO8601 de BD y convierte a local
  /// NOTA: Usar [parseUtcToLocal] en su lugar para manejar correctamente
  /// strings sin indicador de zona horaria.
  static DateTime parseFromDb(String isoString) {
    return parseUtcToLocal(isoString);
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
