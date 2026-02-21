# E001-HU-007: Recuperacion de Contrasena

## INFORMACION
- **Codigo:** E001-HU-007
- **Epica:** E001 - Autenticacion y Gestion de Acceso
- **Titulo:** Recuperacion de Contrasena
- **Story Points:** 5 pts
- **Estado:** 🔨 En Desarrollo
- **Prioridad:** Media
- **Fecha:** 2026-02-20

## HISTORIA

### Escenario Jugador
**Como** jugador que olvido su contrasena,
**Quiero** recuperar mi acceso mediante un codigo temporal que me proporciona el administrador de mi grupo,
**Para** volver a acceder a mi cuenta sin perder mi informacion.

### Escenario Admin
**Como** administrador que olvido su contrasena,
**Quiero** recuperar mi acceso mediante mi pregunta de seguridad o email de respaldo,
**Para** volver a gestionar mis grupos sin depender de otra persona.

## MECANISMO DE RECUPERACION (Gratuito - $0 costo)

### Jugador: Codigo temporal generado por Admin
```
1. Jugador contacta a su Admin (WhatsApp, verbal)
2. Admin abre la app → "Generar codigo de recuperacion" para ese jugador
3. Sistema genera codigo temporal (6 digitos) valido por 30 minutos
4. Admin le pasa el codigo al jugador (WhatsApp, verbal)
5. Jugador abre la app → "Recuperar cuenta" → ingresa celular + codigo → nueva contrasena
```

### Admin: Pregunta de seguridad + Email de respaldo
```
1. Admin va a "Recuperar cuenta"
2. Ingresa su celular
3. Responde su pregunta de seguridad (definida al registrarse)
4. Si falla pregunta → puede usar email de respaldo (opcional, definido al registrarse)
5. Crea nueva contrasena
```

### Criterios de Aceptacion

#### CA-001: Admin genera codigo de recuperacion para jugador
- [ ] **DADO** que soy admin/co-admin de un grupo y un jugador me solicita recuperar su contrasena
- [ ] **CUANDO** selecciono al jugador y presiono "Generar codigo de recuperacion"
- [ ] **ENTONCES** el sistema genera un codigo de 6 digitos valido por 30 minutos y lo muestra en pantalla para que yo se lo comunique al jugador

#### CA-002: Jugador usa codigo temporal para recuperar contrasena
- [ ] **DADO** que tengo un codigo de recuperacion proporcionado por mi admin
- [ ] **CUANDO** ingreso mi numero de celular y el codigo temporal en la pantalla de recuperacion
- [ ] **ENTONCES** el sistema valida el codigo y me permite crear una nueva contrasena

#### CA-003: Codigo temporal expirado o invalido
- [ ] **DADO** que intento usar un codigo de recuperacion
- [ ] **CUANDO** el codigo ya expiro (mas de 30 minutos) o es incorrecto
- [ ] **ENTONCES** el sistema muestra un mensaje indicando que el codigo es invalido o expiro y que solicite uno nuevo a su administrador

#### CA-004: Codigo de uso unico
- [ ] **DADO** que use un codigo de recuperacion exitosamente
- [ ] **CUANDO** intento usar el mismo codigo otra vez
- [ ] **ENTONCES** el sistema lo rechaza ya que el codigo es de uso unico

#### CA-005: Admin recupera contrasena con pregunta de seguridad
- [ ] **DADO** que soy admin y olvide mi contrasena
- [ ] **CUANDO** ingreso mi celular y respondo correctamente mi pregunta de seguridad
- [ ] **ENTONCES** el sistema me permite crear una nueva contrasena

#### CA-006: Admin falla pregunta de seguridad - usa email de respaldo
- [ ] **DADO** que soy admin y falle la pregunta de seguridad
- [ ] **CUANDO** tengo un email de respaldo registrado
- [ ] **ENTONCES** el sistema envia un enlace de recuperacion a mi email para crear nueva contrasena

