# E003-HU-006 - Ver Mi Equipo

## Informacion General
- **Epica**: E003 - Gestion de Fechas/Jornadas
- **Estado**: 🟡 Borrador (BOR)
- **Prioridad**: Alta

## Historia de Usuario
**Como** jugador inscrito
**Quiero** saber a que equipo pertenezco
**Para** llegar a la cancha y ponerme el chaleco del color correcto

## Descripcion
Muestra al jugador su equipo asignado y el color de chaleco que debe usar.

## Criterios de Aceptacion (CA)

### CA-001: Ver mi equipo
- **Dado** que estoy inscrito y los equipos fueron asignados
- **Cuando** accedo a la fecha
- **Entonces** veo claramente mi equipo y color (ej: "Equipo Naranja")

### CA-002: Color destacado
- **Dado** que veo mi equipo
- **Cuando** observo la pantalla
- **Entonces** el color se muestra visualmente (fondo o icono del color)

### CA-003: Companeros de equipo
- **Dado** que veo mi equipo
- **Cuando** quiero saber quienes mas estan conmigo
- **Entonces** veo la lista de companeros del mismo equipo

### CA-004: Equipos no asignados
- **Dado** que estoy inscrito
- **Cuando** los equipos aun no se asignaron
- **Entonces** veo mensaje "Equipos pendientes de asignar"

### CA-005: No inscrito
- **Dado** que no estoy inscrito a la fecha
- **Cuando** veo la fecha
- **Entonces** no veo asignacion de equipo (solo opcion de inscribirme si esta abierta)

## Notas Tecnicas
- Pendiente de refinamiento por @negocio-deportivo-expert

---
**Creado**: 2025-01-15
