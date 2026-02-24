# E002-HU-008: Registrar Invitado en el Grupo

## INFORMACION
- **Codigo:** E002-HU-008
- **Epica:** E002 - Grupos Deportivos
- **Titulo:** Registrar Invitado en el Grupo
- **Story Points:** 5 pts
- **Estado:** 🟢 Refinada
- **Prioridad:** Alta
- **Fecha:** 2026-02-20

## HISTORIA
**Como** administrador o co-administrador de un grupo,
**Quiero** registrar a un invitado con solo su nombre,
**Para** que pueda participar en las pichangas (jugar, anotar goles, pagar cancha) sin necesidad de tener cuenta en la app, y que su historial se conserve si en el futuro se convierte en jugador regular.

## Descripcion
En la practica de pichangas, es comun que un jugador traiga a un amigo. Este invitado no tiene cuenta en la app pero participa activamente: juega, anota goles, paga su cancha. El sistema debe poder registrar a esta persona de forma ligera (solo nombre) para que su actividad quede registrada y no se pierda informacion.

### Criterios de Aceptacion

#### CA-001: Registrar invitado con nombre
- [ ] **DADO** que soy admin o co-admin de un grupo
- [ ] **CUANDO** selecciono "Agregar invitado" e ingreso un nombre
- [ ] **ENTONCES** se crea un registro de invitado asociado al grupo con estado "invitado" y sin numero de celular

#### CA-002: Limite de invitados por grupo
- [ ] **DADO** que mi grupo ya tiene el maximo de invitados permitidos (default: 1)
- [ ] **CUANDO** intento agregar otro invitado
- [ ] **ENTONCES** el sistema rechaza la accion indicando que se alcanzo el limite de invitados y sugiere promover invitados existentes a jugadores o eliminar uno para liberar el cupo

#### CA-003: Nombre obligatorio
- [ ] **DADO** que estoy registrando un invitado
- [ ] **CUANDO** intento guardar sin ingresar nombre
- [ ] **ENTONCES** el sistema indica que el nombre es obligatorio

#### CA-004: Invitado aparece en lista de miembros
- [ ] **DADO** que se registro un invitado en el grupo
- [ ] **CUANDO** veo la lista de miembros del grupo
- [ ] **ENTONCES** el invitado aparece con un indicador visual claro de que es "Invitado" (diferenciado de Jugador, Admin, Co-Admin)

#### CA-005: Invitado puede ser inscrito a una fecha
- [ ] **DADO** que existe un invitado registrado en el grupo
- [ ] **CUANDO** el admin crea o gestiona una fecha de pichanga
- [ ] **ENTONCES** puede inscribir al invitado como participante igual que a un jugador regular

#### CA-006: Invitado puede ser asignado a un equipo
- [ ] **DADO** que un invitado esta inscrito en una fecha
- [ ] **CUANDO** el admin asigna equipos
- [ ] **ENTONCES** el invitado puede ser asignado a cualquier equipo como un jugador mas

#### CA-007: Goles del invitado se registran a su nombre
- [ ] **DADO** que un invitado esta jugando un partido
- [ ] **CUANDO** el admin registra un gol del invitado
- [ ] **ENTONCES** el gol queda atribuido al invitado y cuenta para el marcador del equipo

#### CA-008: Pagos del invitado se registran a su nombre
- [ ] **DADO** que un invitado asistio a una fecha
- [ ] **CUANDO** el admin registra su pago
- [ ] **ENTONCES** el pago queda registrado a nombre del invitado

#### CA-009: Invitado NO aparece en rankings del grupo
- [ ] **DADO** que un invitado tiene goles, asistencias y pagos registrados
- [ ] **CUANDO** se consultan los rankings del grupo (goleadores, puntos, etc.)
- [ ] **ENTONCES** el invitado NO aparece en ningun ranking publico del grupo

#### CA-010: Eliminar invitado del grupo
- [ ] **DADO** que soy admin o co-admin
- [ ] **CUANDO** elimino a un invitado del grupo
- [ ] **ENTONCES** el invitado se elimina del grupo pero su historial de participacion se conserva en los registros historicos de fechas y partidos

## Reglas de Negocio (RN)

### RN-001: Registro ligero sin cuenta
**Contexto**: Al registrar un invitado en el grupo.
**Restriccion**: No requiere numero de celular, contrasena ni activacion de cuenta. Solo nombre.
**Validacion**: Un invitado es un registro minimo con: nombre (obligatorio) y grupo al que pertenece. No tiene credenciales de acceso ni puede usar la app.
**Caso especial**: El nombre del invitado puede repetirse (puede haber dos "Luis" invitados en diferentes momentos), pero no al mismo tiempo en el grupo.