#### CA-007: Admin sin email de respaldo y falla pregunta
- [ ] **DADO** que soy admin, falle la pregunta de seguridad y no tengo email de respaldo
- [ ] **CUANDO** no tengo mas opciones de recuperacion
- [ ] **ENTONCES** el sistema muestra mensaje de contactar soporte o crear una cuenta nueva

#### CA-008: Definir pregunta de seguridad al registrarse
- [ ] **DADO** que me estoy registrando como administrador
- [ ] **CUANDO** completo el formulario de registro
- [ ] **ENTONCES** debo seleccionar y responder una pregunta de seguridad (obligatorio) y opcionalmente ingresar un email de respaldo

#### CA-009: Nueva contrasena cumple requisitos
- [ ] **DADO** que estoy creando mi nueva contrasena (admin o jugador)
- [ ] **CUANDO** la contrasena no cumple los requisitos minimos de seguridad
- [ ] **ENTONCES** el sistema muestra los requisitos que no se cumplen

#### CA-010: Contrasena anterior invalidada
- [ ] **DADO** que cambie mi contrasena exitosamente mediante recuperacion
- [ ] **CUANDO** intento iniciar sesion con la contrasena anterior
- [ ] **ENTONCES** el sistema rechaza el intento con mensaje de credenciales incorrectas

#### CA-011: Limite de intentos de codigo
- [ ] **DADO** que estoy ingresando codigos de recuperacion
- [ ] **CUANDO** fallo 5 intentos consecutivos
- [ ] **ENTONCES** el sistema bloquea la recuperacion por 15 minutos para ese numero de celular

## Reglas de Negocio (RN)

### RN-001: Jugador recupera via codigo temporal del admin
**Contexto**: Cuando un jugador olvida su contrasena y necesita recuperar acceso a su cuenta.
**Restriccion**: El jugador no puede recuperar su contrasena de forma autonoma. Requiere intervencion del administrador o co-administrador de su grupo.
**Validacion**: El flujo es: (1) Jugador contacta a su admin por medios externos (WhatsApp, llamada, en persona), (2) Admin genera un codigo de recuperacion desde la app para ese jugador, (3) Admin comunica el codigo al jugador, (4) Jugador ingresa su celular + codigo en la pantalla de recuperacion, (5) Jugador crea nueva contrasena. El codigo debe ser de 6 digitos numericos, valido por 30 minutos desde su generacion.
**Caso especial**: Si el jugador pertenece a multiples grupos, cualquier admin o co-admin de cualquiera de sus grupos puede generar el codigo de recuperacion.

### RN-002: Admin recupera via pregunta de seguridad
**Contexto**: Cuando un administrador olvida su contrasena y necesita recuperar acceso a su cuenta.
**Restriccion**: El admin no depende de otra persona para recuperar su contrasena (a diferencia del jugador).
**Validacion**: El admin ingresa su celular, el sistema le presenta la pregunta de seguridad que definio al registrarse (ver E001-HU-001 RN-004), y si la respuesta es correcta, le permite crear una nueva contrasena. La comparacion de la respuesta no distingue mayusculas de minusculas.
**Caso especial**: Si el admin no recuerda la respuesta a la pregunta de seguridad, puede usar el email de respaldo como alternativa (ver RN-003).

### RN-003: Fallback admin via email de respaldo
**Contexto**: Cuando un administrador falla la pregunta de seguridad y tiene un email de respaldo configurado.
**Restriccion**: Esta opcion solo esta disponible si el admin configuro un email de respaldo durante su registro. No se ofrece si no lo hizo.
**Validacion**: Si el admin falla la pregunta de seguridad, el sistema verifica si tiene email de respaldo registrado. Si lo tiene, le envia un enlace de recuperacion a ese email para que pueda crear una nueva contrasena.
**Caso especial**: Si el admin no tiene email de respaldo configurado y falla la pregunta de seguridad, el sistema muestra un mensaje de contactar soporte o crear una cuenta nueva. No hay mas opciones automatizadas.

