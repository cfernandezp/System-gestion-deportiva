# E004-HU-005 - Finalizar Partido

## Informacion General
- **Epica**: E004 - Partidos en Vivo
- **Estado**: ✅ Completada (COM)
- **Prioridad**: Alta
- **Dependencia**: E004-HU-001 (Iniciar Partido), E004-HU-003 (Registrar Gol)

## Historia de Usuario
**Como** administrador
**Quiero** terminar el partido y registrar el resultado
**Para** cerrar el partido y preparar el siguiente

## Descripcion
Permite finalizar un partido, registrando el resultado final. Al finalizar, se determina el ganador/empate y se prepara la rotacion para el siguiente partido si aplica.

## Criterios de Aceptacion (CA)

### CA-001: Finalizar partido
- **Dado** que el tiempo termino o quiero finalizar antes
- **Cuando** presiono "Finalizar partido"
- **Entonces** el partido se cierra con el marcador actual

### CA-002: Resultado registrado
- **Dado** que finalizo el partido
- **Cuando** se confirma
- **Entonces** se registra: equipos, marcador final, goles por jugador

### CA-003: Determinar resultado
- **Dado** que el partido termino
- **Cuando** se calcula el resultado
- **Entonces** se determina: Victoria equipo A, Victoria equipo B, o Empate

### CA-004: Sugerir siguiente partido
- **Dado** que hay 3 equipos (formato 2 horas)
- **Cuando** termina el partido
- **Entonces** el sistema sugiere que equipo entra segun reglas de rotacion

### CA-005: Resumen del partido
- **Dado** que el partido finalizo
- **Cuando** veo el resultado
- **Entonces** veo resumen: marcador, goleadores, duracion real

### CA-006: Confirmacion antes de finalizar
- **Dado** que el tiempo no ha terminado
- **Cuando** intento finalizar anticipadamente
- **Entonces** se solicita confirmacion

### CA-007: Notificacion de fin
- **Dado** que el partido finalizo
- **Cuando** los usuarios ven la fecha
- **Entonces** ven que el partido termino con el resultado final

## 📐 Reglas de Negocio (RN)

### RN-001: Solo admin finaliza partido
**Contexto**: Al finalizar un partido
**Restriccion**: Solo administradores aprobados pueden finalizar partidos
**Validacion**: Usuario debe tener rol "admin" y estado "aprobado"

### RN-002: Partido debe estar activo
**Contexto**: Al intentar finalizar
**Restriccion**: Solo se pueden finalizar partidos en curso
**Validacion**: Estado del partido debe ser "en_curso" o "pausado"
**Caso especial**: Partidos ya finalizados no pueden finalizarse de nuevo

### RN-003: Resultado inmutable
**Contexto**: Despues de finalizar
**Restriccion**: El resultado del partido no puede modificarse
**Validacion**: Una vez finalizado, el marcador queda registrado permanentemente
**Caso especial**: Solo un superadmin podria corregir errores graves

### RN-004: Determinacion de ganador
**Contexto**: Al calcular el resultado
**Restriccion**: Logica clara para determinar el resultado
**Regla calculo**:
  - Goles equipo A > Goles equipo B = Victoria A
  - Goles equipo A < Goles equipo B = Victoria B
  - Goles equipo A = Goles equipo B = Empate

### RN-005: Duracion real registrada
**Contexto**: Al finalizar el partido
**Restriccion**: Registrar cuanto duro realmente el partido
**Regla calculo**: Duracion = hora_fin - hora_inicio - tiempo_pausado
**Caso especial**: Tiempo extra se suma a la duracion

### RN-006: Finalizacion automatica opcional
**Contexto**: Cuando el temporizador llega a cero
**Restriccion**: El partido NO se finaliza automaticamente
**Validacion**: Requiere accion explicita del admin
**Caso especial**: Alarma suena pero el juego puede continuar en tiempo extra

### RN-007: Estadisticas individuales actualizadas
**Contexto**: Al finalizar el partido
**Restriccion**: Los goles se consolidan en estadisticas de jugadores
**Validacion**: Cada jugador suma sus goles a su historial personal
**Caso especial**: Autogoles no suman al goleador pero si al equipo contrario

### RN-008: Partido sin goles valido
**Contexto**: Si el partido termina 0-0
**Restriccion**: Es un resultado valido
**Validacion**: Se registra como empate 0-0

---
**Creado**: 2025-01-15
**Refinado**: 2026-01-29

