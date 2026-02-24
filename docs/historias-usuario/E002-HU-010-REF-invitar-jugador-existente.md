# E002-HU-010 - Invitar Jugador Existente a Grupo

## Informacion General
- **Epica**: E002 - Grupos Deportivos
- **Estado**: 🟢 Refinada (REF)
- **Prioridad**: Media
- **Story Points**: 5 pts

## Historia de Usuario
**Como** administrador o co-administrador de un grupo
**Quiero** agregar a mi grupo un jugador que ya tiene cuenta en el sistema
**Para** no tener que pedirle que se registre de nuevo si ya juega en otro grupo

## Descripcion
Permite al admin/coadmin buscar jugadores existentes (con cuenta activa) e invitarlos a unirse al grupo. El jugador recibe una notificacion y puede aceptar o rechazar. Al aceptar, queda como miembro del grupo con rol "jugador". Esto resuelve el caso comun donde un jugador ya participa en otro grupo y el admin quiere agregarlo al suyo.

**Nota**: Los invitados (sin cuenta/app) NO pueden ser invitados a otros grupos. Primero deben ser promovidos a jugador (E002-HU-009) para tener cuenta propia.

---

## Criterios de Aceptacion (CA)

### CA-001: Buscar jugador por celular
- **Dado** que soy admin/coadmin de un grupo
- **Cuando** accedo a "Invitar jugador" e ingreso un numero de celular
- **Entonces** el sistema busca jugadores con ese celular
- **Y** si encuentra, muestra: nombre/apodo + foto (si tiene)
- **Y** si no encuentra, muestra "No se encontro jugador con ese numero"

### CA-002: Buscar jugador por nombre
- **Dado** que busco un jugador
- **Cuando** escribo un nombre o apodo (minimo 3 caracteres)
- **Entonces** veo lista de jugadores que coinciden (max 10 resultados)
- **Y** cada resultado muestra: nombre/apodo + foto
- **Y** NO se muestra en que grupo(s) esta (privacidad)

### CA-003: Enviar invitacion
- **Dado** que encontre al jugador que quiero invitar
- **Cuando** toco "Invitar"
- **Entonces** se crea una invitacion pendiente
- **Y** el jugador recibe notificacion: "Te han invitado a unirte a [nombre grupo]"
- **Y** veo confirmacion: "Invitacion enviada a [nombre jugador]"

### CA-004: Jugador acepta invitacion
- **Dado** que recibo una invitacion a un grupo
- **Cuando** toco "Aceptar" en la notificacion o pantalla de invitaciones
- **Entonces** quedo como miembro del grupo con rol "jugador"
- **Y** el grupo aparece en "Mis Grupos"
- **Y** el admin recibe notificacion: "[nombre] acepto tu invitacion"

### CA-005: Jugador rechaza invitacion
- **Dado** que recibo una invitacion a un grupo
- **Cuando** toco "Rechazar"
- **Entonces** la invitacion se elimina
- **Y** el admin NO recibe notificacion (para evitar incomodidad social)
- **Y** el admin puede volver a invitar en el futuro

### CA-006: Jugador ya es miembro
- **Dado** que intento invitar a un jugador
- **Cuando** ya es miembro activo de mi grupo
- **Entonces** veo mensaje: "[nombre] ya es miembro de tu grupo"
- **Y** no se envia invitacion

### CA-007: Invitacion duplicada
- **Dado** que intento invitar a un jugador
- **Cuando** ya tiene una invitacion pendiente a mi grupo
- **Entonces** veo mensaje: "Ya hay una invitacion pendiente para [nombre]"
- **Y** no se crea otra invitacion

### CA-008: Limite de jugadores alcanzado
- **Dado** que mi grupo ya alcanzo el limite de jugadores del plan
- **Cuando** intento invitar a alguien
- **Entonces** veo mensaje con UpgradeReason
- **Y** se sugiere mejorar de plan

---

## Reglas de Negocio (RN)

### RN-001: Solo Jugadores con Cuenta Activa
**Contexto**: Quien puede ser invitado.
**Restriccion**: Solo se puede invitar a usuarios con:
  1. estado = 'aprobado' (cuenta activa)
  2. auth_user_id IS NOT NULL (tiene cuenta de autenticacion)
**Validacion**: WHERE estado = 'aprobado' AND auth_user_id IS NOT NULL.
**Caso especial**: Invitados (sin auth) NO aparecen en busqueda. Deben ser promovidos primero (E002-HU-009).

### RN-002: Permisos para Invitar
**Contexto**: Quien puede enviar invitaciones.
**Restriccion**: Solo admin o coadmin del grupo destino pueden invitar.
**Validacion**: miembros_grupo.rol IN ('admin', 'coadmin') AND activo = true.
**Caso especial**: Un jugador normal NO puede invitar a otros.