### RN-002: Limite de invitados por grupo
**Contexto**: Al intentar agregar un invitado a un grupo.
**Restriccion**: No se puede exceder el limite de invitados configurado para el grupo.
**Validacion**: El limite por defecto es 1 invitado por grupo (configurable desde E003). Este limite es independiente del limite de jugadores (35). Los invitados NO cuentan para el limite de jugadores.
**Caso especial**: En plan Premium, el limite de invitados podria ser mayor (ej: 3 o 5).

### RN-003: Invitado pertenece a un solo grupo
**Contexto**: Al registrar un invitado.
**Restriccion**: Un invitado no puede estar en multiples grupos simultaneamente.
**Validacion**: Como el invitado no tiene celular (identificador unico), es un registro local del grupo. Si la misma persona es invitada en otro grupo, seria un registro diferente e independiente.
**Caso especial**: Al ser promovido a jugador (con celular), si esa persona ya tenia un registro de invitado en otro grupo, los registros NO se fusionan automaticamente.

### RN-004: Participacion completa en actividades
**Contexto**: Durante fechas y partidos.
**Restriccion**: El invitado no debe tener restricciones de participacion dentro de la fecha/partido.
**Validacion**: Un invitado inscrito a una fecha puede: ser asignado a equipo, anotar goles (registrados a su nombre), recibir registro de pagos, participar en todos los partidos de la jornada. Su participacion es identica a la de un jugador en el contexto del partido.
**Caso especial**: El invitado NO puede auto-inscribirse a fechas (no tiene app). Solo el admin lo inscribe.

### RN-005: Exclusion de rankings
**Contexto**: Al calcular y mostrar rankings del grupo.
**Restriccion**: Los invitados no deben aparecer en ningun ranking publico del grupo.
**Validacion**: Rankings de goleadores, puntos, asistencia, etc. solo muestran jugadores con rol Jugador, Co-Admin o Admin. Los goles del invitado SÍ cuentan para el marcador del equipo en el partido, pero NO para rankings individuales.
**Caso especial**: Tras ser promovido a Jugador, todo el historial del invitado (goles, asistencias, pagos) SÍ se incluye retroactivamente en los rankings a partir de ese momento.

### RN-006: Conservacion de historial
**Contexto**: Al eliminar un invitado o al promoverlo a jugador.
**Restriccion**: El historial de participacion del invitado nunca se elimina.
**Validacion**: Si un invitado es eliminado del grupo, sus goles y pagos quedan en los registros historicos de las fechas y partidos donde participo. Si es promovido, su historial se conserva intacto y se vincula a su nueva cuenta de jugador.
**Caso especial**: Los goles historicos aparecen como "Invitado: [nombre]" en el detalle de partidos pasados, incluso si fue eliminado.

### RN-007: Solo admin y co-admin gestionan invitados
**Contexto**: Al crear, editar o eliminar invitados.
**Restriccion**: Jugadores regulares no pueden gestionar invitados.
**Validacion**: Solo admin y co-admin pueden: registrar invitados, inscribirlos a fechas, eliminarlos del grupo, promoverlos a jugadores.
**Caso especial**: Co-admin puede gestionar invitados pero no puede promoverlos (la promocion implica agregar celular, que es similar a invitar un jugador nuevo).

## NOTAS
- Esta funcionalidad refleja un caso de uso real y frecuente en pichangas de futbol amateur.
- El invitado es una "entidad ligera" que evoluciona a jugador completo cuando el admin decide.
- La promocion de invitado a jugador se maneja en E002-HU-009.
- Los limites de invitados se configuran en E003 (Config) y se definen en E000-HU-002 (Infra Planes).
- Impacta epicas futuras: E003 (Fechas - inscripcion), E004 (Partidos - goles), E005 (Pagos), E006 (Stats - exclusion rankings).
- HU define QUE desde perspectiva usuario. Detalles tecnicos los definen agentes especializados.

---
## FASE 2: Diseno Backend
**Responsable**: supabase-expert
**Status**: Completado
**Fecha**: 2026-02-21

### Funciones RPC Implementadas

**`registrar_invitado(p_grupo_id UUID, p_nombre TEXT) -> JSONB`**
- **Descripcion**: Registra un invitado ligero (solo nombre) en un grupo deportivo. Crea un registro minimo en `usuarios` (sin auth, sin celular) y lo inserta en `miembros_grupo` con rol='invitado'.
- **Reglas de Negocio**: RN-001, RN-002, RN-003, RN-007
- **Parametros**:
  - `p_grupo_id`: UUID - ID del grupo donde se registra el invitado
  - `p_nombre`: TEXT - Nombre del invitado (obligatorio)
- **Response Success**:
  ```json
  {
    "success": true,
    "data": {
      "miembro_id": "uuid",
      "usuario_id": "uuid",
      "nombre": "nombre_limpio",
      "rol": "invitado",
      "invitados_actuales": 2,
      "max_invitados": 3
    },
    "message": "Invitado registrado exitosamente"
  }
  ```
