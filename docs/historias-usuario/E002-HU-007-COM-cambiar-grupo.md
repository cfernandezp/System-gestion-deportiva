# E002-HU-007: Cambiar de Grupo Activo

## INFORMACION
- **Codigo:** E002-HU-007
- **Epica:** E002 - Grupos Deportivos
- **Titulo:** Cambiar de Grupo Activo
- **Story Points:** 2 pts
- **Estado:** Completada
- **Prioridad:** Alta
- **Fecha:** 2026-02-20

## HISTORIA
**Como** usuario con multiples grupos
**Quiero** cambiar de grupo activo sin cerrar sesion
**Para** navegar entre mis grupos de forma rapida y sencilla

### Criterios de Aceptacion

#### CA-001: Acceso rapido al cambio de grupo
- [ ] **DADO** que soy un usuario autenticado que pertenece a mas de un grupo
- [ ] **CUANDO** estoy en cualquier pantalla de la aplicacion
- [ ] **ENTONCES** tengo acceso rapido (desde el menu o encabezado) a la opcion de cambiar de grupo sin necesidad de navegar a una seccion especifica

#### CA-002: Lista de grupos disponibles
- [ ] **DADO** que accedo a la opcion de cambiar de grupo
- [ ] **CUANDO** se muestra la lista de mis grupos
- [ ] **ENTONCES** veo todos los grupos a los que pertenezco con su nombre y logo, pudiendo identificar claramente cual es el grupo activo actualmente

#### CA-003: Cambio de contexto sin re-autenticacion
- [ ] **DADO** que estoy viendo la lista de mis grupos para cambiar
- [ ] **CUANDO** selecciono un grupo diferente al activo
- [ ] **ENTONCES** el sistema cambia al grupo seleccionado sin pedirme iniciar sesion nuevamente, y todo el contenido de la aplicacion (fechas, partidos, miembros, estadisticas) se actualiza para mostrar la informacion del grupo seleccionado

#### CA-004: Indicador del grupo activo
- [ ] **DADO** que estoy usando la aplicacion
- [ ] **CUANDO** miro el encabezado o menu de la pantalla
- [ ] **ENTONCES** puedo ver claramente el nombre y/o logo del grupo que estoy viendo actualmente, sirviendo como indicador constante del contexto

#### CA-005: Usuario con un solo grupo
- [ ] **DADO** que solo pertenezco a un grupo
- [ ] **CUANDO** uso la aplicacion
- [ ] **ENTONCES** el indicador del grupo activo esta visible pero la opcion de cambiar de grupo no es prominente (ya que solo hay uno disponible)

## Reglas de Negocio (RN)

### RN-001: Accesibilidad desde cualquier pantalla
**Contexto**: Cuando el usuario necesita cambiar de grupo durante el uso normal de la aplicacion.
**Restriccion**: No se debe obligar al usuario a navegar a una seccion especifica para cambiar de grupo.
**Validacion**: La opcion de cambiar de grupo debe estar accesible desde cualquier pantalla de la aplicacion, a traves del menu principal o del encabezado.
**Caso especial**: Ninguno.

### RN-002: Cambio sin re-autenticacion
**Contexto**: Cuando el usuario selecciona un grupo diferente al activo.
**Restriccion**: No se debe solicitar al usuario que inicie sesion nuevamente al cambiar de grupo.
**Validacion**: El cambio de grupo se realiza dentro de la misma sesion activa del usuario, sin requerir credenciales adicionales ni re-autenticacion.
**Caso especial**: Ninguno.

### RN-003: Cambio completo de contexto
**Contexto**: Al momento de efectuarse el cambio de grupo activo.
**Restriccion**: No se debe mostrar informacion mezclada de diferentes grupos simultaneamente.
**Validacion**: Al cambiar de grupo, todo el contenido de la aplicacion se actualiza para reflejar la informacion del grupo seleccionado: fechas de juego, partidos, miembros, estadisticas, pagos y cualquier otra informacion contextual del grupo.
**Caso especial**: Ninguno.

### RN-004: Indicador visible del grupo activo
**Contexto**: En todo momento durante el uso de la aplicacion.
**Restriccion**: No se debe permitir que el usuario desconozca en que grupo esta operando.
**Validacion**: El nombre y/o logo del grupo activo debe estar visible de forma permanente en el encabezado o menu de la aplicacion, sirviendo como indicador constante del contexto actual.
**Caso especial**: Ninguno.

