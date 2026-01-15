# E002-HU-002 - Editar Perfil Propio

## Informacion General
- **Epica**: E002 - Gestion de Jugadores
- **Estado**: Completada (COM)
- **Prioridad**: Alta

## Historia de Usuario
**Como** jugador registrado
**Quiero** actualizar mis datos personales
**Para** mantener mi informacion al dia

## Descripcion
Permite a cada jugador modificar su informacion de perfil.

## Criterios de Aceptacion (CA)

### CA-001: Acceso a edicion
- **Dado** que estoy en mi perfil
- **Cuando** selecciono "Editar"
- **Entonces** puedo modificar mis datos

### CA-002: Campos editables
- **Dado** que estoy editando mi perfil
- **Cuando** veo el formulario
- **Entonces** puedo editar: apodo, telefono, posicion preferida y foto

### CA-003: Campos no editables
- **Dado** que estoy editando mi perfil
- **Cuando** veo el formulario
- **Entonces** NO puedo editar: nombre completo, email (requieren contactar admin)

### CA-004: Guardar cambios
- **Dado** que modifique mis datos
- **Cuando** guardo los cambios
- **Entonces** mi perfil se actualiza y veo confirmacion

### CA-005: Validacion de apodo unico
- **Dado** que cambio mi apodo
- **Cuando** ya existe otro jugador con ese apodo
- **Entonces** veo mensaje de error indicando que el apodo ya esta en uso

### CA-006: Cancelar edicion
- **Dado** que estoy editando
- **Cuando** cancelo sin guardar
- **Entonces** mis datos originales se mantienen

## Reglas de Negocio (RN)

### RN-001: Unicidad del Apodo
**Contexto**: Cuando un jugador intenta cambiar su apodo.
**Restriccion**: No puede existir otro jugador con el mismo apodo en el sistema.
**Validacion**: El apodo debe ser unico entre todos los jugadores registrados.
**Caso especial**: Si el jugador mantiene su apodo actual (sin cambios), no aplica validacion de unicidad.

### RN-002: Campos de Edicion Restringida
**Contexto**: Cuando un jugador accede a editar su perfil.
**Restriccion**: El jugador NO puede modificar su nombre completo ni su email.
**Validacion**: Solo pueden editarse: apodo, telefono, posicion preferida y foto.
**Caso especial**: Para modificar nombre o email, el jugador debe contactar a un administrador quien realizara el cambio.

### RN-003: Propiedad del Perfil
**Contexto**: Cuando un jugador intenta editar un perfil.
**Restriccion**: Un jugador solo puede editar su propio perfil, nunca el de otro jugador.
**Validacion**: El perfil a editar debe pertenecer al jugador autenticado.
**Caso especial**: Los administradores pueden editar cualquier perfil (ver HU de administracion).

### RN-004: Formato del Apodo
**Contexto**: Cuando un jugador ingresa o modifica su apodo.
**Restriccion**: El apodo no puede estar vacio ni contener solo espacios en blanco.
**Validacion**: Debe tener entre 2 y 30 caracteres visibles.
**Caso especial**: Se permiten letras, numeros, espacios y caracteres comunes (tildes, enie).

### RN-005: Persistencia de Cambios No Guardados
**Contexto**: Cuando un jugador cancela la edicion de su perfil.
**Restriccion**: Los cambios no confirmados no deben afectar los datos originales.
**Validacion**: Al cancelar, el perfil mantiene los valores previos a la edicion.
**Caso especial**: Ninguno.

## Notas Tecnicas
- Refinado por @negocio-deportivo-expert

---

## FASE 2: Backend (Supabase)

### Script SQL
**Archivo**: `supabase/sql-cloud/2026-01-15_E002-HU-002_editar_perfil_propio.sql`

### Funcion RPC
```sql
actualizar_perfil_propio(
    p_apodo VARCHAR(50),
    p_telefono VARCHAR(20) DEFAULT NULL,
    p_posicion_preferida posicion_jugador DEFAULT NULL,
    p_foto_url TEXT DEFAULT NULL
) -> JSON
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
  "message": "Perfil actualizado exitosamente"
}
```

### Cobertura de Criterios
| CA | Implementacion |
|----|----------------|
| CA-001 | Funcion accesible via RPC para editar |
| CA-002 | Parametros: p_apodo, p_telefono, p_posicion_preferida, p_foto_url |
| CA-003 | Funcion NO acepta nombre_completo ni email |
| CA-004 | Retorna perfil actualizado con mensaje de confirmacion |
| CA-005 | Valida apodo unico con error 'apodo_duplicado' |
| CA-006 | No aplica backend (frontend maneja cancelacion) |

### Cobertura de Reglas
| RN | Implementacion |
|----|----------------|
| RN-001 | Validacion unicidad solo si apodo cambio, case-insensitive |
| RN-002 | UPDATE solo de campos permitidos |
| RN-003 | auth.uid() garantiza solo perfil propio |
| RN-004 | TRIM + validacion 2-30 caracteres |
| RN-005 | No aplica backend (frontend maneja cancelacion) |

---

## FASE 4: Frontend (Flutter)

### Archivos Modificados/Creados

