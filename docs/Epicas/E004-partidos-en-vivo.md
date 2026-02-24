# EPICA E004: Partidos en Vivo

## INFORMACION
- **Codigo:** E004
- **Nombre:** Partidos en Vivo
- **Descripcion:** Gestiona el desarrollo de los partidos en tiempo real dentro de una jornada (fecha): temporizador con alarma, registro de goles por jugador, score en vivo con realtime, rotacion de equipos para formato 3 equipos, y resumen de jornada.
- **Story Points:** 38 pts
- **Estado:** ✅ Completada (7 COM + 1 REF)
- **Plataforma:** App Movil (Android/iOS) - Flutter + Supabase
- **Origen:** Implementada 2026-01, docs en archive/v1

## RELACION CON FECHAS (E007)
- Una **Fecha** (E007) puede tener multiples **Partidos** (E004)
- Los partidos solo existen cuando la fecha esta en estado `en_juego`
- Jerarquia: Fecha → Partidos → Goles

## FORMATOS DE PARTIDO

| Formato | Equipos | Partidos | Duracion/Partido |
|---------|---------|----------|------------------|
| 1 Hora | 2 | 3 partidos | 20 min |
| 2 Horas | 3 | Rotacion | 10 min |

## SISTEMA DE ROTACION (3 equipos)
1. Dos equipos inician (seleccion manual)
2. Ganador continua, perdedor descansa
3. Despues de 2 partidos seguidos, equipo descansa obligatoriamente
4. Empate: admin decide quien continua

## HISTORIAS

### E004-HU-001: Iniciar Partido
- **Archivo:** docs/archive/v1/historias-usuario/E004-HU-001-COM-iniciar-partido.md
- **Estado:** ✅ Completada | **Story Points:** 5 | **Prioridad:** Alta
- **Funcionalidad:** Seleccionar 2 equipos, iniciar temporizador. Duracion auto (10 o 20 min). Pausar/reanudar.

### E004-HU-002: Temporizador con Alarma
- **Archivo:** docs/archive/v1/historias-usuario/E004-HU-002-COM-temporizador-alarma.md
- **Estado:** ✅ Completada | **Story Points:** 8 | **Prioridad:** Alta
- **Funcionalidad:** Cuenta regresiva MM:SS, alarma inicio/fin, pantalla completa inmersiva (120px), tiempo extra negativo, alerta 2 min.

### E004-HU-003: Registrar Gol
- **Archivo:** docs/archive/v1/historias-usuario/E004-HU-003-COM-registrar-gol.md
- **Estado:** ✅ Completada | **Story Points:** 5 | **Prioridad:** Alta
- **Funcionalidad:** Boton gol por equipo, seleccionar goleador, autogol, gol sin asignar, deshacer (30seg), minuto automatico.

### E004-HU-004: Ver Score en Vivo
- **Archivo:** docs/archive/v1/historias-usuario/E004-HU-004-COM-ver-score-vivo.md
- **Estado:** ✅ Completada | **Story Points:** 5 | **Prioridad:** Alta
- **Funcionalidad:** Marcador realtime con colores de equipo, indicador ganador, lista de goles, animacion gol reciente.

### E004-HU-005: Finalizar Partido
- **Archivo:** docs/archive/v1/historias-usuario/E004-HU-005-COM-finalizar-partido.md
- **Estado:** ✅ Completada | **Story Points:** 3 | **Prioridad:** Alta
- **Funcionalidad:** Admin termina partido, registra resultado final.

### E004-HU-006: Rotacion de Equipos
- **Archivo:** docs/archive/v1/historias-usuario/E004-HU-006-REF-rotacion-equipos.md
- **Estado:** 🟢 Refinada | **Story Points:** 5 | **Prioridad:** Alta
- **Funcionalidad:** Sugerencia automatica de rotacion, regla ganador continua, max 2 consecutivos, override manual.

### E004-HU-007: Resumen de Jornada
- **Archivo:** docs/archive/v1/historias-usuario/E004-HU-007-COM-resumen-jornada.md
- **Estado:** ✅ Completada | **Story Points:** 5 | **Prioridad:** Media
- **Funcionalidad:** Resumen de todos los partidos de la jornada con stats.

### E004-HU-008: Mi Actividad en Vivo
- **Archivo:** docs/archive/v1/historias-usuario/E004-HU-008-COM-mi-actividad-en-vivo.md
- **Estado:** ✅ Completada | **Story Points:** 2 | **Prioridad:** Media
- **Funcionalidad:** Jugador ve su participacion en la jornada actual.

## CRITERIOS EPICA
- [x] El admin puede iniciar un partido seleccionando 2 equipos
- [x] El temporizador muestra cuenta regresiva y suena alarma al terminar
- [x] El modo pantalla completa muestra temporizador inmersivo
- [x] El admin puede registrar goles por equipo y jugador
- [x] Todos los usuarios ven el score actualizado en tiempo real
- [x] El admin puede finalizar un partido y registrar resultado
- [ ] El sistema sugiere rotacion automatica para formato 3 equipos
- [x] Los usuarios pueden ver resumen de la jornada completa
- [x] Cada jugador puede ver su actividad en la jornada

## IMPLEMENTACION

### Backend (Supabase)
| RPC | HU |
|-----|-----|
| iniciar_partido | HU-001 |
| pausar_partido | HU-001 |
| reanudar_partido | HU-001 |
| obtener_partido_activo | HU-001 |
| registrar_gol | HU-003 |
| eliminar_gol | HU-003 |
| obtener_goles_partido | HU-003 |
| obtener_score_partido | HU-004 |
| finalizar_partido | HU-005 |

### Frontend (Flutter)
- Feature: `lib/features/partidos/`
- BLoCs: Partido, Score, Goles, ListaPartidos, ResumenJornada
- Pages: partido_en_vivo_page, resumen_partido_page
- Widgets: temporizador_widget, temporizador_fullscreen, marcador_widget, botones_gol_widget, registrar_gol_dialog, lista_goles_widget, score_marcador_widget
- Services: alarm_service, web_audio_service, mobile_audio_service
- Realtime: tabla goles para actualizacion instantanea

### Tablas principales
- `partidos` (fecha_id, equipo_local, equipo_visitante, duracion_minutos, estado, hora_inicio, tiempo_pausado_segundos)
- `goles` (partido_id, equipo_anotador, jugador_id, minuto, es_autogol)

## DEPENDENCIAS
- E001: Autenticacion
- E002: Grupos Deportivos
- E007: Gestion de Pichangas/Fechas (fecha debe estar en estado `en_juego`)

## PROGRESO
**Total HU:** 8 | **Completadas:** 7 (87.5%) | **Refinadas:** 1 (12.5%) | **Pendientes:** 0