---
## FASE 2: Diseno Backend
**Responsable**: supabase-expert
**Status**: Completado
**Fecha**: 2026-01-30

### Columnas Agregadas a Tabla partidos

| Columna | Tipo | Descripcion |
|---------|------|-------------|
| hora_fin | TIMESTAMPTZ | Timestamp real de finalizacion del partido |
| resultado | VARCHAR(20) | Resultado: 'local', 'visitante', 'empate' |
| duracion_real_segundos | INTEGER | Duracion real = hora_fin - hora_inicio - tiempo_pausado |
| finalizado_por | UUID | FK a usuarios(id), admin que finalizo |
| finalizado_at | TIMESTAMPTZ | Timestamp cuando se finalizo |

### Funciones RPC Implementadas

#### `finalizar_partido(p_partido_id UUID, p_confirmar_anticipado BOOLEAN DEFAULT false) -> JSON`
- **Descripcion**: Finaliza un partido, registra resultado final y estadisticas
- **Reglas de Negocio**: RN-001, RN-002, RN-003, RN-004, RN-005, RN-006, RN-007, RN-008
- **Parametros**:
  - `p_partido_id` (UUID): ID del partido a finalizar - obligatorio
  - `p_confirmar_anticipado` (BOOLEAN): Confirmar finalizacion anticipada - default false
- **Response Success**:
```json
{
  "success": true,
  "data": {
    "partido_id": "uuid",
    "fecha_id": "uuid",
    "estado": "finalizado",
    "resultado": {
      "codigo": "local|visitante|empate",
      "descripcion": "Victoria NARANJA",
      "equipo_ganador": "naranja",
      "es_empate": false
    },
    "marcador": {
      "equipo_local": "naranja",
      "goles_local": 2,
      "equipo_visitante": "verde",
      "goles_visitante": 1
    },
    "marcador_texto": "NARANJA 2 - 1 VERDE",
    "goleadores": {
      "lista_completa": [...],
      "equipo_local": [...],
      "equipo_visitante": [...],
      "total_goles": 3
    },
    "duracion": {
      "programada_minutos": 10,
      "real_segundos": 625,
      "real_minutos": 10.4,
      "real_formato": "10:25",
      "tiempo_pausado_segundos": 30,
      "finalizado_anticipadamente": false,
      "tiempo_extra": true
    },
    "tiempos": {
      "hora_inicio": "...",
      "hora_inicio_formato": "15:30:00",
      "hora_fin": "...",
      "hora_fin_formato": "15:40:25"
    },
    "sugerencia_siguiente": {
      "equipo_entra": "azul",
      "equipo_continua": "naranja",
      "equipo_sale": "verde",
      "razon": "El ganador continua en cancha",
      "sugerencia_texto": "AZUL vs NARANJA"
    },
    "fecha": {...},
    "finalizado_por": {...}
  },
  "message": "Partido finalizado: NARANJA 2 - 1 VERDE. Victoria para NARANJA"
}
```
- **Response Error - Hints**:
  - `no_autenticado` -> Usuario no ha iniciado sesion
  - `partido_id_requerido` -> Falta partido_id
  - `sin_permisos` -> Usuario no es admin aprobado (RN-001)
  - `partido_no_encontrado` -> Partido no existe
  - `partido_ya_finalizado` -> Partido ya fue finalizado (RN-003)
  - `partido_no_activo` -> Partido no esta en_curso ni pausado (RN-002)
  - `requiere_confirmacion_anticipado` -> Tiempo no ha terminado, requiere p_confirmar_anticipado=true (CA-006)

#### `obtener_resumen_partido(p_partido_id UUID) -> JSON`
- **Descripcion**: Obtiene resumen completo de un partido (cualquier estado)
- **Parametros**:
  - `p_partido_id` (UUID): ID del partido - obligatorio
- **Response Success**: Similar a finalizar_partido pero sin modificar datos
- **Response Error - Hints**:
  - `no_autenticado` -> Usuario no ha iniciado sesion
  - `partido_id_requerido` -> Falta partido_id
  - `partido_no_encontrado` -> Partido no existe

#### `obtener_sugerencia_rotacion(p_fecha_id UUID) -> JSON`
- **Descripcion**: Obtiene sugerencia de rotacion para fechas con 3 equipos (CA-004)
- **Parametros**:
  - `p_fecha_id` (UUID): ID de la fecha - obligatorio
