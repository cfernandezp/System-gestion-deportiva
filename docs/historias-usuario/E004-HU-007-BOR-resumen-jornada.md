# E004-HU-007 - Resumen de Jornada

## Informacion General
- **Epica**: E004 - Partidos en Vivo
- **Estado**: 🟡 Borrador (BOR)
- **Prioridad**: Media

## Historia de Usuario
**Como** usuario
**Quiero** ver el resumen de todos los partidos de la jornada
**Para** conocer los resultados finales y estadisticas

## Descripcion
Muestra resumen completo de la jornada con todos los partidos, goleadores y posiciones.

## Criterios de Aceptacion (CA)

### CA-001: Lista de partidos
- **Dado** que la jornada termino o esta en curso
- **Cuando** accedo al resumen
- **Entonces** veo lista de todos los partidos con sus resultados

### CA-002: Posiciones de equipos
- **Dado** que veo el resumen
- **Cuando** hay resultados
- **Entonces** veo tabla de posiciones: 1ro, 2do, 3ro con puntos

### CA-003: Goleadores de la fecha
- **Dado** que veo el resumen
- **Cuando** hubo goles
- **Entonces** veo ranking de goleadores de la fecha

### CA-004: Puntos asignados
- **Dado** que veo el resumen
- **Cuando** la jornada finalizo
- **Entonces** veo los puntos asignados a cada jugador segun puesto de su equipo

### CA-005: Goleador de la fecha destacado
- **Dado** que veo el resumen
- **Cuando** hay un maximo goleador
- **Entonces** se destaca al goleador de la fecha

### CA-006: Compartir resumen
- **Dado** que veo el resumen final
- **Cuando** quiero compartirlo
- **Entonces** puedo generar imagen o texto para compartir en WhatsApp

## Notas Tecnicas
- Pendiente de refinamiento por @negocio-deportivo-expert

---
**Creado**: 2025-01-15
