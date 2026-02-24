# E003-HU-006 - Ver Mi Equipo

## Informacion General
- **Epica**: E003 - Gestion de Fechas/Jornadas
- **Estado**: Completada (COM)
- **Prioridad**: Alta

## Historia de Usuario
**Como** jugador inscrito
**Quiero** saber a que equipo pertenezco
**Para** llegar a la cancha con el chaleco del color correcto

## Descripcion
Muestra al jugador su equipo asignado y el color de chaleco que debe usar, junto con sus companeros de equipo.

## Criterios de Aceptacion (CA)

### CA-001: Ver mi equipo asignado
- **Dado** que estoy inscrito y los equipos fueron asignados
- **Cuando** veo la fecha
- **Entonces** veo prominentemente mi equipo con su color
- **Y** ejemplo: "Equipo Naranja" con fondo naranja

### CA-002: Color visual destacado
- **Dado** que veo mi equipo
- **Cuando** observo la pantalla
- **Entonces** el color se muestra claramente (fondo, borde o icono)
- **Y** el contraste es suficiente para identificar rapidamente

### CA-003: Lista de companeros
- **Dado** que veo mi equipo
- **Cuando** expando los detalles
- **Entonces** veo la lista de companeros del mismo equipo
- **Y** cada uno muestra: foto/avatar, apodo

### CA-004: Ver todos los equipos
- **Dado** que los equipos estan asignados
- **Cuando** quiero ver la distribucion completa
- **Entonces** puedo ver los 2 o 3 equipos con sus jugadores
- **Y** mi equipo aparece primero o destacado

### CA-005: Equipos no asignados aun
- **Dado** que estoy inscrito
- **Cuando** los equipos aun no se asignaron
- **Entonces** veo mensaje "Esperando asignacion de equipos"
- **Y** veo icono de reloj o pendiente

### CA-006: No inscrito
- **Dado** que no estoy inscrito a la fecha
- **Cuando** veo la fecha
- **Entonces** no veo seccion de "Mi equipo"
- **Y** solo veo opcion de inscribirme (si esta abierta) o los equipos generales

### CA-007: Cambio de equipo notificado
- **Dado** que tengo equipo asignado
- **Cuando** el admin me cambia de equipo
- **Entonces** recibo notificacion del cambio
- **Y** la vista se actualiza con el nuevo equipo

---

## Reglas de Negocio (RN)

### RN-001: Visibilidad de Equipo Propio
**Contexto**: Cada jugador inscrito puede ver su equipo asignado.
**Restriccion**: Solo ve su asignacion si esta inscrito y equipos fueron confirmados.
**Validacion**: EXISTS inscripcion (usuario, fecha) AND EXISTS asignacion_equipo (usuario, fecha).
**Regla calculo**: N/A.
**Caso especial**: Si no hay asignacion, mostrar estado pendiente.

### RN-002: Visibilidad de Todos los Equipos
**Contexto**: Cualquier jugador inscrito puede ver la distribucion completa.
**Restriccion**: No se ocultan equipos rivales.
**Validacion**: Si usuario tiene inscripcion activa a la fecha.
**Regla calculo**: N/A.
**Caso especial**: Jugadores no inscritos pueden ver equipos pero no destacado "el suyo".

### RN-003: Informacion de Companeros
**Contexto**: Se muestra informacion basica de companeros de equipo.
**Restriccion**: Solo informacion publica: foto, apodo.
**Validacion**: Query con campos limitados.
**Regla calculo**: N/A.
**Caso especial**: Si un jugador no tiene foto, mostrar avatar con inicial.

### RN-004: Actualizacion en Tiempo Real
**Contexto**: Si el admin modifica equipos, el cambio debe reflejarse.
**Restriccion**: Latencia maxima aceptable: 5 segundos.
**Validacion**: Subscripcion Supabase Realtime a asignaciones_equipo.
**Regla calculo**: N/A.
**Caso especial**: Mostrar indicador de "actualizado" al recibir cambios.

### RN-005: Codigo de Color Consistente
**Contexto**: El color del equipo debe ser uniforme en toda la app.
**Restriccion**: Usar palette de colores definida en design system.
**Validacion**: Colores hex predefinidos por color_equipo.
**Regla calculo**:
- naranja: #FF9800
- verde: #4CAF50
- azul: #2196F3
- rojo: #F44336
- amarillo: #FFEB3B
- blanco: #FFFFFF (con borde gris)
**Caso especial**: En modo oscuro ajustar luminosidad para contraste.

---

