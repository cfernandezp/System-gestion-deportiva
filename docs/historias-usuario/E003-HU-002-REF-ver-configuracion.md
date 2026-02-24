# E003-HU-002: Ver Configuracion del Grupo

## INFORMACION
- **Codigo:** E003-HU-002
- **Epica:** E003 - Configuracion y Limites del Grupo
- **Titulo:** Ver Configuracion del Grupo
- **Story Points:** 2 pts
- **Estado:** Refinada
- **Prioridad:** Media
- **Fecha:** 2026-02-20

## HISTORIA
**Como** administrador o co-administrador del grupo,
**Quiero** ver la configuracion actual del grupo con todos sus limites y parametros vigentes,
**Para** conocer las restricciones operativas y saber cuanto margen tengo disponible.

### Criterios de Aceptacion

#### CA-001: Vista de solo lectura para co-admin
- [ ] **DADO** que soy co-administrador del grupo
- [ ] **CUANDO** accedo a la seccion de configuracion desde el menu del grupo
- [ ] **ENTONCES** veo toda la configuracion en modo solo lectura, sin opciones de edicion

#### CA-002: Mostrar limite de jugadores con uso actual
- [ ] **DADO** que estoy viendo la configuracion del grupo
- [ ] **CUANDO** se muestra el limite de jugadores
- [ ] **ENTONCES** veo la cantidad actual de jugadores en el grupo y el maximo permitido segun el plan (ejemplo: "20 de 25 jugadores" en Gratis)

#### CA-003: Mostrar limite de grupos del administrador
- [ ] **DADO** que estoy viendo la configuracion del grupo
- [ ] **CUANDO** se muestra el limite de grupos
- [ ] **ENTONCES** veo la cantidad de grupos que el administrador gestiona actualmente y el maximo permitido por su plan (ejemplo: "1 de 1 grupos" en Gratis)

#### CA-004: Mostrar limite de co-admins con uso actual
- [ ] **DADO** que estoy viendo la configuracion del grupo
- [ ] **CUANDO** se muestra el limite de co-administradores
- [ ] **ENTONCES** veo la cantidad actual de co-admins en el grupo y el maximo permitido segun el plan (ejemplo: "0 de 1 co-admins" en Gratis)

#### CA-005: Mostrar tamano maximo de logo
- [ ] **DADO** que estoy viendo la configuracion del grupo
- [ ] **CUANDO** se muestra el parametro de logo
- [ ] **ENTONCES** veo el tamano maximo permitido para el logo del grupo segun el plan actual

#### CA-006: Distincion entre limites del plan gratuito y pago
- [ ] **DADO** que estoy viendo la configuracion del grupo
- [ ] **CUANDO** se muestran los limites
- [ ] **ENTONCES** cada limite indica claramente si corresponde al plan gratuito o si podria ampliarse con el plan pago, diferenciandolos visualmente

#### CA-007: Acceso denegado para jugadores
- [ ] **DADO** que soy un jugador del grupo (sin rol de admin ni co-admin)
- [ ] **CUANDO** navego por las opciones del grupo
- [ ] **ENTONCES** no veo la opcion de configuracion en el menu y no puedo acceder a esta pantalla

#### CA-008: Administrador tambien puede ver esta pantalla
- [ ] **DADO** que soy administrador del grupo
- [ ] **CUANDO** accedo a la configuracion
- [ ] **ENTONCES** veo la misma informacion de limites y uso actual, ademas de las opciones de edicion disponibles en su pantalla de configuracion (E003-HU-001)

## Reglas de Negocio (RN)

### RN-001: Acceso permitido para administrador y co-administrador
**Contexto**: Cuando un usuario intenta acceder a la pantalla de visualizacion de configuracion del grupo.
**Restriccion**: Solo los usuarios con rol de administrador o co-administrador del grupo pueden acceder a esta pantalla.
**Validacion**: El sistema debe verificar que el usuario tenga uno de los dos roles autorizados antes de mostrar la informacion de configuracion.
**Caso especial**: Ninguno.

### RN-002: Jugadores sin acceso a la configuracion
**Contexto**: Cuando un jugador navega por el menu de opciones del grupo.
**Restriccion**: La opcion de "Configuracion" no debe aparecer en el menu para usuarios con rol de jugador.
**Validacion**: Un jugador no puede ver ni acceder a la pantalla de configuracion bajo ninguna circunstancia.
**Caso especial**: Si un jugador intenta acceder directamente a la pantalla (por ejemplo, mediante un enlace compartido o navegacion manual), debe recibir un mensaje de acceso denegado o ser redirigido.

### RN-003: Formato de uso actual versus maximo permitido
**Contexto**: Cuando se muestra cualquier limite en la pantalla de configuracion.
**Restriccion**: No se debe mostrar unicamente el valor maximo; siempre debe acompanarse del uso actual.
**Validacion**: Cada parametro con limite debe mostrarse en formato "X de Y" donde X es la cantidad actualmente utilizada e Y es el maximo permitido segun el plan. Ejemplo: "20 de 25 jugadores", "0 de 1 co-admins", "1 de 1 grupos" (plan Gratis).
**Caso especial**: Para el tamano de logo, se muestra solo el maximo permitido ya que no hay un "uso actual" progresivo (el logo actual tiene un tamano fijo).

### RN-004: Distincion visual entre plan gratuito y plan pago
**Contexto**: Cuando se presentan los limites del grupo al usuario.
**Restriccion**: No se deben mostrar todos los limites de forma identica; debe existir diferenciacion visual.
**Validacion**: Los parametros incluidos en el plan gratuito deben distinguirse visualmente de aquellos que requieren o podrian ampliarse con el plan pago. El usuario debe poder identificar a simple vista que limites tiene por su plan actual y cuales podria mejorar con un upgrade.
**Caso especial**: Si el usuario ya tiene un plan pago, los limites ampliados deben reflejar los valores del plan contratado sin mostrar la sugerencia de upgrade para esos parametros.

### RN-005: Administrador ve informacion mas opciones de edicion
**Contexto**: Cuando un administrador accede a la pantalla de configuracion.
**Restriccion**: No se debe limitar al administrador a solo lectura; debe tener acceso a las funcionalidades de edicion definidas en E003-HU-001.
**Validacion**: El administrador visualiza la misma informacion de limites y uso actual que el co-admin, pero ademas tiene acceso a los controles de edicion para los parametros modificables segun su plan.
**Caso especial**: Los enlaces o botones de edicion deben llevar a la funcionalidad de E003-HU-001 de forma integrada.

### RN-006: Co-administrador en modo estrictamente de solo lectura
**Contexto**: Cuando un co-administrador esta visualizando la configuracion del grupo.
**Restriccion**: No se deben mostrar botones de guardar, campos editables ni controles de modificacion al co-admin.
**Validacion**: Toda la informacion se presenta de forma estatica y de solo lectura. El co-admin puede consultar todos los parametros vigentes pero no tiene ninguna forma de iniciar una modificacion.
**Caso especial**: Ninguno.

## NOTAS
- Esta pantalla es complementaria a E003-HU-001. El administrador tiene acceso de edicion (HU-001) mientras que el co-admin solo tiene vista de lectura (esta HU).
- El formato "X de Y" (uso actual vs maximo) permite al usuario entender rapidamente cuanto margen le queda antes de alcanzar un limite.
- La distincion visual entre plan gratuito y pago es importante para la estrategia de conversion freemium del negocio.
- Los jugadores no necesitan conocer estos limites operativos; su experiencia se enfoca en inscripciones, partidos y estadisticas.
- HU define QUE desde perspectiva usuario. Detalles tecnicos los definen agentes especializados.
