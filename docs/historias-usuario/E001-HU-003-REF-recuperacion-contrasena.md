# E001-HU-003 - Recuperacion de Contrasena

## Informacion General
- **Epica**: E001 - Login de Usuario
- **Estado**: 🟢 Refinada (REF)
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
**Ultima actualizacion**: 2025-01-13
