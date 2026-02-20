# E001-HU-002: Inicio de Sesion

## INFORMACION
- **Codigo:** E001-HU-002
- **Epica:** E001 - Autenticacion y Gestion de Acceso
- **Titulo:** Inicio de Sesion
- **Story Points:** 3 pts
- **Estado:** ✅ Completada
- **Prioridad:** Alta
- **Fecha:** 2026-02-20

## HISTORIA
**Como** usuario registrado,
**Quiero** iniciar sesion con mi numero de celular y contrasena,
**Para** acceder al sistema y gestionar mis actividades deportivas.

### Criterios de Aceptacion

#### CA-001: Login exitoso con un solo grupo
- [x] **DADO** que soy un usuario registrado con cuenta activa y pertenezco a un unico grupo
- [x] **CUANDO** ingreso mi numero de celular y contrasena correctos
- [x] **ENTONCES** el sistema me autentica y me lleva directamente a la pantalla principal de ese grupo

#### CA-002: Login exitoso con multiples grupos
- [x] **DADO** que soy un usuario registrado con cuenta activa y pertenezco a mas de un grupo
- [x] **CUANDO** ingreso mi numero de celular y contrasena correctos
- [x] **ENTONCES** el sistema me autentica y me lleva a la pantalla de seleccion de grupo (ver E001-HU-003)

#### CA-003: Credenciales incorrectas
- [x] **DADO** que estoy en la pantalla de inicio de sesion
- [x] **CUANDO** ingreso un celular o contrasena incorrectos
- [x] **ENTONCES** el sistema muestra un mensaje generico "Credenciales incorrectas" sin revelar si el celular existe o no en el sistema

#### CA-004: Proteccion contra intentos repetidos
- [x] **DADO** que se han realizado multiples intentos fallidos de inicio de sesion para un mismo celular
- [x] **CUANDO** se supera el limite de intentos permitidos
- [x] **ENTONCES** el sistema bloquea temporalmente los intentos de login para ese celular y muestra un mensaje indicando el tiempo de espera

#### CA-005: Cuenta en estado pendiente de activacion
- [x] **DADO** que fui invitado a un grupo pero aun no he activado mi cuenta
- [x] **CUANDO** intento iniciar sesion con mi numero de celular
- [x] **ENTONCES** el sistema me informa que debo activar mi cuenta primero y me ofrece ir a la pantalla de activacion

#### CA-006: Usuario sin grupos asociados
- [x] **DADO** que soy un usuario con cuenta activa pero no pertenezco a ningun grupo
- [x] **CUANDO** inicio sesion exitosamente
- [x] **ENTONCES** el sistema me redirige a la pantalla de creacion de grupo

## Reglas de Negocio (RN)

### RN-001: Autenticacion por celular y contrasena
**Contexto**: Al iniciar sesion en la aplicacion.
**Restriccion**: No se permite autenticacion por email, redes sociales ni ningun otro metodo. El unico mecanismo es celular + contrasena.
**Validacion**: El sistema debe verificar que el numero de celular exista en el sistema y que la contrasena proporcionada coincida con la registrada para esa cuenta.
**Caso especial**: Las cuentas en estado "pendiente de activacion" no pueden completar el login normal (ver RN-005).

### RN-002: Bloqueo temporal por intentos fallidos
**Contexto**: Cuando se realizan multiples intentos fallidos de inicio de sesion para un mismo numero de celular.
**Restriccion**: No se permite continuar intentando login despues de alcanzar el limite de intentos fallidos.
**Validacion**: Tras 5 intentos fallidos consecutivos para un mismo celular, el sistema bloquea los intentos de login para ese celular durante 15 minutos. El contador se reinicia tras un login exitoso o tras cumplirse el tiempo de bloqueo.
**Caso especial**: El bloqueo es por numero de celular, no por dispositivo. Si el usuario tiene acceso a otro dispositivo, el bloqueo sigue aplicando para ese celular.

### RN-003: Mensaje de error generico por seguridad
**Contexto**: Cuando un intento de inicio de sesion falla por credenciales incorrectas.
**Restriccion**: No se debe revelar al usuario si el numero de celular existe o no en el sistema. Tampoco se debe indicar si el error es en el celular o en la contrasena.
**Validacion**: El sistema debe mostrar siempre el mismo mensaje generico "Credenciales incorrectas" independientemente de si el celular no existe o si la contrasena es incorrecta.
**Caso especial**: Este criterio no aplica para cuentas en estado "pendiente de activacion", donde si se informa al usuario que debe activar su cuenta.

### RN-004: Navegacion post-login segun cantidad de grupos
**Contexto**: Despues de un inicio de sesion exitoso.
**Restriccion**: No se debe mostrar la pantalla de seleccion de grupo si el usuario solo pertenece a un grupo.
**Validacion**: Si el usuario pertenece a 1 solo grupo, se redirige directamente a la pantalla principal de ese grupo. Si pertenece a multiples grupos, se redirige a la pantalla de seleccion de grupo (ver E001-HU-003). Si no pertenece a ningun grupo, se redirige a la pantalla de creacion de grupo.
**Caso especial**: Un usuario que era admin de un grupo eliminado y no tiene otros grupos debe ser redirigido a la pantalla de creacion de grupo.

### RN-005: Restriccion de login para cuentas pendientes de activacion
**Contexto**: Cuando un usuario con cuenta en estado "pendiente de activacion" intenta iniciar sesion.
**Restriccion**: No se permite el inicio de sesion normal para cuentas que no han sido activadas.
**Validacion**: El sistema debe detectar que la cuenta esta pendiente de activacion e informar al usuario que debe activar su cuenta primero, ofreciendo la opcion de ir a la pantalla de activacion (ver E001-HU-005).
**Caso especial**: Este es el unico caso donde el sistema revela informacion sobre el estado de la cuenta, ya que es necesario para guiar al usuario invitado.

## IMPLEMENTACION

### Archivos Modificados
- `lib/features/auth/presentation/bloc/login/login_event.dart` - Eventos: email → celular
- `lib/features/auth/presentation/bloc/login/login_state.dart` - Estados: agregado cuentaPendienteActivacion
- `lib/features/auth/presentation/bloc/login/login_bloc.dart` - BLoC: validacion celular, email derivado, mapeo errores
- `lib/features/auth/presentation/pages/login_page.dart` - UI: campo celular (9 digitos, teclado numerico)

### Decisiones Tecnicas
- **Email derivado**: Celular se convierte a `{celular}@gestiondeportiva.app` para Supabase Auth (misma convencion que E001-HU-001)
- **Sin cambios en backend**: El DataSource/Repository existente ya acepta email como string, se reutiliza con el email derivado
- **Validacion frontend**: Celular 9 digitos, inicia con 9 (formato Peru)
- **AppTextField.number**: Se usa constructor .number() con prefixIcon phone_android y maxLength 9

## NOTAS
- El mensaje de error ante credenciales incorrectas debe ser generico por seguridad: no debe revelar si el numero de celular existe o no en el sistema.
- El bloqueo por intentos fallidos es temporal para evitar ataques de fuerza bruta. La duracion y cantidad de intentos son configurables como regla de negocio.
- HU define QUE desde perspectiva usuario. Detalles tecnicos los definen agentes especializados.
