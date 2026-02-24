-- ============================================
-- EJECUTAR FIXES PENDIENTES
-- Fecha: 2026-02-23
-- ============================================
--
-- INSTRUCCIONES: Ejecutar ESTE archivo en Supabase SQL Editor.
-- Consolida todos los fixes pendientes en un solo script.
--
-- CONTENIDO:
--   PASO 1: DROP de overloads de listar_fechas_por_rol
--   PASO 2: Fix timezone para crear_fecha (de fix_timezone_fecha_hora_inicio.sql)
--   PASO 3: Fix timezone para editar_fecha (de fix_timezone_fecha_hora_inicio.sql)
--   PASO 4: Fix timezone + total_inscritos para listar_fechas_por_rol
--   PASO 5: Fix timezone para obtener_mi_actividad_vivo
--   PASO 6: Fix timezone para obtener_resumen_jornada
--
-- NOTA: Este script reemplaza la ejecucion separada de:
--   - 2026-02-22_fix_timezone_fecha_hora_inicio.sql
--   - 2026-02-22_fix_listar_fechas_total_inscritos.sql
-- ============================================


-- ============================================
-- PASO 1: DROP todas las versiones de listar_fechas_por_rol
-- Necesario porque existen multiples overloads en la BD
-- que impiden CREATE OR REPLACE
-- ============================================
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN
        SELECT p.oid, pg_get_function_identity_arguments(p.oid) AS args
        FROM pg_proc p
        JOIN pg_namespace n ON n.oid = p.pronamespace
        WHERE p.proname = 'listar_fechas_por_rol'
          AND n.nspname = 'public'
    LOOP
        EXECUTE format('DROP FUNCTION IF EXISTS public.listar_fechas_por_rol(%s) CASCADE', r.args);
        RAISE NOTICE 'Dropped listar_fechas_por_rol(%)', r.args;
    END LOOP;
END;
$$;

