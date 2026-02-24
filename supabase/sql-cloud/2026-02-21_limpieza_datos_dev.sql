-- ============================================
-- LIMPIEZA DE DATOS DE DESARROLLO
-- Fecha: 2026-02-21
-- Descripcion: Elimina todos los usuarios excepto Cristian Fernandez (939079213)
--              y limpia datos de pichangas/fechas/partidos.
--              Conserva: usuario principal, sus grupos, su membresia, tabla planes.
-- EJECUTAR EN: https://supabase.com/dashboard/project/tvvubzkqbksxvcjvivij/sql
-- ============================================

DO $$
DECLARE
    v_usuario_id UUID;
    v_auth_user_id UUID;
    v_count INTEGER;
BEGIN
    -- =============================================
    -- PASO 0: Identificar usuario a conservar
    -- =============================================
    SELECT id, auth_user_id
    INTO v_usuario_id, v_auth_user_id
    FROM usuarios
    WHERE celular = '939079213';

    IF v_usuario_id IS NULL THEN
        RAISE EXCEPTION 'No se encontro usuario con celular 939079213';
    END IF;

    RAISE NOTICE 'Usuario a conservar: % (auth: %)', v_usuario_id, v_auth_user_id;

    -- =============================================
    -- PASO 1: Limpiar datos de pichangas (TODO, incluso los de Cristian)
    -- Orden: hijos antes que padres por FK
    -- =============================================

    -- 1a. Goles (depende de partidos)
    DELETE FROM goles;
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE 'Goles eliminados: %', v_count;

    -- 1b. Partidos (depende de fechas)
    DELETE FROM partidos;
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE 'Partidos eliminados: %', v_count;

    -- 1c. Pagos (depende de inscripciones, fechas)
    DELETE FROM pagos;
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE 'Pagos eliminados: %', v_count;

    -- 1d. Asignaciones de equipos (depende de fechas)
    DELETE FROM asignaciones_equipos;
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE 'Asignaciones eliminadas: %', v_count;

    -- 1e. Inscripciones (depende de fechas)
    DELETE FROM inscripciones;
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE 'Inscripciones eliminadas: %', v_count;

    -- 1f. Fechas
    DELETE FROM fechas;
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE 'Fechas eliminadas: %', v_count;

    -- =============================================
    -- PASO 2: Limpiar tablas auxiliares (TODO)
    -- =============================================

    -- 2a. Codigos de recuperacion
    DELETE FROM codigos_recuperacion;
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE 'Codigos recuperacion eliminados: %', v_count;

    -- 2b. Tokens de recuperacion
    DELETE FROM tokens_recuperacion;
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE 'Tokens recuperacion eliminados: %', v_count;

    -- 2c. Intentos de recuperacion
    DELETE FROM intentos_recuperacion;
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE 'Intentos recuperacion eliminados: %', v_count;

    -- 2d. Intentos de login
    DELETE FROM intentos_login;
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE 'Intentos login eliminados: %', v_count;

    -- 2e. Notificaciones
    DELETE FROM notificaciones;
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE 'Notificaciones eliminadas: %', v_count;

    -- 2f. Sesiones log (conservar solo las de Cristian)
    DELETE FROM sesiones_log WHERE usuario_id != v_usuario_id;
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE 'Sesiones log eliminadas: %', v_count;

    -- =============================================
    -- PASO 3: Limpiar miembros de grupo (excepto Cristian)
    -- =============================================
    DELETE FROM miembros_grupo WHERE usuario_id != v_usuario_id;
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE 'Miembros grupo eliminados: %', v_count;

    -- =============================================
    -- PASO 4: Eliminar otros usuarios de tabla usuarios
    -- =============================================
    DELETE FROM usuarios WHERE id != v_usuario_id;
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE 'Usuarios eliminados: %', v_count;

    -- =============================================
    -- PASO 5: Eliminar otros usuarios de auth.users
    -- =============================================
    IF v_auth_user_id IS NOT NULL THEN
        DELETE FROM auth.users WHERE id != v_auth_user_id;
        GET DIAGNOSTICS v_count = ROW_COUNT;
        RAISE NOTICE 'Auth users eliminados: %', v_count;
    END IF;

    RAISE NOTICE '--- LIMPIEZA COMPLETADA ---';
END $$;

-- =============================================
-- VERIFICACION: Que quedo en la BD
-- =============================================
SELECT 'usuarios' AS tabla, COUNT(*) AS registros FROM usuarios
UNION ALL SELECT 'auth.users', COUNT(*) FROM auth.users
UNION ALL SELECT 'grupos', COUNT(*) FROM grupos
UNION ALL SELECT 'miembros_grupo', COUNT(*) FROM miembros_grupo
UNION ALL SELECT 'planes', COUNT(*) FROM planes
UNION ALL SELECT 'fechas', COUNT(*) FROM fechas
UNION ALL SELECT 'inscripciones', COUNT(*) FROM inscripciones
UNION ALL SELECT 'partidos', COUNT(*) FROM partidos
UNION ALL SELECT 'goles', COUNT(*) FROM goles
UNION ALL SELECT 'pagos', COUNT(*) FROM pagos
ORDER BY tabla;
