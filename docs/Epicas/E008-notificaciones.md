# EPICA E008: Notificaciones

## INFORMACION
- **Codigo:** E008
- **Nombre:** Notificaciones (In-App + Push)
- **Descripcion:** Sistema completo de notificaciones para que los jugadores se enteren de eventos importantes (pichangas creadas, inscripciones, cambios de fecha, pichanga iniciada) tanto dentro de la app como fuera de ella. Actualmente la tabla `notificaciones` existe en BD y los RPCs crean registros, pero NO hay UI para verlas ni push notifications implementadas.
- **Story Points:** 34 pts (estimado)
- **Estado:** Borrador
- **Plataforma:** App Movil (Android/iOS) - Flutter + Supabase + Firebase Cloud Messaging

## CONTEXTO
La tabla `notificaciones` en BD ya recibe inserts desde:
- crear_fecha() -> "Nueva pichanga creada"
- inscribir_jugador_admin() -> "Te inscribieron a una pichanga"
- iniciar_fecha() -> "Pichanga iniciada"
- editar_fecha() -> "Cambios en la pichanga"

Pero NINGUN usuario puede verlas. No existe pantalla, icono, ni badge. El dato se crea y nadie lo lee.

## HISTORIAS

### E008-HU-001: Centro de Notificaciones In-App
- **Archivo:** docs/historias-usuario/E008-HU-001-BOR-centro-notificaciones.md
- **Estado:** Borrador | **Story Points:** 8 | **Prioridad:** Alta
- **Descripcion:** Pantalla donde el jugador ve todas sus notificaciones. Icono de campana en la barra superior con badge de no leidas. Lista de notificaciones ordenadas por fecha. Marcar como leida al tocar.

### E008-HU-002: Badge de Notificaciones No Leidas
- **Archivo:** docs/historias-usuario/E008-HU-002-BOR-badge-no-leidas.md
- **Estado:** Borrador | **Story Points:** 3 | **Prioridad:** Alta
- **Descripcion:** Icono de campana visible en todas las pantallas (AppBar o NavigationRail) con badge numerico rojo que muestra cantidad de notificaciones no leidas. Se actualiza en tiempo real via Supabase Realtime.

### E008-HU-003: Configurar Firebase Cloud Messaging
- **Archivo:** docs/historias-usuario/E008-HU-003-BOR-configurar-fcm.md
- **Estado:** Borrador | **Story Points:** 8 | **Prioridad:** Alta
- **Descripcion:** Configurar proyecto Firebase para Android e iOS. Integrar paquete firebase_messaging en Flutter. Guardar token de dispositivo por usuario en BD. Manejar permisos de notificacion en iOS.

### E008-HU-004: Enviar Push Notifications desde Backend
- **Archivo:** docs/historias-usuario/E008-HU-004-BOR-enviar-push.md
- **Estado:** Borrador | **Story Points:** 8 | **Prioridad:** Alta
- **Descripcion:** Supabase Edge Function que escucha inserts en tabla notificaciones y envia push via FCM al dispositivo del usuario. Manejar tokens multiples (un usuario con varios dispositivos).

### E008-HU-005: Preferencias de Notificacion
- **Archivo:** docs/historias-usuario/E008-HU-005-BOR-preferencias-notificacion.md
- **Estado:** Borrador | **Story Points:** 5 | **Prioridad:** Baja
- **Descripcion:** Pantalla de configuracion donde el jugador elige que notificaciones quiere recibir (push y/o in-app). Opciones: nueva pichanga, inscripcion, pichanga iniciada, cambios de fecha. Por defecto todo activado.

### E008-HU-006: Notificacion Recordatorio Pre-Pichanga
- **Archivo:** docs/historias-usuario/E008-HU-006-BOR-recordatorio-pre-pichanga.md
- **Estado:** Borrador | **Story Points:** 2 | **Prioridad:** Media
- **Descripcion:** Push notification automatica 30 minutos antes de la hora de inicio de la pichanga para todos los jugadores inscritos. "Tu pichanga en Activa Club empieza en 30 min".

## DEPENDENCIAS
- E001 (Autenticacion) - Necesita usuario autenticado
- E002 (Grupos) - Las notificaciones son por grupo
- Firebase Project configurado (Google Console)
- Apple Developer account (para APNs - ya lo tienen)

## COSTOS
| Servicio | Costo | Notas |
|----------|-------|-------|
| Firebase Cloud Messaging | GRATIS | Sin limite de mensajes |
| Apple APNs | GRATIS | Incluido en Apple Developer ($99/ano ya pagado) |
| Supabase Edge Functions | GRATIS | Incluido en plan Supabase |
| Firebase Project | GRATIS | Plan Spark (gratuito) es suficiente |

## ORDEN DE IMPLEMENTACION
1. **E008-HU-001** + **E008-HU-002**: In-app primero (los datos ya existen en BD, solo falta UI)
2. **E008-HU-003**: Configurar Firebase (prerequisito para push)
3. **E008-HU-004**: Enviar push desde backend
4. **E008-HU-005**: Preferencias (puede esperar)
5. **E008-HU-006**: Recordatorio (puede esperar)

## NOTAS
- HU-001 y HU-002 son las mas urgentes: la data ya existe, solo falta mostrarla
- HU-003 y HU-004 son el core de push: configuracion + envio
- HU-005 y HU-006 son mejoras que pueden esperar a una segunda iteracion
- El costo total es S/ 0.00 adicionales
- Las notificaciones in-app (HU-001 + HU-002) se pueden implementar sin Firebase, son independientes

---
**Creado**: 2026-02-23
