# E006-HU-005 - Estadisticas Mensuales

## Informacion General
- **Epica**: E006 - Estadisticas y Rankings
- **Estado**: ✅ Completada (COM)
- **Prioridad**: Media
- **Story Points**: 5 pts

## Historia de Usuario
**Como** usuario del sistema
**Quiero** ver estadisticas del mes
**Para** conocer el rendimiento mensual del grupo y comparar periodos

## Descripcion
Muestra estadisticas agregadas por mes: resumen de actividad, goleador del mes, ranking mensual, jugador mas constante y comparativas con meses anteriores.

**Restriccion de plan**: Estadisticas mensuales completas disponibles desde Plan 5+. Plan Gratis NO tiene acceso a esta funcionalidad.

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
**Caso especial**: Usar timezone local (America/Lima).

### RN-002: Solo Fechas Finalizadas
**Contexto**: Para estadisticas precisas.
**Restriccion**: Solo contar fechas con estado = 'finalizada'.
**Validacion**: WHERE estado = 'finalizada'.
**Caso especial**: Fechas canceladas o en curso no se cuentan.

### RN-003: Goleador del Mes
**Contexto**: Determinar maximo anotador mensual.
**Restriccion**: El jugador con mas goles validos en fechas finalizadas del mes.
**Validacion**: COUNT goles WHERE anulado=false AND es_autogol=false GROUP BY jugador_id ORDER BY COUNT DESC.
**Caso especial**: Si hay empate, mostrar todos como co-goleadores del mes.

### RN-004: Jugador Mas Constante
**Contexto**: Reconocer asistencia.
**Restriccion**: El jugador que asistio a mas fechas del mes (inscripcion activa).
**Validacion**: COUNT DISTINCT fecha_id WHERE inscripcion.estado='inscrito' GROUP BY usuario_id.
**Caso especial**: Desempate por: mas goles > fecha registro mas antigua.

### RN-005: Asistentes Unicos del Mes
**Contexto**: Contar participantes.
**Restriccion**: Contar jugadores DISTINTOS que asistieron al menos a 1 fecha del mes.
**Validacion**: COUNT DISTINCT usuario_id FROM inscripciones WHERE estado='inscrito'.
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
**Caso especial**: Mostrar top 5, no ranking completo.

### RN-008: Restriccion por Plan
**Contexto**: Feature flag de stats avanzadas.
**Restriccion**:
  - Plan Gratis: NO tiene acceso a estadisticas mensuales (mostrar pantalla de upgrade)
  - Plan 5+: Acceso completo a todas las estadisticas mensuales
**Validacion**: Verificar plan del usuario via limites_plan.stats_avanzadas.
**Caso especial**: Si el admin baja a plan Gratis, redirigir a pantalla de upgrade con UpgradeReason.statsAvanzadas.

---

## Notas Tecnicas
- Refinado por @negocio-deportivo-expert
- Depende de E006-HU-001 (ranking goleadores) y E006-HU-002 (ranking puntos) para rankings mensuales
- Depende de E007 (fechas, inscripciones) y E004 (partidos, goles)

---

## FASE 2: Diseno Backend
**Responsable**: supabase-expert
**Status**: Completado
**Fecha**: 2026-02-23

### Funciones RPC Implementadas

**`obtener_estadisticas_mensuales(p_grupo_id UUID, p_anio INTEGER DEFAULT NULL, p_mes INTEGER DEFAULT NULL) -> JSONB`**
- **Descripcion**: Retorna estadisticas agregadas por mes para un grupo deportivo
- **Reglas de Negocio**: RN-001 a RN-008 (todas)
- **Parametros**:
  - `p_grupo_id`: UUID - ID del grupo deportivo
  - `p_anio`: INTEGER (opcional) - Ano a consultar. Si NULL, usa ano actual (America/Lima)
  - `p_mes`: INTEGER (opcional) - Mes a consultar (1-12). Si NULL, usa mes actual (America/Lima)
- **Response Success**:
  ```json
  {
    "success": true,
    "data": {
      "periodo": {"anio": 2026, "mes": 2, "nombre_mes": "Febrero"},
      "resumen": {"fechas_jugadas": 4, "total_partidos": 12, "total_goles": 35, "asistentes_unicos": 18},
      "goleador_mes": [{"jugador_id": "...", "nombre": "...", "apodo": "...", "foto_url": "...", "goles": 8, "promedio_por_fecha": 2.0}],
      "jugador_constante": {"jugador_id": "...", "nombre": "...", "apodo": "...", "fechas_asistidas": 4},
      "ranking_goleadores": [{"posicion": 1, "jugador_id": "...", "nombre": "...", "apodo": "...", "goles": 8}],
      "ranking_puntos": [{"posicion": 1, "jugador_id": "...", "nombre": "...", "apodo": "...", "puntos": 12}],
      "comparativa": {"fechas_actual": 4, "fechas_anterior": 3, "dif_fechas": 1, "goles_actual": 35, "goles_anterior": 28, "dif_goles": 7, "asistentes_actual": 18, "asistentes_anterior": 15, "dif_asistentes": 3, "porcentaje_fechas": 33.3, "porcentaje_goles": 25.0, "porcentaje_asistentes": 20.0},
      "fechas_mes": [{"fecha_id": "...", "fecha_formato": "15/02/2026", "lugar": "Cancha X", "total_partidos": 3, "total_goles": 10}],
      "meses_disponibles": [{"anio": 2026, "mes": 2, "nombre_mes": "Febrero"}]
    },
    "message": "Estadisticas de Febrero 2026"
  }
  ```
