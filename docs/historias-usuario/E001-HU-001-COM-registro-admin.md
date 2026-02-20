# E001-HU-001: Registro de Administrador

## INFORMACION
- **Codigo:** E001-HU-001
- **Epica:** E001 - Autenticacion y Gestion de Acceso
- **Titulo:** Registro de Administrador
- **Story Points:** 5 pts
- **Estado:** ✅ Completada
- **Prioridad:** Alta
- **Fecha:** 2026-02-20

## HISTORIA
**Como** persona interesada en organizar partidos de futbol,
**Quiero** registrarme con mi numero de celular, nombre y contrasena,
**Para** crear mi cuenta de administrador y poder gestionar grupos deportivos.

### Criterios de Aceptacion

#### CA-001: Registro exitoso con datos validos
- [x] **DADO** que soy una persona nueva que quiere usar la aplicacion
- [x] **CUANDO** ingreso mi numero de celular en formato valido, mi nombre completo y una contrasena que cumple los requisitos de seguridad
- [x] **ENTONCES** el sistema crea mi cuenta con estado activo y me redirige a la pantalla de crear mi primer grupo

#### CA-002: Celular ya registrado en el sistema
- [x] **DADO** que intento registrarme con un numero de celular
- [x] **CUANDO** ese numero ya esta asociado a una cuenta existente en el sistema
- [x] **ENTONCES** el sistema muestra un mensaje indicando que el numero ya esta registrado y sugiere iniciar sesion o recuperar contrasena

#### CA-003: Validacion de formato de celular
- [x] **DADO** que estoy en el formulario de registro
- [x] **CUANDO** ingreso un numero de celular con formato invalido (menos o mas digitos de los esperados, caracteres no numericos)
- [x] **ENTONCES** el sistema muestra un mensaje de error indicando el formato correcto esperado

#### CA-004: Validacion de contrasena segura
- [x] **DADO** que estoy completando el formulario de registro
- [x] **CUANDO** ingreso una contrasena que no cumple los requisitos minimos de seguridad (largo minimo, combinacion de caracteres)
- [x] **ENTONCES** el sistema muestra los requisitos que no se cumplen para que pueda corregirla

#### CA-005: Nombre obligatorio
- [x] **DADO** que estoy completando el formulario de registro
- [x] **CUANDO** intento enviar el formulario sin ingresar mi nombre
- [x] **ENTONCES** el sistema me indica que el nombre es un campo obligatorio

#### CA-006: Pregunta de seguridad obligatoria
- [x] **DADO** que estoy completando el formulario de registro
- [x] **CUANDO** llego al paso de seguridad
- [x] **ENTONCES** debo seleccionar una pregunta de seguridad de una lista predefinida y proporcionar mi respuesta (obligatorio). Esta se usara para recuperar mi contrasena en el futuro.

#### CA-007: Email de respaldo opcional
- [x] **DADO** que estoy completando el formulario de registro
- [x] **CUANDO** llego al campo de email de respaldo
- [x] **ENTONCES** puedo ingresar opcionalmente un email que servira como segunda opcion de recuperacion de contrasena

#### CA-008: Redireccion post-registro
- [x] **DADO** que mi cuenta se creo exitosamente
- [x] **CUANDO** el sistema confirma el registro
- [x] **ENTONCES** soy redirigido automaticamente a la pantalla de creacion de mi primer grupo deportivo

## Reglas de Negocio (RN)

### RN-001: Celular como identificador unico global
**Contexto**: Al registrar una nueva cuenta de administrador en el sistema.
**Restriccion**: No se permite registrar dos cuentas con el mismo numero de celular. El celular reemplaza al email como identificador principal del usuario.
**Validacion**: El sistema debe verificar que el numero de celular no exista previamente en el sistema antes de completar el registro. Si ya existe, debe sugerir iniciar sesion o recuperar contrasena.
**Caso especial**: Un celular puede estar asociado a multiples grupos, pero siempre corresponde a una unica cuenta de usuario.

