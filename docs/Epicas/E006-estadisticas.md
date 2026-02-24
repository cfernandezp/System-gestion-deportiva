# EPICA E006: Estadisticas y Rankings

## INFORMACION
- **Codigo:** E006
- **Nombre:** Estadisticas y Rankings
- **Descripcion:** Muestra estadisticas de jugadores, equipos y rankings historicos. Los datos base ya existen (goles en E004, partidos, inscripciones). HU-001 (Ranking Goleadores) ya esta implementada. El resto de la UI esta pendiente.
- **Story Points:** 31 pts
- **Estado:** 🟡 En Progreso (1/6 COM, 5/6 REF pendientes de implementar)
- **Plataforma:** App Movil (Android/iOS) - Flutter + Supabase
- **Feature del plan:** Stats avanzadas disponibles desde Plan 5+

## CONTEXTO DE NEGOCIO

### Sistema de Puntuacion por Equipo (en la fecha)
- Victoria: 3 pts
- Empate: 1 pt
- Derrota: 0 pts

### Puntos por Jugador (segun puesto de su equipo)

| Formato | 1er Puesto | 2do Puesto | 3er Puesto |
|---------|------------|------------|------------|
| 2 equipos | 3 pts | 1 pt | - |
| 3 equipos | 3 pts | 2 pts | 1 pt |

### Metricas Clave
- Goles por jugador (fecha, mes, ano, historico)
- Puntos acumulados por jugador
- Asistencias a fechas
- Equipo ganador por fecha

### Restriccion por Plan
- **Plan Gratis**: Rankings basicos (historico, sin filtros), metricas basicas
- **Plan 5+**: Stats avanzadas (filtros por periodo, promedios, comparativas, estadisticas mensuales, badges)

## LO QUE YA EXISTE (datos base + HU-001)
- Tabla `goles` con jugador_id, equipo, minuto, es_autogol (via E004)
- Tabla `partidos` con equipos, estado, resultado (via E004)
- Tabla `inscripciones` con participacion por fecha (via E007)
- Tabla `asignaciones_equipos` con equipo por jugador por fecha (via E007)
- Widget `tabla_posiciones_widget.dart` (basico, en partidos feature)
- **HU-001 COMPLETA**: RPC `obtener_ranking_goleadores`, BLoC, Pages, Widgets (podio, lista, filtros)

## LO QUE FALTA
- RPCs para ranking puntos, mis estadisticas, resultados por fecha, stats mensuales, goleador fecha
- UI de pantallas restantes (HU-002 a HU-006)
- Restriccion por plan (stats avanzadas solo Plan 5+)

## HISTORIAS

### E006-HU-001: Ranking Goleadores ✅
- **Archivo:** docs/historias-usuario/E006-HU-001-COM-ranking-goleadores.md
- **Estado:** ✅ Completada (COM) | **Story Points:** 5 | **Prioridad:** Alta
- **Funcionalidad:** Ranking de goleadores del grupo (total goles, promedio por fecha, podio top 3, filtros por periodo)
- **Implementado:** RPC + BLoC + Pages + Widgets + QA validado

### E006-HU-002: Ranking Puntos
- **Archivo:** docs/historias-usuario/E006-HU-002-REF-ranking-puntos.md
- **Estado:** 🟢 Refinada (REF) | **Story Points:** 8 | **Prioridad:** Alta
- **Funcionalidad:** Ranking por puntos acumulados (3 pts victoria, 2 pts segundo, 1 pt tercero)

### E006-HU-003: Mis Estadisticas
- **Archivo:** docs/historias-usuario/E006-HU-003-REF-mis-estadisticas.md
- **Estado:** 🟢 Refinada (REF) | **Story Points:** 5 | **Prioridad:** Media
- **Funcionalidad:** Dashboard personal: goles, puntos, fechas, racha, mejor fecha, posicion en rankings

### E006-HU-004: Resultados por Fecha
- **Archivo:** docs/historias-usuario/E006-HU-004-REF-resultados-por-fecha.md
- **Estado:** 🟢 Refinada (REF) | **Story Points:** 5 | **Prioridad:** Media
- **Funcionalidad:** Historial de fechas finalizadas: partidos, marcadores, tabla posiciones, goleadores

### E006-HU-005: Estadisticas Mensuales
- **Archivo:** docs/historias-usuario/E006-HU-005-REF-estadisticas-mensuales.md
- **Estado:** 🟢 Refinada (REF) | **Story Points:** 5 | **Prioridad:** Media
- **Funcionalidad:** Stats agregadas por mes: goleador del mes, comparativas, jugador mas constante

### E006-HU-006: Goleador de la Fecha
- **Archivo:** docs/historias-usuario/E006-HU-006-REF-goleador-fecha.md
- **Estado:** 🟢 Refinada (REF) | **Story Points:** 3 | **Prioridad:** Media
- **Funcionalidad:** Destacar al goleador de cada fecha, historial, badge, notificacion automatica

## CRITERIOS EPICA
- [x] Los usuarios pueden ver ranking de goleadores del grupo (HU-001 COM)
- [ ] Los usuarios pueden ver ranking por puntos acumulados
- [ ] Cada jugador puede ver sus estadisticas personales
- [ ] Se pueden ver resultados detallados de cualquier fecha pasada
- [ ] Existen estadisticas agregadas mensuales
- [ ] Se destaca al goleador de cada fecha
- [ ] Stats avanzadas solo disponibles para Plan 5+ (feature flag)
- [ ] Invitados NO aparecen en rankings publicos

## DEPENDENCIAS
- E001: Autenticacion
- E002: Grupos Deportivos
- E004: Partidos en Vivo (goles, resultados)
- E007: Gestion de Pichangas/Fechas (inscripciones, asignaciones)

## PROGRESO
**Total HU:** 6 | **Completadas:** 1 | **Refinadas:** 5 | **Pendientes implementar:** 5 | **Datos base:** Si (tablas goles, partidos, inscripciones)
