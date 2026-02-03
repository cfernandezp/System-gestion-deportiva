# E006-HU-005 - Estadisticas Mensuales

## Informacion General
- **Epica**: E006 - Estadisticas y Rankings
- **Estado**: 🟢 Refinada (REF)
- **Prioridad**: Media
- **Story Points**: 5 pts

## Historia de Usuario
**Como** usuario del sistema
**Quiero** ver estadisticas del mes
**Para** conocer el rendimiento mensual del grupo y comparar periodos

## Descripcion
Muestra estadisticas agregadas por mes: resumen de actividad, goleador del mes, ranking mensual, jugador mas constante y comparativas con meses anteriores.

---

## Criterios de Aceptacion (CA)

### CA-001: Seleccionar mes a consultar
- **Dado** que accedo a "Estadisticas Mensuales"
- **Cuando** veo la pantalla
- **Entonces** puedo seleccionar mes y ano a consultar
- **Y** por defecto muestra el mes actual

### CA-002: Resumen del mes
- **Dado** que selecciono un mes
- **Cuando** veo el resumen
- **Entonces** veo:
  - Cantidad de fechas jugadas
  - Total de partidos
  - Total de goles
  - Total de asistentes unicos

### CA-003: Goleador del mes destacado
- **Dado** que veo el mes
- **Cuando** hay goles registrados
- **Entonces** veo destacado al goleador del mes:
  - Foto/avatar
  - Apodo
  - Cantidad de goles
  - Promedio por fecha

### CA-004: Ranking mensual
- **Dado** que veo el mes
- **Cuando** accedo a rankings
- **Entonces** veo rankings SOLO del mes seleccionado:
  - Top 5 goleadores del mes
  - Top 5 puntos del mes

### CA-005: Comparativa con mes anterior
- **Dado** que veo un mes
- **Cuando** hay datos del mes anterior
- **Entonces** puedo ver comparativa:
  - Mas/menos fechas que mes anterior
  - Mas/menos goles que mes anterior
  - Mas/menos asistentes que mes anterior
  - Indicadores visuales (flecha arriba/abajo, porcentaje)

### CA-006: Jugador mas constante del mes
- **Dado** que veo el mes
- **Cuando** hay asistencias registradas
- **Entonces** veo destacado al jugador mas constante:
  - El que asistio a MAS fechas del mes
  - Si empate: el que tiene mas goles

### CA-007: Lista de fechas del mes
- **Dado** que veo el resumen mensual
- **Cuando** quiero ver detalle
- **Entonces** veo lista de fechas del mes con resultados resumidos

### CA-008: Mes sin actividad
- **Dado** que selecciono un mes
- **Cuando** no hay fechas finalizadas en ese mes
- **Entonces** veo mensaje "No hubo actividad en [Mes Ano]"

---

## Reglas de Negocio (RN)

### RN-001: Definicion de Mes
**Contexto**: Para filtrar datos por mes.
**Restriccion**: Un mes se define desde el dia 1 00:00:00 hasta el ultimo dia 23:59:59.
**Validacion**: fecha_hora_inicio BETWEEN inicio_mes AND fin_mes.
**Regla calculo**: N/A.
**Caso especial**: Usar timezone local (America/Lima).

### RN-002: Solo Fechas Finalizadas
**Contexto**: Para estadisticas precisas.
**Restriccion**: Solo contar fechas con estado = 'finalizada'.
**Validacion**: WHERE estado = 'finalizada'.
**Regla calculo**: N/A.
**Caso especial**: Fechas canceladas o en curso no se cuentan.

### RN-003: Goleador del Mes
**Contexto**: Determinar maximo anotador mensual.
**Restriccion**: El jugador con mas goles validos en fechas finalizadas del mes.
**Validacion**: COUNT goles WHERE anulado=false AND es_autogol=false GROUP BY jugador_id ORDER BY COUNT DESC.
**Regla calculo**: N/A.
**Caso especial**: Si hay empate, mostrar todos como co-goleadores del mes.

### RN-004: Jugador Mas Constante
**Contexto**: Reconocer asistencia.
**Restriccion**: El jugador que asistio a mas fechas del mes (inscripcion activa).
**Validacion**: COUNT DISTINCT fecha_id WHERE inscripcion.estado='inscrito' GROUP BY usuario_id.
**Regla calculo**: Desempate por: mas goles > fecha registro mas antigua.
**Caso especial**: Si nadie asistio, no mostrar.

### RN-005: Asistentes Unicos del Mes
**Contexto**: Contar participantes.
**Restriccion**: Contar jugadores DISTINTOS que asistieron al menos a 1 fecha del mes.
**Validacion**: COUNT DISTINCT usuario_id FROM inscripciones WHERE estado='inscrito'.
**Regla calculo**: N/A.
**Caso especial**: Un jugador que asistio a 3 fechas cuenta como 1 asistente unico.

### RN-006: Comparativa con Mes Anterior
**Contexto**: Mostrar tendencias.
**Restriccion**: Comparar metricas del mes seleccionado vs mes inmediatamente anterior.
**Validacion**: Calcular diferencia: (valor_actual - valor_anterior).
**Regla calculo**:
  - Porcentaje = ((actual - anterior) / anterior) * 100
  - Si anterior = 0 y actual > 0: mostrar "+100%" o "Nuevo"
**Caso especial**: Si no hay datos del mes anterior, no mostrar comparativa.

### RN-007: Ranking Mensual
**Contexto**: Rankings filtrados por mes.
**Restriccion**: Aplicar mismas reglas de E006-HU-001 y E006-HU-002 pero filtrado por fecha del mes.
**Validacion**: WHERE fecha_hora_inicio BETWEEN inicio_mes AND fin_mes.
**Regla calculo**: N/A.
**Caso especial**: Mostrar top 5, no ranking completo.

### RN-008: Meses Disponibles
**Contexto**: Que meses se pueden consultar.
**Restriccion**: Solo mostrar meses donde haya al menos 1 fecha finalizada.
**Validacion**: SELECT DISTINCT YEAR(fecha_hora_inicio), MONTH(fecha_hora_inicio) FROM fechas WHERE estado='finalizada'.
**Regla calculo**: N/A.
**Caso especial**: No permitir seleccionar meses futuros.

---

## Notas Tecnicas
- Refinado por @negocio-deportivo-expert

---
**Creado**: 2025-01-15
**Refinado**: 2026-02-02
