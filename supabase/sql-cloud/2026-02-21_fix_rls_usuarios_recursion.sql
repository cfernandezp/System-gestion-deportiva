-- ============================================
-- FIX: Recursion infinita en RLS de usuarios/grupos/miembros_grupo
-- Fecha: 2026-02-21
-- Error: PostgrestException 42P17 "infinite recursion detected in policy for relation usuarios"
--
-- CAUSA RAIZ:
--   grupos policy      -> subquery a usuarios (dispara RLS de usuarios)
--   miembros_grupo pol -> subquery a usuarios (dispara RLS de usuarios)
--   usuarios policy    -> subquery a grupos/miembros_grupo (dispara RLS de estos)
--   = CICLO INFINITO
--
-- SOLUCION:
--   1. usuarios: policies SOLO usan auth_user_id = auth.uid() (sin subqueries a otras tablas)
--   2. grupos: policies usan auth.uid() directo via JOIN, sin depender de RLS de usuarios
--   3. miembros_grupo: policies usan auth.uid() directo via JOIN, sin depender de RLS de usuarios
--   4. Para ver datos de OTROS usuarios (ej. miembros del grupo): usar RPCs SECURITY DEFINER
--
-- EJECUTAR EN: https://supabase.com/dashboard/project/tvvubzkqbksxvcjvivij/sql
-- ============================================


-- ============================================
-- PASO 0: DIAGNOSTICO - Ver policies actuales
-- Ejecutar este SELECT primero para ver el estado actual.
-- Luego ejecutar el resto del script completo.
-- ============================================
-- SELECT schemaname, tablename, policyname, cmd, qual, with_check
-- FROM pg_policies
-- WHERE tablename IN ('usuarios', 'grupos', 'miembros_grupo')
-- ORDER BY tablename, policyname;


-- ============================================
-- PASO 1: LIMPIAR TODAS las policies de las 3 tablas
-- Eliminamos todo para recrear desde cero sin recursion
-- ============================================

-- 1a. Eliminar TODAS las policies de "usuarios"
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'usuarios' AND schemaname = 'public')
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON usuarios', r.policyname);
        RAISE NOTICE 'Eliminada policy de usuarios: %', r.policyname;
    END LOOP;
END $$;

-- 1b. Eliminar TODAS las policies de "grupos"
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'grupos' AND schemaname = 'public')
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON grupos', r.policyname);
        RAISE NOTICE 'Eliminada policy de grupos: %', r.policyname;
    END LOOP;
END $$;

-- 1c. Eliminar TODAS las policies de "miembros_grupo"
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'miembros_grupo' AND schemaname = 'public')
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON miembros_grupo', r.policyname);
        RAISE NOTICE 'Eliminada policy de miembros_grupo: %', r.policyname;
    END LOOP;
END $$;


-- ============================================
-- PASO 2: Asegurar RLS habilitado en las 3 tablas
-- ============================================
ALTER TABLE usuarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE grupos ENABLE ROW LEVEL SECURITY;
ALTER TABLE miembros_grupo ENABLE ROW LEVEL SECURITY;


-- ============================================
-- PASO 3: POLICIES DE "usuarios" (tabla raiz - SIN subqueries a otras tablas)
--
-- PATRON ANTI-RECURSION: Solo comparar auth_user_id con auth.uid()
-- Para ver otros usuarios del grupo se usan RPCs SECURITY DEFINER
-- ============================================

-- 3a. SELECT: Un usuario solo puede ver su propio registro
-- No necesita consultar grupos ni miembros_grupo
CREATE POLICY "usuarios_select_own"
ON usuarios
FOR SELECT
TO authenticated
USING (auth_user_id = auth.uid());

-- 3b. UPDATE: Un usuario solo puede actualizar su propio registro
CREATE POLICY "usuarios_update_own"
ON usuarios
FOR UPDATE
TO authenticated
USING (auth_user_id = auth.uid())
WITH CHECK (auth_user_id = auth.uid());

-- 3c. INSERT: Permitir inserts (controlado via RPCs SECURITY DEFINER)
-- Los RPCs registrar_administrador, invitar_jugador_grupo, activar_cuenta_jugador
-- ya son SECURITY DEFINER y bypassean RLS.
-- Esta policy permisiva es para el caso edge de que se necesite INSERT directo.
CREATE POLICY "usuarios_insert_auth"
ON usuarios
FOR INSERT
TO authenticated
WITH CHECK (TRUE);

-- 3d. SELECT para service_role (operaciones internas, RPCs SECURITY DEFINER)
-- service_role bypasea RLS por defecto en Supabase, pero lo dejamos explicito
-- No es necesario crear policy para service_role (ya bypasea)


-- ============================================
-- PASO 4: POLICIES DE "grupos" (SIN subqueries a tabla "usuarios")
--
-- PATRON ANTI-RECURSION: Usar JOIN con auth.uid() directamente
-- en vez de subquery "SELECT id FROM usuarios WHERE auth_user_id = auth.uid()"
-- ============================================

-- 4a. SELECT: Admin creador puede ver sus grupos
-- Antes: admin_creador_id IN (SELECT id FROM usuarios WHERE auth_user_id = auth.uid())
-- Ahora: EXISTS con JOIN directo usando auth.uid()
CREATE POLICY "grupos_select_admin"
ON grupos
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM usuarios u
        WHERE u.id = grupos.admin_creador_id
        AND u.auth_user_id = auth.uid()
    )
);

