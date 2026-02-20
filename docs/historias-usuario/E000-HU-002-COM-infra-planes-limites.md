# E000-HU-002: Infraestructura de Planes y Limites

## INFORMACION
- **Codigo:** E000-HU-002
- **Epica:** E000 - Sprint 0: Infraestructura Base
- **Titulo:** Infraestructura de Planes, Limites y Feature Flags
- **Story Points:** 8 pts
- **Estado:** ✅ Completada
- **Prioridad:** Alta
- **Fecha:** 2026-02-20
- **Fecha Implementacion:** 2026-02-20

## HISTORIA
**Como** sistema,
**Quiero** tener una infraestructura de planes con limites numericos y funcionalidades habilitadas/bloqueadas,
**Para** que cada funcionalidad del sistema pueda validar si un grupo/admin tiene permiso de usarla segun su plan (gratuito o pago).

## Descripcion
Esta HU NO tiene pantallas. Es infraestructura pura (backend + logica) que las demas HUs consumiran para validar limites y features. Todas las HUs de E001, E002, E003 y futuras epicas dependen de esta infraestructura.

### Modelo de Planes Definitivo

| Concepto | Gratis | Plan 5 | Plan 10 | Plan 15 | Plan 20 |
|----------|--------|--------|---------|---------|---------|
| **Precio/mes** | S/ 0 | S/ 9.90 | S/ 19.90 | S/ 29.90 | S/ 39.90 |
| **max_grupos_por_admin** | 1 | 5 | 10 | 15 | 20 |
| **max_jugadores_por_grupo** | 25 | 50 | 50 | 70 | 70 |
| **max_invitados_por_grupo** | 1 | 3 | 5 | 8 | 10 |
| **max_coadmins_por_grupo** | 1 | 3 | 6 | 9 | 9 |
| **max_equipos_por_fecha** | 2 | 3 | 4 | 4 | 4 |
| **max_tamano_logo_mb** | 2 | 2 | 2 | 2 | 2 |
| **estadisticas_avanzadas** | NO | SI | SI | SI | SI |
| **temas_personalizados_grupo** | NO | NO | SI | SI | SI |

### Criterios de Aceptacion

#### CA-001: Planes definidos en el sistema
- [x] **DADO** que el sistema se inicializa
- [x] **CUANDO** se consultan los planes disponibles
- [x] **ENTONCES** existen 5 planes definidos: "Gratis" (activo), "Plan 5", "Plan 10", "Plan 15" y "Plan 20" (definidos pero sin pasarela de pago aun)

#### CA-002: Limites numericos del plan Gratis
- [x] **DADO** que existe el plan Gratis
- [x] **CUANDO** se consultan sus limites
- [x] **ENTONCES** los limites son:
  - max_grupos_por_admin: 1
  - max_jugadores_por_grupo: 25
  - max_invitados_por_grupo: 1
  - max_coadmins_por_grupo: 1
  - max_equipos_por_fecha: 2
  - max_tamano_logo_mb: 2

#### CA-003: Limites numericos del Plan 5
- [x] **DADO** que existe el Plan 5
- [x] **CUANDO** se consultan sus limites
- [x] **ENTONCES** los limites son:
  - max_grupos_por_admin: 5
  - max_jugadores_por_grupo: 50
  - max_invitados_por_grupo: 3
  - max_coadmins_por_grupo: 3
  - max_equipos_por_fecha: 3
  - max_tamano_logo_mb: 2

#### CA-004: Limites numericos del Plan 10
- [x] **DADO** que existe el Plan 10
- [x] **CUANDO** se consultan sus limites
- [x] **ENTONCES** los limites son:
  - max_grupos_por_admin: 10
  - max_jugadores_por_grupo: 50
  - max_invitados_por_grupo: 5
  - max_coadmins_por_grupo: 6
  - max_equipos_por_fecha: 4
  - max_tamano_logo_mb: 2

#### CA-005: Limites numericos del Plan 15
- [x] **DADO** que existe el Plan 15
- [x] **CUANDO** se consultan sus limites
- [x] **ENTONCES** los limites son:
  - max_grupos_por_admin: 15
  - max_jugadores_por_grupo: 70
  - max_invitados_por_grupo: 8
  - max_coadmins_por_grupo: 9
  - max_equipos_por_fecha: 4
  - max_tamano_logo_mb: 2

