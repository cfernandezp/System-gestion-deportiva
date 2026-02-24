# E006-HU-004 - Resultados por Fecha

## Informacion General
- **Epica**: E006 - Estadisticas y Rankings
- **Estado**: ✅ Completada (COM)
- **Prioridad**: Media
- **Story Points**: 5 pts

## Historia de Usuario
**Como** usuario del sistema
**Quiero** ver los resultados de una fecha especifica
**Para** revisar como quedaron los partidos de una jornada pasada

## Descripcion
Muestra el historial de fechas finalizadas con sus resultados detallados: partidos, marcadores, tabla de posiciones, goleadores y asistentes de cada jornada.

**Restriccion de plan**: Historial basico disponible para todos. Detalle completo (tabla posiciones, goleadores, asistentes por equipo) disponible desde Plan 5+.

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

### CA-004: Tabla de posiciones de la fecha (Plan 5+)
- **Dado** que veo el detalle de una fecha
- **Cuando** observo el resumen
- **Entonces** veo tabla de posiciones:
  - Posicion (1ro, 2do, 3ro)
  - Equipo (color)
  - Partidos jugados, ganados, empatados, perdidos
  - Goles a favor, en contra, diferencia
  - Puntos de equipo

### CA-005: Goleadores de la fecha (Plan 5+)
- **Dado** que veo el detalle de una fecha
- **Cuando** observo las estadisticas
- **Entonces** veo lista de goleadores de esa fecha ordenados por goles
- **Y** destaco al goleador de la fecha (maximo anotador)

### CA-006: Lista de asistentes
- **Dado** que veo el detalle de una fecha
- **Cuando** quiero saber quienes jugaron
- **Entonces** veo lista de asistentes agrupados por equipo
- **Y** cada jugador muestra: apodo, goles anotados

### CA-007: Filtrar lista de fechas (Plan 5+)
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
**Caso especial**: Fechas canceladas no aparecen en el historial.

### RN-002: Orden de Lista de Fechas
**Contexto**: Para facilitar busqueda.
**Restriccion**: Ordenar por fecha_hora_inicio DESC (mas reciente primero).
**Validacion**: ORDER BY fecha_hora_inicio DESC.
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
**Caso especial**: Si equipo no jugo ningun partido, no aparece en tabla.

### RN-004: Criterios para Posicion en Tabla
**Contexto**: Ordenar equipos en la tabla.
**Restriccion**: Orden de criterios:
  1. Mas puntos de equipo (PTS)
  2. Mejor diferencia de goles (DIF)
  3. Mas goles a favor (GF)
  4. Resultado directo entre empatados
**Validacion**: ORDER BY PTS DESC, DIF DESC, GF DESC.
**Caso especial**: Si aun empatan, comparten posicion.

### RN-005: Goleadores de la Fecha
**Contexto**: Listar anotadores.
**Restriccion**: Mostrar jugadores que anotaron al menos 1 gol en la fecha.
**Validacion**: WHERE anulado=false AND es_autogol=false AND jugador_id IS NOT NULL.
**Caso especial**: Si nadie anoto, mostrar "No hubo goles en esta fecha".

### RN-006: Goleador de la Fecha (Destacado)
**Contexto**: Reconocer al maximo anotador.
**Restriccion**: El jugador (o jugadores) con mas goles en la fecha.
**Validacion**: MAX(COUNT goles) GROUP BY jugador_id.
**Caso especial**: Si hay empate, todos son co-goleadores de la fecha.

### RN-007: Asistentes por Equipo
**Contexto**: Listar quien jugo.
**Restriccion**: Jugadores con inscripcion estado='inscrito' Y asignacion de equipo.
**Validacion**: JOIN inscripciones con asignaciones_equipos.
**Caso especial**: Jugadores sin equipo asignado se listan como "Sin equipo".

### RN-008: Restriccion por Plan
**Contexto**: Feature flag de stats avanzadas.
**Restriccion**:
  - Plan Gratis: Lista de fechas + resultados de partidos (marcador) basico
  - Plan 5+: Todo lo anterior + tabla de posiciones, goleadores de fecha, filtros avanzados
**Validacion**: Verificar plan del usuario via limites_plan.stats_avanzadas.
**Caso especial**: Invitados pueden ver resultados basicos pero no aparecen en listas de goleadores.

---

## Notas Tecnicas
- Refinado por @negocio-deportivo-expert
- Esta vista es para fechas PASADAS (finalizadas). Para fechas en curso, ver E007/E004
- Depende de E007 (fechas, inscripciones) y E004 (partidos, goles)

---

## FASE 2: Diseno Backend
**Responsable**: supabase-expert
**Status**: Completado
**Fecha**: 2026-02-23

### Funciones RPC Implementadas

**`obtener_historial_fechas(p_grupo_id UUID, p_anio INTEGER DEFAULT NULL, p_mes INTEGER DEFAULT NULL, p_solo_mias BOOLEAN DEFAULT false) -> JSONB`**
- **Descripcion**: Lista fechas finalizadas del grupo con info basica y filtros opcionales
- **Reglas de Negocio**: RN-001, RN-002, RN-008 (CA-001, CA-007, CA-008)
- **Parametros**:
  - `p_grupo_id`: UUID - Grupo activo del usuario
  - `p_anio`: INTEGER (opcional) - Filtrar por anio (solo Plan 5+)
  - `p_mes`: INTEGER (opcional) - Filtrar por mes (solo Plan 5+)
  - `p_solo_mias`: BOOLEAN (opcional, default false) - Solo fechas donde participe (solo Plan 5+)
