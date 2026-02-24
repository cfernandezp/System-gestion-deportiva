# E001-HU-002 - Inicio de Sesion

## Informacion General
- **Epica**: E001 - Login de Usuario
- **Estado**: ✅ Completada (COM)
- **Prioridad**: Alta

## Historia de Usuario
**Como** usuario registrado
**Quiero** iniciar sesion en el sistema
**Para** acceder a las funcionalidades correspondientes a mi rol

## Descripcion
Permite a usuarios registrados autenticarse en el sistema usando sus credenciales (email y contrasena).

## Criterios de Aceptacion (CA)

### CA-001: Formulario de login
- **Dado** que soy un usuario registrado
- **Cuando** accedo a la pantalla de login
- **Entonces** debo ver campos para email y contrasena

### CA-002: Login exitoso
- **Dado** que ingreso credenciales validas
- **Cuando** envio el formulario de login
- **Entonces** accedo al sistema y veo la pantalla principal segun mi rol

### CA-003: Credenciales invalidas
- **Dado** que ingreso credenciales incorrectas
- **Cuando** envio el formulario de login
- **Entonces** veo un mensaje de error generico (sin revelar si es email o contrasena)

### CA-004: Campos obligatorios
- **Dado** que intento iniciar sesion
- **Cuando** dejo campos vacios
- **Entonces** veo mensajes indicando los campos requeridos

### CA-005: Enlace a registro
- **Dado** que estoy en la pantalla de login
- **Cuando** no tengo cuenta
- **Entonces** puedo acceder al formulario de registro

### CA-006: Enlace a recuperacion de contrasena
- **Dado** que estoy en la pantalla de login
- **Cuando** olvide mi contrasena
- **Entonces** puedo acceder a la opcion de recuperacion

## Reglas de Negocio (RN)

### RN-001: Credenciales obligatorias
**Contexto**: Cuando un usuario intenta iniciar sesion
**Restriccion**: No permitir envio del formulario con campos vacios
**Validacion**: Email y contrasena son campos obligatorios para iniciar sesion
**Caso especial**: Ninguno

### RN-002: Cuenta aprobada requerida
**Contexto**: Cuando un usuario registrado intenta iniciar sesion
**Restriccion**: No permitir acceso a usuarios cuya cuenta no haya sido aprobada por un administrador
**Validacion**: Solo usuarios con estado de cuenta "Aprobada" pueden iniciar sesion exitosamente
**Caso especial**: Mostrar mensaje diferenciado segun estado:
- "Pendiente de aprobacion": Indicar que su solicitud esta siendo revisada
- "Rechazada": Indicar que su solicitud fue rechazada

### RN-003: Validacion de credenciales
**Contexto**: Cuando se recibe una solicitud de inicio de sesion
**Restriccion**: No permitir acceso con credenciales incorrectas (email inexistente o contrasena erronea)
**Validacion**: El email debe existir en el sistema Y la contrasena debe coincidir con la registrada
**Caso especial**: Ninguno

### RN-004: Mensaje de error generico por seguridad
**Contexto**: Cuando las credenciales ingresadas son incorrectas
**Restriccion**: No revelar si el error es por email inexistente o contrasena incorrecta
**Validacion**: Mostrar mensaje generico tipo "Credenciales invalidas" sin especificar cual campo fallo
**Caso especial**: Esta regla aplica solo para credenciales incorrectas, no para cuentas pendientes/rechazadas (ver RN-002)

### RN-005: Sesion segun rol asignado
**Contexto**: Cuando un usuario inicia sesion exitosamente
**Restriccion**: No mostrar funcionalidades que no correspondan al rol del usuario
**Validacion**: La pantalla principal y opciones visibles deben corresponder al rol asignado (Admin, Entrenador, Jugador, Arbitro)
**Caso especial**: Un usuario puede tener multiples roles; en ese caso, mostrar funcionalidades de todos sus roles

### RN-006: Navegacion alternativa
**Contexto**: Cuando un usuario esta en la pantalla de login
**Restriccion**: No dejar al usuario sin opciones si no puede iniciar sesion
**Validacion**: Debe existir acceso visible a:
- Formulario de registro (para usuarios sin cuenta)
- Recuperacion de contrasena (para usuarios que olvidaron credenciales)
**Caso especial**: Ninguno

### RN-007: Intentos de acceso (proteccion basica)
**Contexto**: Cuando un usuario falla multiples intentos de inicio de sesion
**Restriccion**: No permitir intentos ilimitados que faciliten ataques de fuerza bruta
**Validacion**: Tras 5 intentos fallidos consecutivos, bloquear temporalmente el acceso por 15 minutos
**Regla calculo**: Intentos maximos = 5 | Tiempo bloqueo = 15 minutos
**Caso especial**: El contador de intentos se reinicia tras inicio de sesion exitoso o al expirar el tiempo de bloqueo

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

