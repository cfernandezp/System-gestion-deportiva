-- ============================================
-- FIX: Ampliar columna sesiones_log.evento y CHECK constraint
-- Fecha: 2026-02-21
-- Descripcion: La columna sesiones_log.evento tenia dos restricciones
--   que impedian insertar los nuevos tipos de evento de E001-HU-007
--   (recuperacion de contrasena):
--
--   1) VARCHAR(20) - insuficiente para 'password_reset_codigo' (21 chars)
--      y 'password_reset_pregunta' (24 chars).
--      Solucion: Ampliar a VARCHAR(50).
--
--   2) CHECK constraint "sesiones_log_evento_check" - solo permitia
--      los valores 'login' y 'logout'.
--      Error en produccion: "new row for relation sesiones_log violates
--      check constraint sesiones_log_evento_check"
--      Solucion: Eliminar el CHECK viejo y recrear con todos los valores.
--
-- Impacto:
--   - ALTER TYPE en VARCHAR (ampliar) no reescribe la tabla, es seguro.
--   - DROP/ADD CONSTRAINT es una operacion DDL rapida.
--   - Los datos existentes ('login', 'logout') siguen siendo validos.
-- ============================================

BEGIN;

-- -----------------------------------------------
-- Paso 1: Ampliar VARCHAR(20) a VARCHAR(50)
-- -----------------------------------------------
-- Si ya se ejecuto este paso antes, no causa error (es idempotente para ampliar)
ALTER TABLE sesiones_log
    ALTER COLUMN evento TYPE VARCHAR(50);

-- -----------------------------------------------
-- Paso 2: Eliminar el CHECK constraint actual
-- -----------------------------------------------
-- El constraint "sesiones_log_evento_check" solo permite 'login' y 'logout'
-- Usamos IF EXISTS para que sea idempotente
ALTER TABLE sesiones_log
    DROP CONSTRAINT IF EXISTS sesiones_log_evento_check;

-- -----------------------------------------------
-- Paso 3: Recrear el CHECK constraint con todos los valores permitidos
-- -----------------------------------------------
-- Valores:
--   'login'                    -> inicio de sesion
--   'logout'                   -> cierre de sesion
--   'password_reset_codigo'    -> restablecimiento via codigo del admin (E001-HU-007)
--   'password_reset_pregunta'  -> restablecimiento via pregunta de seguridad (E001-HU-007)
ALTER TABLE sesiones_log
    ADD CONSTRAINT sesiones_log_evento_check
    CHECK (evento IN ('login', 'logout', 'password_reset_codigo', 'password_reset_pregunta'));

COMMIT;

-- -----------------------------------------------
-- Verificacion (ejecutar como SELECT aparte si se desea confirmar)
-- -----------------------------------------------
-- SELECT conname, pg_get_constraintdef(oid)
-- FROM pg_constraint
-- WHERE conrelid = 'sesiones_log'::regclass AND contype = 'c';
