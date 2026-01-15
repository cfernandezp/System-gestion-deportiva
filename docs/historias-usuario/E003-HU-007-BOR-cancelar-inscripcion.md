# E003-HU-007 - Cancelar Inscripcion

## Informacion General
- **Epica**: E003 - Gestion de Fechas/Jornadas
- **Estado**: 🟡 Borrador (BOR)
- **Prioridad**: Media

## Historia de Usuario
**Como** jugador inscrito
**Quiero** cancelar mi asistencia
**Para** avisar que ya no podre asistir a la pichanga

## Descripcion
Permite a un jugador retirar su inscripcion de una fecha.

## Criterios de Aceptacion (CA)

### CA-001: Opcion de cancelar
- **Dado** que estoy inscrito a una fecha
- **Cuando** veo la fecha
- **Entonces** veo opcion "Cancelar inscripcion"

### CA-002: Confirmacion de cancelacion
- **Dado** que presiono cancelar
- **Cuando** confirmo la accion
- **Entonces** mi inscripcion se elimina y veo confirmacion

### CA-003: Cancelar antes del cierre
- **Dado** que las inscripciones estan abiertas
- **Cuando** cancelo mi inscripcion
- **Entonces** puedo volver a inscribirme si cambio de opinion

### CA-004: Cancelar despues del cierre
- **Dado** que las inscripciones estan cerradas
- **Cuando** intento cancelar
- **Entonces** debo contactar al administrador (no puedo cancelar directamente)

### CA-005: Notificacion al admin
- **Dado** que cancelo mi inscripcion
- **Cuando** se confirma la cancelacion
- **Entonces** el admin recibe notificacion de la baja

## Notas Tecnicas
- Pendiente de refinamiento por @negocio-deportivo-expert

---
**Creado**: 2025-01-15
