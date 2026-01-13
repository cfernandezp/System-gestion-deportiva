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
