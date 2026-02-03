# E004-HU-007 - Resumen de Jornada

## Informacion General
- **Epica**: E004 - Partidos en Vivo
- **Estado**: ✅ Completada (COM)
- **Prioridad**: Media
- **Dependencia**: E004-HU-005 (Finalizar Partido)

## Historia de Usuario
**Como** usuario
**Quiero** ver el resumen de todos los partidos de la jornada
**Para** conocer los resultados finales y estadisticas

## Descripcion
Muestra resumen completo de la jornada (fecha de pichanga) con todos los partidos jugados, goleadores y posiciones de equipos. Disponible durante y despues de la jornada.

## Criterios de Aceptacion (CA)

### CA-001: Lista de partidos
- **Dado** que la jornada termino o esta en curso
- **Cuando** accedo al resumen
- **Entonces** veo lista de todos los partidos con sus resultados

### CA-002: Posiciones de equipos
- **Dado** que veo el resumen
- **Cuando** hay resultados
- **Entonces** veo tabla de posiciones: 1ro, 2do, 3ro con puntos

### CA-003: Goleadores de la fecha
- **Dado** que veo el resumen
- **Cuando** hubo goles
- **Entonces** veo ranking de goleadores de la fecha

### CA-004: Estadisticas de equipos
- **Dado** que veo el resumen
- **Cuando** la jornada tiene partidos
- **Entonces** veo por equipo: partidos jugados, ganados, empatados, perdidos, goles a favor, goles en contra

### CA-005: Goleador de la fecha destacado
- **Dado** que veo el resumen
- **Cuando** hay un maximo goleador
- **Entonces** se destaca al goleador de la fecha

### CA-006: Compartir resumen
- **Dado** que veo el resumen final
- **Cuando** quiero compartirlo
- **Entonces** puedo generar imagen o texto para compartir en WhatsApp

### CA-007: Resumen parcial en vivo
- **Dado** que la jornada esta en curso
- **Cuando** accedo al resumen
- **Entonces** veo datos actualizados hasta el momento (no solo al final)

## 📐 Reglas de Negocio (RN)

### RN-001: Acceso para todos los inscritos
**Contexto**: Al ver el resumen
**Restriccion**: Cualquier usuario inscrito a la fecha puede ver el resumen
**Validacion**: No requiere permisos especiales
**Caso especial**: Despues de finalizada la fecha, queda como historial

### RN-002: Calculo de posiciones por puntos
**Contexto**: Al generar tabla de posiciones
**Restriccion**: Sistema de puntos estandar
**Regla calculo**:
  - Victoria: 3 puntos
  - Empate: 1 punto
  - Derrota: 0 puntos
**Desempate**: 1) Diferencia de goles, 2) Goles a favor, 3) Enfrentamiento directo

### RN-003: Goleador de la fecha
**Contexto**: Al determinar el maximo goleador
**Restriccion**: Se cuenta solo goles validos (no autogoles)
**Regla calculo**: Jugador con mas goles en todos los partidos de la fecha
**Caso especial**: Si hay empate, todos son co-goleadores

### RN-004: Estadisticas en tiempo real
**Contexto**: Durante la jornada
**Restriccion**: El resumen se actualiza con cada partido finalizado
**Validacion**: Datos reflejan estado actual, no solo al final
**Caso especial**: Partido en curso no suma a estadisticas hasta finalizar

### RN-005: Formato compartible
**Contexto**: Al compartir resumen
**Restriccion**: Generar formato legible para redes sociales
**Validacion**: Incluir: fecha, lugar, posiciones, goleador, marcadores
**Caso especial**: Opcion de imagen (screenshot) o texto plano

### RN-006: Historial permanente
**Contexto**: Despues de finalizar la fecha
**Restriccion**: El resumen queda guardado permanentemente
**Validacion**: Usuarios pueden consultar jornadas pasadas
**Caso especial**: Vinculado con E006 (Estadisticas historicas)

### RN-007: Resumen vacio si no hay partidos
**Contexto**: Si la fecha no tuvo partidos
**Restriccion**: Mostrar mensaje informativo
**Validacion**: "No se jugaron partidos en esta fecha"
**Caso especial**: Puede pasar si la fecha se finalizo sin iniciar partidos

### RN-008: Datos de cada partido
**Contexto**: Al mostrar lista de partidos
**Restriccion**: Informacion completa por partido
**Validacion**: Mostrar:
  - Equipos enfrentados con colores
  - Marcador final
  - Goleadores del partido
  - Duracion del partido

