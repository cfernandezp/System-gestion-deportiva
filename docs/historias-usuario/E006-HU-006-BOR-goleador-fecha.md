# E006-HU-006 - Goleador de la Fecha

## Informacion General
- **Epica**: E006 - Estadisticas y Rankings
- **Estado**: 🟡 Borrador (BOR)
- **Prioridad**: Media

## Historia de Usuario
**Como** usuario
**Quiero** ver quien fue el goleador de cada fecha
**Para** reconocer al maximo anotador de la jornada

## Descripcion
Muestra el goleador destacado de cada fecha jugada.

## Criterios de Aceptacion (CA)

### CA-001: Goleador en resumen de fecha
- **Dado** que veo el resumen de una fecha
- **Cuando** hubo goles
- **Entonces** veo destacado al goleador de la fecha con sus goles

### CA-002: Empate en goles
- **Dado** que varios jugadores tienen el maximo de goles
- **Cuando** veo el goleador de la fecha
- **Entonces** se muestran todos los empatados como co-goleadores

### CA-003: Historial de goleadores
- **Dado** que accedo a "Goleadores por fecha"
- **Cuando** veo la lista
- **Entonces** veo cada fecha con su goleador correspondiente

### CA-004: Sin goles
- **Dado** que una fecha no tuvo goles
- **Cuando** veo el resumen
- **Entonces** no se muestra goleador de la fecha

### CA-005: Notificacion al goleador
- **Dado** que se finaliza una jornada
- **Cuando** se determina el goleador
- **Entonces** el jugador puede recibir reconocimiento/notificacion

### CA-006: Contador de veces goleador
- **Dado** que veo el perfil de un jugador
- **Cuando** ha sido goleador de la fecha
- **Entonces** veo cuantas veces ha sido goleador de la fecha

## Notas Tecnicas
- Pendiente de refinamiento por @negocio-deportivo-expert

---
**Creado**: 2025-01-15