#### CA-006: Limites numericos del Plan 20
- [x] **DADO** que existe el Plan 20
- [x] **CUANDO** se consultan sus limites
- [x] **ENTONCES** los limites son:
  - max_grupos_por_admin: 20
  - max_jugadores_por_grupo: 70
  - max_invitados_por_grupo: 10
  - max_coadmins_por_grupo: 9
  - max_equipos_por_fecha: 4
  - max_tamano_logo_mb: 2

#### CA-007: Feature flags del plan Gratis
- [x] **DADO** que existe el plan Gratis
- [x] **CUANDO** se consultan sus features habilitadas
- [x] **ENTONCES** las features son:
  - estadisticas_avanzadas: DESHABILITADO
  - temas_personalizados_grupo: DESHABILITADO

#### CA-008: Feature flags de planes de pago
- [x] **DADO** que existe cualquier plan de pago (Plan 5, 10, 15, 20)
- [x] **CUANDO** se consultan sus features
- [x] **ENTONCES** las features son:
  - estadisticas_avanzadas: HABILITADO (todos los planes de pago)
  - temas_personalizados_grupo: HABILITADO solo en Plan 10, 15 y 20 (NO en Plan 5)

#### CA-009: Asignacion automatica de plan Gratis
- [x] **DADO** que un nuevo administrador se registra y crea su primer grupo
- [x] **CUANDO** se completa el registro
- [x] **ENTONCES** el admin y su grupo se asignan automaticamente al plan Gratis sin intervencion manual

#### CA-010: Validacion de limite numerico
- [x] **DADO** que un grupo tiene plan Gratis con limite de 25 jugadores
- [x] **CUANDO** se intenta agregar el jugador numero 26
- [x] **ENTONCES** el sistema rechaza la accion e indica que se alcanzo el limite del plan

#### CA-011: Validacion de feature bloqueada
- [x] **DADO** que un grupo tiene plan Gratis
- [x] **CUANDO** un admin intenta usar estadisticas avanzadas o temas personalizados
- [x] **ENTONCES** el sistema bloquea la accion y redirige a la pantalla de upgrade (E000-HU-003)

#### CA-012: Validacion de equipos por fecha
- [x] **DADO** que un grupo tiene plan Gratis (max 2 equipos por fecha)
- [x] **CUANDO** un admin intenta crear una fecha con 3 equipos
- [x] **ENTONCES** el sistema bloquea la accion y redirige a la pantalla de upgrade

#### CA-013: Consulta reutilizable "puede hacer X?"
- [x] **DADO** que cualquier funcionalidad del sistema necesita validar permisos de plan
- [x] **CUANDO** consulta "puede este grupo hacer X?"
- [x] **ENTONCES** obtiene una respuesta clara: SI (permitido) o NO (motivo: limite alcanzado / feature no disponible en plan)

#### CA-014: Limites editables por admin dentro del rango del plan
- [x] **DADO** que un admin tiene plan Gratis (max 25 jugadores)
- [x] **CUANDO** quiere reducir el limite de su grupo a 20 jugadores
- [x] **ENTONCES** puede hacerlo siempre que no sea menor a los miembros actuales del grupo

#### CA-015: Precio asociado a cada plan
- [x] **DADO** que se consulta la informacion de un plan de pago
- [x] **CUANDO** se obtienen los detalles del plan
- [x] **ENTONCES** incluye el precio mensual en Soles (S/) para mostrarse en la pantalla de upgrade

## Reglas de Negocio (RN)

### RN-001: Dos tipos de control por plan
**Contexto**: Al definir que incluye cada plan.
**Restriccion**: No mezclar limites numericos con features. Son conceptos distintos.
**Validacion**: Cada plan define: (1) Limites numericos (cuantos de algo se permiten) y (2) Feature flags (si una funcionalidad esta habilitada o no). Ambos se validan de forma independiente.
**Caso especial**: Un limite numerico puede ser "ilimitado" en planes superiores (representado como un valor muy alto, no como ausencia de limite).

### RN-002: Plan Gratis es el default universal
**Contexto**: Al registrarse un nuevo admin o crear un grupo.
**Restriccion**: Ningun usuario debe quedar sin plan asignado.
**Validacion**: Todo admin nuevo se asigna automaticamente al plan Gratis. No existe un estado "sin plan". El plan Gratis no tiene fecha de vencimiento.
**Caso especial**: Si en el futuro se desactiva el plan Gratis, los usuarios existentes conservan sus beneficios (grandfather clause).

