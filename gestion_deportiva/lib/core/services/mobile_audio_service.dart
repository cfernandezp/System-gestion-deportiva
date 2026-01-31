import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Servicio de audio para plataformas Mobile (iOS/Android)
/// E004-HU-002: Temporizador con Alarma
/// Usa audioplayers para reproducir sonidos generados
class PlatformAudioService {
  final AudioPlayer _player = AudioPlayer();
  bool _initialized = false;

  /// Inicializa el reproductor de audio
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      await _player.setReleaseMode(ReleaseMode.stop);
      _initialized = true;
    } catch (e) {
      debugPrint('MobileAudioService: Error initializing: $e');
      _initialized = false;
    }
  }

  /// RN-007: Pitido corto de inicio (1-2 segundos)
  Future<void> playStartWhistle() async {
    if (!_initialized) await initialize();

    try {
      // Usar un tono generado como asset o URL
      // Por ahora usa un placeholder - en produccion usar archivo real
      await _playBeepSequence(
        frequency: 2500,
        durationMs: 300,
        repetitions: 2,
        pauseMs: 150,
      );
    } catch (e) {
      debugPrint('MobileAudioService: Error playing start whistle: $e');
    }
  }

  /// RN-010: Alarma fuerte de fin (3-5 segundos)
  Future<void> playEndAlarm() async {
    if (!_initialized) await initialize();

    try {
      await _playBeepSequence(
        frequency: 2800,
        durationMs: 400,
        repetitions: 5,
        pauseMs: 50,
      );
    } catch (e) {
      debugPrint('MobileAudioService: Error playing end alarm: $e');
    }
  }

  /// RN-005: Beep de advertencia (2 minutos restantes)
  Future<void> playWarningBeep() async {
    if (!_initialized) await initialize();

    try {
      await _playBeepSequence(
        frequency: 1500,
        durationMs: 200,
        repetitions: 3,
        pauseMs: 200,
      );
    } catch (e) {
      debugPrint('MobileAudioService: Error playing warning beep: $e');
    }
  }

  /// Genera una secuencia de beeps
  /// En mobile, audioplayers no puede generar tonos directamente,
  /// por lo que esta es una implementacion placeholder.
  /// En produccion, usar archivos de audio reales.
  Future<void> _playBeepSequence({
    required int frequency,
    required int durationMs,
    required int repetitions,
    required int pauseMs,
  }) async {
    // Para mobile, idealmente usar archivos de audio pregrabados
    // o el package flutter_beep para generar tonos
    // Por ahora, simula la duracion
    for (int i = 0; i < repetitions; i++) {
      // Aqui iria la reproduccion real del audio
      // await _player.play(AssetSource('sounds/beep_$frequency.mp3'));
      await Future.delayed(Duration(milliseconds: durationMs));
      if (i < repetitions - 1) {
        await Future.delayed(Duration(milliseconds: pauseMs));
      }
    }
  }

  /// Detiene todos los sonidos
  void stopAll() {
    try {
      _player.stop();
    } catch (e) {
      // Ignorar errores al detener
    }
  }

  /// Verifica si el audio esta disponible
  bool get isAvailable => _initialized;

  /// Libera recursos
  void dispose() {
    try {
      _player.dispose();
    } catch (e) {
      // Ignorar errores al liberar
    }
    _initialized = false;
  }
}
