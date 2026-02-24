# E003-HU-001: Configurar Limites del Grupo

## INFORMACION
- **Codigo:** E003-HU-001
- **Epica:** E003 - Configuracion y Limites del Grupo
- **Titulo:** Configurar Limites del Grupo
- **Story Points:** 5 pts
- **Estado:** Refinada
- **Prioridad:** Alta
- **Fecha:** 2026-02-20

## HISTORIA
**Como** administrador de un grupo deportivo,
**Quiero** configurar los limites de mi grupo desde una pantalla de configuracion,
**Para** adaptar el funcionamiento del grupo a mis necesidades dentro de lo que permite mi plan.

### Criterios de Aceptacion

#### CA-001: Acceso a la pantalla de configuracion
- [ ] **DADO** que soy administrador del grupo
- [ ] **CUANDO** accedo al menu de opciones del grupo
- [ ] **ENTONCES** veo una opcion de "Configuracion" que me lleva a la pantalla de limites y parametros del grupo

#### CA-002: Visualizacion de limites actuales
- [ ] **DADO** que estoy en la pantalla de configuracion del grupo
- [ ] **CUANDO** se carga la pantalla
- [ ] **ENTONCES** veo todos los limites del grupo con sus valores actuales, incluyendo: maximo de jugadores por grupo, maximo de co-admins por grupo, maximo de grupos que puedo administrar, y tamano maximo de logo

#### CA-003: Modificar limite editable dentro del rango permitido
- [ ] **DADO** que estoy en la pantalla de configuracion y mi plan permite editar ciertos limites (ejemplo: maximo de jugadores)
- [ ] **CUANDO** modifico el valor de un limite editable a un valor dentro del rango permitido por mi plan
- [ ] **ENTONCES** el sistema acepta el cambio y lo deja listo para guardar

#### CA-004: Intento de exceder el rango del plan
- [ ] **DADO** que estoy editando un limite configurable
- [ ] **CUANDO** intento establecer un valor que excede el rango maximo permitido por mi plan actual
- [ ] **ENTONCES** el sistema muestra un mensaje indicando que ese valor no esta disponible en mi plan y sugiere actualizar al plan pago para obtener limites mayores

#### CA-005: Limites de solo lectura segun el plan
- [ ] **DADO** que estoy en la pantalla de configuracion
- [ ] **CUANDO** veo limites que son definidos por el sistema segun mi plan (ejemplo: maximo de grupos, tamano maximo de logo)
- [ ] **ENTONCES** esos limites se muestran como solo lectura, con una indicacion clara de que son establecidos por el plan contratado

#### CA-006: Guardar cambios con confirmacion
- [ ] **DADO** que he modificado uno o mas limites editables
- [ ] **CUANDO** presiono el boton de guardar
- [ ] **ENTONCES** el sistema solicita confirmacion antes de aplicar los cambios y, al confirmar, guarda los nuevos valores mostrando un mensaje de exito

#### CA-007: Valores por defecto al crear un grupo nuevo
- [ ] **DADO** que soy un administrador que acaba de crear un grupo nuevo
- [ ] **CUANDO** el grupo se crea exitosamente
- [ ] **ENTONCES** el grupo se inicializa con los valores por defecto del plan Gratis: maximo 25 jugadores, maximo 1 co-admin, maximo 1 grupo por administrador, maximo 1 invitado, maximo 2 equipos por fecha, tamano de logo maximo 2MB

#### CA-008: Acceso denegado para roles no autorizados
- [ ] **DADO** que soy un co-admin o jugador del grupo
- [ ] **CUANDO** intento acceder a la opcion de edicion de configuracion
- [ ] **ENTONCES** el sistema no me muestra la opcion de editar (co-admin ve solo lectura, jugador no ve la pantalla)

## Reglas de Negocio (RN)

### RN-001: Solo el administrador puede modificar la configuracion del grupo
**Contexto**: Cuando un usuario accede a la pantalla de configuracion del grupo.
**Restriccion**: Ningun otro rol (co-admin, jugador) puede modificar los parametros del grupo.
**Validacion**: Unicamente el usuario con rol de administrador del grupo puede editar y guardar cambios en la configuracion.
**Caso especial**: Si un administrador es degradado a co-admin mientras esta en la pantalla, al intentar guardar debe rechazarse la operacion.

### RN-002: Co-administrador accede en modo solo lectura
**Contexto**: Cuando un co-administrador accede a la configuracion del grupo.
**Restriccion**: No se le deben mostrar controles de edicion ni botones de guardar.
**Validacion**: El co-admin puede visualizar todos los parametros y limites vigentes pero sin posibilidad de modificarlos.
**Caso especial**: Ninguno.

