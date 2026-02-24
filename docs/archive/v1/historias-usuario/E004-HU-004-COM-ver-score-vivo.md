# E004-HU-004 - Ver Score en Vivo

## Informacion General
- **Epica**: E004 - Partidos en Vivo
- **Estado**: ✅ Completada (COM)
- **Prioridad**: Alta
- **Dependencia**: E004-HU-003 (Registrar Gol)

## Historia de Usuario
**Como** usuario
**Quiero** ver el marcador actual del partido
**Para** saber como va el juego en tiempo real

## Descripcion
Muestra el score actualizado del partido en curso. Todos los usuarios inscritos a la fecha pueden ver el marcador sin necesidad de refrescar la pantalla.

## Criterios de Aceptacion (CA)

### CA-001: Marcador visible
- **Dado** que hay un partido en curso
- **Cuando** veo la pantalla
- **Entonces** veo el marcador: Equipo1 [goles] - [goles] Equipo2

### CA-002: Colores de equipo
- **Dado** que veo el marcador
- **Cuando** observo los equipos
- **Entonces** cada equipo se muestra con su color (Naranja, Verde, Azul)

### CA-003: Actualizacion en tiempo real
- **Dado** que se registra un gol
- **Cuando** veo el marcador
- **Entonces** se actualiza inmediatamente sin recargar

### CA-004: Lista de goles
- **Dado** que quiero ver detalle
- **Cuando** accedo al detalle del partido
- **Entonces** veo lista de goles con: jugador, minuto, equipo

### CA-005: Tiempo restante
- **Dado** que veo el marcador
- **Cuando** el partido esta en curso
- **Entonces** tambien veo el tiempo restante junto al score

### CA-006: Indicador de equipo ganando
- **Dado** que un equipo va ganando
- **Cuando** veo el marcador
- **Entonces** el equipo con ventaja se destaca visualmente

### CA-007: Empate visible
- **Dado** que el partido va empatado
- **Cuando** veo el marcador
- **Entonces** se indica claramente que van empatados

## 📐 Reglas de Negocio (RN)

### RN-001: Acceso universal al score
**Contexto**: Al visualizar el marcador
**Restriccion**: Cualquier usuario inscrito puede ver el score
**Validacion**: No requiere permisos especiales
**Caso especial**: Usuarios no inscritos pueden ver pero no los detalles

### RN-002: Actualizacion instantanea
**Contexto**: Cuando se registra un gol
**Restriccion**: El marcador debe reflejar el cambio inmediatamente
**Validacion**: Maximo 2 segundos de delay
**Caso especial**: Si hay problemas de conexion, mostrar indicador de "sincronizando"

### RN-003: Score oficial desde servidor
**Contexto**: Al mostrar el marcador
**Restriccion**: El score mostrado es el registrado en el sistema
**Validacion**: No hay scores "locales", siempre es el del servidor
**Caso especial**: Si no hay conexion, mostrar ultimo score conocido con advertencia

### RN-004: Formato de marcador estandar
**Contexto**: Al presentar el score
**Restriccion**: Formato consistente: EQUIPO_LOCAL [goles] - [goles] EQUIPO_VISITANTE
**Validacion**: Colores visibles, numeros grandes y legibles
**Caso especial**: El equipo que selecciono primero el admin es "local"

### RN-005: Detalle de goles cronologico
**Contexto**: Al ver lista de goles
**Restriccion**: Goles ordenados por minuto de anotacion
**Validacion**: Mostrar: minuto, nombre jugador, equipo, tipo (normal/autogol)
**Caso especial**: Goles sin asignar muestran "Gol de [EQUIPO]"

### RN-006: Indicadores visuales de estado
**Contexto**: Al mostrar el marcador
**Restriccion**: El estado del partido debe ser evidente
**Validacion**:
  - Partido en curso: indicador verde pulsante
  - Partido pausado: indicador amarillo
  - Tiempo extra: indicador rojo
  - Partido finalizado: sin indicador de "en vivo"

### RN-007: Goles recientes destacados
**Contexto**: Cuando se anota un gol
**Restriccion**: Notificar visualmente el gol reciente
**Validacion**: Animacion o highlight durante 5 segundos
**Caso especial**: Sonido opcional si el usuario lo tiene activado

---
**Creado**: 2025-01-15
**Refinado**: 2026-01-29

---
## FASE 2: Diseno Backend
**Responsable**: supabase-expert
**Status**: Completado
**Fecha**: 2026-01-30

### Cambios en Tabla Existente

**Tabla `partidos`** - Columnas agregadas:
| Columna | Tipo | Descripcion |
|---------|------|-------------|
| `goles_local` | INTEGER DEFAULT 0 | Goles del equipo local (desnormalizado) |
| `goles_visitante` | INTEGER DEFAULT 0 | Goles del equipo visitante (desnormalizado) |

