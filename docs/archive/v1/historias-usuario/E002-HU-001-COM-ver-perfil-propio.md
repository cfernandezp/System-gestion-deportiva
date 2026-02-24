# E002-HU-001 - Ver Perfil Propio

## Informacion General
- **Epica**: E002 - Gestion de Jugadores
- **Estado**: COMPLETADA (COM)
- **Prioridad**: Alta

## Historia de Usuario
**Como** jugador registrado
**Quiero** ver mi perfil personal
**Para** conocer mis datos registrados en el sistema

## Descripcion
Permite a cada jugador visualizar su informacion personal y datos de perfil.

## Criterios de Aceptacion (CA)

### CA-001: Acceso al perfil
- **Dado** que estoy autenticado como jugador
- **Cuando** accedo a la seccion "Mi Perfil"
- **Entonces** veo mi informacion personal

### CA-002: Datos visibles
- **Dado** que estoy en mi perfil
- **Cuando** visualizo la informacion
- **Entonces** veo: nombre completo, apodo, email, telefono, posicion preferida, foto y fecha de ingreso

### CA-003: Datos opcionales vacios
- **Dado** que no he completado campos opcionales
- **Cuando** veo mi perfil
- **Entonces** los campos opcionales muestran indicador de "No especificado"

## Reglas de Negocio (RN)

### RN-001: Acceso exclusivo a perfil propio
**Contexto**: Cuando un jugador solicita ver su perfil personal.
**Restriccion**: Un jugador solo puede visualizar sus propios datos a traves de esta funcionalidad. No puede usar esta vista para acceder a datos de otros jugadores.
**Validacion**: El sistema debe mostrar unicamente la informacion del jugador autenticado que realiza la solicitud.
**Caso especial**: Ninguno.

### RN-002: Datos obligatorios del perfil
**Contexto**: Al mostrar el perfil de un jugador.
**Restriccion**: No se puede mostrar un perfil sin los datos obligatorios completos.
**Validacion**: El perfil debe mostrar siempre: nombre completo, apodo/alias, email y fecha de ingreso al grupo.
**Caso especial**: Si por error de datos historicos faltara alguno de estos campos, el sistema debe indicar "Dato pendiente de completar".

### RN-003: Tratamiento de datos opcionales
**Contexto**: Cuando el jugador visualiza campos opcionales de su perfil.
**Restriccion**: No mostrar campos opcionales como si estuvieran vacios o con errores.
**Validacion**: Los campos opcionales (telefono, posicion preferida, foto) deben mostrar "No especificado" cuando no tienen valor registrado.
**Caso especial**: Si la foto no esta registrada, mostrar una imagen generica de perfil (avatar por defecto).

### RN-004: Posiciones preferidas validas
**Contexto**: Al mostrar la posicion preferida del jugador.
**Restriccion**: La posicion mostrada debe ser una posicion valida de futbol.
**Validacion**: Las posiciones validas son: Arquero, Defensa, Mediocampista, Delantero.
**Caso especial**: Si el jugador tiene registrada una posicion que ya no existe en el sistema, mostrar "Posicion no valida - actualizar perfil".

### RN-005: Formato de fecha de ingreso
**Contexto**: Al mostrar la antiguedad del jugador en el grupo.
**Restriccion**: La fecha de ingreso no debe mostrarse en formato tecnico o ambiguo.
**Validacion**: Mostrar la fecha en formato legible (ejemplo: "15 de enero de 2025") y opcionalmente indicar la antiguedad en el grupo (ejemplo: "Miembro desde hace 6 meses").
**Caso especial**: Ninguno.

## Notas Tecnicas
- Refinado por @negocio-deportivo-expert

---

## FASE 2: Backend (Supabase)

### Script SQL
**Archivo**: `supabase/sql-cloud/2026-01-15_E002-HU-001_ver_perfil_propio.sql`

### Cambios en Base de Datos

#### Tipo ENUM nuevo
```sql
posicion_jugador: 'arquero', 'defensa', 'mediocampista', 'delantero'
```

#### Columnas agregadas a tabla `usuarios`
| Columna | Tipo | Obligatorio | Descripcion |
|---------|------|-------------|-------------|
| apodo | VARCHAR(50) | Si | Apodo/alias del jugador |
| telefono | VARCHAR(20) | No | Telefono de contacto |
| posicion_preferida | posicion_jugador | No | Posicion preferida |
| foto_url | TEXT | No | URL de foto de perfil |

### Funcion RPC
```sql
obtener_perfil_propio() -> JSON
```

**Retorna**:
```json
{
  "success": true,
  "data": {
    "usuario_id": "uuid",
    "nombre_completo": "string",
    "apodo": "string",
    "email": "string",
    "telefono": "string|null",
    "posicion_preferida": "string|null",
    "foto_url": "string|null",
    "fecha_ingreso": "timestamp",
    "fecha_ingreso_formato": "15 de enero de 2025",
    "antiguedad": "6 mes(es)",
    "estado": "string",
    "rol": "string"
  },
  "message": "Perfil obtenido exitosamente"
}
```

