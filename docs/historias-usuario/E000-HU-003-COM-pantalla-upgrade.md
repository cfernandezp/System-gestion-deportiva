# E000-HU-003: Pantalla de Upgrade (Placeholder)

## INFORMACION
- **Codigo:** E000-HU-003
- **Epica:** E000 - Sprint 0: Infraestructura Base
- **Titulo:** Pantalla de Upgrade - Placeholder Freemium
- **Story Points:** 2 pts
- **Estado:** ✅ Completada
- **Prioridad:** Media
- **Fecha:** 2026-02-20

## HISTORIA
**Como** usuario del plan gratuito,
**Quiero** ver informacion clara cuando intento usar una funcionalidad premium,
**Para** entender que beneficios ofrece el plan pago y saber que estara disponible proximamente.

### Criterios de Aceptacion

#### CA-001: Redireccion desde feature bloqueada
- [x] **DADO** que tengo plan Gratis e intento usar una feature de pago (ej: estadisticas avanzadas, temas personalizados, mas de 2 equipos)
- [x] **CUANDO** el sistema detecta que la feature no esta disponible en mi plan
- [x] **ENTONCES** me muestra la pantalla de upgrade en lugar de un mensaje de error generico

#### CA-002: Redireccion desde limite alcanzado
- [x] **DADO** que tengo plan Gratis y alcance un limite numerico (ej: 25 jugadores, 1 grupo, 1 co-admin)
- [x] **CUANDO** intento exceder el limite
- [x] **ENTONCES** me muestra la pantalla de upgrade indicando que con planes de pago tengo mayor capacidad

#### CA-003: Informacion del plan Premium
- [x] **DADO** que veo la pantalla de upgrade
- [x] **CUANDO** leo el contenido
- [x] **ENTONCES** veo una comparativa de los 5 planes disponibles (Gratis, Plan 5, Plan 10, Plan 15, Plan 20) con sus limites y precios:
  - Grupos por admin: 1 / 5 / 10 / 15 / 20
  - Jugadores por grupo: 25 / 50 / 50 / 70 / 70
  - Co-admins, invitados, equipos por fecha
  - Features: estadisticas avanzadas (desde Plan 5), temas personalizados (desde Plan 10)
  - Precios: S/0, S/9.90, S/19.90, S/29.90, S/39.90 mensual

#### CA-004: Mensaje de "Proximamente"
- [x] **DADO** que veo la pantalla de upgrade
- [x] **CUANDO** busco un boton de compra o suscripcion
- [x] **ENTONCES** veo un mensaje claro de "Proximamente" o "Estamos trabajando en esto" ya que la pasarela de pago aun no esta implementada

#### CA-005: Volver a la pantalla anterior
- [x] **DADO** que estoy en la pantalla de upgrade
- [x] **CUANDO** presiono volver o cierro la pantalla
- [x] **ENTONCES** regreso a la pantalla desde donde fui redirigido sin perder mi contexto

#### CA-006: Pantalla respeta el tema activo
- [x] **DADO** que veo la pantalla de upgrade
- [x] **CUANDO** tengo modo oscuro o claro activo
- [x] **ENTONCES** la pantalla se muestra correctamente en ambos modos

## Reglas de Negocio (RN)

### RN-001: Pantalla informativa, no transaccional
**Contexto**: Cuando un usuario es redirigido a la pantalla de upgrade.
**Restriccion**: No debe haber boton de "Comprar" ni formulario de pago. Es solo informativa por ahora.
**Validacion**: La pantalla muestra comparativa de los 5 planes con precios, un mensaje de "Proximamente", y un boton de "Volver". No recoge datos de pago ni hace promesas de fechas.
**Caso especial**: Cuando se implemente la pasarela de pago (epica futura), esta pantalla se convertira en el punto de compra real.

### RN-002: Mensaje contextualizado segun el motivo
**Contexto**: Cuando el usuario llega a la pantalla desde diferentes situaciones.
**Restriccion**: No mostrar siempre el mismo mensaje generico.
**Validacion**: El mensaje se adapta segun el motivo de redireccion: (1) Si fue por feature bloqueada: "Las estadisticas avanzadas estan disponibles desde el Plan 5", (2) Si fue por limite numerico: "Tu grupo alcanzo el limite de 25 jugadores. Con Plan 5 puedes tener hasta 50". El mensaje debe ser claro y motivar al upgrade sin ser agresivo.
**Caso especial**: Si el usuario llega desde el menu de configuracion (explorando planes), muestra la comparacion general de los 5 planes con precios.