### Nueva Tabla Creada

**Tabla `goles`**
| Columna | Tipo | Descripcion |
|---------|------|-------------|
| `id` | UUID PK | Identificador unico |
| `partido_id` | UUID FK | Referencia al partido |
| `equipo` | color_equipo | Color del equipo que anota |
| `usuario_id` | UUID FK (nullable) | Jugador que anoto (NULL = sin asignar) |
| `minuto` | INTEGER | Minuto del partido |
| `es_autogol` | BOOLEAN | True si es gol en contra |
| `created_at` | TIMESTAMPTZ | Timestamp de registro |
| `created_by` | UUID FK | Admin que registro |
| `anulado` | BOOLEAN | True si fue anulado |
| `anulado_at` | TIMESTAMPTZ | Timestamp de anulacion |
| `anulado_por` | UUID FK | Admin que anulo |

### Funcion RPC Implementada

**`obtener_score_partido(p_partido_id UUID) -> JSON`**
- **Descripcion**: Obtiene score actual, lista de goles y estado del partido
- **Reglas de Negocio**: RN-001, RN-003, RN-004, RN-005, RN-006, RN-007
- **Parametros**:
  - `p_partido_id`: UUID - ID del partido a consultar
- **Response Success**:
  ```json
  {
    "success": true,
    "data": {
      "score": {
        "goles_local": 2,
        "goles_visitante": 1,
        "marcador_formato": "2 - 1"
      },
      "equipo_local": {
        "color": "naranja",
        "goles": 2,
        "ganando": true
      },
      "equipo_visitante": {
        "color": "verde",
        "goles": 1,
        "ganando": false
      },
      "indicadores": {
        "quien_gana": "local",
        "es_empate": false,
        "diferencia_goles": 1,
        "equipo_ganando_color": "naranja"
      },
      "tiempo": {
        "restante_segundos": 300,
        "restante_formato": "05:00",
        "transcurrido_segundos": 300,
        "transcurrido_formato": "05:00",
        "minuto_actual": 5,
        "duracion_minutos": 10,
        "tiempo_extra": false
      },
      "estado": {
        "codigo": "en_curso",
        "indicador": "en_vivo",
        "color": "verde",
        "en_curso": true,
        "pausado": false,
        "finalizado": false
      },
      "goles": {
        "lista": [...],
        "total": 3
      },
      "gol_reciente": {
        "hay_gol_reciente": true,
        "ultimo_gol": {...}
      },
      "permisos": {
        "es_admin": true,
        "puede_registrar_gol": true
      }
    },
    "message": "NARANJA 2 - 1 VERDE"
  }
  ```
- **Response Error - Hints**:
  - `no_autenticado` -> Usuario no ha iniciado sesion
  - `partido_id_requerido` -> Falta parametro p_partido_id
  - `usuario_no_encontrado` -> Usuario no existe en tabla usuarios
  - `partido_no_encontrado` -> Partido con ese ID no existe

### Realtime Habilitado

- Tabla `goles` agregada a `supabase_realtime` publication
- Permite actualizaciones instantaneas (RN-002: max 2 seg delay)
- Frontend debe suscribirse a cambios en tabla `goles` filtrado por `partido_id`

### RLS (Row Level Security)

**Tabla `goles`**:
- SELECT: Todos los usuarios autenticados (RN-001: acceso universal)
- INSERT/UPDATE/DELETE: Solo admins aprobados

### Indices Creados

- `idx_goles_partido_id` - Busqueda por partido
- `idx_goles_partido_activos` - Goles no anulados por partido y minuto
- `idx_goles_usuario_id` - Estadisticas por jugador
- `idx_goles_created_at` - Goles recientes

### Script SQL
- `supabase/sql-cloud/2026-01-30_E004-HU-004_ver_score_vivo.sql`

### Criterios de Aceptacion Backend
- [x] **CA-001**: Score visible via `obtener_score_partido` -> data.score
- [x] **CA-002**: Colores de equipo en data.equipo_local.color y data.equipo_visitante.color
- [x] **CA-003**: Realtime habilitado en tabla goles
- [x] **CA-004**: Lista de goles en data.goles.lista con jugador, minuto, equipo, es_autogol
- [x] **CA-005**: Tiempo restante en data.tiempo.restante_formato
- [x] **CA-006**: Indicador quien gana en data.indicadores.quien_gana
- [x] **CA-007**: Empate visible en data.indicadores.es_empate