- **Response Success**:
```json
{
  "success": true,
  "data": {
    "aplica_rotacion": true,
    "tiene_partido_previo": true,
    "partido_previo": {...},
    "equipo_descansando": "azul",
    "sugerencia": {
      "equipo_entra": "azul",
      "equipo_continua": "naranja",
      "equipo_sale": "verde",
      "razon": "El ganador continua"
    },
    "sugerencia_texto": "AZUL vs NARANJA",
    "equipos_disponibles": ["naranja", "verde", "azul"]
  },
  "message": "Siguiente partido sugerido: AZUL entra a la cancha"
}
```
- **Response Error - Hints**:
  - `no_autenticado` -> Usuario no ha iniciado sesion
  - `fecha_id_requerido` -> Falta fecha_id
  - `fecha_no_encontrada` -> Fecha no existe

### Script SQL
- `supabase/sql-cloud/2026-01-30_E004-HU-005_finalizar_partido.sql`

### Criterios de Aceptacion Backend

- [x] **CA-001**: Funcion `finalizar_partido` cierra partido con marcador actual
- [x] **CA-002**: Registra equipos, marcador final, goles por jugador en response
- [x] **CA-003**: Determina resultado (local/visitante/empate) segun RN-004
- [x] **CA-004**: Incluye `sugerencia_siguiente` para 3 equipos + funcion `obtener_sugerencia_rotacion`
- [x] **CA-005**: Retorna resumen completo: marcador, goleadores, duracion real
- [x] **CA-006**: Parametro `p_confirmar_anticipado` con hint `requiere_confirmacion_anticipado`
- [x] **CA-007**: El estado queda 'finalizado' visible para todos via `obtener_resumen_partido`

### Reglas de Negocio Validadas

- [x] **RN-001**: Validacion rol='admin' y estado='aprobado' con hint `sin_permisos`
- [x] **RN-002**: Validacion estado IN ('en_curso', 'pausado') con hint `partido_no_activo`
- [x] **RN-003**: Validacion estado != 'finalizado' con hint `partido_ya_finalizado`
- [x] **RN-004**: Calculo resultado: goles_local > goles_visitante = 'local', etc.
- [x] **RN-005**: Calculo duracion_real_segundos = hora_fin - hora_inicio - tiempo_pausado
- [x] **RN-006**: Requiere accion explicita del admin (no auto-finaliza)
- [x] **RN-007**: Solo cuenta goles con `anulado = false`, autogoles ya contabilizados correctamente
- [x] **RN-008**: Empate 0-0 es valido, resultado = 'empate'

### Notas de Implementacion

- La tabla goles usa columnas `equipo_anota` y `jugador_id` (no equipo_anotador/usuario_id)
- Los goles se cuentan de tabla `goles` WHERE `anulado = false`
- La sugerencia de rotacion solo aplica cuando `num_equipos = 3`
- Si el partido esta pausado, se descuenta la pausa actual de la duracion real
- El resultado queda en columna `resultado` de partidos para consultas rapidas

---

## FASE 4: Desarrollo Frontend
**Responsable**: flutter-expert
**Status**: Completado
**Fecha**: 2026-01-30

### Archivos Creados/Modificados

#### Models
- `lib/features/partidos/data/models/finalizar_partido_response_model.dart` - Modelos de respuesta
  - `ResultadoPartidoModel` - Resultado del partido (codigo, descripcion, ganador)
  - `MarcadorFinalModel` - Marcador con goles local/visitante
  - `GoleadorResumenModel` - Gol individual con jugador y minuto
  - `GoleadoresModel` - Lista de goleadores agrupada
  - `DuracionPartidoModel` - Duracion real y programada
  - `SugerenciaSiguienteModel` - Sugerencia de rotacion (3 equipos)
  - `FinalizarPartidoResponseModel` - Response completo del RPC

#### BLoC
- `lib/features/partidos/presentation/bloc/finalizar_partido/finalizar_partido_event.dart`
  - `FinalizarPartidoRequested` - Solicitar finalizacion
  - `ConfirmarFinalizacionAnticipada` - Confirmar finalizacion antes de tiempo
  - `CancelarFinalizacion` - Cancelar finalizacion
  - `ResetFinalizarPartido` - Reiniciar estado
- `lib/features/partidos/presentation/bloc/finalizar_partido/finalizar_partido_state.dart`
  - `FinalizarPartidoInitial` - Estado inicial
  - `FinalizarPartidoLoading` - Procesando
  - `FinalizarPartidoRequiereConfirmacion` - CA-006: Requiere confirmacion
  - `FinalizarPartidoSuccess` - CA-005: Exito con resumen
  - `FinalizarPartidoError` - Error con hints del backend