### RN-002: Formato celular Peru
**Contexto**: Al ingresar el numero de celular en el formulario de registro.
**Restriccion**: No se aceptan numeros que no cumplan el formato peruano de celular movil.
**Validacion**: El numero debe tener exactamente 9 digitos, debe iniciar con el digito 9, y solo debe contener caracteres numericos.
**Caso especial**: No se requiere codigo de pais (+51); el sistema asume Peru como pais por defecto.

### RN-003: Requisitos de contrasena segura
**Contexto**: Al crear la contrasena durante el registro de administrador.
**Restriccion**: No se permite establecer contrasenas que no cumplan todos los requisitos minimos de seguridad.
**Validacion**: La contrasena debe tener un minimo de 8 caracteres, al menos una letra mayuscula, al menos una letra minuscula, al menos un numero y al menos un caracter especial (por ejemplo: @, #, $, %, &, !, ?).
**Caso especial**: Los mismos requisitos aplican para jugadores al activar su cuenta (ver E001-HU-005) y al cambiar contrasena por recuperacion (ver E001-HU-007).

### RN-004: Pregunta de seguridad obligatoria al registro admin
**Contexto**: Durante el proceso de registro de un nuevo administrador.
**Restriccion**: No se puede completar el registro sin haber seleccionado y respondido una pregunta de seguridad.
**Validacion**: El administrador debe seleccionar una pregunta de una lista predefinida ("Nombre de tu primer equipo", "Ciudad donde naciste", "Nombre de tu mejor amigo", "Apodo de infancia") y proporcionar una respuesta no vacia.
**Caso especial**: La respuesta a la pregunta de seguridad no distingue mayusculas de minusculas al momento de la verificacion (ver E001-HU-007).

### RN-005: Email de respaldo opcional
**Contexto**: Durante el registro de un nuevo administrador, en el paso de datos de seguridad.
**Restriccion**: El email de respaldo NO se usa para inicio de sesion ni como identificador del usuario. Solo se usa como segunda opcion de recuperacion de contrasena.
**Validacion**: Si el administrador decide ingresar un email, este debe tener un formato valido de correo electronico. Si no lo ingresa, el registro se completa igualmente.
**Caso especial**: Si el admin no configura email de respaldo y luego falla la pregunta de seguridad, no tendra opcion automatizada de recuperar su contrasena (debera contactar soporte o crear cuenta nueva).

### RN-006: Cuenta admin activa inmediatamente sin verificacion
**Contexto**: Al completar exitosamente el formulario de registro de administrador.
**Restriccion**: No se requiere verificacion por SMS, email ni ningun otro mecanismo externo para activar la cuenta.
**Validacion**: La cuenta del administrador pasa a estado "activo" inmediatamente despues del registro exitoso, permitiendo el uso completo del sistema.
**Caso especial**: Esto difiere del flujo de jugadores invitados, quienes tienen estado "pendiente de activacion" hasta que completen su proceso de activacion (ver E001-HU-005).

## NOTAS
- El numero de celular es el identificador unico del usuario en todo el sistema (no email).
- Este flujo es exclusivamente para quien quiere crear un grupo y ser administrador. Los jugadores ingresan al sistema mediante invitacion del administrador (ver E001-HU-004 y E001-HU-005).
- La cuenta se activa inmediatamente tras el registro, sin necesidad de verificacion por SMS o email.
- **Pregunta de seguridad**: Obligatoria al registrarse. Se usa para recuperar contrasena (ver E001-HU-007). Preguntas sugeridas: "Nombre de tu primer equipo", "Ciudad donde naciste", "Nombre de tu mejor amigo", "Apodo de infancia".
- **Email de respaldo**: Opcional. Solo se usa como segunda opcion si falla la pregunta de seguridad. NO se usa para login.
- HU define QUE desde perspectiva usuario. Detalles tecnicos los definen agentes especializados.

---

## IMPLEMENTACION TECNICA

### FASE 2: Backend (SQL)

**Script:** `supabase/sql-cloud/2026-02-20_E001-HU-001_registrar_administrador.sql`

- ALTER TABLE `usuarios`: nuevas columnas `celular`, `pregunta_seguridad`, `respuesta_seguridad`, `email_respaldo`
- UNIQUE INDEX en `celular` (RN-001)
- RPC `registrar_administrador(p_auth_user_id, p_celular, p_nombre_completo, p_pregunta_seguridad, p_respuesta_seguridad, p_email_respaldo)`
- Validaciones: formato celular Peru 9 digitos (RN-002), celular unico (RN-001), pregunta/respuesta obligatoria (RN-004), email formato valido (RN-005)
- Respuesta almacenada en minusculas para comparacion case-insensitive (RN-004)
- Estado = 'activo', rol = 'administrador' (RN-006)

### FASE 4: Frontend

**Archivos creados:**
```
lib/features/auth/data/models/
  registro_admin_response_model.dart     # Modelo respuesta registro admin
lib/features/auth/presentation/bloc/registro_admin/
  registro_admin.dart                    # Barrel export
  registro_admin_bloc.dart               # BLoC con validaciones frontend
  registro_admin_event.dart              # RegistroAdminSubmitEvent, ValidarPasswordAdminEvent
  registro_admin_state.dart              # States: Initial, Loading, Success, Error, Validation
```

**Archivos modificados:**
- `lib/features/auth/data/datasources/auth_remote_datasource.dart` - Nuevo metodo `registrarAdministrador()` con signUp(email derivado) + RPC
- `lib/features/auth/domain/repositories/auth_repository.dart` - Interfaz con `registrarAdministrador()`
- `lib/features/auth/data/repositories/auth_repository_impl.dart` - Implementacion delegando a datasource
- `lib/features/auth/presentation/pages/registro_page.dart` - Reescrita con formulario basado en celular
- `lib/core/di/injection_container.dart` - Registro de `RegistroAdminBloc`

**Estrategia Supabase Auth:** Email derivado `{celular}@gestiondeportiva.app` para mantener compatibilidad con `signUp(email:)` y `signInWithPassword(email:)`. El celular real se almacena en tabla `usuarios`.

**Formulario:** Nombre, celular (9 digitos, solo numeros), contrasena con indicador de fuerza, confirmar contrasena, pregunta de seguridad (dropdown), respuesta, email de respaldo (opcional).

**Post-registro:** Sesion se mantiene activa (RN-006), SessionBloc se actualiza y GoRouter redirige a home via refreshListenable.

### FASE 1: UX/UI

**RegistroPage:** Scaffold + SingleChildScrollView con AppCard
- Header con logo gradient + titulo "Gestion Deportiva"
- Card: titulo "Crear cuenta de administrador", subtitulo "Registrate para organizar tus partidos"
- Campos: nombre (TextCapitalization.words), celular (phone keyboard, max 9 digitos), password + indicador fuerza, confirmar password
- Separador visual "Seguridad"
- DropdownButtonFormField con 4 preguntas predefinidas (RN-004)
- Campo respuesta de seguridad
- Campo email respaldo (opcional) con texto helper explicativo
- Boton "Crear cuenta" con estado loading
- Link "Ya tienes cuenta? Inicia sesion"
- Usa colorScheme para dark/light mode

### FASE 5: QA

**flutter analyze:** 0 errores nuevos
**Validacion CA:**
- CA-001: registrarAdministrador con celular, nombre, password, pregunta seguridad -> estado activo
- CA-002: celular_duplicado hint -> mensaje amigable sugiriendo login
- CA-003: Validacion frontend (9 digitos, inicia con 9) + backend (RN-002)
- CA-004: PasswordStrengthIndicator + ValidarPasswordAdminEvent en tiempo real
- CA-005: Validacion frontend nombre obligatorio min 2 chars
- CA-006: DropdownButtonFormField obligatorio + respuesta obligatoria
- CA-007: Campo email respaldo opcional con validacion formato
- CA-008: SessionAuthenticatedEvent post-registro -> GoRouter redirige a home
**Validacion RN:**
- RN-001: UNIQUE INDEX en celular + verificacion en RPC
- RN-002: Regex validacion 9 digitos inicia con 9 (frontend + backend)
- RN-003: Delegado a validar_password RPC existente
- RN-004: Dropdown 4 preguntas, respuesta almacenada lowercase
- RN-005: Email formato regex validado si no vacio
- RN-006: Estado 'activo' inmediato, sesion no se cierra post-registro