- **Response Error - Hints**:
  - `no_autenticado` -> Usuario no tiene sesion activa
  - `usuario_no_encontrado` -> Usuario no existe o no aprobado
  - `no_miembro_grupo` -> No es miembro activo del grupo
  - `invitado_sin_acceso` -> Invitados no pueden ver estadisticas
  - `plan_gratis` -> Plan Gratis no tiene acceso (code: PLAN_GRATIS)

### Notas de Implementacion
- **goleador_mes** es un ARRAY: si hay empate en goles, retorna TODOS los co-goleadores
- **goleador_mes** = null si no hubo goles en el mes
- **jugador_constante** = null si no hubo asistencias
- **comparativa** = null si no hay datos del mes anterior
- **porcentaje_***: null cuando anterior=0 y actual>0 (UI muestra "Nuevo")
- Nombres de meses hardcodeados en espanol (no depende de locale del servidor)

### Script SQL
- `supabase/sql-cloud/2026-02-23_E006-HU-005_estadisticas_mensuales.sql`

### Criterios de Aceptacion Backend
- [x] **CA-001**: Parametros p_anio/p_mes opcionales (default=mes actual) + meses_disponibles en response
- [x] **CA-002**: Resumen con fechas_jugadas, total_partidos, total_goles, asistentes_unicos
- [x] **CA-003**: Goleador del mes con foto, apodo, goles, promedio_por_fecha. Co-goleadores si empate
- [x] **CA-004**: ranking_goleadores top 5 + ranking_puntos top 5 con RANK()
- [x] **CA-005**: Comparativa con diferencias absolutas y porcentuales. null si no hay mes anterior
- [x] **CA-006**: Jugador constante con desempate por goles > fecha registro mas antigua
- [x] **CA-007**: Lista fechas_mes con fecha_formato, lugar, total_partidos, total_goles
- [x] **CA-008**: Mes sin actividad retorna resumen en ceros + message "No hubo actividad en [Mes Ano]"

## FASE 3: Implementacion Frontend
**Responsable**: flutter-expert
**Status**: Completado
**Fecha**: 2026-02-23

### Archivos Nuevos
- `lib/features/estadisticas/data/models/estadisticas_mensuales_model.dart` - 8 modelos Equatable
- `lib/features/estadisticas/presentation/bloc/estadisticas_mensuales/estadisticas_mensuales_event.dart` - CargarEstadisticasMensualesEvent, CambiarMesEvent
- `lib/features/estadisticas/presentation/bloc/estadisticas_mensuales/estadisticas_mensuales_state.dart` - Initial, Loading, Loaded, Error
- `lib/features/estadisticas/presentation/bloc/estadisticas_mensuales/estadisticas_mensuales_bloc.dart` - Maneja carga y cambio de mes
- `lib/features/estadisticas/presentation/bloc/estadisticas_mensuales/estadisticas_mensuales.dart` - Barrel
- `lib/features/estadisticas/presentation/pages/estadisticas_mensuales_page.dart` - Pagina completa con todos los CAs

### Archivos Modificados
- `lib/features/estadisticas/data/models/models.dart` - Export del nuevo modelo
- `lib/features/estadisticas/data/datasources/estadisticas_remote_datasource.dart` - +1 metodo (obtenerEstadisticasMensuales)
- `lib/features/estadisticas/domain/repositories/estadisticas_repository.dart` - +1 metodo interface
- `lib/features/estadisticas/data/repositories/estadisticas_repository_impl.dart` - +1 metodo impl
- `lib/core/di/injection_container.dart` - +1 bloc (EstadisticasMensualesBloc)
- `lib/core/routing/app_router.dart` - +1 ruta (/estadisticas-mensuales)
- `lib/features/estadisticas/presentation/pages/estadisticas_hub_page.dart` - Habilitado "Estadisticas Mensuales"

### Criterios de Aceptacion Frontend
- [x] **CA-001**: Selector de mes con flechas + bottom sheet con meses disponibles
- [x] **CA-002**: Grid de 4 metricas (pichangas, partidos, goles, asistentes)
- [x] **CA-003**: Card goleador del mes con avatar, apodo, goles, promedio. Co-goleadores si empate
- [x] **CA-004**: Top 5 goleadores + Top 5 puntos en cards separadas
- [x] **CA-005**: Comparativa con flechas arriba/abajo y porcentajes
- [x] **CA-006**: Card jugador mas constante con fechas asistidas
- [x] **CA-007**: Lista de fechas del mes con partidos y goles
- [x] **CA-008**: Estado vacio "No hubo actividad en [Mes Ano]"
- [x] **RN-008**: Error plan_gratis redirige a pantalla de upgrade

---
**Creado**: 2025-01-15
**Refinado**: 2026-02-02
**Implementado**: 2026-02-23