- **Response Success**:
  ```json
  {
    "success": true,
    "data": {
      "stats_avanzadas": true,
      "fechas": [
        {
          "fecha_id": "uuid",
          "fecha_formato": "DD/MM/YYYY",
          "fecha_hora": "HH:MM",
          "lugar": "string",
          "total_asistentes": 12,
          "total_partidos": 3
        }
      ],
      "filtros_disponibles": {
        "anios": [2026, 2025],
        "meses": [1, 2, 3]
      }
    },
    "message": "3 fechas encontradas"
  }
  ```
- **Response Error - Hints**:
  - `no_autenticado` -> Usuario no tiene sesion activa
  - `usuario_no_encontrado` -> Usuario no existe o no aprobado
  - `no_miembro_grupo` -> No es miembro activo del grupo

**`obtener_detalle_fecha_resultados(p_fecha_id UUID, p_grupo_id UUID) -> JSONB`**
- **Descripcion**: Detalle completo de una fecha con partidos, tabla posiciones, goleadores y asistentes
- **Reglas de Negocio**: RN-001 a RN-008 (CA-002 a CA-006)
- **Parametros**:
  - `p_fecha_id`: UUID - ID de la fecha a consultar
  - `p_grupo_id`: UUID - Grupo activo del usuario
- **Response Success**:
  ```json
  {
    "success": true,
    "data": {
      "stats_avanzadas": true,
      "fecha": { "fecha_id": "uuid", "fecha_formato": "DD/MM/YYYY", "fecha_hora": "HH:MM", "lugar": "string", "total_asistentes": 12 },
      "partidos": [{ "partido_id": "uuid", "equipo_local": "rojo", "equipo_visitante": "azul", "goles_local": 2, "goles_visitante": 1, "estado": "finalizado" }],
      "tabla_posiciones": [{ "posicion": 1, "equipo": "rojo", "pj": 2, "pg": 2, "pe": 0, "pp": 0, "gf": 5, "gc": 1, "dif": 4, "pts": 6 }],
      "goleadores": [{ "jugador_id": "uuid", "nombre": "string", "apodo": "string", "goles": 3, "es_maximo_goleador": true }],
      "asistentes_por_equipo": [{ "equipo": "rojo", "jugadores": [{ "jugador_id": "uuid", "nombre": "string", "apodo": "string", "goles": 2 }] }]
    },
    "message": "Resultados de la fecha"
  }
  ```
- **Response Error - Hints**:
  - `no_autenticado` -> Usuario no tiene sesion activa
  - `usuario_no_encontrado` -> Usuario no existe o no aprobado
  - `no_miembro_grupo` -> No es miembro activo del grupo
  - `fecha_no_encontrada` -> Fecha no existe, no finalizada, o no pertenece al grupo
- **Nota Plan Gratis**: `tabla_posiciones` y `goleadores` retornan `null` (no array vacio)

### Script SQL
- `supabase/sql-cloud/2026-02-23_E006-HU-004_resultados_por_fecha.sql`

### Criterios de Aceptacion Backend
- [x] **CA-001**: Lista de fechas finalizadas, ordenadas DESC - implementado en `obtener_historial_fechas`
- [x] **CA-002**: Seleccionar fecha para detalle - implementado en `obtener_detalle_fecha_resultados`
- [x] **CA-003**: Partidos con equipos, marcador, estado - implementado en seccion 7 del detalle
- [x] **CA-004**: Tabla de posiciones PJ/PG/PE/PP/GF/GC/DIF/PTS (Plan 5+) - implementado en seccion 8
- [x] **CA-005**: Goleadores con maximo goleador destacado (Plan 5+) - implementado en seccion 9
- [x] **CA-006**: Asistentes agrupados por equipo con goles - implementado en seccion 10
- [x] **CA-007**: Filtros anio/mes/solo_mias (Plan 5+, ignorados en Plan Gratis) - implementado en historial
- [x] **CA-008**: Sin fechas = array vacio + mensaje "No hay fechas finalizadas aun" - implementado

### Reglas de Negocio Backend
- [x] **RN-001**: Solo fechas estado='finalizada' (WHERE en ambas RPCs)
- [x] **RN-002**: ORDER BY fecha_hora_inicio DESC
- [x] **RN-003**: Tabla posiciones calculada desde partidos finalizados
- [x] **RN-004**: Orden: PTS DESC, DIF DESC, GF DESC
- [x] **RN-005**: Goles validos: anulado=false, es_autogol=false, jugador_id NOT NULL
- [x] **RN-006**: Maximo goleador con es_maximo_goleador=true, soporta co-goleadores
- [x] **RN-007**: Asistentes = inscripcion 'inscrito' + LEFT JOIN asignaciones, sin equipo = 'sin_equipo'
- [x] **RN-008**: Plan Gratis: partidos + asistentes. Plan 5+: + tabla + goleadores + filtros

---
**Creado**: 2025-01-15
**Refinado**: 2026-02-02