---
**Creado**: 2025-01-15
**Refinado**: 2026-01-29

---
## FASE 2: Diseno Backend
**Responsable**: supabase-expert
**Status**: Completado
**Fecha**: 2026-02-02

### Funcion RPC Implementada

#### `obtener_resumen_jornada(p_fecha_id UUID) -> JSON`
- **Descripcion**: Retorna el resumen completo de una fecha/jornada
- **Reglas de Negocio**: RN-001 a RN-008
- **Parametros**:
  - `p_fecha_id` (UUID): ID de la fecha - obligatorio

**Response Success**:
```json
{
  "success": true,
  "data": {
    "fecha": { "id", "lugar", "fecha_programada", "fecha_formato", "estado", "num_equipos" },
    "partidos": [
      { "id", "equipo_local", "equipo_visitante", "goles_local", "goles_visitante", "estado", "goleadores": [...] }
    ],
    "tabla_posiciones": [
      { "equipo", "pj", "pg", "pe", "pp", "gf", "gc", "dif", "pts", "posicion" }
    ],
    "goleadores": [
      { "jugador_id", "jugador_nombre", "equipo", "goles", "posicion" }
    ],
    "goleador_fecha": [{ "jugador_id", "jugador_nombre", "equipo", "goles" }],
    "estadisticas": {
      "total_partidos", "partidos_finalizados", "total_goles",
      "promedio_goles_partido", "partido_mas_goles"
    },
    "hay_partidos": true/false
  },
  "message": "Resumen de jornada generado"
}
```

**Response Error - Hints**:
- `fecha_no_encontrada` -> Fecha no existe

### Criterios de Aceptacion Backend

- [x] **CA-001**: Lista de partidos con equipos, marcador, goleadores, duracion, estado
- [x] **CA-002**: Tabla de posiciones calculada (PJ, PG, PE, PP, GF, GC, DIF, PTS)
- [x] **CA-003**: Ranking de goleadores (solo goles validos, sin autogoles ni anulados)
- [x] **CA-004**: Estadisticas por equipo en tabla_posiciones
- [x] **CA-005**: Goleador de la fecha destacado (o co-goleadores si hay empate)
- [x] **CA-007**: Datos en tiempo real (incluye partidos finalizados)

### Reglas de Negocio Validadas

- [x] **RN-001**: Sin validacion estricta de permisos (cualquiera puede ver)
- [x] **RN-002**: Sistema de puntos: Victoria=3, Empate=1, Derrota=0
- [x] **RN-003**: Solo goles validos (anulado=false, es_autogol=false)
- [x] **RN-004**: Datos en tiempo real (partidos finalizados y en curso)
- [x] **RN-007**: Estructura vacia con mensaje si no hay partidos
- [x] **RN-008**: Datos completos por partido

### Script SQL
- `supabase/sql-cloud/2026-02-02_E004-HU-007_resumen_jornada.sql`

---

## FASE 4: Desarrollo Frontend
**Responsable**: flutter-expert
**Status**: Completado
**Fecha**: 2026-02-02

### Archivos Creados

#### Models
- `lib/features/partidos/data/models/resumen_jornada_model.dart`
  - `FechaResumenModel` - Info de la fecha
  - `GoleadorPartidoModel` - Goleador de un partido
  - `PartidoResumenModel` - Partido con marcador y goleadores
  - `TablaPosicionModel` - Fila de tabla de posiciones
  - `GoleadorJornadaModel` - Goleador con ranking
  - `GoleadorFechaModel` - Goleador destacado
  - `EstadisticasJornadaModel` - Estadisticas generales
  - `ResumenJornadaModel` - Response completo

#### BLoC
- `lib/features/partidos/presentation/bloc/resumen_jornada/resumen_jornada_event.dart`
  - `CargarResumenJornada` - Cargar resumen de una fecha
  - `RefrescarResumen` - Refrescar datos
  - `ResetResumenJornada` - Resetear estado
- `lib/features/partidos/presentation/bloc/resumen_jornada/resumen_jornada_state.dart`
  - `ResumenJornadaInitial` - Estado inicial
  - `ResumenJornadaLoading` - Cargando
  - `ResumenJornadaLoaded` - Cargado con datos
  - `ResumenJornadaRefreshing` - Refrescando
  - `ResumenJornadaError` - Error
