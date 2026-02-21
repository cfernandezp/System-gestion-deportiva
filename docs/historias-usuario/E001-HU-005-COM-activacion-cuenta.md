# E001-HU-005: Activacion de Cuenta de Jugador Invitado

## INFORMACION
- **Codigo:** E001-HU-005
- **Epica:** E001 - Autenticacion y Gestion de Acceso
- **Titulo:** Activacion de Cuenta de Jugador Invitado
- **Story Points:** 5 pts
- **Estado:** ✅ Completada
- **Prioridad:** Alta
- **Fecha:** 2026-02-20

## HISTORIA
**Como** jugador que fue invitado a un grupo deportivo,
**Quiero** activar mi cuenta creando una contrasena,
**Para** poder acceder al sistema con mis credenciales y participar en las actividades del grupo.

### Criterios de Aceptacion

#### CA-001: Activacion exitosa de cuenta
- [ ] **DADO** que fui invitado a un grupo y mi cuenta esta en estado "pendiente de activacion"
- [ ] **CUANDO** ingreso mi numero de celular, verifico que tengo una invitacion pendiente y creo una contrasena que cumple los requisitos de seguridad
- [ ] **ENTONCES** mi cuenta cambia a estado activo, puedo completar mi nombre y el sistema me permite hacer login normal

#### CA-002: Celular sin invitacion
- [ ] **DADO** que estoy en la pantalla de activacion de cuenta
- [ ] **CUANDO** ingreso un numero de celular que no tiene ninguna invitacion pendiente en el sistema
- [ ] **ENTONCES** el sistema muestra el mensaje "No tienes invitacion. Contacta al administrador de tu grupo."

#### CA-003: Validacion de contrasena en activacion
- [ ] **DADO** que estoy activando mi cuenta
- [ ] **CUANDO** ingreso una contrasena que no cumple los requisitos minimos de seguridad
- [ ] **ENTONCES** el sistema muestra los requisitos que no se cumplen para que pueda corregirla

#### CA-004: Cuenta ya activada previamente
- [ ] **DADO** que estoy en la pantalla de activacion de cuenta
- [ ] **CUANDO** ingreso un numero de celular que ya tiene una cuenta activa
- [ ] **ENTONCES** el sistema me informa que mi cuenta ya esta activa y me sugiere iniciar sesion

#### CA-005: Completar nombre durante la activacion
- [ ] **DADO** que estoy activando mi cuenta exitosamente
- [ ] **CUANDO** el sistema me permite ingresar mis datos
- [ ] **ENTONCES** puedo registrar mi nombre completo que se mostrara en el grupo

#### CA-006: Acceso post-activacion
- [ ] **DADO** que active mi cuenta exitosamente
- [ ] **CUANDO** el proceso de activacion se completa
- [ ] **ENTONCES** el sistema me redirige al flujo normal de login donde puedo acceder con mi celular y contrasena recien creada

## Reglas de Negocio (RN)

### RN-001: Solo usuarios con estado pendiente de activacion pueden activar
**Contexto**: Cuando un usuario accede a la pantalla de activacion de cuenta e ingresa su numero de celular.
**Restriccion**: No se permite activar una cuenta que ya esta activa ni una cuenta que no existe en el sistema.
**Validacion**: El sistema debe verificar que el celular ingresado corresponda a un usuario con estado "pendiente de activacion". Si la cuenta ya esta activa, debe sugerir iniciar sesion. Si el celular no existe en el sistema, debe informar que no hay invitacion pendiente.
**Caso especial**: Si un usuario activo es invitado a un grupo adicional, no necesita activar nada; la asociacion es automatica (ver E001-HU-004 RN-003).

### RN-002: El jugador define su propia contrasena con mismos requisitos que admin
**Contexto**: Durante el proceso de activacion de cuenta, cuando el jugador invitado crea su contrasena.
**Restriccion**: No se permite establecer una contrasena que no cumpla los requisitos minimos de seguridad.
**Validacion**: La contrasena debe cumplir exactamente los mismos requisitos que la del administrador: minimo 8 caracteres, al menos una mayuscula, al menos una minuscula, al menos un numero y al menos un caracter especial (ver E001-HU-001 RN-003).
**Caso especial**: El admin no define la contrasena del jugador en ningun momento; solo registra el celular al invitar.

