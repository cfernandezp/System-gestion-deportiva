import 'dart:async';

import 'package:flutter/foundation.dart';

import 'web_audio_service.dart' if (dart.library.io) 'mobile_audio_service.dart';

/// Servicio de alarmas de audio para partidos
/// E004-HU-002: Temporizador con Alarma
///
/// Criterios de Aceptacion:
/// - CA-003: Alarma al finalizar
/// - CA-004: Alarma audible en ambiente ruidoso
/// - CA-008: Alarma al iniciar partido
///
/// Reglas de Negocio:
/// - RN-007: Alarma de inicio obligatoria (1-2 segundos)
/// - RN-010: Alarmas audibles en ambiente ruidoso
///   - Alarma inicio: 1-2 segundos
///   - Alarma fin: 3-5 segundos con repeticion
class AlarmService {
  /// Singleton instance
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal();

  /// Servicio de audio especifico de plataforma
  final PlatformAudioService _platformAudio = PlatformAudioService();

  /// Timer para repeticion de alarma de fin
  Timer? _endAlarmTimer;

  /// Flag para saber si la alarma de fin esta sonando
  bool _isEndAlarmPlaying = false;

  /// Flag para indicar si el beep de advertencia ya sono
  bool _warningBeepPlayed = false;

  /// Callback para notificar eventos de audio
  void Function(AlarmEvent)? onAlarmEvent;

  /// Inicializa el servicio de audio
  /// Debe llamarse despues de una interaccion del usuario (requisito web)
  Future<void> initialize() async {
    await _platformAudio.initialize();
  }

  /// RN-007: Pitido corto de inicio de partido (1-2 segundos)
  /// CA-008: Suena al iniciar partido
  Future<void> playStartWhistle() async {
    try {
      await _platformAudio.playStartWhistle();
      onAlarmEvent?.call(AlarmEvent.startWhistle);
    } catch (e) {
      debugPrint('AlarmService: Error playing start whistle: $e');
    }
  }

  /// RN-002, RN-010: Alarma fuerte de fin de partido (3-5 segundos con repeticion)
  /// CA-003, CA-004: Alarma audible que se repite
  Future<void> playEndAlarm() async {
    if (_isEndAlarmPlaying) return;

    try {
      _isEndAlarmPlaying = true;
      onAlarmEvent?.call(AlarmEvent.endAlarmStart);

      // Alarma de fin - Mas larga e intensa
      await _platformAudio.playEndAlarm();

      // Repetir la alarma cada 4 segundos mientras no se detenga
      _endAlarmTimer = Timer.periodic(
        const Duration(seconds: 4),
        (_) async {
          if (_isEndAlarmPlaying) {
            await _platformAudio.playEndAlarm();
          }
        },
      );
    } catch (e) {
      debugPrint('AlarmService: Error playing end alarm: $e');
    }
  }

  /// Detiene la alarma de fin (cuando el admin finaliza el partido)
  void stopEndAlarm() {
    _isEndAlarmPlaying = false;
    _endAlarmTimer?.cancel();
    _endAlarmTimer = null;
    _platformAudio.stopAll();
    onAlarmEvent?.call(AlarmEvent.endAlarmStop);
  }

  /// RN-005: Beep de advertencia cuando quedan 2 minutos
  /// Alerta visual (color amarillo) complementada con sonido
  Future<void> playWarningBeep() async {
    if (_warningBeepPlayed) return;

    try {
      _warningBeepPlayed = true;
      await _platformAudio.playWarningBeep();
      onAlarmEvent?.call(AlarmEvent.warningBeep);
    } catch (e) {
      debugPrint('AlarmService: Error playing warning beep: $e');
    }
  }

  /// Reinicia el flag del beep de advertencia (para nuevo partido)
  void resetWarningBeep() {
    _warningBeepPlayed = false;
  }

  /// Verifica si el audio esta disponible
  bool get isAudioAvailable => _platformAudio.isAvailable;

  /// Verifica si la alarma de fin esta sonando
  bool get isEndAlarmPlaying => _isEndAlarmPlaying;

  /// Verifica si el beep de advertencia ya sono
  bool get warningBeepPlayed => _warningBeepPlayed;

  /// Libera recursos
  void dispose() {
    stopEndAlarm();
    _platformAudio.dispose();
  }
}

/// Eventos de alarma para notificaciones
enum AlarmEvent {
  startWhistle,
  warningBeep,
  endAlarmStart,
  endAlarmStop,
}