### RN-003: No Auto-Invitacion
**Contexto**: Evitar invitaciones a uno mismo.
**Restriccion**: No se puede invitar a un usuario que ya es miembro activo del grupo.
**Validacion**: NOT EXISTS miembros_grupo WHERE usuario_id = X AND grupo_id = Y AND activo = true.
**Caso especial**: Si fue eliminado del grupo (activo = false), SI puede ser re-invitado.

### RN-004: Limite de Jugadores por Grupo
**Contexto**: Respetar limites del plan.
**Restriccion**: Verificar que el grupo no exceda el limite de jugadores al aceptar la invitacion.
**Validacion**: COUNT miembros activos con rol 'jugador' < limites_plan.max_jugadores_por_grupo.
**Caso especial**: La validacion se hace al ACEPTAR (no al invitar), porque entre el envio y la aceptacion podrian entrar otros jugadores.

### RN-005: Expiracion de Invitacion
**Contexto**: Invitaciones no deben quedar pendientes eternamente.
**Restriccion**: Las invitaciones expiran a los 7 dias.
**Validacion**: created_at + INTERVAL '7 days' > NOW().
**Caso especial**: Invitacion expirada se puede reenviar.

### RN-006: Busqueda con Privacidad
**Contexto**: Proteger informacion de los jugadores.
**Restriccion**: La busqueda retorna:
  - Nombre/apodo + foto (si tiene)
  - NO retorna: celular completo, email, grupos a los que pertenece, estadisticas
  - Busqueda por celular: debe ser numero exacto (9 digitos)
  - Busqueda por nombre: minimo 3 caracteres, match parcial
**Validacion**: Solo campos publicos en el response.
**Caso especial**: Si el jugador configura su perfil como "no buscable" en el futuro, no aparece.

### RN-007: Rol al Aceptar
**Contexto**: Con que rol entra al grupo.
**Restriccion**: Al aceptar la invitacion, el jugador entra con rol = 'jugador'.
**Validacion**: INSERT miembros_grupo con rol = 'jugador'.
**Caso especial**: Si el admin quiere que sea coadmin, lo nombra despues (E002-HU-004).

### RN-008: Una Invitacion por Grupo
**Contexto**: Evitar spam de invitaciones.
**Restriccion**: Solo puede existir 1 invitacion pendiente por combinacion (usuario, grupo).
**Validacion**: UNIQUE(usuario_id, grupo_id) en invitaciones pendientes.
**Caso especial**: Si rechazo, el admin puede volver a invitar (se crea nueva).

---

## Modelo de Datos

### Nueva tabla: `invitaciones_grupo`
```sql
CREATE TABLE invitaciones_grupo (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  grupo_id UUID NOT NULL REFERENCES grupos(id),
  usuario_id UUID NOT NULL REFERENCES usuarios(id),
  invitado_por UUID NOT NULL REFERENCES usuarios(id),
  estado TEXT NOT NULL DEFAULT 'pendiente', -- pendiente, aceptada, rechazada, expirada
  created_at TIMESTAMPTZ DEFAULT NOW(),
  respondida_at TIMESTAMPTZ,
  UNIQUE(usuario_id, grupo_id, estado) -- solo 1 pendiente por combo
);
```

---

## Flujo UI

### Desde donde se accede
1. Pantalla "Miembros del Grupo" → boton "Invitar jugador" (visible solo para admin/coadmin)
2. O desde la pantalla de grupo → opcion en menu

### Pantalla de busqueda
```
+------------------------------------------+
| ← Invitar Jugador                        |
+------------------------------------------+
| Buscar por:                              |
| [Celular] [Nombre]          <- tabs      |
+------------------------------------------+
| [_________________________]  <- input     |
|                                          |
| Resultados:                              |
| +--------------------------------------+ |
| | [Foto] Juan Perez          [Invitar] | |
| | [Foto] Juan Carlos Lopez   [Invitar] | |
| +--------------------------------------+ |
|                                          |
| Si no encuentras al jugador, puedes      |
| registrarlo como invitado.               |
| [Registrar invitado]                     |
+------------------------------------------+
```

### Pantalla de invitaciones pendientes (jugador)
```
+------------------------------------------+
| Invitaciones                              |
+------------------------------------------+
| Te invitaron a:                          |
| +--------------------------------------+ |
| | Sport las Webas                      | |
| | Invitado por: Cristian               | |
| | Hace 2 horas                         | |
| | [Aceptar]  [Rechazar]               | |
| +--------------------------------------+ |
+------------------------------------------+
```

---

## Notas Tecnicas
- Refinado por @negocio-deportivo-expert
- Depende de E002-HU-005 (ver miembros) para el punto de acceso
- Relacionada con E002-HU-008 (registrar invitado) como alternativa cuando no se encuentra al jugador
- La busqueda por celular es exacta (9 digitos, Peru). La busqueda por nombre es parcial (ILIKE)

---
**Creado**: 2026-02-23
**Refinado**: 2026-02-23
