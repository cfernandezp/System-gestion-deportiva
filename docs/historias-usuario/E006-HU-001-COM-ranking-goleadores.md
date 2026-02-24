# E006-HU-001 - Ranking de Goleadores

## Informacion General
- **Epica**: E006 - Estadisticas y Rankings
- **Estado**: ✅ Completada (COM)
- **Prioridad**: Alta
- **Story Points**: 5 pts

## Historia de Usuario
**Como** usuario del sistema
**Quiero** ver el ranking de goleadores
**Para** saber quienes son los maximos anotadores del grupo

## Descripcion
Muestra el ranking de jugadores ordenados por cantidad de goles anotados. Solo se cuentan goles validos (no anulados) y no autogoles. El ranking puede filtrarse por diferentes periodos de tiempo.

**Restriccion de plan**: Stats avanzadas (filtros por periodo, promedios) disponibles desde Plan 5+. Plan Gratis ve ranking basico (historico, sin filtros).

---

## Criterios de Aceptacion (CA)

### CA-001: Ranking general visible
- **Dado** que accedo a la seccion "Goleadores"
- **Cuando** se carga la pantalla
- **Entonces** veo lista de jugadores ordenados por cantidad de goles (mayor a menor)
- **Y** el orden se actualiza en tiempo real si hay cambios