### RN-003: Planes de pago - definidos pero no comprables aun
**Contexto**: En la version actual de la app (pre-monetizacion).
**Restriccion**: No se puede comprar ningun plan de pago todavia. No hay pasarela de pago.
**Validacion**: Los planes de pago (Plan 5, 10, 15, 20) existen en el sistema con todos sus limites, features y precios definidos, pero no hay forma de adquirirlos desde la app. Cuando un usuario intenta acceder a una feature de pago, ve la pantalla de upgrade (E000-HU-003) con mensaje "Proximamente".
**Caso especial**: Para pruebas internas, un admin del sistema podria asignar manualmente un plan de pago a un grupo.

### RN-004: Limites del plan aplican por grupo
**Contexto**: Al validar limites como max_jugadores o max_equipos_por_fecha.
**Restriccion**: Los limites se validan a nivel de grupo, no a nivel global del admin.
**Validacion**: Cada grupo tiene su propio plan asignado (heredado del admin al crearlo). Si un admin tiene 5 grupos, cada grupo tiene su plan y limites independientes.
**Caso especial**: El limite de grupos (max_grupos_por_admin) es la excepcion: se valida a nivel de admin, no de grupo.

### RN-005: Escalamiento por cantidad de grupos
**Contexto**: Al disenar la estructura de planes.
**Restriccion**: El nombre del plan refleja la cantidad de grupos que permite.
**Validacion**: Los planes escalan principalmente por la cantidad de grupos que un admin puede gestionar: 1 (Gratis), 5, 10, 15, 20. Los demas limites (jugadores, invitados, co-admins) tambien escalan progresivamente.
**Caso especial**: Algunos limites se estabilizan en planes superiores (ej: max_coadmins es 9 tanto en Plan 15 como Plan 20).

### RN-006: Limites numericos del plan Gratis
**Contexto**: Valores por defecto para todo admin/grupo nuevo.
**Restriccion**: Estos valores son los topes maximos del plan, no valores fijos.
**Validacion**: Plan Gratis: max_grupos_por_admin=1, max_jugadores_por_grupo=25, max_invitados_por_grupo=1, max_coadmins_por_grupo=1, max_equipos_por_fecha=2, max_tamano_logo_mb=2. El admin puede configurar valores iguales o menores dentro de su grupo (ej: limitar a 20 jugadores en vez de 25), pero nunca superiores a lo que permite su plan.
**Caso especial**: Con 1 solo grupo, el admin Gratis puede gestionar hasta 25 jugadores + 1 invitado + 1 co-admin.

### RN-007: Features del plan Gratis
**Contexto**: Funcionalidades disponibles en el plan sin costo.
**Restriccion**: Las features bloqueadas no deben desaparecer de la UI, deben verse pero estar bloqueadas (para generar interes en el upgrade).
**Validacion**: Plan Gratis: estadisticas_avanzadas=NO, temas_personalizados_grupo=NO, max_equipos_por_fecha=2 (solo formato 2 equipos). El usuario puede VER que existen estas opciones pero al intentar usarlas se redirige a la pantalla de upgrade.
**Caso especial**: El formato de 2 equipos siempre esta disponible en todos los planes.

### RN-008: Features escalonadas en planes de pago
**Contexto**: No todas las features se desbloquean en el primer plan de pago.
**Restriccion**: Cada feature define en que plan se activa.
**Validacion**: estadisticas_avanzadas se activa desde Plan 5. temas_personalizados_grupo se activa desde Plan 10. Esto incentiva la progresion entre planes de pago.
**Caso especial**: Si se agregan nuevas features en el futuro, se debe definir en que plan se activan.

### RN-009: Validacion centralizada "puede hacer X?"
**Contexto**: Cuando cualquier parte del sistema necesita verificar permisos de plan.
**Restriccion**: No duplicar logica de validacion en cada funcionalidad. Debe existir una funcion centralizada.
**Validacion**: La consulta "puede este grupo hacer X?" debe retornar: (1) permitido=SI/NO, (2) motivo (si NO): "limite_alcanzado" o "feature_no_disponible", (3) limite_actual y limite_maximo (si es limite numerico), (4) plan_requerido (si es feature bloqueada). Esta funcion es consumida por TODAS las HUs que validan permisos.
**Caso especial**: Si el plan del grupo expira (futuro), la respuesta debe indicar "plan_expirado" como motivo.