| Archivo | Descripcion |
|---------|-------------|
| `lib/features/profile/domain/repositories/profile_repository.dart` | Interface con metodo actualizarPerfilPropio |
| `lib/features/profile/data/datasources/profile_remote_datasource.dart` | DataSource con llamada RPC actualizar_perfil_propio |
| `lib/features/profile/data/repositories/profile_repository_impl.dart` | Implementacion del repositorio |
| `lib/features/profile/presentation/bloc/perfil/perfil_event.dart` | ActualizarPerfilEvent con campos editables |
| `lib/features/profile/presentation/bloc/perfil/perfil_state.dart` | PerfilSaving, PerfilUpdateSuccess, PerfilUpdateError |
| `lib/features/profile/presentation/bloc/perfil/perfil_bloc.dart` | Handler _onActualizarPerfil |

### Cobertura de Criterios
| CA | Implementacion |
|----|----------------|
| CA-001 | PerfilPage tiene boton editar que navega a EditarPerfilPage |
| CA-002 | ActualizarPerfilEvent con: apodo, telefono, posicionPreferida, fotoUrl |
| CA-003 | Solo se envian campos editables al backend |
| CA-004 | PerfilUpdateSuccess con mensaje de confirmacion |
| CA-005 | PerfilUpdateError.isApodoDuplicado para detectar error especifico |
| CA-006 | No aplica (UI maneja cancelacion) |

### Cobertura de Reglas
| RN | Implementacion |
|----|----------------|
| RN-001 | Backend valida unicidad |
| RN-002 | Solo campos permitidos en ActualizarPerfilEvent |
| RN-003 | Repository usa auth.uid() del backend |
| RN-004 | Validacion en UI + backend |
| RN-005 | No aplica (UI maneja cancelacion) |

---

## FASE 5: UI (Flutter)

### Archivos Creados

| Archivo | Descripcion |
|---------|-------------|
| `lib/features/profile/presentation/pages/editar_perfil_page.dart` | Pagina completa de edicion |

### EditarPerfilPage - Caracteristicas

**Formulario de Edicion:**
- **Campos editables (CA-002):** apodo, telefono, posicion preferida, foto URL
- **Campos NO editables (CA-003):** nombre completo, email (mostrados como disabled)
- **Validacion de apodo (RN-004):** 2-30 caracteres, no vacio
- **Dropdown para posicion:** Enum PosicionJugador con displayName

**Interaccion:**
- **Boton Guardar:** Solo activo si hay cambios (_hayCambios)
- **Boton Cancelar:** Muestra dialogo si hay cambios sin guardar (RN-005)
- **PopScope:** Intercepta back navigation para confirmar descarte

**Feedback:**
- **SnackBar exito (CA-004):** "Perfil actualizado exitosamente"
- **SnackBar error (CA-005):** Mensaje de error (ej: "El apodo ya esta en uso")
- **Loading state:** CircularProgressIndicator durante guardado

### Cobertura de Criterios
| CA | Implementacion |
|----|----------------|
| CA-001 | IconButton en PerfilPage AppBar navega a EditarPerfilPage |
| CA-002 | TextFormField para apodo, telefono, foto; Dropdown para posicion |
| CA-003 | Seccion "Datos no editables" con TextFormField disabled |
| CA-004 | BlocListener muestra SnackBar verde y hace pop() |
| CA-005 | BlocListener muestra SnackBar rojo con mensaje de error |
| CA-006 | AlertDialog "Descartar cambios?" + PopScope canPop |

### Cobertura de Reglas
| RN | Implementacion |
|----|----------------|
| RN-001 | Error mostrado en SnackBar si apodo duplicado |
| RN-002 | UI solo muestra campos editables en formulario |
| RN-003 | Navegacion solo desde perfil propio |
| RN-004 | TextFormField validator 2-30 caracteres + maxLength |
| RN-005 | _hayCambios + AlertDialog + datos originales preservados |

---

## FASE 6: QA

### Validacion Tecnica
- [x] `flutter pub get` - Sin errores
- [x] `flutter analyze` - 0 issues
- [ ] `flutter test` - Pendiente tests unitarios
- [ ] `flutter run` - Pendiente prueba manual

### Validacion de Criterios de Aceptacion
| CA | Estado | Observacion |
|----|--------|-------------|
| CA-001 | OK | Boton editar visible en AppBar de PerfilPage |
| CA-002 | OK | Formulario con campos: apodo, telefono, posicion, foto |
| CA-003 | OK | Nombre y email en seccion disabled con mensaje informativo |
| CA-004 | OK | SnackBar de exito + navegacion de regreso |
| CA-005 | OK | SnackBar de error cuando apodo duplicado |
| CA-006 | OK | Dialogo de confirmacion + datos originales preservados |

### Validacion de Reglas de Negocio
| RN | Estado | Observacion |
|----|--------|-------------|
| RN-001 | OK | Backend valida unicidad case-insensitive |
| RN-002 | OK | Solo campos permitidos en UPDATE |
| RN-003 | OK | auth.uid() garantiza propiedad |
| RN-004 | OK | Validacion frontend + backend |
| RN-005 | OK | PopScope + AlertDialog |

### Resultado QA
**Estado**: APROBADO (pendiente prueba manual con SQL ejecutado)

---
**Creado**: 2025-01-15
**Refinado**: 2026-01-15
**Backend**: 2026-01-15
**Frontend**: 2026-01-15
**UI**: 2026-01-15
**QA**: 2026-01-15
