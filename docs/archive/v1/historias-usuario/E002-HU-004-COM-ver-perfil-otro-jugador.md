# E002-HU-004 - Ver Perfil de Otro Jugador

## Informacion General
- **Epica**: E002 - Gestion de Jugadores
- **Estado**: ✅ Completada (COM)
- **Prioridad**: Baja

## Historia de Usuario
**Como** jugador registrado
**Quiero** ver el perfil de otro miembro del grupo
**Para** conocer informacion basica de mis companeros

## Descripcion
Permite ver informacion publica de otros jugadores del grupo.

## Criterios de Aceptacion (CA)

### CA-001: Acceso desde lista
- **Dado** que estoy en la lista de jugadores
- **Cuando** selecciono un jugador
- **Entonces** veo su perfil publico

### CA-002: Datos publicos visibles
- **Dado** que veo el perfil de otro jugador
- **Cuando** observo su informacion
- **Entonces** veo: foto, apodo, posicion preferida y fecha de ingreso

### CA-003: Datos privados ocultos
- **Dado** que veo el perfil de otro jugador
- **Cuando** observo su informacion
- **Entonces** NO veo: email ni telefono (datos privados)

### CA-004: Estadisticas basicas
- **Dado** que veo el perfil de otro jugador
- **Cuando** hay estadisticas disponibles
- **Entonces** veo: goles totales, partidos jugados, puntos acumulados

## Reglas de Negocio (RN)

### RN-001: Clasificacion de Datos Publicos
**Contexto**: Cuando un jugador visualiza el perfil de otro miembro del grupo.
**Restriccion**: No mostrar informacion clasificada como privada en el perfil de terceros.
**Validacion**: Los siguientes datos son publicos y visibles para cualquier miembro del grupo:
- Foto de perfil
- Apodo/Alias
- Posicion preferida de juego
- Fecha de ingreso al grupo
**Caso especial**: Si un dato publico no esta registrado (ej: foto, posicion), mostrar un valor por defecto o indicador de "no disponible".

### RN-002: Proteccion de Datos Privados
**Contexto**: Cuando un jugador visualiza el perfil de otro miembro del grupo.
**Restriccion**: Nunca exponer datos de contacto personal de otros jugadores.
**Validacion**: Los siguientes datos son privados y NO deben mostrarse a terceros:
- Email
- Telefono
**Caso especial**: El jugador SI puede ver sus propios datos privados en su perfil personal (HU-001).

### RN-003: Visibilidad de Estadisticas
**Contexto**: Cuando se visualiza el perfil de cualquier jugador del grupo.
**Restriccion**: No mostrar estadisticas si el jugador no tiene participacion registrada.
**Validacion**: Las estadisticas publicas incluyen:
- Goles totales anotados
- Cantidad de partidos jugados
- Puntos acumulados
**Caso especial**: Si el jugador no tiene partidos jugados, mostrar los valores en cero (0) en lugar de ocultar la seccion.

### RN-004: Requisito de Membresia
**Contexto**: Cuando se intenta acceder al perfil de otro jugador.
**Restriccion**: No permitir visualizar perfiles de jugadores que no pertenecen al mismo grupo.
**Validacion**: Solo los miembros registrados y activos del grupo pueden ver perfiles de otros miembros del mismo grupo.
**Caso especial**: Si el jugador consultado fue dado de baja del grupo, no debe ser accesible su perfil.

## Notas Tecnicas
- Refinado por @negocio-deportivo-expert

---

## 🗄️ FASE 2: Backend (Supabase)

**Implementado por**: @supabase-expert

### Script SQL
- `supabase/sql-cloud/2026-01-16_E002-HU-004_ver_perfil_otro_jugador.sql`

### Funcion RPC
- `obtener_perfil_jugador(p_jugador_id UUID)` → JSON

### Cumplimiento CA/RN
| Criterio | Implementacion |
|----------|----------------|
| CA-001 | Funcion RPC recibe jugador_id como parametro |
| CA-002 | Retorna: foto_url, apodo, posicion_preferida, fecha_ingreso |
| CA-003 | NO retorna email ni telefono (solo datos publicos) |
| CA-004 | Retorna estadisticas: goles_totales, partidos_jugados, puntos_acumulados |
| RN-001 | Solo retorna campos publicos definidos |
| RN-002 | Excluye email y telefono del JSON de respuesta |
| RN-003 | Estadisticas en 0 si no hay partidos (no oculta seccion) |
| RN-004 | Valida que solicitante y jugador esten "aprobado" |

