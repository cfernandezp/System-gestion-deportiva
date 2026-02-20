# E000-HU-001: Sistema de Temas (Dark/Light)

## INFORMACION
- **Codigo:** E000-HU-001
- **Epica:** E000 - Sprint 0: Infraestructura Base
- **Titulo:** Sistema de Temas (Dark/Light) con Arquitectura Extensible
- **Story Points:** 5 pts
- **Estado:** ✅ Completada
- **Prioridad:** Alta
- **Fecha:** 2026-02-20

## HISTORIA
**Como** usuario de la app,
**Quiero** poder elegir entre modo oscuro y modo claro,
**Para** usar la aplicacion con la apariencia que me resulte mas comoda segun mis preferencias o condiciones de luz.

### Criterios de Aceptacion

#### CA-001: Modo oscuro disponible
- [x] **DADO** que abro la app por primera vez
- [x] **CUANDO** el sistema detecta la preferencia del dispositivo (dark/light)
- [x] **ENTONCES** la app se muestra con el tema correspondiente al sistema operativo

#### CA-002: Modo claro disponible
- [x] **DADO** que la app esta en modo oscuro
- [x] **CUANDO** cambio la preferencia a modo claro
- [x] **ENTONCES** toda la interfaz cambia a colores claros inmediatamente sin reiniciar la app

#### CA-003: Selector de tema accesible
- [x] **DADO** que soy un usuario autenticado
- [x] **CUANDO** accedo a la configuracion de la app
- [x] **ENTONCES** veo un selector de tema con opciones: "Sistema" (default), "Oscuro", "Claro"

#### CA-004: Persistencia de preferencia
- [x] **DADO** que seleccione un tema especifico (ej: modo oscuro)
- [x] **CUANDO** cierro y vuelvo a abrir la app
- [x] **ENTONCES** el tema seleccionado se mantiene sin tener que elegirlo de nuevo

#### CA-005: Tema en pantallas de autenticacion
- [x] **DADO** que no estoy autenticado (pantallas de login, registro, activacion)
- [x] **CUANDO** abro la app
- [x] **ENTONCES** las pantallas de autenticacion tambien respetan el tema del sistema operativo o el ultimo seleccionado

#### CA-006: Todos los componentes respetan el tema
- [x] **DADO** que estoy usando la app con cualquier tema
- [x] **CUANDO** navego por cualquier pantalla
- [x] **ENTONCES** todos los textos, botones, iconos, fondos, tarjetas e inputs se ven correctamente con contraste adecuado en el tema activo

#### CA-007: Transicion suave
- [x] **DADO** que cambio de tema
- [x] **CUANDO** se aplica el nuevo tema
- [x] **ENTONCES** la transicion es suave (sin parpadeo ni pantalla en blanco)

## Reglas de Negocio (RN)

### RN-001: Tema por defecto sigue al sistema operativo
**Contexto**: Cuando el usuario no ha seleccionado un tema manualmente.
**Restriccion**: No imponer un tema por defecto arbitrario.
**Validacion**: La app debe respetar la configuracion de tema del sistema operativo (Android/iOS) como valor por defecto. Si el dispositivo esta en modo oscuro, la app abre en modo oscuro.
**Caso especial**: Si el usuario selecciona un tema manualmente, este tiene prioridad sobre la configuracion del sistema.

### RN-002: Tres opciones de tema
**Contexto**: Al configurar el tema de la app.
**Restriccion**: No limitar a solo dark/light. Debe existir la opcion "Sistema".
**Validacion**: Las opciones disponibles son: "Sistema" (sigue al SO), "Oscuro" (siempre oscuro), "Claro" (siempre claro). En el futuro se podran agregar mas opciones (temas por grupo, temas personalizados).
**Caso especial**: La opcion "Sistema" cambia dinamicamente si el usuario cambia el tema del SO mientras la app esta abierta.

### RN-003: Persistencia local de preferencia
**Contexto**: Cuando el usuario selecciona un tema.
**Restriccion**: La preferencia se guarda localmente en el dispositivo, no requiere conexion a internet.
**Validacion**: Al reabrir la app, se aplica el ultimo tema seleccionado. No se pierde la preferencia al cerrar la app ni al reiniciar el dispositivo.
**Caso especial**: Si el usuario desinstala y reinstala la app, la preferencia se pierde y vuelve a "Sistema".

### RN-004: Paleta de colores deportiva
**Contexto**: Al definir los colores de cada tema (oscuro y claro).
**Restriccion**: No usar colores genericos/por defecto del framework. La app debe tener identidad visual deportiva.
**Validacion**: La paleta debe incluir colores que transmitan energia deportiva (verdes cesped, naranjas energia, etc.) adaptados a cada modo (oscuro: colores sobre fondos oscuros, claro: colores sobre fondos claros). Textos siempre con contraste suficiente para legibilidad.
**Caso especial**: Los colores de equipos (Naranja, Verde, Azul, Rojo) deben ser distinguibles en ambos modos.

