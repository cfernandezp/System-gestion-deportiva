-- ============================================
-- E003-HU-006: MIGRACION - Corregir tabla asignaciones_equipos
-- Fecha: 2026-01-29
-- Descripcion: La tabla ya existe con esquema incorrecto.
--              Este script corrige la estructura existente.
-- ============================================
--
-- PROBLEMA DETECTADO:
-- La tabla tiene columna "equipo" pero los scripts esperan "color_equipo"
-- Faltan columnas: numero_equipo, asignado_por, asignado_at
--
-- SOLUCION:
-- 1. Renombrar columna equipo -> color_equipo
-- 2. Agregar columnas faltantes
-- 3. Crear funciones RPC
-- ============================================

-- ============================================
-- PASO 1: RENOMBRAR COLUMNA equipo -> color_equipo
-- ============================================

-- Verificar si la columna se llama 'equipo' y renombrarla
DO $$
BEGIN
    -- Si existe columna 'equipo' y no existe 'color_equipo', renombrar
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'asignaciones_equipos'
        AND column_name = 'equipo'
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'asignaciones_equipos'
        AND column_name = 'color_equipo'
    ) THEN
        ALTER TABLE asignaciones_equipos RENAME COLUMN equipo TO color_equipo;
        RAISE NOTICE 'Columna equipo renombrada a color_equipo';
    ELSE
        RAISE NOTICE 'Columna ya tiene el nombre correcto o no existe';
    END IF;
END $$;

-- ============================================
-- PASO 2: AGREGAR COLUMNAS FALTANTES
-- ============================================

-- Agregar numero_equipo si no existe
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'asignaciones_equipos'
        AND column_name = 'numero_equipo'
    ) THEN
        ALTER TABLE asignaciones_equipos
        ADD COLUMN numero_equipo INTEGER NOT NULL DEFAULT 1
        CHECK (numero_equipo BETWEEN 1 AND 3);
        RAISE NOTICE 'Columna numero_equipo agregada';
    ELSE
        RAISE NOTICE 'Columna numero_equipo ya existe';
    END IF;
END $$;

-- Agregar asignado_por si no existe
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'asignaciones_equipos'
        AND column_name = 'asignado_por'
    ) THEN
        ALTER TABLE asignaciones_equipos
        ADD COLUMN asignado_por UUID REFERENCES usuarios(id) ON DELETE SET NULL;
        RAISE NOTICE 'Columna asignado_por agregada';
    ELSE
        RAISE NOTICE 'Columna asignado_por ya existe';
    END IF;
END $$;

-- Agregar asignado_at si no existe
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'asignaciones_equipos'
        AND column_name = 'asignado_at'
    ) THEN
        ALTER TABLE asignaciones_equipos
        ADD COLUMN asignado_at TIMESTAMPTZ DEFAULT NOW();
        RAISE NOTICE 'Columna asignado_at agregada';
    ELSE
        RAISE NOTICE 'Columna asignado_at ya existe';
    END IF;
END $$;

-- ============================================
-- PASO 3: AGREGAR INDICE SI NO EXISTE
-- ============================================

-- Indice para consultas por fecha y numero de equipo
CREATE INDEX IF NOT EXISTS idx_asignaciones_fecha_numero
ON asignaciones_equipos(fecha_id, numero_equipo);

-- ============================================
-- PASO 4: VERIFICAR ESTRUCTURA FINAL
-- ============================================

-- Mostrar columnas actuales de la tabla
SELECT column_name, data_type, udt_name, is_nullable
FROM information_schema.columns
WHERE table_name = 'asignaciones_equipos'
ORDER BY ordinal_position;

-- ============================================
-- FIN DE MIGRACION DE TABLA
-- ============================================
--
-- SIGUIENTE PASO:
-- Ejecutar 2026-01-28_E003-HU-006_ver_mi_equipo.sql
-- Las funciones RPC y RLS se crearan/actualizaran
-- (CREATE OR REPLACE y DROP POLICY IF EXISTS son seguros)
-- ============================================