### RN-003: Tras activar, el estado cambia a activo
**Contexto**: Cuando el jugador completa exitosamente todos los pasos del proceso de activacion.
**Restriccion**: La cuenta no debe permanecer en estado "pendiente de activacion" despues de una activacion exitosa.
**Validacion**: Al completar la activacion (celular verificado, contrasena creada, nombre ingresado), el estado de la cuenta cambia inmediatamente a "activo", permitiendo login normal en futuras sesiones.
**Caso especial**: Si el jugador fue invitado a multiples grupos antes de activar, al activar obtiene acceso a todos esos grupos simultaneamente.

### RN-004: Sin invitacion no hay activacion
**Contexto**: Cuando alguien intenta activar una cuenta sin haber sido invitado previamente por un administrador.
**Restriccion**: No se permite el autoregistro de jugadores. Solo se puede activar una cuenta que fue creada mediante invitacion por un admin o co-admin.
**Validacion**: Si el celular ingresado no tiene una invitacion pendiente (no existe en el sistema o ya esta activo), el sistema rechaza la activacion y muestra el mensaje "No tienes invitacion. Contacta al administrador de tu grupo."
**Caso especial**: Quien quiera usar el sistema sin invitacion debe registrarse como administrador (ver E001-HU-001) y crear su propio grupo.

### RN-005: El jugador debe ingresar su nombre al activar
**Contexto**: Durante el proceso de activacion, el jugador debe completar su perfil basico.
**Restriccion**: No se puede completar la activacion sin proporcionar un nombre. El admin solo registro el celular al invitar, no el nombre.
**Validacion**: El jugador debe ingresar su nombre completo durante la activacion. Este nombre sera el que se muestre en el grupo y en las actividades deportivas.
**Caso especial**: El nombre ingresado durante la activacion aplica para todos los grupos a los que el jugador fue invitado (es un dato del usuario, no del grupo).

## NOTAS
- Este flujo es exclusivo para jugadores que fueron invitados por un administrador. No se puede activar una cuenta sin invitacion previa.
- La pantalla de activacion debe ser accesible desde la pantalla principal de la app (antes del login), con un enlace claro tipo "Fui invitado a un grupo".
- El jugador invitado no elige su rol; automaticamente ingresa como Jugador en el grupo al que fue invitado.
- Si el jugador fue invitado a multiples grupos antes de activar, al activar su cuenta tendra acceso a todos esos grupos.
- HU define QUE desde perspectiva usuario. Detalles tecnicos los definen agentes especializados.

---

## IMPLEMENTACION TECNICA

### Backend (Supabase SQL)
- **Script:** `supabase/sql-cloud/2026-02-20_E001-HU-005_activar_cuenta_jugador.sql`
- **RPC verificar_invitacion_pendiente(p_celular):** Funcion publica (anon) que verifica si un celular tiene invitacion pendiente. Retorna tiene_invitacion, ya_activo, grupos_pendientes, mensaje.
- **RPC activar_cuenta_jugador(p_auth_user_id, p_celular, p_nombre_completo):** Funcion autenticada que vincula auth_user_id, actualiza nombre y cambia estado a 'aprobado'.

### Frontend (Flutter)
- **Modelos:**
  - `auth/data/models/verificar_invitacion_model.dart` - Respuesta de verificacion
  - `auth/data/models/activacion_cuenta_response_model.dart` - Respuesta de activacion
- **DataSource:** Extendido `auth_remote_datasource.dart` con `verificarInvitacionPendiente()` y `activarCuentaJugador()`
- **Repository:** Extendido `auth_repository.dart` y `auth_repository_impl.dart`
- **Bloc:** `auth/presentation/bloc/activacion_cuenta/` (bloc, event, state)
  - Eventos: VerificarInvitacionEvent, ActivarCuentaEvent, ResetActivacionEvent
  - Estados: Initial, Loading, InvitacionVerificada, InvitacionNoEncontrada, Success, Error

### UI (Mobile)
- **Pagina:** `auth/presentation/pages/activacion_cuenta_page.dart`
  - Flujo de 2 pasos con indicador visual
  - Paso 1: Ingresar celular -> verificar invitacion
  - Paso 2: Nombre + contrasena + confirmar -> activar cuenta
  - Dialog de exito con redireccion al login
  - Dialog informativo para sin invitacion / cuenta ya activa
- **Login Page:** Agregado link "Fui invitado a un grupo" -> `/activar-cuenta`

### Router y DI
- **Ruta:** `/activar-cuenta` (publica, sin autenticacion)
- **DI:** `ActivacionCuentaBloc` registrado como factory en `injection_container.dart`

### QA
- flutter analyze: 0 warnings/errors nuevos (18 pre-existentes)
