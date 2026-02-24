# E001-HU-003 - Recuperacion de Contrasena

## Informacion General
- **Epica**: E001 - Login de Usuario
- **Estado**: 🔵 En Desarrollo (DEV)
- **Prioridad**: Media

## Historia de Usuario
**Como** usuario registrado
**Quiero** recuperar mi contrasena si la olvido
**Para** poder volver a acceder al sistema

## Descripcion
Permite a usuarios que olvidaron su contrasena restablecerla mediante un proceso seguro por email.

## Criterios de Aceptacion (CA)

### CA-001: Solicitud de recuperacion
- **Dado** que olvide mi contrasena
- **Cuando** accedo a "Recuperar contrasena"
- **Entonces** debo poder ingresar mi email registrado

### CA-002: Email de recuperacion enviado
- **Dado** que ingreso un email registrado
- **Cuando** solicito recuperacion
- **Entonces** recibo un email con instrucciones/enlace para restablecer

### CA-003: Email no registrado
- **Dado** que ingreso un email no registrado
- **Cuando** solicito recuperacion
- **Entonces** veo el mismo mensaje de confirmacion (por seguridad, no revelar si existe)

### CA-004: Enlace de recuperacion valido
- **Dado** que recibo el email de recuperacion
- **Cuando** uso el enlace dentro del tiempo limite
- **Entonces** puedo establecer una nueva contrasena

### CA-005: Enlace expirado
- **Dado** que recibo el email de recuperacion
- **Cuando** uso el enlace despues del tiempo limite
- **Entonces** veo un mensaje indicando que el enlace expiro y debo solicitar uno nuevo

### CA-006: Nueva contrasena establecida
- **Dado** que accedo con un enlace valido
- **Cuando** ingreso y confirmo mi nueva contrasena
- **Entonces** mi contrasena se actualiza y puedo iniciar sesion con ella

## Reglas de Negocio (RN)

### RN-001: Mensaje uniforme de confirmacion
**Contexto**: Cuando un usuario solicita recuperacion de contrasena
**Restriccion**: No revelar si el email existe o no en el sistema
**Validacion**: El sistema debe mostrar siempre el mismo mensaje de confirmacion independientemente de si el email esta registrado
**Regla calculo**: N/A
**Caso especial**: Ninguno - aplica a todas las solicitudes sin excepcion

### RN-002: Tiempo limite del enlace de recuperacion
**Contexto**: Cuando se genera un enlace de recuperacion de contrasena
**Restriccion**: El enlace no puede ser utilizado despues de expirar
**Validacion**: El enlace debe tener un tiempo de validez de 1 hora desde su generacion
**Regla calculo**: Tiempo validez = Hora generacion + 60 minutos
**Caso especial**: Si el usuario solicita un nuevo enlace antes de que expire el anterior, el enlace anterior debe invalidarse

### RN-003: Uso unico del enlace
**Contexto**: Cuando un usuario utiliza un enlace de recuperacion
**Restriccion**: El enlace no puede reutilizarse una vez usado
**Validacion**: Despues de establecer exitosamente la nueva contrasena, el enlace debe quedar invalido
**Regla calculo**: N/A
**Caso especial**: Si el usuario abandona el proceso sin completarlo, el enlace permanece valido hasta su expiracion

### RN-004: Requisitos de la nueva contrasena
**Contexto**: Cuando el usuario establece su nueva contrasena
**Restriccion**: La nueva contrasena no puede ser identica a la anterior
**Validacion**: La nueva contrasena debe cumplir los mismos requisitos de seguridad que en el registro (minimo 8 caracteres, al menos una mayuscula, una minuscula y un numero)
**Regla calculo**: N/A
**Caso especial**: Ninguno

### RN-005: Confirmacion de contrasena
**Contexto**: Al establecer la nueva contrasena
**Restriccion**: No permitir el cambio si la confirmacion no coincide
**Validacion**: El usuario debe ingresar la nueva contrasena dos veces y ambas deben coincidir exactamente
**Regla calculo**: N/A
**Caso especial**: Ninguno

