-- ============================================
-- FIX: Agregar columna limite_jugadores a tabla fechas
-- Fecha: 2026-02-01
-- Descripcion: Corrige error "column 'limite_jugadores' does not exist"
--              referenciado en E003-HU-011 inscribir_jugador_admin
-- ============================================
-- IMPORTANTE: Ejecutar ANTES del script 2026-01-31_E003-HU-011_inscribir_jugador_admin.sql
-- ============================================

-- ============================================
-- PARTE 1: AGREGAR COLUMNA limite_jugadores
-- ============================================

-- Agregar columna limite_jugadores a la tabla fechas
-- NULL significa sin limite de jugadores
ALTER TABLE fechas
ADD COLUMN IF NOT EXISTS limite_jugadores INTEGER DEFAULT NULL;

-- Comentario de documentacion
COMMENT ON COLUMN fechas.limite_jugadores IS 'Limite maximo de jugadores para la fecha. NULL = sin limite.';

-- ============================================
-- PARTE 2: CONSTRAINT DE VALIDACION (opcional pero recomendado)
-- ============================================

-- Asegurar que si se define un limite, sea mayor a 0
-- Usamos DO block para evitar error si el constraint ya existe
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'fechas_limite_jugadores_positivo'
    ) THEN
        ALTER TABLE fechas
        ADD CONSTRAINT fechas_limite_jugadores_positivo
        CHECK (limite_jugadores IS NULL OR limite_jugadores > 0);
    END IF;
END $$;

-- ============================================
-- PARTE 3: INDICE PARA CONSULTAS (opcional)
-- ============================================

-- Indice parcial para fechas con limite definido
CREATE INDEX IF NOT EXISTS idx_fechas_limite_jugadores
ON fechas(limite_jugadores)
WHERE limite_jugadores IS NOT NULL;

-- ============================================
-- VERIFICACION
-- ============================================

-- Mostrar estructura actualizada de la columna
SELECT column_name, data_type, column_default, is_nullable
FROM information_schema.columns
WHERE table_name = 'fechas'
AND column_name = 'limite_jugadores';

-- ============================================
-- FIN DEL SCRIPT
-- ============================================