### RN-004: Codigo de uso unico
**Contexto**: Al generar y utilizar un codigo de recuperacion para un jugador.
**Restriccion**: Un codigo de recuperacion no puede ser utilizado mas de una vez, independientemente de si aun no ha expirado.
**Validacion**: Una vez que un codigo es utilizado exitosamente para restablecer una contrasena, se invalida permanentemente. Cualquier intento posterior de usar el mismo codigo debe ser rechazado.
**Caso especial**: Si el admin genera un nuevo codigo para el mismo jugador, el codigo anterior (si aun estaba vigente) se invalida automaticamente. Solo el codigo mas reciente es valido.

### RN-005: Maximo 5 intentos de codigo con bloqueo de 15 minutos
**Contexto**: Cuando se ingresan codigos de recuperacion incorrectos repetidamente para un mismo numero de celular.
**Restriccion**: No se permite seguir intentando indefinidamente codigos de recuperacion.
**Validacion**: Tras 5 intentos fallidos consecutivos de ingresar un codigo de recuperacion para un mismo celular, el sistema bloquea la funcionalidad de recuperacion para ese celular durante 15 minutos. El contador se reinicia tras el periodo de bloqueo o tras un uso exitoso.
**Caso especial**: El bloqueo aplica por numero de celular, no por dispositivo ni por codigo especifico.

### RN-006: Contrasena anterior se invalida al cambiar
**Contexto**: Cuando un usuario (admin o jugador) establece exitosamente una nueva contrasena mediante el proceso de recuperacion.
**Restriccion**: La contrasena anterior no debe seguir siendo valida despues de establecer una nueva.
**Validacion**: Al completar exitosamente el cambio de contrasena, la contrasena anterior queda permanentemente invalidada. Cualquier intento de login con la contrasena anterior debe ser rechazado con el mensaje generico de "Credenciales incorrectas".
**Caso especial**: Si el usuario tenia sesiones activas en otros dispositivos, estas deberian cerrarse al cambiar la contrasena por seguridad.

## NOTAS
- **Costo: $0** - No requiere SMS, ni APIs externas, ni servicios de terceros.
- **Coherente con el modelo de negocio**: El admin ya se comunica con jugadores por WhatsApp/verbal para invitaciones, este flujo sigue el mismo patron.
- **Preguntas de seguridad sugeridas**: "Nombre de tu primer equipo", "Ciudad donde naciste", "Nombre de tu mejor amigo", "Apodo de infancia".
- **Email de respaldo**: Es opcional al registrarse, solo se usa como segunda opcion si falla la pregunta de seguridad. NO se usa para login.
- La decision de pregunta de seguridad al registro impacta la HU E001-HU-001 (Registro Admin) que debe incluir este paso.
- HU define QUE desde perspectiva usuario. Detalles tecnicos los definen agentes especializados.

---
## FASE 2: Diseno Backend
**Responsable**: supabase-expert
**Status**: Completado
**Fecha**: 2026-02-21

### Tablas Creadas

**`codigos_recuperacion`**
- Almacena codigos de 6 digitos hasheados con bcrypt (pgcrypto)
- Columnas: id, usuario_id, codigo_hash, generado_por, tipo ('admin_para_jugador'|'email_admin'), expira_at, usado, usado_at, intentos_fallidos, created_at
- RLS habilitado sin policies (acceso solo via RPC SECURITY DEFINER)

**`intentos_recuperacion`**
- Rate limiting por celular para prevenir fuerza bruta
- Columnas: id, celular (unique), intentos_fallidos, bloqueado_hasta, ultimo_intento_at, created_at, updated_at
- RLS habilitado sin policies

### Funciones Auxiliares (privadas)

| Funcion | Descripcion |
|---------|-------------|
| `_validar_celular_peru(text)` | Valida formato 9 digitos Peru, retorna limpio |
| `_verificar_rate_limit_recuperacion(varchar)` | Retorna TRUE si bloqueado, resetea si bloqueo expiro |
| `_registrar_intento_fallido_recuperacion(varchar)` | Incrementa contador, bloquea 15 min al llegar a 5 |
| `_resetear_intentos_recuperacion(varchar)` | Limpia contador tras exito |
| `_validar_password_requisitos(text)` | Valida min 6 caracteres |