### CA-002: Informacion por jugador en el ranking
- **Dado** que veo el ranking
- **Cuando** observo cada entrada
- **Entonces** veo: posicion (#1, #2...), foto/avatar, apodo, cantidad de goles
- **Y** opcionalmente: partidos jugados, promedio de goles

### CA-003: Filtro por periodo (Plan 5+)
- **Dado** que veo el ranking
- **Cuando** quiero ver periodos especificos
- **Entonces** puedo filtrar por:
  - Historico (todos los tiempos)
  - Este ano
  - Este mes
  - Ultima fecha jugada
- **Nota**: Plan Gratis solo ve Historico

### CA-004: Manejo de empates
- **Dado** que varios jugadores tienen la misma cantidad de goles
- **Cuando** veo el ranking
- **Entonces** desempatan por: menor cantidad de partidos jugados (mejor promedio)
- **Y** si aun hay empate: fecha de registro mas antigua primero

### CA-005: Mi posicion destacada
- **Dado** que estoy logueado y aparezco en el ranking
- **Cuando** veo la lista
- **Entonces** mi fila aparece destacada visualmente (borde, color de fondo)
- **Y** si no estoy en los primeros N visibles, hay acceso rapido a "Ver mi posicion"

### CA-006: Top 3 destacado (Podio)
- **Dado** que veo el ranking
- **Cuando** hay al menos 3 jugadores con goles
- **Entonces** el top 3 se muestra en formato podio especial:
  - 1ro: Medalla oro, posicion central/superior
  - 2do: Medalla plata, izquierda
  - 3ro: Medalla bronce, derecha

### CA-007: Ranking vacio
- **Dado** que no hay goles registrados en el periodo seleccionado
- **Cuando** veo el ranking
- **Entonces** se muestra mensaje "No hay goles registrados en este periodo"
- **Y** se sugiere seleccionar otro periodo

---

## Reglas de Negocio (RN)

### RN-001: Goles Validos para Ranking
**Contexto**: Al contabilizar goles para el ranking.
**Restriccion**: Solo se cuentan goles que cumplan:
  1. `anulado = false` (no anulados)
  2. `es_autogol = false` (no autogoles)
  3. `jugador_id IS NOT NULL` (goles asignados a un jugador)
**Validacion**: COUNT goles WHERE anulado=false AND es_autogol=false AND jugador_id IS NOT NULL.
**Caso especial**: Goles sin jugador asignado no cuentan para ningun ranking individual.

### RN-002: Solo Fechas Finalizadas
**Contexto**: Para evitar rankings incompletos.
**Restriccion**: Solo se contabilizan goles de partidos en fechas con estado = 'finalizada'.
**Validacion**: JOIN con fechas WHERE estado = 'finalizada'.
**Caso especial**: Fechas `en_juego` no afectan el ranking hasta que finalicen.

### RN-003: Criterios de Desempate
**Contexto**: Cuando varios jugadores tienen los mismos goles.
**Restriccion**: Orden de desempate:
  1. Mayor cantidad de goles (principal)
  2. Menor cantidad de partidos jugados (mejor eficiencia)
  3. Fecha de registro mas antigua (veterania)
**Validacion**: ORDER BY goles DESC, partidos ASC, created_at ASC.
**Caso especial**: Si aun empatan, comparten posicion (#2, #2, #4...).

### RN-004: Calculo de Partidos Jugados
**Contexto**: Para calcular promedio y desempate.
**Restriccion**: Un partido cuenta como "jugado" si:
  1. El jugador tenia asignacion de equipo en esa fecha
  2. Su equipo participo en el partido
  3. El partido esta finalizado
**Validacion**: COUNT partidos WHERE jugador_equipo IN (equipo_local, equipo_visitante) AND estado='finalizado'.
**Caso especial**: Partidos cancelados no cuentan.

### RN-005: Periodos de Filtrado
**Contexto**: Al filtrar el ranking por tiempo.
**Restriccion**: Definicion de periodos:
  - Historico: todos los goles desde el inicio
  - Este ano: goles de fechas desde 1 de enero del ano actual
  - Este mes: goles de fechas desde 1 del mes actual
  - Ultima fecha: goles solo de la fecha finalizada mas reciente
**Validacion**: Filter por fecha_hora_inicio de la fecha.
**Caso especial**: Si no hay datos en el periodo, mostrar mensaje informativo.

### RN-006: Visibilidad del Ranking
**Contexto**: Quien puede ver el ranking.
**Restriccion**: El ranking es visible para todos los usuarios autenticados del sistema.
**Validacion**: Usuario autenticado.
**Caso especial**: Invitados NO aparecen en rankings publicos (solo jugadores con rol 'jugador' o superior).

### RN-007: Actualizacion del Ranking
**Contexto**: Cuando se actualiza el ranking.
**Restriccion**: El ranking se recalcula cuando:
  1. Se finaliza una fecha
  2. Se registra/anula un gol (en fecha finalizada - ajuste)
  3. Se cambia jugador_id de un gol
**Caso especial**: Cambios durante fecha `en_juego` no afectan hasta finalizacion.

### RN-008: Restriccion por Plan
**Contexto**: Feature flag de stats avanzadas.
**Restriccion**:
  - Plan Gratis: Ranking basico (historico, sin filtros de periodo, sin promedios)
  - Plan 5+: Stats avanzadas (filtros por periodo, promedios, detalle completo)
**Validacion**: Verificar plan del usuario via limites_plan.stats_avanzadas.
**Caso especial**: Si el admin baja de plan, los jugadores del grupo tambien pierden acceso avanzado.

---

## Implementacion Completada

### Backend (Supabase)
- **RPC**: `obtener_ranking_goleadores(p_periodo TEXT) -> JSON`
- **SQL**: `supabase/sql-cloud/2026-02-02_E006-HU-001_ranking_goleadores.sql`
- Todas las RN implementadas en CTEs

### Frontend (Flutter)
- **Estructura**: `lib/features/estadisticas/`
- **Models**: `ranking_goleador_model.dart`, `ranking_response_model.dart`
- **DataSource**: `estadisticas_remote_datasource.dart`
- **Repository**: Interface + Impl con Either pattern
- **BLoC**: `RankingGoleadoresBloc` (CargarRanking, CambiarPeriodo, Refrescar)
- **Pages**: `ranking_goleadores_page.dart` (responsive mobile/desktop)
- **Widgets**: `podio_goleadores_widget.dart`, `goleador_list_item.dart`, `periodo_selector_widget.dart`
- **Ruta**: `/ranking-goleadores`
- **DI**: Registrado en `injection_container.dart`

### QA Validado
- flutter pub get: PASS
- flutter analyze: PASS (0 errores en feature)
- flutter build web --release: PASS
- 7/7 CA implementados

---

## Notas Tecnicas
- Refinado por @negocio-deportivo-expert
- Backend, Frontend y QA completados

---
**Creado**: 2025-01-15
**Refinado**: 2026-02-02
**Completado**: 2026-02-02