- **Response Error - Codes**:
  - `NO_AUTH` - No autenticado
  - `USER_NOT_FOUND` - Perfil de usuario no encontrado
  - `GROUP_NOT_FOUND` - Grupo no existe o esta inactivo
  - `NOT_ADMIN_OR_COADMIN` - Sin permisos (RN-007)
  - `NOMBRE_REQUERIDO` - Nombre vacio (CA-003)
  - `NOMBRE_DUPLICADO` - Nombre duplicado entre invitados activos del grupo (RN-001)
  - `INVITADO_LIMIT_REACHED` - Limite de invitados alcanzado segun plan (CA-002/RN-002)

**`eliminar_invitado(p_grupo_id UUID, p_miembro_id UUID) -> JSONB`**
- **Descripcion**: Elimina (soft delete) un invitado del grupo. Conserva historial.
- **Reglas de Negocio**: RN-006, RN-007
- **Parametros**:
  - `p_grupo_id`: UUID - ID del grupo
  - `p_miembro_id`: UUID - ID del registro en miembros_grupo
- **Response Success**:
  ```json
  {
    "success": true,
    "data": {
      "miembro_id": "uuid",
      "nombre": "nombre",
      "grupo_id": "uuid"
    },
    "message": "Invitado eliminado del grupo exitosamente"
  }
  ```
- **Response Error - Codes**:
  - `NO_AUTH` - No autenticado
  - `USER_NOT_FOUND` - Perfil de usuario no encontrado
  - `GROUP_NOT_FOUND` - Grupo no existe o esta inactivo
  - `NOT_ADMIN_OR_COADMIN` - Sin permisos (RN-007)
  - `MEMBER_NOT_FOUND` - Miembro no encontrado o ya eliminado
  - `NOT_INVITADO` - El miembro no tiene rol invitado

### Estrategia tecnica: Invitado como usuario ligero
- Se crea un registro en `usuarios` con `auth_user_id = NULL`, `celular = NULL`
- Email ficticio: `invitado_{uuid}@invitado.local` para satisfacer NOT NULL
- Estado: `aprobado` (participacion inmediata)
- Rol sistema: `jugador` (generico)
- Rol en grupo: `invitado` (en tabla `miembros_grupo`)
- Esto permite reutilizar `usuario_id` en inscripciones, goles, pagos sin cambios de schema

### Script SQL
- `supabase/sql-cloud/2026-02-21_E002-HU-008_registrar_invitado.sql`

### Criterios de Aceptacion Backend
- [x] **CA-001**: Implementado en `registrar_invitado` - crea usuario ligero + miembro con rol invitado
- [x] **CA-002**: Implementado en `registrar_invitado` - valida limite segun `planes.max_invitados_por_grupo`
- [x] **CA-003**: Implementado en `registrar_invitado` - valida nombre no vacio
- [ ] **CA-004**: Frontend - invitado aparece en lista de miembros (ya soportado por obtener_miembros_grupo)
- [ ] **CA-005**: Epica futura (E003 Fechas)
- [ ] **CA-006**: Epica futura (E003 Fechas - asignacion equipos)
- [ ] **CA-007**: Epica futura (E004 Partidos - goles)
- [ ] **CA-008**: Epica futura (E005 Pagos)
- [ ] **CA-009**: Epica futura (E006 Stats - exclusion rankings)
- [x] **CA-010**: Implementado en `eliminar_invitado` - soft delete conservando historial

---
## FASE 4: Implementacion Frontend
**Responsable**: flutter-expert
**Status**: Completado
**Fecha**: 2026-02-21

### Estructura Clean Architecture

**BLoC (nuevo)**: `lib/features/grupos/presentation/bloc/registrar_invitado/`
- `registrar_invitado_event.dart` - RegistrarInvitadoSubmitEvent
- `registrar_invitado_state.dart` - Initial, Loading, Success, Error, LimiteAlcanzado
- `registrar_invitado_bloc.dart` - Handler con deteccion de hint 'limite_invitados'

**BLoC (modificado)**: `lib/features/grupos/presentation/bloc/miembros_grupo/`
- `miembros_grupo_event.dart` - Agregado EliminarInvitadoEvent
- `miembros_grupo_state.dart` - Agregado EliminarInvitadoSuccess
- `miembros_grupo_bloc.dart` - Agregado handler _onEliminarInvitado

**DataSource (modificado)**: `lib/features/grupos/data/datasources/grupos_remote_datasource.dart`
- registrarInvitado() -> RPC 'registrar_invitado'
- eliminarInvitado() -> RPC 'eliminar_invitado'

**Repository (modificado)**: `lib/features/grupos/domain/repositories/grupos_repository.dart`
- registrarInvitado() -> Either<Failure, Map<String, dynamic>>
- eliminarInvitado() -> Either<Failure, void>