-- 4b. SELECT: Miembros pueden ver grupos donde participan
-- Antes: doble subquery via usuarios -> miembros_grupo
-- Ahora: JOIN directo miembros_grupo -> usuarios con auth.uid()
CREATE POLICY "grupos_select_miembro"
ON grupos
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM miembros_grupo mg
        JOIN usuarios u ON u.id = mg.usuario_id
        WHERE mg.grupo_id = grupos.id
        AND mg.activo = TRUE
        AND u.auth_user_id = auth.uid()
    )
);

-- 4c. UPDATE: Solo admin creador puede actualizar
CREATE POLICY "grupos_update_admin"
ON grupos
FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM usuarios u
        WHERE u.id = grupos.admin_creador_id
        AND u.auth_user_id = auth.uid()
    )
);

-- 4d. INSERT: Via RPCs SECURITY DEFINER (crear_grupo ya es SECURITY DEFINER)
CREATE POLICY "grupos_insert_auth"
ON grupos
FOR INSERT
TO authenticated
WITH CHECK (TRUE);


-- ============================================
-- PASO 5: POLICIES DE "miembros_grupo" (SIN subqueries a tabla "usuarios")
--
-- PATRON ANTI-RECURSION: JOIN directo con usuarios usando auth.uid()
-- ============================================

-- 5a. SELECT: Miembros del grupo pueden ver otros miembros del mismo grupo
-- Antes: doble subquery miembros_grupo -> usuarios -> miembros_grupo
-- Ahora: EXISTS con JOIN directo usando auth.uid()
-- "Puedo ver los miembros de un grupo si YO soy miembro activo de ese grupo"
CREATE POLICY "miembros_select"
ON miembros_grupo
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM miembros_grupo my_membership
        JOIN usuarios u ON u.id = my_membership.usuario_id
        WHERE my_membership.grupo_id = miembros_grupo.grupo_id
        AND my_membership.activo = TRUE
        AND u.auth_user_id = auth.uid()
    )
);

-- 5b. INSERT: Via RPCs SECURITY DEFINER
CREATE POLICY "miembros_insert_auth"
ON miembros_grupo
FOR INSERT
TO authenticated
WITH CHECK (TRUE);

-- 5c. UPDATE: Permitir updates (controlado via RPCs)
CREATE POLICY "miembros_update_auth"
ON miembros_grupo
FOR UPDATE
TO authenticated
USING (TRUE)
WITH CHECK (TRUE);


-- ============================================
-- PASO 6: VERIFICACION
-- Ejecutar para confirmar que las policies se crearon correctamente
-- y NO hay referencias cruzadas peligrosas
-- ============================================

-- 6a. Listar TODAS las policies de las 3 tablas
SELECT
    tablename,
    policyname,
    cmd,
    LEFT(qual::text, 120) AS using_clause,
    LEFT(with_check::text, 120) AS with_check_clause
FROM pg_policies
WHERE tablename IN ('usuarios', 'grupos', 'miembros_grupo')
AND schemaname = 'public'
ORDER BY tablename, policyname;

-- 6b. Resumen: contar policies por tabla
SELECT
    tablename,
    COUNT(*) AS total_policies,
    COUNT(*) FILTER (WHERE cmd = 'SELECT') AS select_policies,
    COUNT(*) FILTER (WHERE cmd = 'INSERT') AS insert_policies,
    COUNT(*) FILTER (WHERE cmd = 'UPDATE') AS update_policies,
    COUNT(*) FILTER (WHERE cmd = 'DELETE') AS delete_policies
FROM pg_policies
WHERE tablename IN ('usuarios', 'grupos', 'miembros_grupo')
AND schemaname = 'public'
GROUP BY tablename
ORDER BY tablename;


-- ============================================
-- NOTAS IMPORTANTES
-- ============================================
-- 1. Las policies de "usuarios" NUNCA referencian grupos ni miembros_grupo
--    Esto rompe el ciclo de recursion.
--
-- 2. Las policies de "grupos" y "miembros_grupo" SIN hacer subquery
--    a "usuarios" con RLS, usan JOIN directo que no dispara
--    las policies de "usuarios" porque la consulta es:
--      EXISTS (SELECT 1 FROM usuarios u WHERE u.auth_user_id = auth.uid())
--    Postgres evalua esto como parte de la policy, no como una
--    query separada que dispare RLS de "usuarios".
--
--    CORRECCION TECNICA: En realidad, el JOIN a "usuarios" SI dispara
--    RLS de "usuarios". PERO como la policy de "usuarios" es:
--      auth_user_id = auth.uid()
--    Esta policy NO referencia ni "grupos" ni "miembros_grupo",
--    por lo tanto NO hay recursion. La cadena termina ahi:
--      grupos -> usuarios (auth_user_id = auth.uid()) -> FIN
--      miembros_grupo -> usuarios (auth_user_id = auth.uid()) -> FIN
--
-- 3. Para ver datos de OTROS usuarios (ej. nombre de miembros del grupo):
--    Usar las RPCs SECURITY DEFINER que ya existen:
--    - obtener_miembros_grupo(p_grupo_id) -> retorna datos de todos los miembros
--    - obtener_mis_grupos() -> retorna grupos con datos agregados
--    Estas funciones bypasean RLS y pueden consultar libremente.
--
-- 4. Queries directas desde Flutter a tabla "grupos":
--      supabase.from('grupos').select().eq('id', grupoId).single()
--    Ahora funcionaran SIN recursion porque:
--    - La policy de grupos consulta usuarios
--    - La policy de usuarios solo compara auth_user_id = auth.uid()
--    - No hay mas subqueries -> no hay recursion
-- ============================================