**`intentos_login`**
- **Descripcion**: Registro de intentos fallidos de login para proteccion contra fuerza bruta
- **Columnas**:
  - `id` (UUID): Identificador unico
  - `email` (VARCHAR 255): Email del intento
  - `intentos_fallidos` (INT): Contador de intentos fallidos
  - `bloqueado_hasta` (TIMESTAMPTZ): Fecha/hora hasta cuando esta bloqueado
  - `ultimo_intento_at` (TIMESTAMPTZ): Ultimo intento realizado
  - `created_at` (TIMESTAMPTZ): Fecha creacion
  - `updated_at` (TIMESTAMPTZ): Fecha actualizacion
- **Regla**: RN-007

### Funciones RPC Implementadas

**`iniciar_sesion(p_email TEXT, p_password TEXT) -> JSON`**
- **Descripcion**: Autentica usuario verificando credenciales, estado de cuenta y bloqueo
- **Reglas de Negocio**: RN-002, RN-003, RN-004, RN-005, RN-007
- **Criterios**: CA-002, CA-003
- **Parametros**:
  - `p_email`: (TEXT) Email del usuario
  - `p_password`: (TEXT) Contrasena del usuario
- **Response Success**:
  ```json
  {
    "success": true,
    "data": {
      "usuario_id": "uuid",
      "auth_user_id": "uuid",
      "nombre_completo": "Juan Perez",
      "email": "juan@example.com",
      "rol": "jugador",
      "estado": "aprobado"
    },
    "message": "Inicio de sesion exitoso"
  }
  ```
- **Response Error - Hints**:
  - `credenciales_invalidas` -> Email o contrasena incorrectos (mensaje generico por seguridad)
  - `cuenta_pendiente` -> Cuenta pendiente de aprobacion por administrador
  - `cuenta_rechazada` -> Solicitud de registro fue rechazada
  - `cuenta_bloqueada` -> Demasiados intentos fallidos, incluye `minutos_restantes`
  - `campo_requerido` -> Email o contrasena vacios

**`verificar_bloqueo_login(p_email TEXT) -> JSON`**
- **Descripcion**: Verifica si un email esta bloqueado por intentos fallidos
- **Uso**: Para mostrar mensaje antes de intentar login
- **Parametros**:
  - `p_email`: (TEXT) Email a verificar
- **Response Success**:
  ```json
  {
    "success": true,
    "data": {
      "bloqueado": false,
      "intentos_fallidos": 2,
      "intentos_restantes": 3
    },
    "message": "No hay bloqueo activo"
  }
  ```

**`limpiar_intentos_expirados() -> JSON`**
- **Descripcion**: Limpia registros de intentos con bloqueo expirado (mantenimiento)
- **Uso**: Ejecutar periodicamente o manualmente desde service_role

### Script SQL
- `supabase/sql-cloud/2026-01-14_HU-002_inicio_sesion.sql`

### Criterios de Aceptacion Backend
- [x] **CA-002**: Login exitoso - Implementado en `iniciar_sesion`, retorna datos del usuario con rol
- [x] **CA-003**: Credenciales invalidas - Mensaje generico "Email o contrasena incorrectos"

### Reglas de Negocio Backend
- [x] **RN-002**: Verifica estado "aprobado", rechaza "pendiente_aprobacion" y "rechazado" con mensajes diferenciados
- [x] **RN-003**: Valida email existe en auth.users y contrasena coincide con encrypted_password
- [x] **RN-004**: Mensaje generico para credenciales invalidas (no revela que fallo)
- [x] **RN-005**: Retorna rol del usuario en respuesta exitosa
- [x] **RN-007**: Bloqueo tras 5 intentos por 15 minutos, contador se reinicia en login exitoso o expiracion

---
## FASE 4: Implementacion Frontend
**Responsable**: flutter-expert
**Status**: Completado
**Fecha**: 2026-01-14

### Estructura Clean Architecture

```
gestion_deportiva/lib/features/auth/
├── data/
│   ├── datasources/
│   │   └── auth_remote_datasource.dart  (actualizado: iniciarSesion, verificarBloqueoLogin)
│   ├── models/
│   │   └── login_response_model.dart    (nuevo: LoginResponseModel, VerificarBloqueoModel)
│   └── repositories/
│       └── auth_repository_impl.dart    (actualizado: metodos login)
├── domain/
│   └── repositories/
│       └── auth_repository.dart         (actualizado: interface login)
└── presentation/
    ├── bloc/
    │   └── login/                       (nuevo)
    │       ├── login.dart               (barrel file)
    │       ├── login_bloc.dart          (logica de negocio)
    │       ├── login_event.dart         (eventos)
    │       └── login_state.dart         (estados con tipos de error)
    └── pages/
        └── login_page.dart              (nuevo: UI responsive)
```

