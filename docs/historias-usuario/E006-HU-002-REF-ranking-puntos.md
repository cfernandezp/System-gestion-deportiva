# E006-HU-002 - Ranking de Puntos

## Informacion General
- **Epica**: E006 - Estadisticas y Rankings
- **Estado**: 🟢 Refinada (REF)
- **Prioridad**: Alta
- **Story Points**: 8 pts

## Historia de Usuario
**Como** usuario del sistema
**Quiero** ver el ranking por puntos acumulados
**Para** saber quienes son los jugadores mas exitosos del grupo

## Descripcion
Muestra el ranking de jugadores ordenados por puntos acumulados. Los puntos se otorgan segun la posicion final del equipo en cada fecha jugada. Todos los jugadores del equipo reciben los mismos puntos.

**Restriccion de plan**: Stats avanzadas (filtros por periodo, detalle de puntos) disponibles desde Plan 5+. Plan Gratis ve ranking basico (historico, sin filtros).

---

## Sistema de Puntos

### Formato 2 Equipos
| Posicion | Puntos por jugador |
|----------|-------------------|
| 1er puesto (campeon) | 3 pts |
| 2do puesto | 1 pt |

### Formato 3 Equipos
| Posicion | Puntos por jugador |
|----------|-------------------|
| 1er puesto (campeon) | 3 pts |
| 2do puesto | 2 pts |
| 3er puesto | 1 pt |

---

## Criterios de Aceptacion (CA)

### CA-001: Ranking por puntos visible
- **Dado** que accedo a "Ranking de Puntos"
- **Cuando** se carga la pantalla
- **Entonces** veo jugadores ordenados por puntos acumulados (mayor a menor)

### CA-002: Informacion por jugador en el ranking
- **Dado** que veo el ranking
- **Cuando** observo cada entrada
- **Entonces** veo: posicion, foto/avatar, apodo, puntos totales
- **Y** opcionalmente: fechas jugadas, promedio de puntos por fecha

### CA-003: Filtro por periodo (Plan 5+)
- **Dado** que veo el ranking
- **Cuando** quiero ver periodos especificos
- **Entonces** puedo filtrar por:
  - Historico (todos los tiempos)
  - Este ano
  - Este mes
- **Nota**: Plan Gratis solo ve Historico

### CA-004: Detalle de puntos del jugador (Plan 5+)
- **Dado** que selecciono un jugador del ranking
- **Cuando** veo su detalle
- **Entonces** veo desglose:
  - Fechas jugadas con su equipo
  - Posicion del equipo en cada fecha
  - Puntos obtenidos por fecha

### CA-005: Mi posicion destacada
- **Dado** que estoy logueado y aparezco en el ranking
- **Cuando** veo la lista
- **Entonces** mi fila aparece destacada visualmente

### CA-006: Manejo de empates
- **Dado** que hay empate en puntos
- **Cuando** se ordena el ranking
- **Entonces** desempata por: mayor cantidad de fechas asistidas (mas constancia)
- **Y** si aun empatan: mas goles anotados

### CA-007: Top 3 destacado (Podio)
- **Dado** que veo el ranking
- **Cuando** hay al menos 3 jugadores con puntos
- **Entonces** el top 3 se muestra en formato podio especial

---

## Reglas de Negocio (RN)

### RN-001: Calculo de Posicion de Equipo en la Fecha
**Contexto**: Para determinar puntos al finalizar una fecha.
**Restriccion**: La posicion del equipo se determina por:
  1. Diferencia de goles total del equipo en la fecha (GF - GC)
  2. Si empate: goles a favor totales
  3. Si aun empate: resultado directo entre equipos empatados
  4. Si aun empate: comparten posicion
**Validacion**: Calcular suma de goles a favor y en contra de todos los partidos del equipo.
**Caso especial**: Si solo hay 1 equipo o no hubo partidos, no se otorgan puntos.

### RN-002: Asignacion de Puntos a Jugadores
**Contexto**: Al finalizar una fecha.
**Restriccion**: Todos los jugadores asignados al equipo reciben los mismos puntos que su equipo gano.
**Validacion**: Jugador debe tener registro en asignaciones_equipos para esa fecha.
**Caso especial**: Jugadores que cancelaron inscripcion no reciben puntos aunque hayan tenido equipo asignado previamente.

### RN-003: Solo Fechas Finalizadas
**Contexto**: Para evitar rankings incompletos.
**Restriccion**: Solo se contabilizan puntos de fechas con estado = 'finalizada'.
**Validacion**: fecha.estado = 'finalizada'.
**Caso especial**: Fechas canceladas no otorgan puntos.

### RN-004: Puntos Segun Cantidad de Equipos
**Contexto**: El sistema de puntos varia segun el formato de la fecha.
**Restriccion**:
  - 2 equipos: 1ro=3pts, 2do=1pt
  - 3 equipos: 1ro=3pts, 2do=2pts, 3ro=1pt
**Validacion**: Obtener num_equipos de la fecha.
**Caso especial**: Si una fecha tiene otro numero de equipos, extrapolar (4 equipos: 3,2,1,0 pts).

### RN-005: Criterios de Desempate
**Contexto**: Cuando varios jugadores tienen los mismos puntos.
**Restriccion**: Orden de desempate:
  1. Mayor cantidad de puntos (principal)
  2. Mayor cantidad de fechas asistidas (constancia)
  3. Mayor cantidad de goles anotados (aporte individual)
  4. Fecha de registro mas antigua (veterania)
**Validacion**: ORDER BY puntos DESC, fechas DESC, goles DESC, created_at ASC.
**Caso especial**: Si aun empatan, comparten posicion.

### RN-006: Inscripcion Activa Requerida
**Contexto**: Para recibir puntos de una fecha.
**Restriccion**: El jugador debe tener inscripcion con estado = 'inscrito' (no 'cancelado') en la fecha.
**Validacion**: EXISTS inscripcion WHERE usuario_id=X AND fecha_id=Y AND estado='inscrito'.
**Caso especial**: Si cancelo antes de finalizar la fecha, no recibe puntos aunque jugo.

### RN-007: Visibilidad del Ranking
**Contexto**: Quien puede ver el ranking.
**Restriccion**: El ranking es visible para todos los usuarios autenticados.
**Validacion**: Usuario autenticado.
**Caso especial**: Invitados NO aparecen en rankings publicos (solo jugadores con rol 'jugador' o superior).

### RN-008: Restriccion por Plan
**Contexto**: Feature flag de stats avanzadas.
**Restriccion**:
  - Plan Gratis: Ranking basico (historico, sin filtros de periodo)
  - Plan 5+: Stats avanzadas (filtros por periodo, detalle de puntos por fecha)
**Validacion**: Verificar plan del usuario via limites_plan.stats_avanzadas.
**Caso especial**: Si el admin baja de plan, los jugadores del grupo tambien pierden acceso avanzado.

---

## Notas Tecnicas
- Refinado por @negocio-deportivo-expert
- Requiere calculo de posiciones de equipo al finalizar fecha (puede ser trigger o funcion)
- Depende de E007 (fechas, inscripciones, asignaciones_equipos) y E004 (partidos, goles)

---
**Creado**: 2025-01-15
**Refinado**: 2026-02-02
