# E006-HU-003 - Mis Estadisticas

## Informacion General
- **Epica**: E006 - Estadisticas y Rankings
- **Estado**: 🟢 Refinada (REF)
- **Prioridad**: Media
- **Story Points**: 5 pts

## Historia de Usuario
**Como** jugador del sistema
**Quiero** ver mis estadisticas personales
**Para** conocer mi rendimiento historico en el grupo

## Descripcion
Muestra un dashboard con las estadisticas personales del jugador logueado. Incluye metricas acumuladas, posiciones en rankings, historial por fecha y logros destacados.

---

## Criterios de Aceptacion (CA)

### CA-001: Acceso a mis estadisticas
- **Dado** que estoy logueado como jugador
- **Cuando** accedo a "Mis Estadisticas"
- **Entonces** veo mi dashboard personal de rendimiento

### CA-002: Metricas principales visibles
- **Dado** que veo mis estadisticas
- **Cuando** observo el resumen
- **Entonces** veo:
  - Goles totales
  - Puntos acumulados
  - Fechas asistidas
  - Partidos jugados

### CA-003: Posicion en rankings
- **Dado** que veo mis estadisticas
- **Cuando** existen rankings
- **Entonces** veo mi posicion actual en:
  - Ranking de goleadores (#X de Y)
  - Ranking de puntos (#X de Y)

### CA-004: Promedio de goles
- **Dado** que veo mis estadisticas
- **Cuando** tengo partidos jugados
- **Entonces** veo mi promedio de goles por partido (redondeado a 2 decimales)
- **Y** veo comparativa con el promedio general del grupo

### CA-005: Historial por fecha
- **Dado** que quiero ver mi detalle
- **Cuando** accedo al historial
- **Entonces** veo cada fecha donde participe:
  - Fecha y lugar
  - Mi equipo (color)
  - Resultado de mi equipo (1ro, 2do, 3ro)
  - Mis goles en esa fecha
  - Puntos obtenidos

### CA-006: Mejor fecha destacada
- **Dado** que tengo historial de fechas
- **Cuando** veo mis estadisticas
- **Entonces** veo destacada mi "Mejor Fecha":
  - La fecha donde anote mas goles
  - O donde mi equipo quedo campeon (si empate en goles)

### CA-007: Racha actual
- **Dado** que veo mis estadisticas
- **Cuando** tengo participaciones recientes
- **Entonces** veo mi racha de asistencia (fechas consecutivas asistidas)

### CA-008: Sin datos
- **Dado** que soy jugador nuevo
- **Cuando** no tengo participaciones
- **Entonces** veo mensaje "Aun no tienes estadisticas. Inscribete a tu primera pichanga!"

---

## Reglas de Negocio (RN)

### RN-001: Solo Mis Datos
**Contexto**: Privacidad de estadisticas.
**Restriccion**: Esta vista muestra SOLO los datos del usuario logueado.
**Validacion**: Filtrar por usuario_id = auth.uid() (mapeado a tabla usuarios).
**Regla calculo**: N/A.
**Caso especial**: Admin ve sus propias estadisticas, no las de otros.

### RN-002: Solo Fechas Finalizadas
**Contexto**: Para estadisticas precisas.
**Restriccion**: Solo se contabilizan datos de fechas con estado = 'finalizada'.
**Validacion**: JOIN con fechas WHERE estado = 'finalizada'.
**Regla calculo**: N/A.
**Caso especial**: Fechas en_juego no afectan estadisticas hasta finalizacion.

### RN-003: Calculo de Goles Totales
**Contexto**: Conteo de goles del jugador.
**Restriccion**: Solo goles validos:
  1. anulado = false
  2. es_autogol = false
  3. jugador_id = mi usuario_id
**Validacion**: COUNT goles con condiciones.
**Regla calculo**: N/A.
**Caso especial**: Autogoles no suman (son en contra).

### RN-004: Calculo de Puntos Acumulados
**Contexto**: Suma de puntos por posiciones de equipo.
**Restriccion**: Puntos = SUM de puntos obtenidos en cada fecha donde participe con inscripcion activa.
**Validacion**: Ver sistema de puntos de E006-HU-002.
**Regla calculo**: Segun posicion de mi equipo en cada fecha.
**Caso especial**: Si cancele inscripcion, no cuento puntos de esa fecha.

### RN-005: Calculo de Fechas Asistidas
**Contexto**: Conteo de asistencia.
**Restriccion**: Una fecha cuenta como "asistida" si:
  1. Tenia inscripcion con estado = 'inscrito'
  2. La fecha esta finalizada
**Validacion**: COUNT fechas con inscripcion activa.
**Regla calculo**: N/A.
**Caso especial**: Inscripcion cancelada = no asistio.

### RN-006: Calculo de Partidos Jugados
**Contexto**: Conteo de partidos.
**Restriccion**: Un partido cuenta si:
  1. Estaba asignado a un equipo (asignaciones_equipos)
  2. Mi equipo participo en el partido
  3. Partido esta finalizado
**Validacion**: COUNT partidos WHERE mi_equipo IN (equipo_local, equipo_visitante) AND estado='finalizado'.
**Regla calculo**: N/A.
**Caso especial**: Partidos cancelados no cuentan.

### RN-007: Calculo de Posicion en Ranking
**Contexto**: Mostrar mi puesto en rankings.
**Restriccion**: Usar mismas reglas de E006-HU-001 y E006-HU-002 para calcular posicion.
**Validacion**: Buscar mi posicion en el ranking calculado.
**Regla calculo**: Mi posicion es COUNT de jugadores con mas goles/puntos que yo + 1.
**Caso especial**: Si no tengo goles/puntos, no aparezco en ranking (mostrar "Sin clasificar").

### RN-008: Mejor Fecha
**Contexto**: Determinar la mejor actuacion.
**Restriccion**: Criterios para "mejor fecha":
  1. Fecha donde anote mas goles (principal)
  2. Si empate: fecha donde mi equipo quedo campeon
  3. Si aun empate: fecha mas reciente
**Validacion**: ORDER BY mis_goles DESC, mi_equipo_primero DESC, fecha DESC LIMIT 1.
**Regla calculo**: N/A.
**Caso especial**: Si nunca anote ni gane, mostrar "Aun no tienes mejor fecha".

### RN-009: Racha de Asistencia
**Contexto**: Mostrar constancia.
**Restriccion**: Racha = cantidad de fechas consecutivas (sin faltar) finalizadas.
**Validacion**: Contar desde la ultima fecha hacia atras mientras haya inscripcion activa.
**Regla calculo**: N/A.
**Caso especial**: Si la ultima fecha no asistio, racha = 0.

---

## Notas Tecnicas
- Refinado por @negocio-deportivo-expert
- Esta HU complementa E004-HU-008 (Mi Actividad en Vivo) que es para fechas activas

---
**Creado**: 2025-01-15
**Refinado**: 2026-02-02