---

## 💻 FASE 4: Frontend (Flutter)

**Implementado por**: @flutter-expert

### Archivos Creados/Modificados

**Model:**
- `lib/features/jugadores/data/models/jugador_perfil_model.dart`
  - `EstadisticasJugador`: goles, partidos, puntos
  - `JugadorPerfilModel`: perfil publico completo
  - `JugadorPerfilResponseModel`: wrapper de respuesta

**DataSource:**
- `lib/features/jugadores/data/datasources/jugadores_remote_datasource.dart`
  - Metodo: `obtenerPerfilJugador(jugadorId)` → llama RPC

**Repository:**
- `lib/features/jugadores/domain/repositories/jugadores_repository.dart`
- `lib/features/jugadores/data/repositories/jugadores_repository_impl.dart`
  - Metodo: `obtenerPerfilJugador(jugadorId)` → Either<Failure, Response>

**Bloc:**
- `lib/features/jugadores/presentation/bloc/perfil_jugador/`
  - `perfil_jugador_bloc.dart`: Maneja CargarPerfilJugadorEvent, RefrescarPerfilJugadorEvent
  - `perfil_jugador_event.dart`: Eventos del bloc
  - `perfil_jugador_state.dart`: Estados (Loading, Loaded, Error)
  - `perfil_jugador.dart`: Barrel file

**DI:**
- `lib/core/di/injection_container.dart`
  - Registrado: `PerfilJugadorBloc`

---

## 🎨 FASE 1: UI (Flutter)

**Implementado por**: @ux-ui-expert

### Archivos Creados/Modificados

**Page:**
- `lib/features/jugadores/presentation/pages/jugador_perfil_page.dart`
  - `_MobilePerfilView`: Header con gradiente, avatar, apodo, info y estadisticas
  - `_DesktopPerfilView`: Layout 2 columnas, card izquierda avatar, card derecha info
  - `_LoadingView`: Spinner centrado
  - `_ErrorView`: Mensaje de error con botones Volver/Reintentar

**Routing:**
- `lib/core/routing/app_router.dart`
  - Ruta: `/jugadores/:id` → `JugadorPerfilPage`
  - BlocProvider inyecta `PerfilJugadorBloc`

**Navegacion desde Lista:**
- `lib/features/jugadores/presentation/pages/jugadores_page.dart`
  - `JugadorCard.onTap` → `context.push('/jugadores/${jugador.jugadorId}')`

### Cumplimiento Visual CA
| Criterio | Widget/Seccion |
|----------|----------------|
| CA-001 | Navegacion desde JugadorCard.onTap a /jugadores/:id |
| CA-002 | Header: avatar (foto o iniciales), apodo, posicion badge, fecha ingreso |
| CA-003 | NO se muestra email ni telefono en ningun lugar |
| CA-004 | Card Estadisticas: 3 columnas (Goles, Partidos, Puntos) |

---

## 🧪 FASE 5: QA

**Validado por**: @web-architect-expert

### Validacion Tecnica
- [x] `flutter pub get` - OK
- [x] `flutter analyze` - 0 errores
- [x] Compilacion exitosa

### Validacion Funcional CA
- [x] CA-001: Tap en jugador navega a perfil
- [x] CA-002: Se muestran foto/avatar, apodo, posicion, fecha
- [x] CA-003: NO se muestran email ni telefono
- [x] CA-004: Se muestran estadisticas (0 si no hay partidos)

### Validacion RN
- [x] RN-001: Solo datos publicos visibles
- [x] RN-002: Datos privados protegidos (solo en backend, no llegan a UI)
- [x] RN-003: Estadisticas en 0, seccion siempre visible
- [x] RN-004: Backend valida membresia activa

---
**Creado**: 2025-01-15
**Refinado**: 2026-01-15
**Implementado**: 2026-01-16