### RN-006: Invalidacion de sesiones activas
**Contexto**: Cuando se cambia la contrasena exitosamente
**Restriccion**: N/A
**Validacion**: Todas las sesiones activas del usuario deben cerrarse al cambiar la contrasena (excepto la sesion actual si aplica)
**Regla calculo**: N/A
**Caso especial**: Si el cambio se realiza desde el flujo de recuperacion (sin sesion activa), no hay sesion que preservar

## Notas Tecnicas
- Refinado por @negocio-deportivo-expert

## Mockups/Wireframes
- Pendiente

---
**Creado**: 2025-01-13
**Ultima actualizacion**: 2026-01-14

---
## FASE 2: Diseno Backend
**Responsable**: supabase-expert
**Status**: Completado
**Fecha**: 2026-01-14

### Tabla Creada

**`tokens_recuperacion`**
- **Descripcion**: Almacena tokens de recuperacion de contrasena con expiracion
- **Columnas**:
  - `id` (UUID, PK): Identificador unico
  - `usuario_id` (UUID, FK): Referencia al usuario
  - `token_hash` (TEXT): Hash SHA256 del token (no se guarda token plano)
  - `expira_at` (TIMESTAMPTZ): Fecha/hora de expiracion (1 hora desde creacion)
  - `usado` (BOOLEAN): Indica si el token ya fue utilizado
  - `usado_at` (TIMESTAMPTZ): Cuando se uso el token
  - `created_at` (TIMESTAMPTZ): Fecha de creacion

### Funciones RPC Implementadas

**`solicitar_recuperacion_contrasena(p_email TEXT) -> JSON`**
- **Descripcion**: Solicita recuperacion de contrasena. Siempre retorna mensaje generico por seguridad.
- **Reglas de Negocio**: RN-001, RN-002
- **Criterios**: CA-001, CA-002, CA-003
- **Parametros**:
  - `p_email`: Email del usuario que solicita recuperacion
- **Response Success**:
  ```json
  {
    "success": true,
    "data": {
      "email_enviado": true,
      "token": "abc123...",
      "token_id": "uuid",
      "expira_en_minutos": 60,
      "usuario_nombre": "Juan Perez"
    },
    "message": "Si el email esta registrado, recibiras instrucciones..."
  }
  ```
- **Comportamiento**:
  - Si email existe y usuario aprobado: genera token, invalida anteriores
  - Si email no existe o no aprobado: retorna mismo mensaje (seguridad)
  - El token retornado debe ser enviado por email (frontend/Edge Function)

**`validar_token_recuperacion(p_token TEXT) -> JSON`**
- **Descripcion**: Valida si un token de recuperacion es valido y no ha expirado
- **Reglas de Negocio**: RN-002, RN-003
- **Criterios**: CA-004, CA-005
- **Parametros**:
  - `p_token`: Token de recuperacion (de la URL del email)
- **Response Success**:
  ```json
  {
    "success": true,
    "data": {
      "valido": true,
      "email": "user@email.com",
      "nombre": "Usuario",
      "minutos_restantes": 45
    },
    "message": "Token valido"
  }
  ```
- **Response Error - Hints**:
  - `token_requerido` -> Token no proporcionado
  - `token_invalido` -> Token no existe en BD
  - `token_usado` -> Token ya fue utilizado
  - `token_expirado` -> Token expiro (mas de 1 hora)

**`restablecer_contrasena(p_token TEXT, p_nueva_contrasena TEXT, p_confirmar_contrasena TEXT) -> JSON`**
- **Descripcion**: Restablece la contrasena usando un token valido
- **Reglas de Negocio**: RN-002, RN-003, RN-004, RN-005, RN-006
- **Criterios**: CA-004, CA-005, CA-006
- **Parametros**:
  - `p_token`: Token de recuperacion
  - `p_nueva_contrasena`: Nueva contrasena
  - `p_confirmar_contrasena`: Confirmacion de contrasena
- **Response Success**:
  ```json
  {
    "success": true,
    "data": {
      "email": "user@email.com",
      "sesiones_cerradas": true
    },
    "message": "Contrasena actualizada exitosamente..."
  }
  ```
