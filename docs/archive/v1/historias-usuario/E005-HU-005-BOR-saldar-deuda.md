# E005-HU-005 - Saldar Deuda

## Informacion General
- **Epica**: E005 - Pagos
- **Estado**: 🟡 Borrador (BOR)
- **Prioridad**: Media

## Historia de Usuario
**Como** administrador
**Quiero** marcar una deuda antigua como pagada
**Para** actualizar el estado cuando un jugador salda su deuda

## Descripcion
Permite al admin registrar el pago de deudas de fechas anteriores.

## Criterios de Aceptacion (CA)

### CA-001: Acceso desde deudores
- **Dado** que veo la lista de deudores
- **Cuando** selecciono un jugador
- **Entonces** puedo ver sus deudas y marcarlas como pagadas

### CA-002: Pago parcial
- **Dado** que un jugador debe varias fechas
- **Cuando** paga solo algunas
- **Entonces** puedo marcar como pagadas solo las fechas que pago

### CA-003: Pago total
- **Dado** que un jugador paga todo lo que debe
- **Cuando** registro el pago
- **Entonces** puedo marcar todas sus deudas como pagadas de una vez

### CA-004: Confirmacion
- **Dado** que marco una deuda como pagada
- **Cuando** confirmo
- **Entonces** veo confirmacion y la deuda desaparece de pendientes

### CA-005: Historial actualizado
- **Dado** que salde una deuda
- **Cuando** el jugador ve su historial
- **Entonces** ve la fecha como "Pagada"

### CA-006: Registro de fecha de pago
- **Dado** que registro un pago de deuda
- **Cuando** se guarda
- **Entonces** se registra la fecha en que se realizo el pago

## Notas Tecnicas
- Pendiente de refinamiento por @negocio-deportivo-expert

---
**Creado**: 2025-01-15
