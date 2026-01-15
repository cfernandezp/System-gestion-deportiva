# E003-HU-004 - Cerrar Inscripciones

## Informacion General
- **Epica**: E003 - Gestion de Fechas/Jornadas
- **Estado**: 🟡 Borrador (BOR)
- **Prioridad**: Alta

## Historia de Usuario
**Como** administrador
**Quiero** cerrar las inscripciones de una fecha
**Para** poder proceder a armar los equipos

## Descripcion
Permite al admin cerrar las inscripciones cuando ya no se aceptan mas jugadores.

## Criterios de Aceptacion (CA)

### CA-001: Boton cerrar inscripciones
- **Dado** que soy admin y hay una fecha abierta
- **Cuando** veo la fecha
- **Entonces** veo opcion "Cerrar inscripciones"

### CA-002: Confirmacion de cierre
- **Dado** que presiono cerrar inscripciones
- **Cuando** confirmo la accion
- **Entonces** las inscripciones se cierran y nadie mas puede anotarse

### CA-003: Estado actualizado
- **Dado** que se cierran las inscripciones
- **Cuando** cualquier usuario ve la fecha
- **Entonces** ve estado "Inscripciones cerradas"

### CA-004: Minimo de jugadores
- **Dado** que quiero cerrar inscripciones
- **Cuando** hay menos de 6 jugadores inscritos
- **Entonces** veo advertencia pero puedo continuar si lo deseo

### CA-005: Reabrir inscripciones
- **Dado** que las inscripciones estan cerradas
- **Cuando** necesito agregar mas jugadores
- **Entonces** puedo reabrir inscripciones (solo admin)

## Notas Tecnicas
- Pendiente de refinamiento por @negocio-deportivo-expert

---
**Creado**: 2025-01-15