- **Response Error - Hints**:
  - `token_requerido` -> Token no proporcionado
  - `contrasena_requerida` -> Contrasena vacia
  - `confirmacion_requerida` -> Confirmacion vacia
  - `contrasenas_no_coinciden` -> Contrasenas diferentes (RN-005)
  - `token_invalido` -> Token no existe
  - `token_usado` -> Token ya utilizado (RN-003)
  - `token_expirado` -> Token expiro (RN-002)
  - `contrasena_invalida` -> No cumple requisitos (RN-004)
  - `contrasena_igual_anterior` -> Igual a la anterior (RN-004)

**`limpiar_tokens_expirados() -> JSON`**
- **Descripcion**: Funcion de mantenimiento para limpiar tokens expirados
- **Permisos**: Solo service_role
- **Response Success**:
  ```json
  {"success": true, "data": {"tokens_eliminados": 5}, "message": "..."}
  ```

### Seguridad Implementada

1. **Tokens con hash**: Se almacena hash SHA256, no token plano
2. **Expiracion 1 hora**: Tokens invalidos despues de 60 minutos
3. **Uso unico**: Token marcado como usado tras restablecer
4. **Invalidacion de anteriores**: Nuevos tokens invalidan los anteriores
5. **Cierre de sesiones**: Se eliminan refresh_tokens y sessions al cambiar contrasena
6. **RLS habilitado**: Solo funciones SECURITY DEFINER acceden a tokens

### Script SQL
- `supabase/sql-cloud/2026-01-14_HU-003_recuperacion_contrasena.sql`

### Criterios de Aceptacion Backend
- [x] **CA-001**: Implementado en `solicitar_recuperacion_contrasena`
- [x] **CA-002**: Implementado - funcion genera token para enviar por email
- [x] **CA-003**: Implementado - mensaje generico siempre (RN-001)
- [x] **CA-004**: Implementado en `validar_token_recuperacion` y `restablecer_contrasena`
- [x] **CA-005**: Implementado - validacion de expiracion (1 hora)
- [x] **CA-006**: Implementado en `restablecer_contrasena`

### Reglas de Negocio Backend
- [x] **RN-001**: Mensaje uniforme - siempre mismo mensaje
- [x] **RN-002**: Token valido 1 hora, invalida anteriores
- [x] **RN-003**: Uso unico - campo `usado` en tokens
- [x] **RN-004**: Validacion contrasena + diferente a anterior
- [x] **RN-005**: Confirmacion coincide con nueva contrasena
- [x] **RN-006**: Cierre de sesiones via DELETE en auth.refresh_tokens

### Notas de Integracion Frontend

El frontend debe:
1. Llamar `solicitar_recuperacion_contrasena(email)` desde pantalla de recuperacion
2. Si `email_enviado = true`, usar el `token` para construir URL y enviar email
3. En la URL del email, incluir el token: `/reset-password?token=xxx`
4. Al abrir URL, llamar `validar_token_recuperacion(token)` para verificar
5. Si valido, mostrar form de nueva contrasena
6. Al submit, llamar `restablecer_contrasena(token, nueva, confirmacion)`
7. Redirigir a login con mensaje de exito

---
## FASE 4: Implementacion Frontend
**Responsable**: flutter-expert
**Status**: Completado
**Fecha**: 2026-01-14

### Estructura Clean Architecture

**Models**: `lib/features/auth/data/models/`
- `recuperacion_response_model.dart`
  - `SolicitudRecuperacionModel`: Respuesta de solicitar_recuperacion_contrasena
  - `ValidarTokenModel`: Respuesta de validar_token_recuperacion
  - `RestablecerContrasenaModel`: Respuesta de restablecer_contrasena

**DataSource**: `lib/features/auth/data/datasources/auth_remote_datasource.dart`
- `solicitarRecuperacion(email)` -> RPC `solicitar_recuperacion_contrasena`
- `validarTokenRecuperacion(token)` -> RPC `validar_token_recuperacion`
- `restablecerContrasena(token, nuevaContrasena, confirmarContrasena)` -> RPC `restablecer_contrasena`

**Repository**: `lib/features/auth/domain/repositories/auth_repository.dart`
- Interface con Either pattern para manejo de errores

**Repository Impl**: `lib/features/auth/data/repositories/auth_repository_impl.dart`
- Implementacion con conversion ServerException -> ServerFailure

