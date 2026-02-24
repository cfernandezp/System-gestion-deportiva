# E002-HU-001: Crear Grupo Deportivo

## INFORMACION
- **Codigo:** E002-HU-001
- **Epica:** E002 - Grupos Deportivos
- **Titulo:** Crear Grupo Deportivo
- **Story Points:** 5 pts
- **Estado:** Refinada
- **Prioridad:** Alta
- **Fecha:** 2026-02-20

## HISTORIA
**Como** administrador
**Quiero** crear un grupo deportivo con nombre, logo, lema y reglas
**Para** organizar mi equipo de futbol y gestionar las pichangas de forma centralizada

### Criterios de Aceptacion

#### CA-001: Creacion exitosa del grupo con datos obligatorios
- [ ] **DADO** que soy un usuario autenticado con capacidad de administrar grupos
- [ ] **CUANDO** completo el formulario de creacion ingresando al menos el nombre del grupo
- [ ] **ENTONCES** el sistema crea el grupo, me asigna automaticamente como administrador (creador) y me redirige a la pantalla de gestion del grupo recien creado

#### CA-002: Validacion del nombre del grupo
- [ ] **DADO** que estoy creando un grupo deportivo
- [ ] **CUANDO** ingreso un nombre que ya utilice en otro grupo que administro
- [ ] **ENTONCES** el sistema me indica que ya tengo un grupo con ese nombre y no permite la creacion duplicada

#### CA-003: Carga de logo del grupo
- [ ] **DADO** que estoy en el formulario de creacion del grupo
- [ ] **CUANDO** selecciono una imagen como logo del grupo
- [ ] **ENTONCES** el sistema acepta la imagen solo si es formato JPG o PNG y no supera los 2MB, mostrando un mensaje de error claro si no cumple estas condiciones

#### CA-004: Campos opcionales del grupo
- [ ] **DADO** que estoy creando un grupo deportivo
- [ ] **CUANDO** completo el formulario dejando vacios el lema, las reglas y el logo
- [ ] **ENTONCES** el sistema permite crear el grupo exitosamente solo con el nombre, ya que los demas campos son opcionales

#### CA-005: Tipo de deporte fijo
- [ ] **DADO** que estoy creando un grupo deportivo
- [ ] **CUANDO** el formulario se muestra
- [ ] **ENTONCES** el tipo de deporte aparece como "Futbol" de forma fija (sin opcion de cambio en esta version)

#### CA-006: Validacion de limite de grupos por administrador
- [ ] **DADO** que ya alcance el limite de grupos permitidos segun mi plan (freemium)
- [ ] **CUANDO** intento crear un nuevo grupo
- [ ] **ENTONCES** el sistema me informa que he alcanzado el limite y no permite la creacion, sugiriendo actualizar el plan para obtener mas grupos

#### CA-007: Configuracion inicial del grupo
- [ ] **DADO** que el grupo se crea exitosamente
- [ ] **CUANDO** el sistema finaliza la creacion
- [ ] **ENTONCES** el grupo se crea con los limites por defecto del plan del admin (25 jugadores en Gratis) y el creador queda registrado como administrador del grupo

## Reglas de Negocio (RN)

### RN-001: Elegibilidad para crear grupos
**Contexto**: Cuando un usuario autenticado intenta crear un nuevo grupo deportivo.
**Restriccion**: No se permite crear grupos a usuarios que no esten autenticados.
**Validacion**: Cualquier usuario autenticado puede crear un grupo y se convierte en administrador de ese grupo. Un jugador en otros grupos puede ser administrador de los grupos que el crea.
**Caso especial**: Un usuario puede ser jugador en unos grupos y administrador en otros simultaneamente.

### RN-002: Unicidad del nombre de grupo por administrador
**Contexto**: Al asignar o validar el nombre de un grupo durante la creacion.
**Restriccion**: No pueden existir dos grupos con el mismo nombre bajo el mismo administrador creador.
**Validacion**: El nombre del grupo debe ser obligatorio y unico entre todos los grupos donde el usuario es administrador creador. La unicidad NO aplica entre grupos de diferentes administradores (dos admins distintos pueden tener grupos con el mismo nombre).
**Caso especial**: Ninguno.

### RN-003: Formato y tamano del logo
**Contexto**: Cuando el usuario carga una imagen como logo del grupo.
**Restriccion**: No se aceptan imagenes en formatos distintos a JPG y PNG, ni imagenes que superen los 2MB de tamano.
**Validacion**: El logo debe ser una imagen en formato JPG o PNG con un peso maximo de 2MB. El logo es opcional; el grupo puede existir sin logo.
**Caso especial**: Si no se carga logo, el grupo se crea sin imagen y puede mostrarse un indicador visual por defecto (inicial del nombre, por ejemplo).

### RN-004: Lema del grupo
**Contexto**: Cuando el usuario ingresa un lema para el grupo durante la creacion o edicion.
**Restriccion**: El lema no debe exceder los 100 caracteres.
**Validacion**: El lema es un campo opcional de texto corto con un maximo sugerido de 100 caracteres.
**Caso especial**: Si no se ingresa lema, el grupo se crea sin lema y el campo queda vacio.

### RN-005: Reglas del grupo
**Contexto**: Cuando el usuario ingresa las reglas internas del grupo.
**Restriccion**: Ninguna restriccion estricta de longitud.
**Validacion**: Las reglas son un campo opcional de texto libre donde el administrador puede detallar las normas internas del grupo.
**Caso especial**: Si no se ingresan reglas, el grupo se crea sin reglas definidas.

### RN-006: Tipo de deporte
**Contexto**: Al definir el tipo de deporte del grupo durante la creacion.
**Restriccion**: No se permite seleccionar ni cambiar el tipo de deporte en esta version.
**Validacion**: El tipo de deporte se asigna automaticamente como "Futbol" de forma fija. En versiones futuras se podra soportar otros deportes.
**Caso especial**: Ninguno.

### RN-007: Limite de grupos por administrador segun plan
**Contexto**: Cuando un usuario intenta crear un nuevo grupo y ya administra grupos existentes.
**Restriccion**: No se permite crear un grupo si el usuario ya alcanzo el limite de grupos permitidos por su plan.
**Validacion**: El limite de grupos por administrador depende del plan contratado: 1 (Gratis), 5 (Plan 5), 10 (Plan 10), 15 (Plan 15), 20 (Plan 20). Si se alcanza el limite, se debe sugerir al usuario actualizar su plan.
**Caso especial**: Grupos donde el usuario es jugador o co-admin NO cuentan para este limite; solo cuentan los grupos donde es administrador creador.

### RN-008: Asignacion automatica de rol administrador al creador
**Contexto**: Inmediatamente despues de la creacion exitosa de un grupo.
**Restriccion**: No se puede crear un grupo sin que el creador quede asignado como administrador.
**Validacion**: Al crear un grupo, el sistema asigna automaticamente al creador como administrador del grupo. Ademas, el grupo se inicializa con los limites por defecto del plan del admin (25 jugadores en Gratis).
**Caso especial**: Ninguno.

## NOTAS ADICIONALES
- El nombre del grupo es obligatorio; logo, lema y reglas son opcionales
- El lema es un texto corto descriptivo del grupo
- Las reglas son texto libre donde el admin puede detallar las normas del grupo
- El limite de grupos por administrador depende del plan contratado (modelo freemium)
- En esta version solo se soporta futbol como tipo de deporte
- Un jugador que es miembro de otros grupos puede crear su propio grupo y ser admin de este
- HU define QUE desde perspectiva usuario. Detalles tecnicos los definen agentes especializados.