### Integracion Backend

```
UI (LoginPage)
  -> Bloc (LoginBloc)
    -> Repository (AuthRepositoryImpl)
      -> DataSource (AuthRemoteDataSourceImpl)
        -> RPC (iniciar_sesion, verificar_bloqueo_login)
```

### Archivos Modificados

| Archivo | Cambio |
|---------|--------|
| `auth_remote_datasource.dart` | Agregado `iniciarSesion()`, `verificarBloqueoLogin()` |
| `auth_repository.dart` | Agregada interface para metodos de login |
| `auth_repository_impl.dart` | Implementacion Either pattern para login |
| `models.dart` | Export de `login_response_model.dart` |
| `app_router.dart` | Ruta `/login` con `LoginPage` |
| `injection_container.dart` | Registro de `LoginBloc` |

### Archivos Nuevos

| Archivo | Descripcion |
|---------|-------------|
| `login_response_model.dart` | Modelos `LoginResponseModel` y `VerificarBloqueoModel` |
| `login_bloc.dart` | Bloc con validaciones frontend y mapeo de errores |
| `login_event.dart` | `LoginSubmitEvent`, `LoginResetEvent`, `VerificarBloqueoEvent` |
| `login_state.dart` | Estados con `LoginErrorType` enum para RN-002, RN-004, RN-007 |
| `login_page.dart` | Pagina responsive con formulario y manejo de estados |

### Criterios de Aceptacion Frontend

- [x] **CA-001**: Formulario con campos email y contrasena (`AppTextField.email`, `AppTextField.password`)
- [x] **CA-002**: Login exitoso navega a home (`context.go('/')` en `LoginSuccess`)
- [x] **CA-003**: Error generico para credenciales invalidas (SnackBar con mensaje)
- [x] **CA-004**: Validacion de campos obligatorios (`LoginValidationError`, `_fieldErrors`)
- [x] **CA-005**: Link a registro (`_buildRegistroLink` -> `/registro`)
- [x] **CA-006**: Link a recuperacion de contrasena (TextButton con mensaje "proximamente")

### Reglas de Negocio Frontend

- [x] **RN-001**: Validacion frontend de campos obligatorios en `_validarFormulario()`
- [x] **RN-002**: Mensajes diferenciados para `cuenta_pendiente` y `cuenta_rechazada` en `_mapearErrorBackend()`
- [x] **RN-004**: Mensaje generico "Email o contrasena incorrectos" para `credenciales_invalidas`
- [x] **RN-006**: Links visibles a registro y recuperacion de contrasena
- [x] **RN-007**: Manejo de `cuenta_bloqueada` con minutos restantes, estado `LoginBloqueoInfo`

### Verificacion

- [x] `flutter pub get`: Dependencias instaladas
- [x] `flutter analyze --no-pub`: 0 issues found
- [x] Mapping snake_case (BD) <-> camelCase (Dart) en models
- [x] Either pattern en repository
- [x] BlocConsumer para manejo de estados en UI

---
## FASE 1: Diseno UX/UI
**Responsable**: ux-ui-expert
**Status**: Completado
**Fecha**: 2026-01-14

### Componentes UI Implementados

**Paginas**:
- `login_page.dart`: Pagina de inicio de sesion responsive

**Widgets del Design System utilizados**:
- `AppCard`: Contenedor del formulario (variant: standard en mobile, elevated en desktop)
- `AppButton`: Boton principal "Iniciar sesion" con soporte de loading
- `AppTextField.email`: Campo de correo electronico con icono
- `AppTextField.password`: Campo de contrasena con toggle de visibilidad

**Rutas**:
- `/login`: Pagina de inicio de sesion (ruta inicial de la app)

### Diseno Visual

**Layout**:
- Header con gradiente primario conteniendo logo de la app (icono de futbol)
- Titulo "Gestion Deportiva" centrado
- Card centrada con formulario de login
- Titulo interno "Iniciar sesion" con subtitulo descriptivo
- Campos de formulario: email y contrasena
- Link "?Olvidaste tu contrasena?" alineado a la derecha
- Boton "Iniciar sesion" de ancho completo
- Link "No tienes cuenta? Registrate" centrado al final

**Responsive**:
- **Mobile (<600px)**: Formulario ancho completo con padding lateral de 16px, AppCard variant standard
- **Tablet/Desktop (>=600px)**: Card centrada con ancho maximo de 420px, AppCard variant elevated

