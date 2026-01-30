-- ============================================
-- E003-HU-006: Ver Mi Equipo - PASO 1: ENUM
-- Fecha: 2026-01-28
-- IMPORTANTE: Ejecutar ANTES del script principal
-- ============================================

-- Crear tipo ENUM para colores de equipo (RN-005)
-- Si ya existe, el script fallara con error "type already exists" - eso es OK
CREATE TYPE color_equipo AS ENUM (
    'naranja',   -- #FF9800
    'verde',     -- #4CAF50
    'azul',      -- #2196F3
    'rojo',      -- #F44336
    'amarillo',  -- #FFEB3B
    'blanco'     -- #FFFFFF (con borde gris)
);

-- Verificar que el tipo se creo correctamente
SELECT typname, typtype FROM pg_type WHERE typname = 'color_equipo';
