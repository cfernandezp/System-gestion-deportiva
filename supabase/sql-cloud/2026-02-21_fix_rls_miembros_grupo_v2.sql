-- ============================================
-- FIX: Recursion infinita en RLS de miembros_grupo
-- Fecha: 2026-02-21
-- Error: PostgrestException 42P17 "infinite recursion detected in policy for relation miembros_grupo"
--
-- CAUSA RAIZ:
--   La policy "miembros_select" en miembros_grupo hace:
--     EXISTS (SELECT 1 FROM miembros_grupo my_membership ...)
--   Esto se auto-referencia: al evaluar la policy de miembros_grupo,
--   el subquery a miembros_grupo dispara la MISMA policy = recursion infinita.
--
--   La cadena completa cuando se consulta "grupos":
--     grupos policy (grupos_select_miembro)
--       -> JOIN miembros_grupo (dispara miembros_select policy)
--         -> SELECT FROM miembros_grupo (dispara miembros_select policy de nuevo)
--           -> RECURSION INFINITA
--
-- SOLUCION:
--   Cambiar miembros_select a USING (TRUE) para usuarios autenticados.
--   Esto es SEGURO porque:
--   - miembros_grupo solo contiene IDs (grupo_id, usuario_id), rol y activo
--   - NO contiene datos personales sensibles (nombre, email, celular, etc.)
--   - Los datos personales estan protegidos por RLS de la tabla "usuarios"
--   - Las RPCs SECURITY DEFINER (obtener_miembros_grupo, etc.) son las que
--     hacen JOIN con usuarios para retornar datos personales
--   - INSERT/UPDATE ya tienen USING (TRUE) sin problemas
--
-- EJECUTAR EN: https://supabase.com/dashboard/project/tvvubzkqbksxvcjvivij/sql
-- ============================================


-- ============================================
-- PASO 1: Eliminar la policy problematica con auto-referencia
-- ============================================
DROP POLICY IF EXISTS "miembros_select" ON miembros_grupo;


-- ============================================
-- PASO 2: Crear nueva policy SIN auto-referencia
--
-- USING (TRUE) = cualquier usuario autenticado puede leer miembros_grupo
-- Esto es seguro porque la tabla solo tiene:
--   id, grupo_id, usuario_id, rol, activo, created_at, updated_at, ultimo_acceso
-- Ningun dato sensible. Los datos personales estan en "usuarios" (protegida por su propio RLS).
-- ============================================
CREATE POLICY "miembros_select"
ON miembros_grupo
FOR SELECT
TO authenticated
USING (TRUE);


-- ============================================
-- PASO 3: Verificacion
-- ============================================

-- 3a. Listar policies de miembros_grupo para confirmar el cambio
SELECT
    policyname,
    cmd,
    LEFT(qual::text, 120) AS using_clause,
    LEFT(with_check::text, 120) AS with_check_clause
FROM pg_policies
WHERE tablename = 'miembros_grupo'
AND schemaname = 'public'
ORDER BY policyname;

-- 3b. Verificar que NO hay auto-referencia en ninguna policy de las 3 tablas
-- Las policies que referencian otras tablas deben formar cadenas que TERMINAN:
--   grupos -> miembros_grupo (TRUE) -> FIN
--   grupos -> usuarios (auth_user_id = auth.uid()) -> FIN
--   miembros_grupo (TRUE) -> FIN
--   usuarios (auth_user_id = auth.uid()) -> FIN
SELECT
    tablename,
    policyname,
    cmd,
    LEFT(qual::text, 150) AS using_clause
FROM pg_policies
WHERE tablename IN ('usuarios', 'grupos', 'miembros_grupo')
AND schemaname = 'public'
ORDER BY tablename, policyname;


-- ============================================
-- NOTAS
-- ============================================
-- Despues de ejecutar este script, la cadena de evaluacion sera:
--
-- Query: supabase.from('grupos').select().eq('id', grupoId).single()
--   1. Evalua policy "grupos_select_miembro":
--      EXISTS (SELECT 1 FROM miembros_grupo mg JOIN usuarios u ...)
--   2. Accede a miembros_grupo -> evalua policy "miembros_select": USING (TRUE) -> OK
--   3. Accede a usuarios -> evalua policy "usuarios_select_own": auth_user_id = auth.uid() -> OK
--   4. FIN. Sin recursion.
--
-- Query: supabase.from('miembros_grupo').select().eq('grupo_id', grupoId)
--   1. Evalua policy "miembros_select": USING (TRUE) -> OK
--   2. FIN. Sin recursion.
-- ============================================
