# E005 - Pagos

## Descripcion
Gestiona el registro de pagos de cada jugador por fecha y el historial de deudas.

## Objetivo
Permitir a los administradores registrar quien pago y llevar control de deudores.

## Contexto de Negocio
- Cada asistente debe pagar segun duracion de la pichanga
- S/ 8 por 1 hora | S/ 10 por 2 horas
- Admin registra quien pago
- Historial de deudores para seguimiento

## Tarifas

| Duracion | Monto |
|----------|-------|
| 1 Hora | S/ 8 |
| 2 Horas | S/ 10 |

## Alcance
- Registrar pago de jugador
- Ver estado de pagos de una fecha
- Ver deudores
- Historial de pagos por jugador
- Marcar deuda como pagada

## Historias de Usuario

| ID | Titulo | Estado | Descripcion |
|----|--------|--------|-------------|
| E005-HU-001 | Registrar Pago | 🟡 PEN | Como admin, quiero registrar que un jugador pago |
| E005-HU-002 | Ver Pagos de Fecha | 🟡 PEN | Como admin, quiero ver quien pago en una fecha |
| E005-HU-003 | Ver Deudores | 🟡 PEN | Como admin, quiero ver jugadores con deudas pendientes |
| E005-HU-004 | Mi Historial de Pagos | 🟡 PEN | Como jugador, quiero ver mi historial de pagos |
| E005-HU-005 | Saldar Deuda | 🟡 PEN | Como admin, quiero marcar una deuda antigua como pagada |

## Dependencias
- E001: Login de Usuario
- E002: Gestion de Jugadores
- E003: Gestion de Fechas

---
**Version**: 1.0
**Estado**: 🟡 En Definicion
