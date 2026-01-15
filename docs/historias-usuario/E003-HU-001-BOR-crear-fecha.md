# E003-HU-001 - Crear Fecha

## Informacion General
- **Epica**: E003 - Gestion de Fechas/Jornadas
- **Estado**: 🟡 Borrador (BOR)
- **Prioridad**: Alta

## Historia de Usuario
**Como** administrador
**Quiero** crear una nueva jornada de pichanga
**Para** que los jugadores puedan inscribirse

## Descripcion
Permite al admin crear una fecha de pichanga definiendo dia, hora, duracion y formato.

## Criterios de Aceptacion (CA)

### CA-001: Acceso a crear fecha
- **Dado** que soy administrador
- **Cuando** selecciono "Crear Fecha"
- **Entonces** veo el formulario de creacion

### CA-002: Datos requeridos
- **Dado** que creo una fecha
- **Cuando** completo el formulario
- **Entonces** debo ingresar: fecha, hora inicio, duracion (1h o 2h), lugar

### CA-003: Formato segun duracion
- **Dado** que selecciono duracion
- **Cuando** elijo 1 hora
- **Entonces** el formato es 2 equipos, costo S/8
- **Cuando** elijo 2 horas
- **Entonces** el formato es 3 equipos, costo S/10

### CA-004: Fecha futura
- **Dado** que ingreso una fecha
- **Cuando** es una fecha pasada
- **Entonces** veo error indicando que debe ser fecha futura

### CA-005: Confirmacion de creacion
- **Dado** que complete los datos correctamente
- **Cuando** guardo la fecha
- **Entonces** la fecha se crea y queda abierta para inscripciones

### CA-006: Notificacion a jugadores
- **Dado** que se crea una nueva fecha
- **Cuando** se confirma la creacion
- **Entonces** los jugadores reciben notificacion de nueva pichanga

## Notas Tecnicas
- Pendiente de refinamiento por @negocio-deportivo-expert

---
**Creado**: 2025-01-15
