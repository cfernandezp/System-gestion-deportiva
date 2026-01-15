# E006-HU-005 - Estadisticas Mensuales

## Informacion General
- **Epica**: E006 - Estadisticas y Rankings
- **Estado**: 🟡 Borrador (BOR)
- **Prioridad**: Media

## Historia de Usuario
**Como** usuario
**Quiero** ver estadisticas del mes
**Para** conocer el rendimiento mensual del grupo

## Descripcion
Muestra estadisticas agregadas por mes.

## Criterios de Aceptacion (CA)

### CA-001: Seleccionar mes
- **Dado** que accedo a "Estadisticas mensuales"
- **Cuando** veo la pantalla
- **Entonces** puedo seleccionar mes y ano a consultar

### CA-002: Resumen del mes
- **Dado** que selecciono un mes
- **Cuando** veo el resumen
- **Entonces** veo: fechas jugadas, total partidos, total goles, total asistentes

### CA-003: Goleador del mes
- **Dado** que veo el mes
- **Cuando** hay goles registrados
- **Entonces** veo destacado al goleador del mes

### CA-004: Ranking mensual
- **Dado** que veo el mes
- **Cuando** accedo a rankings
- **Entonces** veo rankings de goles y puntos solo del mes seleccionado

### CA-005: Comparativa con mes anterior
- **Dado** que veo un mes
- **Cuando** hay datos del mes anterior
- **Entonces** puedo ver comparativa (mas/menos fechas, goles, etc)

### CA-006: Jugador mas asistente
- **Dado** que veo el mes
- **Cuando** hay asistencias registradas
- **Entonces** veo quien asistio a mas fechas del mes

## Notas Tecnicas
- Pendiente de refinamiento por @negocio-deportivo-expert

---
**Creado**: 2025-01-15
