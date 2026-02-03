# E006-HU-006 - Goleador de la Fecha

## Informacion General
- **Epica**: E006 - Estadisticas y Rankings
- **Estado**: 🟢 Refinada (REF)
- **Prioridad**: Media
- **Story Points**: 3 pts

## Historia de Usuario
**Como** usuario del sistema
**Quiero** ver quien fue el goleador de cada fecha
**Para** reconocer al maximo anotador de cada jornada

## Descripcion
Muestra el goleador destacado de cada fecha jugada. Cuando se finaliza una jornada, se determina automaticamente quien fue el maximo anotador y se le otorga el reconocimiento de "Goleador de la Fecha".

---

## Criterios de Aceptacion (CA)

### CA-001: Goleador en resumen de fecha
- **Dado** que veo el resumen de una fecha finalizada
- **Cuando** hubo goles
- **Entonces** veo destacado al goleador de la fecha:
  - Foto/avatar
  - Apodo
  - Cantidad de goles anotados en la fecha

### CA-002: Empate en goles (Co-goleadores)
- **Dado** que varios jugadores tienen el maximo de goles en una fecha
- **Cuando** veo el goleador de la fecha
- **Entonces** se muestran TODOS los empatados como co-goleadores
- **Y** cada uno recibe el reconocimiento

### CA-003: Historial de goleadores por fecha
- **Dado** que accedo a "Goleadores por Fecha"
- **Cuando** veo la lista
- **Entonces** veo cada fecha finalizada con su(s) goleador(es):
  - Fecha y lugar
  - Goleador(es) con cantidad de goles
  - Ordenado por fecha (mas reciente primero)

### CA-004: Fecha sin goles
- **Dado** que una fecha finalizo sin goles
- **Cuando** veo el resumen de esa fecha
- **Entonces** se muestra "Sin goleador de la fecha"
- **Y** en el historial aparece con indicador "0-0"

### CA-005: Notificacion al goleador
- **Dado** que se finaliza una jornada
- **Cuando** se determina el goleador de la fecha
- **Entonces** el/los jugador(es) reciben notificacion:
  - Titulo: "Felicidades! Eres el goleador de la fecha"
  - Mensaje: "Anotaste X goles en la pichanga del [fecha]"

### CA-006: Contador de veces goleador de la fecha
- **Dado** que veo el perfil de un jugador
- **Cuando** ha sido goleador de la fecha alguna vez
- **Entonces** veo la metrica "Veces goleador de la fecha: X"
- **Y** este contador aparece en "Mis Estadisticas" (E006-HU-003)

### CA-007: Badge o icono de goleador
- **Dado** que un jugador es goleador de la fecha
- **Cuando** veo la lista de goleadores de esa fecha
- **Entonces** tiene un badge/icono especial (ej: estrella, balon dorado)

---

## Reglas de Negocio (RN)

### RN-001: Determinacion del Goleador de la Fecha
**Contexto**: Al finalizar una fecha.
**Restriccion**: El goleador de la fecha es el jugador con mas goles validos en esa fecha.
**Validacion**: MAX(COUNT goles) WHERE anulado=false AND es_autogol=false AND jugador_id IS NOT NULL GROUP BY jugador_id.
**Regla calculo**: N/A.
**Caso especial**: Si hay empate, todos los empatados son co-goleadores.

### RN-002: Solo Goles Validos
**Contexto**: Para determinar goleador.
**Restriccion**: Solo contar goles que cumplan:
  1. anulado = false
  2. es_autogol = false
  3. jugador_id IS NOT NULL
**Validacion**: Filtrar goles con condiciones.
**Regla calculo**: N/A.
**Caso especial**: Autogoles no cuentan para ser goleador.

### RN-003: Minimo de Goles
**Contexto**: Para ser goleador de la fecha.
**Restriccion**: Se requiere al menos 1 gol para ser goleador de la fecha.
**Validacion**: COUNT goles >= 1.
**Regla calculo**: N/A.
**Caso especial**: Si todos tienen 0 goles, no hay goleador de la fecha.

### RN-004: Registro al Finalizar Fecha
**Contexto**: Cuando se registra el goleador.
**Restriccion**: El goleador de la fecha se determina automaticamente cuando la fecha cambia a estado = 'finalizada'.
**Validacion**: Trigger o funcion al finalizar fecha.
**Regla calculo**: N/A.
**Caso especial**: Si se anula un gol despues de finalizar y cambia al goleador, se debe recalcular.

### RN-005: Notificacion Automatica
**Contexto**: Notificar al goleador.
**Restriccion**: Crear notificacion automatica al determinar goleador:
  - tipo: 'general' (o nuevo tipo 'goleador_fecha')
  - usuario_id: el/los goleadores
  - titulo y mensaje segun CA-005
**Validacion**: INSERT en notificaciones.
**Regla calculo**: N/A.
**Caso especial**: Si hay co-goleadores, ambos reciben notificacion.

### RN-006: Contador de Veces Goleador
**Contexto**: Estadistica individual.
**Restriccion**: Contar cuantas fechas un jugador ha sido goleador (o co-goleador).
**Validacion**: COUNT fechas WHERE jugador es goleador de la fecha.
**Regla calculo**: Cada fecha donde fue goleador (o co-goleador) suma 1.
**Caso especial**: Co-goleadores: ambos suman 1 a su contador.

### RN-007: No Hay Desempate
**Contexto**: Empate en goles maximos.
**Restriccion**: NO hay criterio de desempate. Si 2+ jugadores tienen el maximo de goles, TODOS son goleadores de la fecha.
**Validacion**: N/A.
**Regla calculo**: N/A.
**Caso especial**: Puede haber 2, 3 o mas goleadores de la fecha.

### RN-008: Visibilidad
**Contexto**: Quien ve esta informacion.
**Restriccion**: El goleador de la fecha es informacion publica visible para todos los usuarios autenticados.
**Validacion**: Usuario autenticado.
**Regla calculo**: N/A.
**Caso especial**: N/A.

---

## Notas Tecnicas
- Refinado por @negocio-deportivo-expert
- Esta funcionalidad se integra con E003-HU-010 (Finalizar Fecha) para determinar automaticamente el goleador

---
**Creado**: 2025-01-15
**Refinado**: 2026-02-02