**Bloc**: `lib/features/auth/presentation/bloc/recuperacion/`
- `recuperacion_bloc.dart`: Logica de negocio
- `recuperacion_event.dart`: Eventos (SolicitarRecuperacion, ValidarToken, RestablecerContrasena)
- `recuperacion_state.dart`: Estados (Initial, Loading, EmailEnviado, TokenValido, TokenInvalido, ContrasenaActualizada, Error)

### Integracion Backend

UI -> Bloc -> Repository -> DataSource -> RPC -> Backend

### Criterios de Aceptacion Frontend
- [x] **CA-001**: Formulario email en SolicitarRecuperacionEvent
- [x] **CA-002**: Estado RecuperacionEmailEnviado con mensaje
- [x] **CA-003**: Mensaje generico (RN-001) siempre igual
- [x] **CA-004**: ValidarTokenEvent -> RecuperacionTokenValido
- [x] **CA-005**: TokenErrorType.tokenExpirado/tokenUsado
- [x] **CA-006**: RestablecerContrasenaEvent -> RecuperacionContrasenaActualizada

### Reglas de Negocio Frontend
- [x] **RN-001**: Mensaje uniforme en RecuperacionEmailEnviado
- [x] **RN-002**: Manejo TokenErrorType.tokenExpirado
- [x] **RN-003**: Manejo TokenErrorType.tokenUsado
- [x] **RN-004**: Validacion local minimo 8 chars + backend valida complejidad
- [x] **RN-005**: Validacion _validarContrasenas() verifica coincidencia
- [x] **RN-006**: Mostrado en RecuperacionContrasenaActualizada.sesionesCerradas

### Verificacion
- [x] flutter analyze: 0 errores
- [x] Mapping snake_case <-> camelCase explicito
- [x] Either pattern en repository
- [x] Inyeccion de dependencias en injection_container.dart

---
## FASE 1: Diseno UX/UI
**Responsable**: ux-ui-expert
**Status**: Completado
**Fecha**: 2026-01-14

### Componentes UI Diseñados

**Paginas**:
- `solicitar_recuperacion_page.dart`: Formulario para solicitar recuperacion via email
- `restablecer_contrasena_page.dart`: Formulario para establecer nueva contrasena con token

**Widgets Reutilizados**:
- `PasswordStrengthIndicator`: Indicador visual de requisitos de contrasena (reutilizado de registro)
- `AppCard`: Card corporativa con variantes standard/elevated
- `AppTextField`: Campos de texto con variantes email/password
- `AppButton`: Boton primario con estados loading

**Rutas Agregadas** (`app_router.dart`):
- `/recuperar-contrasena` -> SolicitarRecuperacionPage
- `/restablecer-contrasena/:token` -> RestablecerContrasenaPage

**Navegacion Actualizada**:
- Login: Link "Olvidaste tu contrasena?" ahora navega a `/recuperar-contrasena`

### Funcionalidad UI

**SolicitarRecuperacionPage (CA-001, CA-002, CA-003)**:
- Formulario con campo email
- Boton "Enviar instrucciones" con estado loading
- Estado exito: Card verde con icono de email enviado
- Mensaje uniforme por seguridad (RN-001)
- Link "Volver al login"
- Boton "Enviar nuevamente" para reintentar

**RestablecerContrasenaPage (CA-004, CA-005, CA-006)**:
- Validacion automatica del token al cargar (ValidarTokenEvent)
- Estados visuales:
  - Loading: Spinner "Verificando enlace..."
  - Token invalido: Card con icono link_off y mensaje de error
  - Token expirado: Card con icono timer_off y mensaje (RN-002)
  - Token usado: Card con icono check_circle_outline (RN-003)
  - Token valido: Formulario de nueva contrasena
- Formulario nueva contrasena:
  - Saludo personalizado con nombre del usuario
  - Indicador de tiempo restante del token
  - Campo nueva contrasena + PasswordStrengthIndicator (RN-004)
  - Campo confirmar contrasena con validacion en tiempo real (RN-005)
  - Check verde cuando las contrasenas coinciden
- Dialog de exito:
  - Icono check verde animado
  - Mensaje de confirmacion
  - Indicador de sesiones cerradas (RN-006)
  - Boton "Iniciar sesion" que redirige a login

### Layout Responsive
- **Mobile (<600px)**: Formulario ancho completo, padding 16px, AppCard standard
- **Tablet/Desktop (>=600px)**: Card centrada maxWidth 420px, padding 24px, AppCard elevated