### Reglas de Negocio Backend
- [x] **RN-001**: Acceso universal - todos los autenticados pueden ver (RLS SELECT)
- [x] **RN-002**: Realtime habilitado para actualizacion instantanea
- [x] **RN-003**: Score oficial desde servidor (columnas goles_local/goles_visitante en partidos)
- [x] **RN-004**: Formato estandar en data.score.marcador_formato
- [x] **RN-005**: Goles ordenados por minuto en data.goles.lista
- [x] **RN-006**: Indicadores visuales en data.estado.indicador y data.estado.color
- [x] **RN-007**: Gol reciente en data.gol_reciente.hay_gol_reciente (ultimos 5 segundos)

---
## FASE 3: Implementacion Frontend
**Responsable**: flutter-expert
**Status**: Completado
**Fecha**: 2026-01-30

### Archivos Creados

**Models (data/models/)**
| Archivo | Descripcion |
|---------|-------------|
| `equipo_score_model.dart` | Modelo de equipo con score para marcador |
| `score_partido_model.dart` | Modelo principal del score con goles, tiempo, indicadores |
| `score_partido_response_model.dart` | Response del RPC obtener_score_partido |

**BLoC (presentation/bloc/score/)**
| Archivo | Descripcion |
|---------|-------------|
| `score_event.dart` | Eventos: CargarScore, ScoreActualizado, ActualizarTiempo, SuscribirseRealtime |
| `score_state.dart` | Estados: ScoreInitial, ScoreLoading, ScoreLoaded, ScoreError |
| `score_bloc.dart` | BLoC con suscripcion Supabase Realtime a tabla goles |
| `score.dart` | Barrel file |

**Widgets (presentation/widgets/)**
| Archivo | Descripcion |
|---------|-------------|
| `score_marcador_widget.dart` | Marcador con colores, tiempo, indicador ganador |
| `lista_goles_widget.dart` | Lista de goles con minuto, jugador, color equipo |
| `score_en_vivo_widget.dart` | Widget integrador con ScoreBloc |

### Archivos Modificados

| Archivo | Cambios |
|---------|---------|
| `data/datasources/partidos_remote_datasource.dart` | Agregado metodo `obtenerScorePartido()` |
| `domain/repositories/partidos_repository.dart` | Agregada interfaz `obtenerScorePartido()` |
| `data/repositories/partidos_repository_impl.dart` | Agregada implementacion |
| `data/models/models.dart` | Exports de nuevos modelos |
| `presentation/widgets/widgets.dart` | Exports de nuevos widgets |
| `core/di/injection_container.dart` | Registrado ScoreBloc (linea 212) |

### Criterios de Aceptacion Frontend
- [x] **CA-001**: ScoreMarcadorWidget muestra goles_local - goles_visitante
- [x] **CA-002**: Colores de equipo con ColorEquipo (naranja, verde, azul)
- [x] **CA-003**: Realtime via Supabase subscription en ScoreBloc
- [x] **CA-004**: ListaGolesWidget con minuto, jugador, equipo
- [x] **CA-005**: Tiempo restante integrado en ScoreMarcadorWidget
- [x] **CA-006**: Indicador visual de equipo ganando (borde/glow)
- [x] **CA-007**: Empate visible con indicador "EMPATE"

---
## FASE 4: Mejoras UX/UI
**Responsable**: ux-ui-expert
**Status**: Completado
**Fecha**: 2026-01-30

### Mejoras Implementadas

**ScoreMarcadorWidget**
- RN-006: Indicador pulsante de estado del partido (EN VIVO verde, PAUSADO amarillo, TIEMPO EXTRA rojo)
- Animacion de pulso para gol reciente
- Icono contextual segun estado

**ListaGolesWidget**
- RN-007: Animacion highlight para goles recientes (5 segundos)
- Badge "GOL!" animado con escala y glow
- Indicador visual mejorado para autogoles
- Display de minuto con gradiente y fuente monoespaciada

---
## FASE 5: Validacion QA
**Responsable**: qa-testing-expert
**Status**: Aprobado
**Fecha**: 2026-01-30

### Verificaciones Realizadas

| Verificacion | Resultado |
|--------------|-----------|
| Archivos SQL | EXISTE |
| Modelos Flutter | EXISTEN |
| BLoC Score | EXISTE |
| Widgets | EXISTEN |
| Exports correctos | SI |
| DI registrado | SI |
| `flutter analyze` | 0 errores |
| `flutter build web --release` | PASS |

### Build Output
- Archivo: `gestion_deportiva/build/web`
- Tiempo: 187.6s
- Estado: Exitoso

---
## Paso Pendiente: Deploy SQL

**Ejecutar manualmente en Supabase:**
1. Ir a: https://supabase.com/dashboard/project/tvvubzkqbksxvcjvivij/sql
2. Abrir archivo: `supabase/sql-cloud/2026-01-30_E004-HU-004_ver_score_vivo.sql`
3. Copiar contenido y ejecutar
4. Verificar que se creo tabla `goles` y funcion `obtener_score_partido`

---
**Completado**: 2026-01-30
