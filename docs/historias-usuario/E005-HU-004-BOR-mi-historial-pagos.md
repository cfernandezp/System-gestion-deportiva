# E005-HU-004 - Mi Historial de Pagos

## Informacion General
- **Epica**: E005 - Pagos
- **Estado**: 🟡 Borrador (BOR)
- **Prioridad**: Media

## Historia de Usuario
**Como** jugador
**Quiero** ver mi historial de pagos
**Para** saber si tengo deudas pendientes y ver mis pagos anteriores

## Descripcion
Permite a cada jugador ver su historial personal de pagos.

## Criterios de Aceptacion (CA)

### CA-001: Acceso a mi historial
- **Dado** que estoy autenticado como jugador
- **Cuando** accedo a "Mis pagos"
- **Entonces** veo mi historial de pagos

### CA-002: Lista de fechas asistidas
- **Dado** que veo mi historial
- **Cuando** observe la lista
- **Entonces** veo las fechas a las que asisti con estado de pago

### CA-003: Deudas destacadas
- **Dado** que tengo pagos pendientes
- **Cuando** veo mi historial
- **Entonces** las deudas se muestran destacadas (color rojo o indicador)

### CA-004: Total adeudado
- **Dado** que tengo deudas
- **Cuando** veo mi historial
- **Entonces** veo el monto total que debo

### CA-005: Historial limpio
- **Dado** que no tengo deudas
- **Cuando** veo mi historial
- **Entonces** veo indicador de "Al dia" o "Sin deudas"

### CA-006: Detalle por fecha
- **Dado** que veo mi historial
- **Cuando** selecciono una fecha
- **Entonces** veo: fecha, duracion, monto, estado

## Notas Tecnicas
- Pendiente de refinamiento por @negocio-deportivo-expert

---
**Creado**: 2025-01-15