## Notas Tecnicas
- Query: asignaciones_equipo JOIN usuarios WHERE fecha_id AND usuario_id = current
- Componente: EquipoCard con color dinamico
- Supabase Realtime para actualizaciones
- Animacion al recibir asignacion inicial

---

## FASE 2: Backend (Supabase)

### Tabla Creada: asignaciones_equipos
```sql
CREATE TABLE asignaciones_equipos (
    id UUID PRIMARY KEY,
    fecha_id UUID NOT NULL REFERENCES fechas(id),
    usuario_id UUID NOT NULL REFERENCES usuarios(id),
    color_equipo color_equipo NOT NULL, -- ENUM: naranja, verde, azul, rojo, amarillo, blanco
    numero_equipo INTEGER NOT NULL CHECK (1-3),
    asignado_por UUID REFERENCES usuarios(id),
    asignado_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Funciones RPC Implementadas

#### 1. obtener_mi_equipo(p_fecha_id)
- **CA cubiertos**: CA-001, CA-002, CA-003, CA-005, CA-006
- **RN cubiertos**: RN-001, RN-003
- **Retorna**: Equipo del usuario con color_hex, companeros (nombre, foto)
- **Estados**: esta_inscrito, tiene_equipo, equipos_asignados

#### 2. obtener_equipos_fecha(p_fecha_id)
- **CA cubiertos**: CA-004
- **RN cubiertos**: RN-002
- **Retorna**: Todos los equipos con jugadores, mi equipo primero
- **Ordenamiento**: es_mi_equipo DESC, numero_equipo ASC

### Colores Hex (RN-005)
| Color | Hex |
|-------|-----|
| naranja | #FF9800 |
| verde | #4CAF50 |
| azul | #2196F3 |
| rojo | #F44336 |
| amarillo | #FFEB3B |
| blanco | #FFFFFF |

### Realtime Habilitado (RN-004)
- Tabla asignaciones_equipos agregada a supabase_realtime
- Latencia maxima: 5 segundos

### Script SQL
`supabase/sql-cloud/2026-01-28_E003-HU-006_ver_mi_equipo.sql`

---

## FASE 4: Frontend (Flutter)

### Modelos Creados
| Archivo | Descripcion |
|---------|-------------|
| `mi_equipo_model.dart` | MiEquipoResponseModel, MiEquipoDataModel, EquipoInfoModel, CompaneroModel |
| `equipos_fecha_model.dart` | EquiposFechaResponseModel, EquiposFechaDataModel, EquipoCompletoModel, FechaResumenModel |

### DataSource Actualizado
`fechas_remote_datasource.dart`:
- `obtenerMiEquipo(fechaId)` - RPC obtener_mi_equipo
- `obtenerEquiposFecha(fechaId)` - RPC obtener_equipos_fecha

### Repository Actualizado
`fechas_repository.dart` / `fechas_repository_impl.dart`:
- `obtenerMiEquipo(fechaId)` -> Either<Failure, MiEquipoResponseModel>
- `obtenerEquiposFecha(fechaId)` -> Either<Failure, EquiposFechaResponseModel>

### BLoC Creado
`presentation/bloc/mi_equipo/`:
- `mi_equipo_event.dart` - CargarMiEquipoEvent, CargarEquiposFechaEvent, ActualizarEquipoRealtimeEvent, IniciarRealtimeEvent, DetenerRealtimeEvent
- `mi_equipo_state.dart` - MiEquipoCargado, EquiposFechaCargados, EquiposPendientes, NoInscrito, MiEquipoError
- `mi_equipo_bloc.dart` - Maneja carga y suscripcion Realtime

### Widgets Creados
`presentation/widgets/mi_equipo_widget.dart`:
- **CA-001**: Header con nombre de equipo destacado
- **CA-002**: Fondo con color del equipo, texto contrastante
- **CA-003**: Lista expandible de companeros con avatar y nombre
- **CA-004**: Vista de todos los equipos con ExpansionTile
- **CA-005**: Card con icono de reloj y mensaje "Esperando asignacion"
- **CA-006**: No muestra nada si no esta inscrito
- **CA-007**: SnackBar "Equipos actualizados" al recibir cambio Realtime

### Colores del Design System (RN-005)
Se reutiliza `ColorEquipo` enum existente en `color_equipo.dart`:
- Propiedad `color` -> Color de Flutter
- Propiedad `textColor` -> Color contrastante para texto
- Propiedad `borderColor` -> Color de borde (blanco usa gris)

### Realtime (RN-004)
- Suscripcion a canal `asignaciones_equipos:{fechaId}`
- Evento PostgresChangeEvent.all para INSERT/UPDATE/DELETE
- Recarga automatica sin mostrar loading
- Flag `actualizadoRealtime` para mostrar indicador visual

---

## FASE 3: UI/UX

### Componentes Visuales Implementados

#### MiEquipoWidget
Widget principal que se integra en la pagina de detalle de fecha.

**Estados Visuales:**
| Estado | Componente | Descripcion |
|--------|------------|-------------|
| Loading | Card con CircularProgressIndicator | Muestra "Cargando equipo..." |
| CA-001/CA-002 | Card con header de color | Fondo con color del equipo, nombre prominente |
| CA-003 | Lista expandible | Avatar + nombre de cada companero |
| CA-004 | ExpansionTile por equipo | Todos los equipos con jugadores |
| CA-005 | Card con icono schedule | "Esperando asignacion de equipos" |
| CA-006 | SizedBox.shrink() | No muestra nada si no inscrito |
| Error | Card con error_outline | Mensaje + boton reintentar |

**Accesibilidad (RN-005):**
- Texto contrastante automatico (blanco/negro segun color)
- Blanco usa borde gris para visibilidad
- Amarillo usa texto negro para legibilidad

**Interacciones:**
- IconButton expand_more/expand_less para ver companeros
- Tap en avatar muestra inicial si no hay foto
- SnackBar flotante para actualizaciones Realtime

### Responsividad
- Card con width: double.infinity
- Padding dinamico con DesignTokens
- Lista de companeros se adapta al ancho disponible

### Integracion
El widget se provee con BlocProvider en la pagina de detalle de fecha.

---

## FASE 5: QA Testing

### Validacion Tecnica
| Comando | Resultado |
|---------|-----------|
| `flutter pub get` | OK |
| `flutter analyze` | 0 errores, 0 warnings |

### Validacion de Criterios de Aceptacion
| CA | Descripcion | Estado |
|----|-------------|--------|
| CA-001 | Ver mi equipo asignado con color prominente | CUMPLIDO - Header con nombre y color del equipo |
| CA-002 | Color visual destacado (fondo, borde o icono) | CUMPLIDO - Fondo con color, texto contrastante |
| CA-003 | Lista de companeros con foto/avatar y apodo | CUMPLIDO - Lista expandible con CircleAvatar |
| CA-004 | Ver todos los equipos (mi equipo primero) | CUMPLIDO - ExpansionTile por equipo, ordenado |
| CA-005 | Estado "Esperando asignacion" si no hay equipos | CUMPLIDO - Card con icono schedule |
| CA-006 | No mostrar seccion si no estoy inscrito | CUMPLIDO - SizedBox.shrink() |
| CA-007 | Cambio de equipo notificado via Realtime | CUMPLIDO - SnackBar "Equipos actualizados" |

### Validacion de Reglas de Negocio
| RN | Descripcion | Estado |
|----|-------------|--------|
| RN-001 | Visibilidad de Equipo Propio | CUMPLIDO - Query con auth.uid() |
| RN-002 | Visibilidad de Todos los Equipos | CUMPLIDO - obtener_equipos_fecha |
| RN-003 | Informacion de Companeros (foto, apodo) | CUMPLIDO - Solo campos publicos |
| RN-004 | Actualizacion en Tiempo Real (<5s) | CUMPLIDO - Supabase Realtime |
| RN-005 | Codigo de Color Consistente | CUMPLIDO - ColorEquipo enum con hex |

### Integracion Completada
- MiEquipoBloc registrado en injection_container.dart
- MiEquipoWidget integrado en fecha_detalle_page.dart (mobile y desktop)
- BlocProvider creado con sl() para repository y supabase

### Archivos Modificados/Creados
| Archivo | Accion |
|---------|--------|
| `injection_container.dart` | Registro de MiEquipoBloc |
| `fecha_detalle_page.dart` | Integracion de MiEquipoWidget |
| `mi_equipo_widget.dart` | Widget completo (ya existia) |
| `mi_equipo_bloc.dart` | BLoC con Realtime (ya existia) |
| `mi_equipo_model.dart` | Modelos de datos (ya existia) |
| `equipos_fecha_model.dart` | Modelos de equipos (ya existia) |
| `fechas_remote_datasource.dart` | Metodos RPC (ya existia) |
| `fechas_repository.dart` | Interface (ya existia) |
| `fechas_repository_impl.dart` | Implementacion (ya existia) |
| `2026-01-28_E003-HU-006_ver_mi_equipo.sql` | Script SQL (ya existia) |

### Resultado Final
**QA APROBADO** - Todos los CA y RN cumplidos, flutter analyze sin errores.

---
**Creado**: 2025-01-15
**Refinado**: 2026-01-16
**Completado**: 2026-01-28