### Cobertura de Reglas
- RN-001: Funcion usa `auth.uid()` para garantizar acceso solo a perfil propio
- RN-002: Apodo con valor por defecto "Dato pendiente de completar" si es null
- RN-003: Campos opcionales retornan null (frontend muestra "No especificado")
- RN-004: ENUM limita posiciones validas
- RN-005: `fecha_ingreso_formato` y `antiguedad` calculados

---

## FASE 4: Frontend (Flutter)

### Arquitectura Clean Architecture

```
lib/features/profile/
├── data/
│   ├── models/
│   │   ├── perfil_model.dart        # Modelo con PosicionJugador enum
│   │   └── models.dart              # Barrel file
│   ├── datasources/
│   │   └── profile_remote_datasource.dart  # Llama RPC obtener_perfil_propio
│   └── repositories/
│       └── profile_repository_impl.dart    # Implementacion
├── domain/
│   └── repositories/
│       └── profile_repository.dart         # Interface
└── presentation/
    ├── bloc/perfil/
    │   ├── perfil_bloc.dart         # BLoC principal
    │   ├── perfil_event.dart        # CargarPerfilEvent, RefrescarPerfilEvent
    │   ├── perfil_state.dart        # Initial, Loading, Loaded, Error, Refreshing
    │   └── perfil.dart              # Barrel file
    ├── pages/
    │   ├── perfil_page.dart         # Pagina principal
    │   └── pages.dart               # Barrel file
    └── widgets/
        ├── perfil_avatar.dart       # Avatar con foto o iniciales
        ├── perfil_info_item.dart    # Item de informacion
        ├── perfil_stats_card.dart   # Card de estadisticas
        └── widgets.dart             # Barrel file
```

### Cobertura de Criterios

| CA | Implementacion |
|----|----------------|
| CA-001 | Ruta `/perfil` + boton "Mi Perfil" en HomePage habilitado |
| CA-002 | `PerfilPage` muestra todos los campos del modelo |
| CA-003 | `PerfilInfoItem` muestra "No especificado" para valores null |

### Cobertura de Reglas

| RN | Implementacion |
|----|----------------|
| RN-001 | `ProfileRemoteDataSource.obtenerPerfilPropio()` usa RPC que valida auth |
| RN-002 | `PerfilModel.fromJson()` maneja apodo con default |
| RN-003 | `telefonoDisplay`, `posicionDisplay` retornan "No especificado" |
| RN-004 | Enum `PosicionJugador` con `displayName` |
| RN-005 | `fechaIngresoFormato` y `antiguedad` desde backend |

### Dependencias Registradas
- `PerfilBloc` en `injection_container.dart`
- Ruta `/perfil` en `app_router.dart`

---

## FASE 3: UI/UX

### Componentes Visuales

1. **PerfilAvatar**
   - Muestra foto si existe (RN-003)
   - Muestra iniciales del nombre si no hay foto
   - Gradiente verde primario
   - Sombra adaptativa (light/dark)

2. **PerfilInfoItem**
   - Icono + etiqueta + valor
   - Estilo italico gris para "No especificado" (CA-003)

3. **PerfilStatsCard**
   - Cards de antiguedad y posicion
   - Diseno responsive

4. **PerfilPage**
   - Header con gradiente y avatar grande
   - Badge de rol
   - Pull to refresh
   - Seccion de informacion personal en card

### Responsive
- Mobile: Layout vertical compacto
- Tablet/Desktop: Layout con mas espacio

### Accesibilidad
- Colores del Design System
- Contraste adecuado
- Textos legibles

---

## FASE 5: QA Testing

### Validaciones Tecnicas

| Validacion | Resultado |
|------------|-----------|
| `flutter pub get` | OK - Dependencias resueltas |
| `flutter analyze` | OK - No issues found |
| `flutter test` | OK - All tests passed (1/1) |

### Checklist de Criterios de Aceptacion

| CA | Estado | Validacion |
|----|--------|------------|
| CA-001 | CUMPLIDO | Ruta `/perfil` configurada, boton "Mi Perfil" habilitado en HomePage |
| CA-002 | CUMPLIDO | PerfilPage muestra: nombre, apodo, email, telefono, posicion, foto, fecha ingreso |
| CA-003 | CUMPLIDO | PerfilInfoItem muestra "No especificado" en italica gris para campos null |

### Checklist de Reglas de Negocio

| RN | Estado | Validacion |
|----|--------|------------|
| RN-001 | CUMPLIDO | RPC `obtener_perfil_propio()` usa `auth.uid()` - solo perfil propio |
| RN-002 | CUMPLIDO | Apodo con default "Dato pendiente de completar" |
| RN-003 | CUMPLIDO | Campos opcionales con "No especificado", avatar generico si no hay foto |
| RN-004 | CUMPLIDO | Enum `PosicionJugador` limita valores validos |
| RN-005 | CUMPLIDO | `fecha_ingreso_formato` y `antiguedad` calculados por backend |

### Resultado Final

**APROBADO**

---
**Creado**: 2025-01-15
**Refinado**: 2026-01-15
**Backend**: 2026-01-15
**Frontend**: 2026-01-15
**UI/UX**: 2026-01-15
**QA**: 2026-01-15
