# E003-HU-002 - Inscribirse a Fecha

## Informacion General
- **Epica**: E003 - Gestion de Fechas/Jornadas
- **Estado**: 🟡 Borrador (BOR)
- **Prioridad**: Alta

## Historia de Usuario
**Como** jugador
**Quiero** anotarme para la proxima pichanga
**Para** confirmar mi asistencia

## Descripcion
Permite a los jugadores inscribirse a una fecha abierta.

## Criterios de Aceptacion (CA)

### CA-001: Ver fecha disponible
- **Dado** que hay una fecha creada
- **Cuando** accedo a "Proxima Pichanga"
- **Entonces** veo los detalles: fecha, hora, lugar, duracion, costo

### CA-002: Boton de inscripcion
- **Dado** que veo una fecha abierta
- **Cuando** no estoy inscrito
- **Entonces** veo boton "Anotarme" o "Confirmar asistencia"

### CA-003: Confirmar inscripcion
- **Dado** que presiono "Anotarme"
- **Cuando** confirmo
- **Entonces** quedo inscrito y veo mensaje de confirmacion

### CA-004: Ya inscrito
- **Dado** que ya estoy inscrito
- **Cuando** veo la fecha
- **Entonces** veo indicador de "Ya inscrito" en lugar del boton

### CA-005: Inscripciones cerradas
- **Dado** que las inscripciones estan cerradas
- **Cuando** intento inscribirme
- **Entonces** no puedo y veo mensaje "Inscripciones cerradas"

### CA-006: Ver cantidad de inscritos
- **Dado** que veo la fecha
- **Cuando** hay jugadores inscritos
- **Entonces** veo el numero total de inscritos

## Notas Tecnicas
- Pendiente de refinamiento por @negocio-deportivo-expert

---
**Creado**: 2025-01-15