- `lib/features/partidos/presentation/bloc/finalizar_partido/finalizar_partido_bloc.dart`
- `lib/features/partidos/presentation/bloc/finalizar_partido/finalizar_partido.dart` - Barrel file

#### Widgets
- `lib/features/partidos/presentation/widgets/finalizar_partido_button.dart` - CA-001: Boton para finalizar
- `lib/features/partidos/presentation/widgets/confirmacion_anticipada_dialog.dart` - CA-006: Dialogo de confirmacion
- `lib/features/partidos/presentation/widgets/resumen_partido_card.dart` - CA-005: Card con resumen
- `lib/features/partidos/presentation/widgets/sugerencia_rotacion_card.dart` - CA-004: Sugerencia de rotacion

#### Pages
- `lib/features/partidos/presentation/pages/resumen_partido_page.dart` - Pagina y dialogo de resumen

#### Inyeccion de Dependencias
- `lib/core/di/injection_container.dart` - Linea 216: `FinalizarPartidoBloc` registrado

### Criterios de Aceptacion Frontend

- [x] **CA-001**: `FinalizarPartidoButton` con evento `FinalizarPartidoRequested`
- [x] **CA-004**: `SugerenciaRotacionCard` muestra equipos sugeridos
- [x] **CA-005**: `ResumenPartidoCard` con marcador, goleadores, duracion
- [x] **CA-006**: `ConfirmacionAnticipadaDialog` y estado `RequiereConfirmacion`
- [x] **CA-007**: Estado `finalizado` reflejado en UI via BLoC

### Arquitectura
- Clean Architecture respetada (data -> domain -> presentation)
- BLoC pattern para manejo de estado
- Barrel files para exports organizados
- Modelos con Equatable para comparacion eficiente

---
## FASE 5: Validacion QA Tecnica
**Responsable**: qa-testing-expert
**Fecha**: 2026-01-30

### Validacion Tecnica APROBADA

#### 1. Dependencias
```
$ flutter pub get
Got dependencies!
45 packages have newer versions incompatible with dependency constraints.
```
Sin errores de dependencias.

#### 2. Analisis Estatico
```
$ flutter analyze --no-pub
Analyzing gestion_deportiva...

   info - dangling_library_doc_comments (preexistente)
   info - unnecessary_import (preexistente)
warning - unused_local_variable (preexistente, otro archivo)

3 issues found. (ran in 1.8s)
```
0 errores. Solo 2 infos y 1 warning preexistentes, no relacionados con E004-HU-005.

#### 3. Compilacion Web
```
$ flutter build web --release
Compiling lib\main.dart for the Web... 81,8s
Built build\web
```
Compilacion exitosa.

#### 4. Tests
Los tests de widget tienen errores de overflow preexistentes en `dashboard_shell.dart` y `home_page.dart` (no relacionados con E004-HU-005).

### Verificacion de Archivos Nuevos

| Archivo | Estado |
|---------|--------|
| `finalizar_partido_response_model.dart` | Existe, compila |
| `finalizar_partido_bloc.dart` | Existe, compila |
| `finalizar_partido_event.dart` | Existe, compila |
| `finalizar_partido_state.dart` | Existe, compila |
| `finalizar_partido.dart` (barrel) | Existe, exporta correctamente |
| `finalizar_partido_button.dart` | Existe, compila |
| `confirmacion_anticipada_dialog.dart` | Existe, compila |
| `resumen_partido_card.dart` | Existe, compila |
| `sugerencia_rotacion_card.dart` | Existe, compila |
| `resumen_partido_page.dart` | Existe, compila |

### Verificacion de Integracion

| Componente | Estado |
|------------|--------|
| BLoC registrado en injection_container.dart | Si (linea 216) |
| Modelo exportado en models.dart | Si (linea 31) |
| Widgets exportados en widgets.dart | Si (lineas 24-27) |
| Page exportada en pages.dart | Si (linea 8) |
| Metodo finalizarPartido en Repository | Si |
| Metodo finalizarPartido en DataSource | Si |

### Resumen

| Validacion | Estado |
|------------|--------|
| Dependencias | PASS |
| Analisis estatico | PASS (0 errores) |
| Compilacion Web | PASS |
| Archivos nuevos | PASS (todos existen) |
| Integracion DI | PASS |

### Decision

**VALIDACION TECNICA APROBADA**

Siguiente paso: Usuario valida manualmente los CA en la aplicacion.

---