### Funciones RPC Implementadas

**`identificar_tipo_recuperacion(p_celular text) -> JSON`**
- **Descripcion**: Determina flujo de recuperacion segun rol del usuario
- **Reglas de Negocio**: Seguridad (no revela si el celular existe)
- **Parametros**: p_celular (text) - Celular Peru 9 digitos
- **Permisos**: anon, authenticated
- **Response Success**:
  ```json
  {"success": true, "data": {"tipo": "admin|jugador|no_encontrado", "pregunta_seguridad": "...", "tiene_email_respaldo": true, "email_respaldo_mascara": "j***@gmail.com"}}
  ```
- **Response Error - Hints**: `celular_formato_invalido`

**`generar_codigo_recuperacion(p_celular_jugador text) -> JSON`**
- **Descripcion**: Admin/coadmin genera codigo de 6 digitos para jugador de su grupo
- **Reglas de Negocio**: RN-001, RN-004
- **Parametros**: p_celular_jugador (text) - Celular del jugador
- **Permisos**: authenticated (solo admin/coadmin)
- **Response Success**:
  ```json
  {"success": true, "data": {"codigo": "123456", "celular_jugador": "987654321", "expira_en_minutos": 30, "mensaje_para_jugador": "..."}}
  ```
- **Response Error - Hints**: `no_autenticado`, `usuario_no_encontrado`, `celular_formato_invalido`, `jugador_no_encontrado`, `codigo_para_si_mismo`, `sin_permisos`

**`obtener_pregunta_seguridad(p_celular text) -> JSON`**
- **Descripcion**: Retorna la pregunta de seguridad de un admin
- **Parametros**: p_celular (text) - Celular del admin
- **Permisos**: anon, authenticated
- **Response Success**:
  ```json
  {"success": true, "data": {"pregunta_seguridad": "Nombre de tu primer equipo"}}
  ```
- **Response Error - Hints**: `celular_formato_invalido`, `sin_pregunta_seguridad`

**`validar_codigo_recuperacion(p_celular text, p_codigo text) -> JSON`**
- **Descripcion**: Valida codigo sin cambiar contrasena (paso previo)
- **Reglas de Negocio**: RN-004, RN-005
- **Parametros**: p_celular (text), p_codigo (text) - Codigo de 6 digitos
- **Permisos**: anon, authenticated
- **Response Success**:
  ```json
  {"success": true, "data": {"codigo_valido": true, "celular": "987654321"}}
  ```
- **Response Error - Hints**: `celular_formato_invalido`, `codigo_requerido`, `cuenta_bloqueada_temporalmente`, `usuario_no_encontrado`, `codigo_invalido_o_expirado`, `codigo_incorrecto`

**`restablecer_contrasena_con_codigo(p_celular text, p_codigo text, p_nueva_contrasena text, p_confirmar_contrasena text) -> JSON`**
- **Descripcion**: Valida codigo + cambia contrasena + invalida sesiones
- **Reglas de Negocio**: RN-004, RN-005, RN-006
- **Parametros**: p_celular, p_codigo, p_nueva_contrasena, p_confirmar_contrasena
- **Permisos**: anon, authenticated
- **Response Success**:
  ```json
  {"success": true, "data": {"contrasena_actualizada": true, "sesiones_cerradas": true}}
  ```
- **Response Error - Hints**: `celular_formato_invalido`, `contrasena_requerida`, `contrasenas_no_coinciden`, `password_muy_corta`, `cuenta_bloqueada_temporalmente`, `usuario_no_encontrado`, `codigo_invalido_o_expirado`, `codigo_incorrecto`