### RN-005: Arquitectura extensible para futuros temas
**Contexto**: Al disenar el sistema de temas.
**Restriccion**: No hardcodear colores en componentes individuales. Todo color debe venir del tema activo.
**Validacion**: La arquitectura debe permitir agregar nuevos temas sin modificar pantallas existentes. Un nuevo tema se define en un solo lugar y se propaga automaticamente a toda la app.
**Caso especial**: En el futuro, los grupos podrian tener temas personalizados (colores del grupo). La arquitectura debe soportar esto sin rediseno.

### RN-006: Accesibilidad de contraste
**Contexto**: En ambos modos (oscuro y claro).
**Restriccion**: No usar combinaciones de colores con bajo contraste que dificulten la lectura.
**Validacion**: Todos los textos deben ser legibles sobre sus fondos en ambos modos. Iconos y elementos interactivos deben ser claramente distinguibles.
**Caso especial**: Los indicadores de estado (activo/pendiente, pagado/no pagado) deben ser distinguibles en ambos modos.

## NOTAS
- Este es un prerequisito para TODAS las pantallas del sistema. Debe implementarse antes de cualquier pantalla de negocio.
- La preferencia de tema es por dispositivo, no por cuenta de usuario (no se sincroniza entre dispositivos).
- El Design System existente del proyecto (Material You + Colores Deportivos) se adaptara a ambos modos.
- HU define QUE desde perspectiva usuario. Detalles tecnicos los definen agentes especializados.

---

## IMPLEMENTACION TECNICA

### 🗄️ FASE 2: Backend
**No requiere backend.** La preferencia de tema se almacena localmente via SharedPreferences (RN-003). No se necesitan scripts SQL ni funciones RPC.

### 💻 FASE 4: Frontend (Clean Architecture)

**Dependencia agregada:** `shared_preferences: ^2.5.4`

**Archivos creados:**
```
lib/features/settings/
├── data/
│   ├── datasources/
│   │   └── theme_local_datasource.dart    # SharedPreferences read/write
│   └── repositories/
│       └── theme_repository_impl.dart     # Implementacion del repositorio
├── domain/
│   └── repositories/
│       └── theme_repository.dart          # Interface del repositorio
└── presentation/
    ├── bloc/theme/
    │   ├── theme.dart                     # Barrel export
    │   ├── theme_bloc.dart                # BLoC: LoadThemeEvent, ChangeThemeEvent
    │   ├── theme_event.dart               # Eventos
    │   └── theme_state.dart               # Estado con ThemeMode
    └── pages/
        └── settings_page.dart             # Pagina de configuracion
```

**Archivos modificados:**
- `lib/app.dart` - ThemeBloc como BlocProvider global + BlocBuilder para themeMode reactivo
- `lib/core/di/injection_container.dart` - SharedPreferences singleton + ThemeBloc/Repository/DataSource
- `lib/core/routing/app_router.dart` - Ruta `/configuracion` para SettingsPage

**Patron:** ThemeBloc es LazySingleton (estado global compartido en toda la app)

### 🎨 FASE 1: UX/UI

**SettingsPage:** Scaffold con AppBar + ListView (patron mobile nativo)
- Card con 3 opciones de tema (ListTile): Sistema, Claro, Oscuro
- Iconos: brightness_auto, light_mode, dark_mode
- Indicador visual: check_circle + color primary para opcion seleccionada
- Ruta: `/configuracion`

**Transicion suave (CA-007):**
- `themeAnimationDuration: Duration(milliseconds: 300)` en MaterialApp.router
- `themeAnimationCurve: Curves.easeInOut`

**Design System reutilizado:**
- AppTheme.lightTheme / darkTheme (ya existian con paleta deportiva completa)
- DesignTokens para spacing y tipografia
- Colores del tema via Theme.of(context).colorScheme

### 🧪 FASE 5: QA

**flutter analyze:** 0 errores nuevos (18 issues pre-existentes, todos info/warning en otros features)
**Validacion CA:**
- CA-001: ThemeMode.system como default → detecta preferencia del SO
- CA-002: BlocBuilder en app.dart → cambio inmediato sin reinicio
- CA-003: SettingsPage con 3 opciones en ruta /configuracion
- CA-004: SharedPreferences persiste entre sesiones
- CA-005: ThemeBloc es global (antes de auth), pantallas de login respetan tema
- CA-006: Todos los componentes usan Theme.of(context) y AppColors
- CA-007: themeAnimationDuration=300ms con easeInOut
**Validacion RN:**
- RN-001: ThemeMode.system es el default
- RN-002: 3 opciones disponibles
- RN-003: Persistencia local sin internet
- RN-004: Paleta deportiva en AppTheme (verde cesped, azul profundo, naranja)
- RN-005: Arquitectura extensible - agregar tema = definir nuevo ThemeData
- RN-006: Colores con contraste adecuado en ambos modos