### RN-003: No bloquear la experiencia del usuario
**Contexto**: Al mostrar la pantalla de upgrade.
**Restriccion**: No usar popups intrusivos ni bloquear la navegacion. La pantalla debe ser una navegacion normal.
**Validacion**: El usuario puede volver facilmente a lo que estaba haciendo. No se muestra la pantalla de upgrade repetidamente si el usuario ya la vio para el mismo motivo en la misma sesion (evitar fatiga).
**Caso especial**: Si el usuario esta en flujo critico (ej: creando una fecha), mostrar un dialog breve en vez de navegar a otra pantalla completa.

### RN-004: Beneficios visibles pero bloqueados
**Contexto**: En las pantallas del sistema donde hay features premium.
**Restriccion**: Las features premium no deben estar completamente ocultas.
**Validacion**: Las opciones premium deben ser visibles en la UI pero con un indicador de "Premium" (ej: icono de estrella o candado). Al tocarlas se redirige a la pantalla de upgrade. Esto genera interes y awareness del plan pago.
**Caso especial**: En listas o selectores, la opcion premium aparece pero deshabilitada con etiqueta "Premium".

## NOTAS
- Esta pantalla es un placeholder temporal que evolucionara cuando se implemente la pasarela de pago.
- El objetivo actual es informar al usuario sobre los beneficios premium y generar expectativa, no vender.
- Debe funcionar correctamente en ambos temas (oscuro/claro).
- En el futuro, esta pantalla tendra: precios, boton de compra, gestion de suscripcion.
- HU define QUE desde perspectiva usuario. Detalles tecnicos los definen agentes especializados.

---

## IMPLEMENTACION TECNICA

### 🗄️ FASE 2: Backend
**No requiere backend.** Es una pantalla placeholder puramente informativa (RN-001).

### 💻 FASE 4: Frontend

**Archivos creados:**
```
lib/features/upgrade/
└── presentation/
    ├── models/
    │   └── upgrade_reason.dart      # Enum UpgradeReasonType + clase UpgradeReason
    ├── pages/
    │   └── upgrade_page.dart        # Pantalla principal de upgrade
    └── widgets/
        └── premium_badge.dart       # PremiumBadge + PremiumLock widgets reutilizables
```

**Archivos modificados:**
- `lib/core/routing/app_router.dart` - Ruta `/upgrade` que recibe UpgradeReason via `extra`

**Modelo UpgradeReason:** Soporta 3 tipos de motivo:
- `UpgradeReason.feature('Formato triangular')` - Feature bloqueada (CA-001)
- `UpgradeReason.limite(recurso: 'jugadores', actual: 35, premium: 70)` - Limite alcanzado (CA-002)
- `UpgradeReason.explorar()` - Desde configuracion (comparacion general)

**Navegacion:** `context.push('/upgrade', extra: UpgradeReason.feature('...'))`

### 🎨 FASE 1: UX/UI

**UpgradePage:** Scaffold con AppBar (back) + SingleChildScrollView
- Icono hero workspace_premium con fondo tertiary
- Mensaje contextualizado segun motivo (RN-002)
- Card de beneficios Premium con checks verdes (CA-003)
- Card comparativa Gratuito vs Premium (limites numericos)
- Banner "Proximamente" con icono construction (CA-004, RN-001)
- Boton "Volver" outline (CA-005)
- Usa Theme.of(context) para dark/light (CA-006)

**PremiumBadge:** Badge compacto con icono workspace_premium + texto "Premium"
**PremiumLock:** Wrapper con opacidad 0.6 + icono lock + PremiumBadge (RN-004)

### 🧪 FASE 5: QA

**flutter analyze:** 0 errores nuevos
**Validacion CA:**
- CA-001: UpgradeReason.feature() + ruta /upgrade con mensaje contextualizado
- CA-002: UpgradeReason.limite() con valores actuales y Premium
- CA-003: Beneficios listados: triangular, 70 jugadores, 20 grupos, estadisticas, temas
- CA-004: Banner "Proximamente" sin boton de compra
- CA-005: AppBar back + boton "Volver" → Navigator.pop mantiene contexto
- CA-006: Colores via colorScheme (tertiary, primary, surface) respetan ambos temas
**Validacion RN:**
- RN-001: Sin formulario de pago ni boton de compra
- RN-002: mensajeContextual se adapta segun UpgradeReasonType
- RN-003: Navegacion normal (push/pop), no popup intrusivo
- RN-004: PremiumBadge y PremiumLock disponibles como widgets reutilizables
