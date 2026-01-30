-- ============================================
-- DIAGNOSTICO: Verificar inscripciones
-- Ejecutar en Supabase SQL Editor
-- ============================================

-- 1. Ver todas las inscripciones de la fecha específica
-- Reemplazar <FECHA_ID> con el UUID de la fecha
SELECT
    i.id as inscripcion_id,
    i.fecha_id,
    i.usuario_id,
    i.estado,
    i.created_at,
    u.nombre_completo,
    u.email,
    u.estado as estado_usuario
FROM inscripciones i
JOIN usuarios u ON u.id = i.usuario_id
WHERE i.fecha_id = '<FECHA_ID>'
ORDER BY i.created_at;

-- 2. Verificar que Realtime está habilitado para inscripciones
SELECT
    p.pubname as publication,
    c.relname as table_name
FROM pg_publication p
JOIN pg_publication_rel pr ON p.oid = pr.prpubid
JOIN pg_class c ON c.oid = pr.prrelid
WHERE p.pubname = 'supabase_realtime'
AND c.relname = 'inscripciones';

-- 3. Verificar políticas RLS de inscripciones
SELECT
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies
WHERE tablename = 'inscripciones';

-- 4. Contar inscritos activos por fecha
SELECT
    fecha_id,
    COUNT(*) as total_inscritos,
    array_agg(usuario_id) as usuarios_ids
FROM inscripciones
WHERE estado = 'inscrito'
GROUP BY fecha_id;

-- 5. Verificar el usuario "Anthony" específicamente
SELECT
    id,
    auth_user_id,
    nombre_completo,
    email,
    rol,
    estado
FROM usuarios
WHERE nombre_completo ILIKE '%anthony%'
   OR email ILIKE '%anthony%';
