# Convenciones Tecnicas

## Zona Horaria
- **Usuario**: Peru (America/Lima, UTC-5)
- **Servidor Supabase**: Brasil (UTC-3)
- **BD almacena**: UTC

## Backend (Supabase)

### Naming
- Tablas: `snake_case` plural (users, partidos)
- Columnas: `snake_case` (user_id, created_at)
- PK: siempre `id` UUID
- Functions RPC: `snake_case` verbo (crear_partido)

### JSON Response
```json
// Success
{"success": true, "data": {...}, "message": "..."}

// Error
{"success": false, "error": {"code": "...", "message": "...", "hint": "..."}}
```

## Frontend (Flutter)

### Clean Architecture
```
lib/features/[modulo]/
├── data/
│   ├── models/
│   ├── datasources/
│   └── repositories/
├── domain/
│   └── repositories/
└── presentation/
    ├── bloc/
    ├── pages/
    └── widgets/
```

### Mapping
- BD (snake_case) -> Dart (camelCase)
- `nombre_completo` -> `nombreCompleto`

### Routing
- Flat: `/register`, `/login`, `/partidos`
- NO anidado: NO `/auth/register`

## UI

### Design System
- Usar Theme: `Theme.of(context).colorScheme.primary`
- NO hardcoded: NO `Color(0xFF...)`

### Breakpoints
- Mobile: < 600px
- Tablet: 600-1200px
- Desktop: > 1200px

### Spacing
- XS: 4px, S: 8px, M: 16px, L: 24px, XL: 32px

### Paginacion en Tablas

**Regla**: Todas las tablas con mas de 10-15 registros DEBEN implementar paginacion.

**Ubicacion de controles**: Los botones de paginacion deben estar en la parte **SUPERIOR** de la tabla para que el usuario pueda navegar rapidamente sin hacer scroll hasta el final.

**Informacion visible**:
- Indicador de pagina actual: "Pagina X de Y"
- Total de registros: "Total: N registros"
- Rango visible: "Mostrando 1-10 de 25"

**Tamano de pagina**:
- Por defecto: 10 registros
- Opciones disponibles: 10 / 25 / 50

**Componentes del control de paginacion (COMPLETO)**:

Para conjuntos de datos grandes (50+ paginas), la paginacion DEBE incluir:

1. **Navegacion rapida**:
   - Boton "Primera pagina" (<<) - ir al inicio
   - Boton "Ultima pagina" (>>) - ir al final
   - Boton "Anterior" (<) - pagina previa
   - Boton "Siguiente" (>) - pagina siguiente

2. **Input de pagina directa**:
   - Campo numerico donde el usuario puede escribir el numero de pagina
   - Al presionar Enter o perder foco, navegar a esa pagina
   - Validar que sea un numero valido (1 a totalPages)
   - Mostrar error visual si el numero es invalido

**Layout de paginacion mejorado**:
```
[<<] [<] [Pagina: ___] de 50 [>] [>>]  |  Mostrar [10 v] por pagina  |  Mostrando 1-10 de 500
```

**Estructura en codigo**:
```dart
// Ubicar ANTES de la tabla, NO despues
Column(
  children: [
    _PaginationControls(
      currentPage: currentPage,
      totalPages: totalPages,
      onFirstPage: () => onPageChanged(1),
      onPreviousPage: () => onPageChanged(currentPage - 1),
      onNextPage: () => onPageChanged(currentPage + 1),
      onLastPage: () => onPageChanged(totalPages),
      onGoToPage: (page) => onPageChanged(page),  // Input directo
      ...
    ),
    DataTable(...),
  ],
)
```

**Comportamiento del input de pagina**:
- El campo muestra el numero de pagina actual
- El usuario puede escribir un numero y presionar Enter
- Si el numero es < 1, ir a pagina 1
- Si el numero es > totalPages, ir a ultima pagina
- Si no es un numero valido, restaurar el valor anterior
