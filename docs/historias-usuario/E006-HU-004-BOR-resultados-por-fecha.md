# E006-HU-004 - Resultados por Fecha

## Informacion General
- **Epica**: E006 - Estadisticas y Rankings
- **Estado**: 🟡 Borrador (BOR)
- **Prioridad**: Media

## Historia de Usuario
**Como** usuario
**Quiero** ver los resultados de una fecha especifica
**Para** revisar como quedaron los partidos de una jornada

## Descripcion
Muestra resultados detallados de fechas pasadas.

## Criterios de Aceptacion (CA)

### CA-001: Lista de fechas
- **Dado** que accedo a "Historial de fechas"
- **Cuando** veo la lista
- **Entonces** veo todas las fechas jugadas ordenadas por fecha (reciente primero)

### CA-002: Seleccionar fecha
- **Dado** que veo la lista de fechas
- **Cuando** selecciono una
- **Entonces** veo el detalle completo de esa jornada

### CA-003: Resultados de partidos
- **Dado** que veo una fecha
- **Cuando** observo los partidos
- **Entonces** veo cada partido con: equipos, marcador final

### CA-004: Posiciones finales
- **Dado** que veo una fecha
- **Cuando** observo el resumen
- **Entonces** veo tabla de posiciones: 1ro, 2do, 3ro con puntos de equipo

### CA-005: Goleadores de la fecha
- **Dado** que veo una fecha
- **Cuando** observo las estadisticas
- **Entonces** veo lista de goleadores de esa fecha

### CA-006: Asistentes
- **Dado** que veo una fecha
- **Cuando** quiero saber quienes jugaron
- **Entonces** veo lista de asistentes y sus equipos

## Notas Tecnicas
- Pendiente de refinamiento por @negocio-deportivo-expert

---
**Creado**: 2025-01-15
