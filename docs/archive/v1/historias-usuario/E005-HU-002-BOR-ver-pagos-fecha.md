# E005-HU-002 - Ver Pagos de Fecha

## Informacion General
- **Epica**: E005 - Pagos
- **Estado**: 🟡 Borrador (BOR)
- **Prioridad**: Media

## Historia de Usuario
**Como** administrador
**Quiero** ver quien pago en una fecha especifica
**Para** tener control del estado financiero de cada jornada

## Descripcion
Muestra el detalle de pagos de una fecha especifica.

## Criterios de Aceptacion (CA)

### CA-001: Seleccionar fecha
- **Dado** que quiero ver pagos historicos
- **Cuando** selecciono una fecha pasada
- **Entonces** veo el detalle de pagos de esa fecha

### CA-002: Lista de pagos
- **Dado** que veo una fecha
- **Cuando** observo la lista
- **Entonces** veo cada asistente con: nombre, estado (pagado/pendiente), monto

### CA-003: Totales
- **Dado** que veo los pagos de una fecha
- **Cuando** observo el resumen
- **Entonces** veo: total asistentes, total pagaron, total pendientes, monto recaudado

### CA-004: Filtrar por estado
- **Dado** que veo la lista
- **Cuando** quiero ver solo pendientes
- **Entonces** puedo filtrar por "Pagados" o "Pendientes"

### CA-005: Exportar lista
- **Dado** que necesito la lista de pagos
- **Cuando** quiero compartirla
- **Entonces** puedo copiar o exportar la lista

## Notas Tecnicas
- Pendiente de refinamiento por @negocio-deportivo-expert

---
**Creado**: 2025-01-15