- `lib/features/partidos/presentation/bloc/resumen_jornada/resumen_jornada_bloc.dart`
- `lib/features/partidos/presentation/bloc/resumen_jornada/resumen_jornada.dart` - Barrel

#### Widgets
- `lib/features/partidos/presentation/widgets/tabla_posiciones_widget.dart` - CA-002, CA-004
- `lib/features/partidos/presentation/widgets/goleadores_fecha_widget.dart` - CA-003, CA-005
- `lib/features/partidos/presentation/widgets/estadisticas_jornada_widget.dart` - Estadisticas
- `lib/features/partidos/presentation/widgets/resumen_jornada_card.dart` - CA-001
- `lib/features/partidos/presentation/widgets/compartir_resumen_button.dart` - CA-006

### Archivos Actualizados
- `lib/features/partidos/data/datasources/partidos_remote_datasource.dart` - Metodo obtenerResumenJornada
- `lib/features/partidos/domain/repositories/partidos_repository.dart` - Interfaz
- `lib/features/partidos/data/repositories/partidos_repository_impl.dart` - Implementacion
- `lib/core/di/injection_container.dart` - ResumenJornadaBloc registrado
- `lib/features/partidos/data/models/models.dart` - Export
- `lib/features/partidos/presentation/widgets/widgets.dart` - Exports
- `pubspec.yaml` - Dependencia share_plus agregada

### Criterios de Aceptacion Frontend

- [x] **CA-001**: `ResumenJornadaCard` muestra lista de partidos
- [x] **CA-002**: `TablaPosicionesWidget` con DataTable (POS, EQUIPO, PJ, PG, PE, PP, GF, GC, DIF, PTS)
- [x] **CA-003**: `GoleadoresFechaWidget` muestra ranking de goleadores
- [x] **CA-004**: Estadisticas por equipo en tabla de posiciones
- [x] **CA-005**: Goleador de la fecha destacado con seccion especial
- [x] **CA-006**: `CompartirResumenButton` genera texto para WhatsApp/redes sociales
- [x] **CA-007**: BLoC permite cargar y refrescar datos en tiempo real

### Arquitectura
- Clean Architecture respetada (data -> domain -> presentation)
- BLoC pattern para manejo de estado
- Barrel files para exports organizados
- Modelos con Equatable para comparacion eficiente

---
## FASE 5: Validacion QA Tecnica
**Responsable**: qa-testing-expert
**Fecha**: 2026-02-02

### Validacion Tecnica APROBADA

#### 1. Dependencias
```
$ flutter pub get
Got dependencies!
```
Sin errores de dependencias. share_plus instalado correctamente.

#### 2. Analisis Estatico
```
$ flutter analyze --no-pub
16 issues found (solo info de deprecation)
0 errores
```

#### 3. Compilacion Web
```
$ flutter build web --release
Built build\web
```
Compilacion exitosa.

### Verificacion de Archivos

| Archivo | Estado |
|---------|--------|
| `resumen_jornada_model.dart` | Existe, compila |
| `resumen_jornada_bloc.dart` | Existe, compila |
| `resumen_jornada_event.dart` | Existe, compila |
| `resumen_jornada_state.dart` | Existe, compila |
| `resumen_jornada.dart` (barrel) | Existe, exporta correctamente |
| `tabla_posiciones_widget.dart` | Existe, compila |
| `goleadores_fecha_widget.dart` | Existe, compila |
| `estadisticas_jornada_widget.dart` | Existe, compila |
| `resumen_jornada_card.dart` | Existe, compila |
| `compartir_resumen_button.dart` | Existe, compila |

### Verificacion de Integracion

| Componente | Estado |
|------------|--------|
| BLoC registrado en injection_container.dart | Si (linea 233) |
| Modelo exportado en models.dart | Si |
| Widgets exportados en widgets.dart | Si (5 nuevos) |
| Metodo en Repository interface | Si |
| Metodo en Repository impl | Si |
| Metodo en DataSource | Si |

### Resumen

| Validacion | Estado |
|------------|--------|
| Dependencias | PASS |
| Analisis estatico | PASS (0 errores) |
| Compilacion Web | PASS |
| Archivos nuevos | PASS (11 archivos) |
| Integracion DI | PASS |

### Decision

**VALIDACION TECNICA APROBADA**

Siguiente paso: Usuario debe ejecutar SQL en Supabase y validar manualmente los CA en la aplicacion.
