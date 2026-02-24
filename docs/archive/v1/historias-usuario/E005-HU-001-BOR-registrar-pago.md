# E005-HU-001 - Registrar Pago

## Informacion General
- **Epica**: E005 - Pagos
- **Estado**: 🟡 Borrador (BOR)
- **Prioridad**: Alta

## Historia de Usuario
**Como** administrador
**Quiero** registrar que un jugador pago
**Para** llevar control de quien cumplio con su aporte

## Descripcion
Permite al admin marcar que un jugador asistente pago su cuota de la fecha.

## Criterios de Aceptacion (CA)

### CA-001: Lista de asistentes
- **Dado** que hay una fecha con jugadores inscritos
- **Cuando** accedo a "Registrar pagos"
- **Entonces** veo lista de asistentes con estado de pago

### CA-002: Marcar como pagado
- **Dado** que veo un jugador sin pagar
- **Cuando** presiono "Marcar pagado"
- **Entonces** el jugador queda registrado como pagado

### CA-003: Monto automatico
- **Dado** que registro un pago
- **Cuando** se guarda
- **Entonces** el monto es automatico segun duracion (S/8 o S/10)

### CA-004: Indicador visual
- **Dado** que veo la lista de asistentes
- **Cuando** hay pagos registrados
- **Entonces** se distingue claramente quien pago y quien no

### CA-005: Desmarcar pago
- **Dado** que marque un pago por error
- **Cuando** necesito corregir
- **Entonces** puedo desmarcar el pago

### CA-006: Resumen de pagos
- **Dado** que veo la lista
- **Cuando** hay pagos
- **Entonces** veo total recaudado y total esperado

## Notas Tecnicas
- Pendiente de refinamiento por @negocio-deportivo-expert

---
**Creado**: 2025-01-15