### RN-010: No se puede reducir limite por debajo del uso actual
**Contexto**: Cuando un admin quiere reducir un limite de su grupo.
**Restriccion**: No permitir configurar un limite menor a lo que ya se esta usando.
**Validacion**: Si un grupo tiene 20 jugadores, el admin no puede configurar el limite en 18. El minimo configurable es 20 (el uso actual). Para bajar a 18, primero debe eliminar 2 jugadores.
**Caso especial**: Esto aplica solo a limites editables por el admin. Los limites definidos por el plan (solo lectura) no se ven afectados.

### RN-011: Precios en Soles peruanos
**Contexto**: Al mostrar precios de planes en la pantalla de upgrade.
**Restriccion**: Los precios se muestran en Soles (S/) ya que la app opera inicialmente en Peru.
**Validacion**: Gratis=S/0, Plan 5=S/9.90, Plan 10=S/19.90, Plan 15=S/29.90, Plan 20=S/39.90 mensuales. Los precios incluyen la comision de tiendas (15% Google Play / Apple Small Business Program).
**Caso especial**: Los precios podran ajustarse en el futuro sin afectar a suscriptores activos.

### RN-012: Logo tiene tamano fijo en todos los planes
**Contexto**: Al validar el tamano del logo del grupo.
**Restriccion**: El tamano maximo de logo NO varia entre planes.
**Validacion**: max_tamano_logo_mb=2 es igual en todos los planes (Gratis hasta Plan 20). No es un diferenciador de plan.
**Caso especial**: Si en el futuro se quiere diferenciar por plan, se puede actualizar sin afectar la infraestructura.

## NOTAS
- Esta HU es INFRAESTRUCTURA PURA: no tiene pantallas propias.
- Todas las HUs de E001, E002, E003 y futuras dependen de esta para validar limites y features.
- Los valores de limites son los iniciales. Pueden ajustarse facilmente sin modificar codigo de negocio.
- La pasarela de pago y gestion de suscripciones sera una epica futura separada.
- Para pruebas, se podra asignar un plan de pago manualmente desde la base de datos.
- Los precios consideran costos operativos: Supabase Pro $25/mes + Apple $99/ano ≈ S/125/mes. Punto de equilibrio estimado: ~15 suscriptores.
- Comision de tiendas: 15% (Google Play y Apple Small Business Program <$1M ingresos/ano).
- HU define QUE desde perspectiva del sistema. Detalles tecnicos los definen agentes especializados.

## IMPLEMENTACION

### Backend (SQL / Supabase)
- **Migracion:** `supabase/sql-cloud/2026-02-20_E000-HU-002_infraestructura_planes_limites.sql`
  - Tabla `planes` con limites numericos y feature flags como columnas
  - Seed data: 5 planes (Gratis, Plan 5, Plan 10, Plan 15, Plan 20)
  - Columna `plan_id` en tabla `usuarios` (FK a planes)
  - Trigger `trg_asignar_plan_gratis`: auto-asigna plan Gratis a admins nuevos
  - RLS: lectura publica para planes activos, sin escritura desde cliente
- **RPCs creadas:**
  - `obtener_planes()` - Lista todos los planes activos con limites y features
  - `verificar_permiso_plan(plan_id, tipo, recurso, cantidad)` - Validacion centralizada "puede hacer X?"
  - `obtener_plan_admin()` - Obtiene plan del admin autenticado (default Gratis)

### Frontend (Flutter)
- **Feature:** `lib/features/planes/` (sin capa de presentacion - infraestructura pura)
- **Modelos:**
  - `data/models/plan_model.dart` - Modelo de plan con limites, features, helpers
  - `data/models/permiso_result_model.dart` - Resultado de verificacion de permiso
- **DataSource:** `data/datasources/planes_remote_datasource.dart` - Llamadas RPC a Supabase
- **Repository:**
  - `domain/repositories/planes_repository.dart` - Interfaz abstracta
  - `data/repositories/planes_repository_impl.dart` - Implementacion con Either/dartz
- **Servicio:** `domain/services/plan_service.dart` - API centralizada con cache
  - `cargarPlanAdmin()` - Carga y cachea plan del admin
  - `verificarLimite(recurso, cantidad)` - Valida limites numericos
  - `verificarFeature(feature)` - Valida feature flags
  - `esLimiteConfigurableValido()` - Valida limites editables (CA-014/RN-010)
- **DI:** Registrado en `core/di/injection_container.dart` como LazySingleton