### RN-005: Ocultamiento para usuario con un solo grupo
**Contexto**: Cuando el usuario pertenece a un unico grupo.
**Restriccion**: No se debe mostrar una opcion prominente de cambiar de grupo cuando no hay alternativas.
**Validacion**: Si el usuario solo pertenece a un grupo, el indicador del grupo activo se mantiene visible pero la opcion de cambiar de grupo no debe ser prominente ya que no tiene otros grupos disponibles.
**Caso especial**: Si el usuario crea o es invitado a un segundo grupo, la opcion de cambio debe aparecer automaticamente.

## NOTAS ADICIONALES
- El cambio de grupo debe ser fluido, sin recargas notables ni perdida de la sesion del usuario
- Al cambiar de grupo, el contexto completo cambia: fechas, partidos, miembros, estadisticas y pagos corresponden al grupo seleccionado
- El grupo activo se recuerda entre sesiones; al volver a abrir la app se muestra el ultimo grupo utilizado
- Esta funcionalidad complementa a E002-HU-002 (Ver Mis Grupos) pero esta orientada al cambio rapido durante el uso normal de la app
- HU define QUE desde perspectiva usuario. Detalles tecnicos los definen agentes especializados.

## IMPLEMENTACION TECNICA

### Backend
No requiere cambios backend. Todo es frontend (navegacion y UI).

### Frontend - Archivos Modificados

#### 1. `grupo_actual_cubit.dart`
- Agregado `_totalGrupos` y `setTotalGrupos(int)` para tracking de cantidad de grupos
- Agregado `tieneMultiplesGrupos` getter para condicionar swap button (RN-005)
- `limpiarGrupo()` ahora resetea `_totalGrupos = 0`

#### 2. `seleccion_grupo_event.dart`
- `CargarGruposParaSeleccionEvent` ahora acepta `forzarSeleccion` (default: false)
- `forzarSeleccion=true`: omite auto-skip para flujo "cambiar grupo" (E002-HU-007)
- `forzarSeleccion=false`: mantiene auto-skip para flujo login (E001-HU-003)

#### 3. `seleccion_grupo_bloc.dart`
- Almacena `totalGrupos` en el cubit al cargar grupos
- Respeta `forzarSeleccion`: si true y 1 grupo, muestra la lista (no auto-skip)

#### 4. `seleccion_grupo_page.dart`
- Acepta `forzarSeleccion` parametro para diferenciar modos login vs cambio
- Modo cambio: muestra AppBar con titulo "Cambiar grupo" y boton back
- Modo login: muestra header completo con logo (sin AppBar)
- **Badge "Grupo activo"**: verde con checkmark en el grupo actualmente seleccionado (CA-002)
- Badge "Reciente": se muestra solo si el grupo no es el activo
- Icono trailing: checkmark verde para activo, flecha para otros

#### 5. `app_router.dart`
- Ruta `/seleccionar-grupo`: lee `extra` como `bool?` para `forzarSeleccion`
- Pasa `forzarSeleccion` tanto al BLoC como a la Page

#### 6. `home_page.dart`
- Swap button condicional: solo visible si `tieneMultiplesGrupos` (RN-005 / CA-005)
- Swap button pasa `extra: true` para forzar seleccion (no auto-skip)

### Mapping CAs -> Implementacion
| CA | Implementacion |
|----|---------------|
| CA-001 | Swap button en AppBar de Home (visible solo con multiples grupos) |
| CA-002 | Badge "Grupo activo" verde + checkmark en SeleccionGrupoPage |
| CA-003 | GrupoActualCubit.seleccionarGrupo() + context.go('/') sin re-auth |
| CA-004 | Nombre del grupo en AppBar subtitle de Home (RN-004) |
| CA-005 | Swap button oculto con 1 grupo, nombre sigue visible (RN-005) |

### Mapping RNs -> Implementacion
| RN | Implementacion |
|----|---------------|
| RN-001 | Swap button accesible desde Home AppBar; Bottom nav "Jugadores" redirige a miembros |
| RN-002 | Cambio via GrupoActualCubit sin logout/login |
| RN-003 | context.go('/') recarga Home con nuevo contexto del grupo |
| RN-004 | grupoActual.nombre en AppBar subtitle siempre visible |
| RN-005 | tieneMultiplesGrupos condiciona visibilidad del swap button |
