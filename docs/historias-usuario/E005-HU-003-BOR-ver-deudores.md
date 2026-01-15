# E005-HU-003 - Ver Deudores

## Informacion General
- **Epica**: E005 - Pagos
- **Estado**: 🟡 Borrador (BOR)
- **Prioridad**: Alta

## Historia de Usuario
**Como** administrador
**Quiero** ver los jugadores con deudas pendientes
**Para** hacer seguimiento y cobrar los montos adeudados

## Descripcion
Muestra lista de jugadores que tienen pagos pendientes de fechas anteriores.

## Criterios de Aceptacion (CA)

### CA-001: Lista de deudores
- **Dado** que hay jugadores con pagos pendientes
- **Cuando** accedo a "Deudores"
- **Entonces** veo lista de jugadores con deudas

### CA-002: Detalle de deuda
- **Dado** que veo un deudor
- **Cuando** observo su entrada
- **Entonces** veo: nombre, fechas adeudadas, monto total

### CA-003: Ordenar por monto
- **Dado** que veo la lista de deudores
- **Cuando** quiero priorizar
- **Entonces** puedo ordenar por monto de mayor a menor

### CA-004: Desglose por fecha
- **Dado** que selecciono un deudor
- **Cuando** veo el detalle
- **Entonces** veo cada fecha que debe y su monto individual

### CA-005: Total general adeudado
- **Dado** que veo la lista de deudores
- **Cuando** observo el resumen
- **Entonces** veo el monto total adeudado por todos los jugadores

### CA-006: Sin deudores
- **Dado** que todos pagaron
- **Cuando** accedo a deudores
- **Entonces** veo mensaje "No hay deudas pendientes"

## Notas Tecnicas
- Pendiente de refinamiento por @negocio-deportivo-expert

---
**Creado**: 2025-01-15
