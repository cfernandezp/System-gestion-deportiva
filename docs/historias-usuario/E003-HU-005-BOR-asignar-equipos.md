# E003-HU-005 - Asignar Equipos

## Informacion General
- **Epica**: E003 - Gestion de Fechas/Jornadas
- **Estado**: 🟡 Borrador (BOR)
- **Prioridad**: Alta

## Historia de Usuario
**Como** administrador
**Quiero** distribuir a los jugadores inscritos en equipos
**Para** que cada uno sepa su equipo y color de chaleco

## Descripcion
Permite al admin asignar jugadores a equipos identificados por colores.

## Criterios de Aceptacion (CA)

### CA-001: Acceso a asignacion
- **Dado** que las inscripciones estan cerradas
- **Cuando** accedo a "Asignar equipos"
- **Entonces** veo la lista de inscritos y los equipos disponibles

### CA-002: Equipos segun formato
- **Dado** que la fecha es de 1 hora
- **Cuando** asigno equipos
- **Entonces** hay 2 equipos disponibles (ej: Naranja, Verde)
- **Dado** que la fecha es de 2 horas
- **Cuando** asigno equipos
- **Entonces** hay 3 equipos disponibles (ej: Naranja, Verde, Azul)

### CA-003: Asignacion manual
- **Dado** que veo la lista de jugadores
- **Cuando** selecciono un jugador
- **Entonces** puedo asignarlo a un equipo especifico

### CA-004: Colores de equipo
- **Dado** que asigno equipos
- **Cuando** veo las opciones
- **Entonces** los equipos son: Naranja, Verde, Azul, Rojo

### CA-005: Equilibrio de equipos
- **Dado** que asigno jugadores
- **Cuando** un equipo tiene 2+ jugadores mas que otro
- **Entonces** veo advertencia de desbalance

### CA-006: Confirmar asignacion
- **Dado** que termine de asignar
- **Cuando** confirmo
- **Entonces** los equipos quedan definidos y visibles para todos

### CA-007: Modificar asignacion
- **Dado** que ya asigne equipos
- **Cuando** necesito cambiar a un jugador de equipo
- **Entonces** puedo reasignarlo antes de iniciar los partidos

## Notas Tecnicas
- Pendiente de refinamiento por @negocio-deportivo-expert

---
**Creado**: 2025-01-15