### Estados Visuales
- **Loading**: CircularProgressIndicator + texto descriptivo
- **Success**: Card verde con icono mark_email_read / check_circle
- **Error**: SnackBar con icono apropiado segun tipo de error
- **Token expirado**: Card con icono timer_off y color accentColor
- **Token usado**: Card con icono check_circle_outline y color outline
- **Token invalido**: Card con icono link_off y color error

### Criterios de Aceptacion UI
- [x] **CA-001**: Formulario email en SolicitarRecuperacionPage
- [x] **CA-002**: Estado RecuperacionEmailEnviado con card de exito
- [x] **CA-003**: Mensaje uniforme mostrado en card verde (RN-001)
- [x] **CA-004**: Formulario nueva contrasena cuando token valido
- [x] **CA-005**: Card de error con boton "Solicitar nuevo enlace"
- [x] **CA-006**: Dialog de exito con redireccion a login

### Reglas de Negocio UI
- [x] **RN-001**: Mensaje uniforme en card de exito (no revela si email existe)
- [x] **RN-002**: Indicador visual de tiempo restante + manejo expiracion
- [x] **RN-003**: Card especifica para token ya utilizado
- [x] **RN-004**: PasswordStrengthIndicator reutilizado de registro
- [x] **RN-005**: Validacion tiempo real + check verde cuando coinciden
- [x] **RN-006**: Indicador "Se cerraron todas las sesiones activas" en dialog

### Verificacion
- [x] flutter analyze: 0 errores
- [x] Responsive verificado: Mobile/Tablet/Desktop
- [x] Sin overflow warnings (SingleChildScrollView, ConstrainedBox)
- [x] Design System aplicado (DesignTokens, Theme-aware)
- [x] Consistente con login_page.dart y registro_page.dart

---

---
## FASE 5: Validacion QA Tecnica
**Responsable**: qa-testing-expert
**Fecha**: 2026-01-14

### Validacion Tecnica APROBADA

#### 1. Dependencias
```bash
$ flutter pub get
```
- Sin errores
- 35 packages con versiones mas recientes disponibles (incompatibles con constraints actuales)

#### 2. Analisis Estatico
```bash
$ flutter analyze --no-pub
```
- **Resultado**: No issues found! (ran in 1.7s)

#### 3. Tests
```bash
$ flutter test
```
- **Resultado**: All tests passed!
- **Nota**: Se actualizo widget_test.dart para registrar SessionBloc y RecuperacionBloc en GetIt

#### 4. Levantamiento
```bash
$ flutter run -d web-server --web-port 8080
```
- App activa en http://localhost:8080
- HTTP Status: 200 OK

### Archivos Verificados

| Archivo | Existe | Lineas |
|---------|--------|--------|
| `lib/features/auth/data/models/recuperacion_response_model.dart` | SI | 159 |
| `lib/features/auth/presentation/bloc/recuperacion/recuperacion_bloc.dart` | SI | 315 |
| `lib/features/auth/presentation/bloc/recuperacion/recuperacion_event.dart` | SI | - |
| `lib/features/auth/presentation/bloc/recuperacion/recuperacion_state.dart` | SI | - |
| `lib/features/auth/presentation/pages/solicitar_recuperacion_page.dart` | SI | 372 |
| `lib/features/auth/presentation/pages/restablecer_contrasena_page.dart` | SI | 711 |
| `supabase/sql-cloud/2026-01-14_HU-003_recuperacion_contrasena.sql` | SI | - |

### Rutas Configuradas

| Ruta | Pagina | Verificado |
|------|--------|------------|
| `/recuperar-contrasena` | SolicitarRecuperacionPage | SI |
| `/restablecer-contrasena/:token` | RestablecerContrasenaPage | SI |

### Resumen

| Validacion | Estado |
|------------|--------|
| Dependencias | PASS |
| Analisis Estatico | PASS |
| Tests | PASS |
| Compilacion Web | PASS |
| Archivos HU-003 | PASS |
| Rutas | PASS |

### Decision

**VALIDACION TECNICA APROBADA**

Siguiente paso: Usuario valida manualmente los CA en http://localhost:8080

---
