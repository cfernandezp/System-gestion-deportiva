# E001-HU-008: Login Biometrico (Opcional)

## INFORMACION
- **Codigo:** E001-HU-008
- **Epica:** E001 - Autenticacion y Gestion de Acceso
- **Titulo:** Login Biometrico (Huella Digital / Face ID)
- **Story Points:** 3 pts
- **Estado:** 🟢 Refinada
- **Prioridad:** Media
- **Fecha:** 2026-02-20

## HISTORIA
**Como** usuario de la app,
**Quiero** poder iniciar sesion con mi huella digital o reconocimiento facial,
**Para** acceder mas rapido sin tener que escribir mi celular y contrasena cada vez.

## Descripcion
El login biometrico es una funcionalidad 100% cliente (no requiere cambios en backend). Funciona como capa de conveniencia sobre el login existente: el usuario se autentica normalmente la primera vez, activa el biometrico, y en posteriores aperturas de la app usa su huella o rostro para ingresar automaticamente.

### Criterios de Aceptacion

#### CA-001: Ofrecimiento post-login exitoso
- [ ] **DADO** que acabo de iniciar sesion exitosamente con celular y contrasena
- [ ] **CUANDO** el dispositivo tiene sensor biometrico configurado (huella o Face ID)
- [ ] **ENTONCES** el sistema me pregunta si quiero activar el inicio de sesion con biometrico

#### CA-002: Activar biometrico
- [ ] **DADO** que acepto activar el login biometrico
- [ ] **CUANDO** confirmo con mi huella o rostro
- [ ] **ENTONCES** el sistema almacena mi token de sesion de forma segura en el dispositivo y me confirma que el biometrico esta activo

#### CA-003: Login con biometrico
- [ ] **DADO** que tengo el login biometrico activo
- [ ] **CUANDO** abro la app y mi sesion no ha expirado
- [ ] **ENTONCES** el sistema me pide mi huella o rostro y al verificar me lleva directo a mi grupo (o selector de grupos)

#### CA-004: Fallback a login normal
- [ ] **DADO** que el login biometrico falla (huella no reconocida, 3 intentos fallidos)
- [ ] **CUANDO** no puedo autenticarme con biometrico
- [ ] **ENTONCES** el sistema me muestra la opcion de ingresar con celular y contrasena normalmente

#### CA-005: Desactivar biometrico
- [ ] **DADO** que tengo el login biometrico activo
- [ ] **CUANDO** voy a configuracion de mi cuenta y desactivo el biometrico
- [ ] **ENTONCES** el sistema elimina el token almacenado y el proximo login sera con celular y contrasena

#### CA-006: Token expirado
- [ ] **DADO** que tengo biometrico activo pero mi sesion/token expiro
- [ ] **CUANDO** intento usar biometrico para ingresar
- [ ] **ENTONCES** el sistema me informa que debo iniciar sesion nuevamente con celular y contrasena

#### CA-007: Dispositivo sin biometrico
- [ ] **DADO** que mi dispositivo no tiene sensor biometrico o no lo tiene configurado
- [ ] **CUANDO** inicio sesion
- [ ] **ENTONCES** el sistema NO ofrece la opcion de biometrico y el login es siempre con celular y contrasena

#### CA-008: Respetar tema activo
- [ ] **DADO** que la pantalla de biometrico se muestra
- [ ] **CUANDO** tengo modo oscuro o claro activo
- [ ] **ENTONCES** la pantalla se muestra correctamente en ambos modos

## Reglas de Negocio (RN)

### RN-001: Biometrico es opcional, nunca obligatorio
**Contexto**: Al ofrecer login biometrico al usuario.
**Restriccion**: El usuario siempre puede rechazar y seguir usando celular + contrasena.
**Validacion**: El sistema ofrece activar biometrico UNA vez despues del primer login exitoso. Si rechaza, no vuelve a preguntar hasta que el usuario lo active manualmente desde configuracion.
**Caso especial**: Si el usuario cierra sesion (logout), al volver a loguearse se puede volver a ofrecer.

### RN-002: Almacenamiento seguro del token
**Contexto**: Al activar el login biometrico.
**Restriccion**: El token de sesion NO se almacena en texto plano. Debe usar almacenamiento seguro del dispositivo.
**Validacion**: En Android se usa el Keystore, en iOS el Keychain. El token solo es accesible tras verificacion biometrica exitosa.
**Caso especial**: Si el usuario elimina su huella del dispositivo, el token almacenado se invalida automaticamente por el sistema operativo.

### RN-003: Biometrico no reemplaza la autenticacion servidor
**Contexto**: Al usar biometrico para ingresar.
**Restriccion**: El biometrico desbloquea un token previamente autenticado. No es una autenticacion independiente.
**Validacion**: Si el token almacenado esta expirado o es invalido, el biometrico no sirve y el usuario debe re-autenticarse con celular + contrasena.
**Caso especial**: El tiempo de vida del token depende de la configuracion de Supabase Auth (por defecto 1 hora para access token, pero el refresh token dura mas).

### RN-004: Maximo 3 intentos biometricos fallidos
**Contexto**: Cuando el biometrico no reconoce al usuario.
**Restriccion**: No permitir intentos infinitos.
**Validacion**: Despues de 3 intentos fallidos de biometrico, el sistema muestra automaticamente el formulario de login con celular + contrasena. No bloquea la cuenta.
**Caso especial**: El limite de intentos lo gestiona el sistema operativo nativo, no la app.

### RN-005: Logout limpia el biometrico
**Contexto**: Cuando el usuario cierra sesion voluntariamente.
**Restriccion**: No dejar tokens almacenados tras un logout.
**Validacion**: Al hacer logout (E001-HU-006), el token almacenado para biometrico se elimina. El usuario debera activar biometrico nuevamente tras el proximo login.
**Caso especial**: Si la sesion expira sin logout explicito, el token almacenado se intenta usar pero fallara y pedira re-login.

### RN-006: Disponible para todos los roles
**Contexto**: Al ofrecer login biometrico.
**Restriccion**: No limitar biometrico a un rol especifico.
**Validacion**: Tanto admin, co-admin como jugador pueden usar login biometrico. No es una feature premium, esta disponible para todos los planes incluyendo Gratis.
**Caso especial**: Ninguno.

## NOTAS
- Es una funcionalidad 100% cliente. NO requiere cambios en backend ni en Supabase.
- Costo: S/ 0 - usa capacidades nativas del dispositivo.
- Package Flutter sugerido: `local_auth` (oficial de Flutter team).
- Almacenamiento seguro sugerido: `flutter_secure_storage`.
- Disponible para TODOS los planes (Gratis incluido). No es feature premium.
- Prioridad Media: mejora UX pero no bloquea funcionalidad de negocio.
- Se recomienda implementar DESPUES de completar E001 y E002 (no es critico para MVP).
- HU define QUE desde perspectiva usuario. Detalles tecnicos los definen agentes especializados.
