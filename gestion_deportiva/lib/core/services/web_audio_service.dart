import 'dart:async';

import 'package:web/web.dart' as web;

/// Servicio de audio para plataforma Web usando Web Audio API
/// E004-HU-002: Temporizador con Alarma
class PlatformAudioService {
  web.AudioContext? _audioContext;
  bool _initialized = false;

  /// Inicializa el contexto de audio
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _audioContext = web.AudioContext();
      _initialized = true;
    } catch (e) {
      _initialized = false;
    }
  }

  /// RN-007: Pitido corto de inicio (1-2 segundos)
  Future<void> playStartWhistle() async {
    if (!_initialized) await initialize();
    final ctx = _audioContext;
    if (ctx == null) return;

    // Dos pitidos cortos tipo silbato
    for (int i = 0; i < 2; i++) {
      await _playTone(
        ctx: ctx,
        frequency: 2500,
        duration: 0.3,
        type: 'sine',
        volume: 0.8,
      );
      if (i < 1) {
        await Future.delayed(const Duration(milliseconds: 150));
      }
    }
  }

  /// RN-010: Alarma fuerte de fin (3-5 segundos)
  Future<void> playEndAlarm() async {
    if (!_initialized) await initialize();
    final ctx = _audioContext;
    if (ctx == null) return;

    // Patron de alarma: frecuencia alta-baja alternada
    final frequencies = [2800.0, 2200.0, 2800.0, 2200.0, 2800.0];

    for (int i = 0; i < frequencies.length; i++) {
      await _playTone(
        ctx: ctx,
        frequency: frequencies[i],
        duration: 0.4,
        type: 'square',
        volume: 1.0,
      );
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  /// RN-005: Beep de advertencia (2 minutos restantes)
  Future<void> playWarningBeep() async {
    if (!_initialized) await initialize();
    final ctx = _audioContext;
    if (ctx == null) return;

    // Tres beeps de advertencia
    for (int i = 0; i < 3; i++) {
      await _playTone(
        ctx: ctx,
        frequency: 1500,
        duration: 0.2,
        type: 'sine',
        volume: 0.7,
      );
      if (i < 2) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }
  }

  /// Genera un tono usando Web Audio API
  Future<void> _playTone({
    required web.AudioContext ctx,
    required double frequency,
    required double duration,
    required String type,
    required double volume,
  }) async {
    try {
      final oscillator = ctx.createOscillator();
      final gainNode = ctx.createGain();

      // Conectar nodos: oscillator -> gain -> destination
      oscillator.connect(gainNode);
      gainNode.connect(ctx.destination);

      // Configurar oscilador
      oscillator.type = type;
      oscillator.frequency.value = frequency;

      // Configurar volumen con fade out
      final startTime = ctx.currentTime;
      gainNode.gain.setValueAtTime(volume, startTime);
      gainNode.gain.exponentialRampToValueAtTime(0.01, startTime + duration);

      // Iniciar y programar fin
      oscillator.start(startTime);
      oscillator.stop(startTime + duration);

      // Esperar a que termine el tono
      await Future.delayed(Duration(milliseconds: (duration * 1000).toInt()));
    } catch (e) {
      // Silenciosamente ignora errores de audio
    }
  }

  /// Detiene todos los sonidos
  void stopAll() {
    // Web Audio API no tiene un metodo simple para detener todo
    // Los osciladores se auto-detienen despues de su duracion
  }

  /// Verifica si el audio esta disponible
  bool get isAvailable => _initialized && _audioContext != null;

  /// Libera recursos
  void dispose() {
    try {
      _audioContext?.close();
    } catch (e) {
      // Ignorar errores al cerrar
    }
    _audioContext = null;
    _initialized = false;
  }
}