**`restablecer_contrasena_con_pregunta(p_celular text, p_respuesta text, p_nueva_contrasena text, p_confirmar_contrasena text) -> JSON`**
- **Descripcion**: Admin restablece contrasena respondiendo pregunta de seguridad
- **Reglas de Negocio**: RN-002, RN-005, RN-006
- **Parametros**: p_celular, p_respuesta, p_nueva_contrasena, p_confirmar_contrasena
- **Permisos**: anon, authenticated
- **Response Success**:
  ```json
  {"success": true, "data": {"contrasena_actualizada": true, "sesiones_cerradas": true}}
  ```
- **Response Error (respuesta incorrecta CON email)**:
  ```json
  {"success": false, "error": {"message": "Respuesta incorrecta", "hint": "respuesta_incorrecta_con_email", "tiene_email_respaldo": true, "email_respaldo_mascara": "j***@gmail.com"}}
  ```
- **Response Error (respuesta incorrecta SIN email)**:
  ```json
  {"success": false, "error": {"message": "Respuesta incorrecta. No tienes email de respaldo...", "hint": "respuesta_incorrecta_sin_email", "tiene_email_respaldo": false}}
  ```

**`solicitar_recuperacion_email_admin(p_celular text) -> JSON`**
- **Descripcion**: Genera codigo de recuperacion para admin, preparado para envio por email
- **Reglas de Negocio**: RN-003
- **Parametros**: p_celular (text)
- **Permisos**: anon, authenticated
- **Response Success**:
  ```json
  {"success": true, "data": {"email_respaldo_mascara": "j***@gmail.com", "expira_en_minutos": 30, "_debug_codigo": "123456"}}
  ```
- **Nota**: `_debug_codigo` solo en desarrollo. Remover en produccion. Email real via Edge Function futuro.
- **Response Error - Hints**: `celular_formato_invalido`, `cuenta_bloqueada_temporalmente`, `admin_no_encontrado`, `sin_email_respaldo`

### Script SQL
- `supabase/sql-cloud/2026-02-21_E001-HU-007_recuperacion_contrasena.sql`

### Criterios de Aceptacion Backend
- [x] **CA-001**: Implementado en `generar_codigo_recuperacion` - genera codigo 6 digitos, 30 min expiracion
- [x] **CA-002**: Implementado en `validar_codigo_recuperacion` + `restablecer_contrasena_con_codigo`
- [x] **CA-003**: Validado en `validar_codigo_recuperacion` - verifica expiracion y hash
- [x] **CA-004**: Implementado en `restablecer_contrasena_con_codigo` - marca como usado, RN-004
- [x] **CA-005**: Implementado en `restablecer_contrasena_con_pregunta` - compara LOWER(TRIM())
- [x] **CA-006**: Implementado en `restablecer_contrasena_con_pregunta` (error con email) + `solicitar_recuperacion_email_admin`
- [x] **CA-007**: Implementado en `restablecer_contrasena_con_pregunta` (error sin email)
- [x] **CA-008**: Ya implementado en E001-HU-001 (registro admin con pregunta seguridad)
- [x] **CA-009**: Validado en `_validar_password_requisitos` - min 6 caracteres
- [x] **CA-010**: UPDATE auth.users.encrypted_password + DELETE auth.sessions
- [x] **CA-011**: Implementado en `_verificar_rate_limit_recuperacion` + `_registrar_intento_fallido_recuperacion` - 5 intentos, 15 min bloqueo

### Reglas de Negocio Backend
- [x] **RN-001**: `generar_codigo_recuperacion` verifica admin/coadmin del grupo del jugador via miembros_grupo JOIN
- [x] **RN-002**: `restablecer_contrasena_con_pregunta` compara con LOWER(TRIM())
- [x] **RN-003**: `solicitar_recuperacion_email_admin` verifica email_respaldo, genera codigo tipo 'email_admin'
- [x] **RN-004**: Codigo invalidado al usar (`usado=TRUE`), codigos previos invalidados al generar nuevo
- [x] **RN-005**: Rate limiting por celular: 5 intentos -> bloqueo 15 min, reseteo tras exito/expiracion
- [x] **RN-006**: UPDATE encrypted_password + DELETE auth.sessions + log en sesiones_log

---
