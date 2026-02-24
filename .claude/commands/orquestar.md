---
description: Comando para orquestar la implementación de HUs coordinando todos los agentes especializados
enabled: true
agent: mobile-architect-expert
---

# Comando: /orquestar

Invoca al **mobile-architect-expert** para coordinar la implementación completa de una Historia de Usuario.

## Uso

```
/orquestar [ID-HU]
```

## Parámetros

- `ID-HU`: Identificador de la Historia de Usuario (ej: E001-HU-001)

## Ejemplos

```bash
# Implementación completa de una HU
/orquestar E001-HU-001

# Con ruta completa
/orquestar docs/historias-usuario/E001-HU-001-REF-gestion-miembros.md
```

## Lo que hace el mobile-architect-expert:

1. Lee y analiza la Historia de Usuario
2. Cambia estado REF -> DEV
3. Invoca agentes en orden correcto (Backend -> Frontend -> UI -> QA)
4. Valida resultados entre fases
5. Gestiona errores y re-ejecuta cuando sea necesario
6. Cambia estado DEV -> COM al completar

## Agentes que coordina:

- **po-user-stories-template**: Creación/refinamiento de HUs
- **negocio-deportivo-expert**: Análisis de reglas de negocio
- **ux-ui-expert**: Diseño de interfaces mobile (Android/iOS)
- **supabase-expert**: Backend y base de datos
- **flutter-expert**: Frontend Flutter Mobile (Android/iOS)
- **qa-testing-expert**: Testing y validación técnica