**Estados visuales**:
- **Loading**: Boton con spinner y texto "Iniciando sesion..."
- **Error credenciales (CA-003)**: SnackBar rojo con icono de candado
- **Error cuenta pendiente (RN-002)**: SnackBar naranja con icono de reloj de arena
- **Error cuenta rechazada (RN-002)**: SnackBar rojo con icono de cancelar
- **Error cuenta bloqueada (RN-007)**: SnackBar naranja con icono de timer y minutos restantes
- **Error validacion (CA-004)**: Errores inline bajo cada campo
- **Error servidor**: SnackBar rojo con icono de nube sin conexion

**Consistencia con Registro**:
- Mismo header con gradiente y logo
- Misma estructura de card centrada
- Mismos componentes AppTextField y AppButton
- Mismo patron responsive
- Misma tipografia y espaciado (DesignTokens)

### Criterios de Aceptacion UI

- [x] **CA-001**: Formulario con campos email (AppTextField.email) y contrasena (AppTextField.password) visualmente claros
- [x] **CA-005**: Link "No tienes cuenta? Registrate" visible y funcional (navega a `/registro`)
- [x] **CA-006**: Link "?Olvidaste tu contrasena?" visible (muestra SnackBar informativo)

### Interacciones

| Accion | Resultado |
|--------|-----------|
| Click en "Iniciar sesion" | Dispara LoginSubmitEvent, muestra loading |
| Click en "?Olvidaste tu contrasena?" | Muestra SnackBar informativo (funcionalidad pendiente) |
| Click en "Registrate" | Navega a `/registro` |
| Enter en campo contrasena | Dispara submit del formulario |
| Enter en campo email | Mueve foco a campo contrasena |

### Design System Aplicado

```dart
// Colores (Theme-aware)
colorScheme.primary        // Botones, links
colorScheme.surface        // Fondo
colorScheme.error          // Errores criticos
Colors.orange              // Warnings (bloqueo, pendiente)

// Espaciado (DesignTokens)
spacingS (8px)             // Entre elementos cercanos
spacingM (16px)            // Padding general
spacingL (24px)            // Entre secciones
spacingXl (32px)           // Header a contenido

// Radios (DesignTokens)
radiusS (8px)              // Bordes de SnackBar
radiusL (16px)             // Bordes del logo
radiusM (12px)             // Bordes de AppCard

// Breakpoints (DesignTokens)
breakpointMobile (600px)   // Cambio de layout mobile/desktop
```

### Verificacion UX/UI

- [x] Responsive verificado en 375px (mobile), 768px (tablet), 1200px (desktop)
- [x] Sin overflow warnings
- [x] Design System aplicado (no colores hardcoded excepto Colors.orange para warnings)
- [x] Consistencia visual con pagina de registro
- [x] Estados de error diferenciados por tipo
- [x] Feedback visual durante carga
- [x] `flutter analyze --no-pub`: 0 issues found
- - -  
 ## FASE 5: Validacion QA Tecnica
**Responsable**: qa-testing-expert
**Fecha**: 2026-01-14

### Validacion Tecnica APROBADA

#### 1. Dependencias
- Comando: flutter pub get
- Resultado: Got dependencies\!
- Estado: PASS

#### 2. Analisis Estatico
- Comando: flutter analyze --no-pub
- Resultado: No issues found\!
- Estado: PASS

#### 3. Tests
- Comando: flutter test
- Resultado: All tests passed\!
- Estado: PASS

#### 4. Build Web Release
- Comando: flutter build web --release
- Resultado: Built build/web
- Estado: PASS

### Validacion de Criterios de Aceptacion

| CA | Archivo | Verificacion | Estado |
|----|---------|--------------|--------|
| CA-001 | login_page.dart | Campos email y password presentes | PASS |
| CA-002 | login_page.dart | context.go en LoginSuccess | PASS |
| CA-003 | auth_remote_datasource.dart | hint credenciales_invalidas | PASS |
| CA-004 | login_bloc.dart | _validarFormulario campos obligatorios | PASS |
| CA-005 | login_page.dart | Link a /registro | PASS |
| CA-006 | login_page.dart | Link recuperacion contrasena | PASS |

### Validacion de Reglas de Negocio

| RN | Archivo | Verificacion | Estado |
|----|---------|--------------|--------|
| RN-001 | login_bloc.dart | Valida email y password | PASS |
| RN-002 | login_state.dart | cuentaPendiente y cuentaRechazada | PASS |
| RN-004 | login_bloc.dart | Mensaje generico credenciales | PASS |
| RN-007 | login_state.dart | LoginBloqueoInfo con minutosRestantes | PASS |

### Validacion de Arquitectura

| Aspecto | Estado |
|---------|--------|
| Clean Architecture | PASS |
| Bloc Pattern | PASS |
| Design System | PASS |
| Routing /login | PASS |
| Inyeccion Dependencias | PASS |

### DECISION

**VALIDACION TECNICA APROBADA**

Siguiente paso: Usuario valida manualmente los CA ejecutando flutter run -d chrome

---