**Repository Impl (modificado)**: `lib/features/grupos/data/repositories/grupos_repository_impl.dart`
- Implementaciones con patron try/catch ServerException -> ServerFailure

**DI (modificado)**: `lib/core/di/injection_container.dart`
- Registrado RegistrarInvitadoBloc como Factory

### Pagina Principal Modificada
**`lib/features/grupos/presentation/pages/miembros_grupo_page.dart`**

Cambios realizados:
1. FAB cambiado de navegacion directa a BottomSheet con 2 opciones (Invitar Jugador / Agregar Invitado)
2. Label FAB cambiado de "Invitar" a "Agregar"
3. Formulario de registrar invitado como BottomSheet modal con BlocProvider inline
4. Manejo de limite alcanzado con AlertDialog informativo (icono warning, sugerencias, boton Ver Planes)
5. Avatar de invitado con borde violeta sutil (1.5px, Color(0xFF8B5CF6) alpha 0.4)
6. Subtitulo "Sin cuenta en la app" en cursiva para invitados en vez del celular
7. "Generar codigo de recuperacion" oculto para invitados
8. Opcion "Promover a Jugador" placeholder para invitados (solo admin, SnackBar proximamente)
9. Opcion "Eliminar del grupo" para invitados con dialogo adaptado (conservacion historial)
10. Listener para EliminarInvitadoSuccess con recarga de lista

### Integracion Backend
UI -> Bloc -> Repository -> DataSource -> RPC -> Backend

### Criterios de Aceptacion Frontend
- [x] **CA-001**: Implementado en formulario BottomSheet + RegistrarInvitadoBloc
- [x] **CA-002**: Implementado con estado LimiteAlcanzado + AlertDialog con sugerencias
- [x] **CA-003**: Validacion en TextFormField (nombre requerido, min 2 caracteres)
- [x] **CA-004**: Invitado visible en lista con badge "Invitado", borde violeta, "Sin cuenta en la app"
- [x] **CA-010**: Implementado en EliminarInvitadoEvent + dialogo adaptado

### Verificacion
- [x] `flutter analyze`: 0 issues en archivos modificados
- [x] Mapping snake_case <-> camelCase correcto (p_grupo_id, p_nombre, p_miembro_id)
- [x] Either pattern en repository
- [x] BlocProvider inline en BottomSheet (no global)
- [x] Patrones consistentes con E002-HU-004, E002-HU-005, E002-HU-006

---
## FASE 5: Validacion QA Tecnica
**Responsable**: qa-testing-expert
**Fecha**: 2026-02-21

### Validacion Tecnica APROBADA

#### 1. Dependencias
```
$ flutter pub get
Got dependencies!
```
PASS - Sin errores

#### 2. Analisis Estatico
```
$ flutter analyze --no-pub
59 issues found (all warnings/info, pre-existing in other files)
0 issues in E002-HU-008 files
```
PASS - 0 errores y 0 warnings en archivos nuevos/modificados de esta HU

#### 3. Compilacion Mobile
```
$ flutter build apk --debug
Running Gradle task 'assembleDebug'... 21.5s
Built build\app\outputs\flutter-apk\app-debug.apk
```
PASS - APK compilado exitosamente

### Archivos Validados (11/11 existentes)

| Archivo | Tipo | Estado |
|---------|------|--------|
| `bloc/registrar_invitado/registrar_invitado_event.dart` | Nuevo | PASS |
| `bloc/registrar_invitado/registrar_invitado_state.dart` | Nuevo | PASS |
| `bloc/registrar_invitado/registrar_invitado_bloc.dart` | Nuevo | PASS |
| `bloc/miembros_grupo/miembros_grupo_event.dart` | Modificado | PASS |
| `bloc/miembros_grupo/miembros_grupo_state.dart` | Modificado | PASS |
| `bloc/miembros_grupo/miembros_grupo_bloc.dart` | Modificado | PASS |
| `data/datasources/grupos_remote_datasource.dart` | Modificado | PASS |
| `domain/repositories/grupos_repository.dart` | Modificado | PASS |
| `data/repositories/grupos_repository_impl.dart` | Modificado | PASS |
| `core/di/injection_container.dart` | Modificado | PASS |
| `pages/miembros_grupo_page.dart` | Modificado | PASS |

### Resumen

| Validacion | Estado |
|------------|--------|
| Dependencias (pub get) | PASS |
| Analisis Estatico (analyze) | PASS |
| Compilacion APK Debug | PASS |
| Archivos existentes (11/11) | PASS |

### Decision

**VALIDACION TECNICA APROBADA** - Intento 1 de 3 (sin errores)

Siguiente paso: Usuario valida manualmente los CA en dispositivo Android/iOS o emulador.
