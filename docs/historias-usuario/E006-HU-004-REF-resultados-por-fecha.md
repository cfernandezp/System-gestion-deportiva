# E006-HU-004 - Resultados por Fecha

## Informacion General
- **Epica**: E006 - Estadisticas y Rankings
- **Estado**: 🟢 Refinada (REF)
- **Prioridad**: Media
- **Story Points**: 5 pts

## Historia de Usuario
**Como** usuario del sistema
**Quiero** ver los resultados de una fecha especifica
**Para** revisar como quedaron los partidos de una jornada pasada

## Descripcion
Muestra el historial de fechas finalizadas con sus resultados detallados: partidos, marcadores, tabla de posiciones, goleadores y asistentes de cada jornada.

---

## Criterios de Aceptacion (CA)

### CA-001: Lista de fechas jugadas
- **Dado** que accedo a "Historial de Fechas"
- **Cuando** veo la lista
- **Entonces** veo todas las fechas con estado 'finalizada' ordenadas por fecha (mas reciente primero)
- **Y** cada entrada muestra: fecha, lugar, cantidad de asistentes

### CA-002: Seleccionar fecha para ver detalle
- **Dado** que veo la lista de fechas
- **Cuando** selecciono una
- **Entonces** veo el detalle completo de esa jornada

### CA-003: Resultados de partidos
- **Dado** que veo el detalle de una fecha
- **Cuando** observo los partidos
- **Entonces** veo cada partido con:
  - Equipos (colores)
  - Marcador final
  - Estado (finalizado)

### CA-004: Tabla de posiciones de la fecha
- **Dado** que veo el detalle de una fecha
- **Cuando** observo el resumen
- **Entonces** veo tabla de posiciones:
  - Posicion (1ro, 2do, 3ro)
  - Equipo (color)
  - Partidos jugados, ganados, empatados, perdidos
  - Goles a favor, en contra, diferencia
  - Puntos de equipo

### CA-005: Goleadores de la fecha
- **Dado** que veo el detalle de una fecha
- **Cuando** observo las estadisticas
- **Entonces** veo lista de goleadores de esa fecha ordenados por goles
- **Y** destaco al goleador de la fecha (maximo anotador)

### CA-006: Lista de asistentes
- **Dado** que veo el detalle de una fecha
- **Cuando** quiero saber quienes jugaron
- **Entonces** veo lista de asistentes agrupados por equipo
- **Y** cada jugador muestra: apodo, goles anotados

### CA-007: Filtrar lista de fechas
- **Dado** que veo el historial
- **Cuando** hay muchas fechas
- **Entonces** puedo filtrar por:
  - Ano
  - Mes
  - Mis fechas (donde participe)

### CA-008: Sin fechas finalizadas
- **Dado** que no hay fechas finalizadas
- **Cuando** accedo al historial
- **Entonces** veo mensaje "No hay fechas finalizadas aun"

---

## Reglas de Negocio (RN)

### RN-001: Solo Fechas Finalizadas
**Contexto**: Para mostrar resultados completos.
**Restriccion**: Solo mostrar fechas con estado = 'finalizada'.
**Validacion**: WHERE estado = 'finalizada'.
**Regla calculo**: N/A.
**Caso especial**: Fechas canceladas no aparecen en el historial.

### RN-002: Orden de Lista de Fechas
**Contexto**: Para facilitar busqueda.
**Restriccion**: Ordenar por fecha_hora_inicio DESC (mas reciente primero).
**Validacion**: ORDER BY fecha_hora_inicio DESC.
**Regla calculo**: N/A.
**Caso especial**: Paginacion si hay muchas fechas (>20).

### RN-003: Calculo de Tabla de Posiciones
**Contexto**: Determinar posicion de cada equipo en la fecha.
**Restriccion**: Calcular por cada equipo:
  1. PJ = partidos donde participo
  2. PG = partidos ganados (mas goles que rival)
  3. PE = partidos empatados
  4. PP = partidos perdidos
  5. GF = goles a favor (suma de goles cuando anoto)
  6. GC = goles en contra (suma de goles que le anotaron)
  7. DIF = GF - GC
  8. PTS_EQUIPO = PG*3 + PE*1 (puntos de equipo en la fecha)
**Validacion**: Calcular desde tabla partidos y goles.
**Regla calculo**: Ver arriba.
**Caso especial**: Si equipo no jugo ningun partido, no aparece en tabla.

### RN-004: Criterios para Posicion en Tabla
**Contexto**: Ordenar equipos en la tabla.
**Restriccion**: Orden de criterios:
  1. Mas puntos de equipo (PTS)
  2. Mejor diferencia de goles (DIF)
  3. Mas goles a favor (GF)
  4. Resultado directo entre empatados
**Validacion**: ORDER BY PTS DESC, DIF DESC, GF DESC.
**Regla calculo**: N/A.
**Caso especial**: Si aun empatan, comparten posicion.

### RN-005: Goleadores de la Fecha
**Contexto**: Listar anotadores.
**Restriccion**: Mostrar jugadores que anotaron al menos 1 gol en la fecha.
**Validacion**: WHERE anulado=false AND es_autogol=false AND jugador_id IS NOT NULL.
**Regla calculo**: ORDER BY COUNT goles DESC.
**Caso especial**: Si nadie anoto, mostrar "No hubo goles en esta fecha".

### RN-006: Goleador de la Fecha (Destacado)
**Contexto**: Reconocer al maximo anotador.
**Restriccion**: El jugador (o jugadores) con mas goles en la fecha.
**Validacion**: MAX(COUNT goles) GROUP BY jugador_id.
**Regla calculo**: N/A.
**Caso especial**: Si hay empate, todos son co-goleadores de la fecha.

### RN-007: Asistentes por Equipo
**Contexto**: Listar quien jugo.
**Restriccion**: Jugadores con inscripcion estado='inscrito' Y asignacion de equipo.
**Validacion**: JOIN inscripciones con asignaciones_equipos.
**Regla calculo**: N/A.
**Caso especial**: Jugadores sin equipo asignado se listan como "Sin equipo".

### RN-008: Acceso al Historial
**Contexto**: Quien puede ver.
**Restriccion**: Todos los usuarios autenticados pueden ver el historial completo.
**Validacion**: Usuario autenticado.
**Regla calculo**: N/A.
**Caso especial**: N/A.

---

## Notas Tecnicas
- Refinado por @negocio-deportivo-expert
- Esta vista es para fechas PASADAS (finalizadas). Para fechas en curso, ver E003/E004.

---
**Creado**: 2025-01-15
**Refinado**: 2026-02-02