### RN-003: Jugador sin acceso a configuracion
**Contexto**: Cuando un jugador navega por las opciones del grupo.
**Restriccion**: La opcion de configuracion no debe ser visible ni accesible para el rol jugador.
**Validacion**: El menu del grupo para un jugador no incluye la entrada de "Configuracion".
**Caso especial**: Si un jugador intenta acceder directamente a la pantalla (por ejemplo, mediante un enlace compartido), debe ser redirigido o recibir un mensaje de acceso denegado.

### RN-004: Limites editables por el administrador
**Contexto**: Cuando el administrador modifica parametros en la pantalla de configuracion.
**Restriccion**: Solo puede editar los parametros que su plan permite modificar. En el plan Gratis, el unico parametro editable es el maximo de jugadores por grupo.
**Validacion**: El valor debe estar dentro del rango minimo y maximo permitido por el plan contratado. Para el plan Gratis, el maximo de jugadores no puede superar 25.
**Caso especial**: En planes de pago, se habilitan parametros adicionales como editables con limites mayores.

### RN-005: Limites de solo lectura definidos por el plan
**Contexto**: Cuando se muestran parametros que el sistema define segun el plan contratado.
**Restriccion**: Estos parametros no pueden ser editados por ningun usuario, independientemente de su rol.
**Validacion**: Los parametros de solo lectura en el plan Gratis son: maximo de grupos por administrador (1), tamano maximo de logo (2MB), maximo de co-admins por grupo (1), maximo de invitados por grupo (1) y maximo de equipos por fecha (2). Deben mostrarse con una indicacion visual de que son definidos por el plan.
**Caso especial**: En un plan pago, algunos de estos parametros podrian pasar a ser editables o tener valores superiores.

### RN-006: Valores por defecto al crear un grupo
**Contexto**: Cuando un administrador crea un grupo nuevo en el sistema.
**Restriccion**: No se permite crear un grupo sin valores de configuracion iniciales.
**Validacion**: Todo grupo nuevo se inicializa automaticamente con los valores por defecto del plan del admin. Plan Gratis: maximo 25 jugadores, maximo 1 co-admin, maximo 1 grupo por administrador, maximo 1 invitado, maximo 2 equipos por fecha y tamano de logo maximo 2MB.
**Caso especial**: Los valores por defecto son configurables a nivel de sistema y pueden ajustarse sin necesidad de actualizar la aplicacion.

### RN-007: No reducir limite por debajo del uso actual
**Contexto**: Cuando el administrador intenta reducir el limite de jugadores del grupo.
**Restriccion**: No se permite establecer un valor inferior a la cantidad de miembros actualmente registrados en el grupo.
**Validacion**: Si el grupo tiene 28 jugadores activos, el limite minimo que puede configurarse es 28. El sistema debe informar al administrador de esta restriccion.
**Caso especial**: Si se quiere reducir el limite, primero se deben eliminar miembros del grupo hasta que la cantidad actual sea menor o igual al nuevo limite deseado.

### RN-008: Sugerencia de upgrade al exceder limite del plan gratuito
**Contexto**: Cuando el administrador intenta establecer un valor que supera lo permitido por su plan actual.
**Restriccion**: El sistema no debe permitir guardar valores fuera del rango del plan contratado.
**Validacion**: Al intentar exceder el limite, el sistema debe mostrar un mensaje claro indicando que el valor no esta disponible en el plan actual y sugerir la actualizacion al plan pago para obtener limites mayores.
**Caso especial**: El mensaje de upgrade debe ser informativo y no bloqueante; el administrador puede cerrar la sugerencia y continuar usando los limites actuales.

## NOTAS
- En el plan Gratis, el unico limite editable por el administrador es el maximo de jugadores por grupo (hasta el tope de 25). Los demas limites son fijos y definidos por el sistema.
- En planes de pago (Plan 5, 10, 15, 20), se desbloquean limites mayores y nuevos parametros configurables. La pantalla debe contemplar esta distincion visual entre lo incluido en el plan y lo que requiere upgrade.
- Los valores por defecto del plan Gratis (25 jugadores, 1 grupo, 2MB logo, 1 co-admin, 1 invitado, 2 equipos) son los definidos en E000-HU-002.
- Los limites deben ser configurables a nivel de sistema (no fijos en el codigo), para facilitar cambios futuros sin necesidad de actualizaciones de la aplicacion.
- HU define QUE desde perspectiva usuario. Detalles tecnicos los definen agentes especializados.
