-- ============================================
-- ASIGNAR PLAN 5 AL USUARIO DE DESARROLLO
-- Fecha: 2026-02-21
-- Descripcion: Cambia el plan de Cristian Fernandez (939079213) a Plan 5
--              y actualiza el grupo asociado con los limites del Plan 5.
-- EJECUTAR EN: https://supabase.com/dashboard/project/tvvubzkqbksxvcjvivij/sql
-- PARA REVERTIR: Ejecutar la seccion de reversion al final (comentada)
-- ============================================

DO $$
DECLARE
    v_plan5_id UUID;
    v_usuario_id UUID;
    v_grupos_count INTEGER;
BEGIN
    -- =============================================
    -- PASO 1: Obtener ID del Plan 5
    -- =============================================
    SELECT id INTO v_plan5_id
    FROM planes
    WHERE slug = 'plan_5';

    IF v_plan5_id IS NULL THEN
        RAISE EXCEPTION 'No se encontro el Plan 5 en la tabla planes';
    END IF;

    RAISE NOTICE 'Plan 5 ID: %', v_plan5_id;

    -- =============================================
    -- PASO 2: Obtener ID del usuario
    -- =============================================
    SELECT id INTO v_usuario_id
    FROM usuarios
    WHERE celular = '939079213';

    IF v_usuario_id IS NULL THEN
        RAISE EXCEPTION 'No se encontro usuario con celular 939079213';
    END IF;

    RAISE NOTICE 'Usuario ID: %', v_usuario_id;

    -- =============================================
    -- PASO 3: Actualizar plan del usuario
    -- =============================================
    UPDATE usuarios
    SET plan_id = v_plan5_id
    WHERE id = v_usuario_id;

    RAISE NOTICE 'Usuario actualizado a Plan 5';

    -- =============================================
    -- PASO 4: Actualizar plan y limites de sus grupos
    -- Plan 5: 50 jugadores, 3 invitados, 3 coadmins, 3 equipos
    -- =============================================
    UPDATE grupos
    SET plan_id = v_plan5_id,
        limite_jugadores = 50
    WHERE admin_creador_id = v_usuario_id;

    GET DIAGNOSTICS v_grupos_count = ROW_COUNT;
    RAISE NOTICE 'Grupos actualizados: %', v_grupos_count;

    RAISE NOTICE '--- PLAN 5 ASIGNADO CORRECTAMENTE ---';
END $$;

-- =============================================
-- VERIFICACION
-- =============================================
SELECT
    u.nombre_completo,
    u.celular,
    p.nombre AS plan_nombre,
    p.slug AS plan_slug,
    p.precio_mensual,
    p.max_grupos_por_admin,
    p.max_jugadores_por_grupo,
    p.max_invitados_por_grupo,
    p.max_coadmins_por_grupo,
    p.max_equipos_por_fecha,
    p.estadisticas_avanzadas,
    p.temas_personalizados_grupo
FROM usuarios u
LEFT JOIN planes p ON p.id = u.plan_id
WHERE u.celular = '939079213';

SELECT
    g.nombre AS grupo_nombre,
    g.limite_jugadores,
    p.nombre AS plan_nombre
FROM grupos g
LEFT JOIN planes p ON p.id = g.plan_id
LEFT JOIN usuarios u ON u.id = g.admin_creador_id
WHERE u.celular = '939079213';

-- =============================================
-- REVERSION (descomentar para volver a Gratis)
-- =============================================
-- DO $$
-- DECLARE
--     v_gratis_id UUID;
--     v_usuario_id UUID;
-- BEGIN
--     SELECT id INTO v_gratis_id FROM planes WHERE slug = 'gratis';
--     SELECT id INTO v_usuario_id FROM usuarios WHERE celular = '939079213';
--
--     UPDATE usuarios SET plan_id = v_gratis_id WHERE id = v_usuario_id;
--     UPDATE grupos SET plan_id = v_gratis_id, limite_jugadores = 25
--     WHERE admin_creador_id = v_usuario_id;
--
--     RAISE NOTICE 'Revertido a Plan Gratis';
-- END $$;
