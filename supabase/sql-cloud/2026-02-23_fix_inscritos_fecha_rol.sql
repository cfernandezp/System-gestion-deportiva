-- ============================================================
-- FIX: obtener_inscritos_fecha - Agregar campo rol_grupo
-- Fecha: 2026-02-23
-- Descripcion: Agrega el campo 'rol_grupo' al JSON de cada inscrito.
--              El rol se obtiene desde miembros_grupo buscando el grupo
--              via el creador (created_by) de la fecha.
--
-- ADVERTENCIA: Esta funcion NO existe en los archivos locales.
--              Solo existe en la BD Cloud. Este script hace
--              CREATE OR REPLACE, por lo que reemplaza la
--              definicion actual en Cloud.
--
-- INSTRUCCIONES:
-- 1. Primero ejecuta en el SQL Editor de Cloud la siguiente
--    query para ver la definicion actual de la funcion:
--
--      SELECT pg_get_functiondef(oid)
--      FROM pg_proc
--      WHERE proname = 'obtener_inscritos_fecha';
--
-- 2. Si el resultado muestra una estructura diferente a la que
--    se reconstruye aqui (por ejemplo, campos adicionales en el
--    JSON de cada inscrito), integra manualmente el campo
--    'rol_grupo' en esa version y ejecuta tu version combinada.
--
-- 3. Si la estructura coincide con la reconstruida aqui, ejecuta
--    directamente este script.
-- ============================================================


-- ============================================================
-- RECONSTRUCCION DE LA FUNCION
-- Basada en el patron de funciones similares del proyecto
-- (obtener_asignaciones, listar_jugadores_disponibles_inscripcion)
-- y el schema de las tablas: inscripciones, usuarios,
-- asignaciones_equipos, pagos, miembros_grupo, fechas.
--
-- CAMBIO APLICADO:
-- Se agrega LEFT JOIN con miembros_grupo (alias mg) buscando
-- el grupo via el creador (created_by) de la fecha.
-- Se incluye 'rol_grupo' en el json_build_object de cada inscrito.
-- ============================================================

CREATE OR REPLACE FUNCTION obtener_inscritos_fecha(p_fecha_id UUID)
RETURNS JSON AS $$
DECLARE
    v_auth_uid UUID;
    v_usuario_id UUID;
    v_rol_usuario TEXT;
    v_estado_usuario TEXT;
    v_error_hint TEXT;
    v_fecha RECORD;
    v_inscritos JSON;
    v_total INT;
    v_grupo_id UUID;
BEGIN
    -- ========================================
    -- 1. Validar autenticacion
    -- ========================================
    v_auth_uid := auth.uid();

    IF v_auth_uid IS NULL THEN
        v_error_hint := 'no_autenticado';
        RAISE EXCEPTION 'Usuario no autenticado';
    END IF;

    -- ========================================
    -- 2. Obtener datos del usuario autenticado
    -- ========================================
    SELECT id, rol::TEXT, estado::TEXT
    INTO v_usuario_id, v_rol_usuario, v_estado_usuario
    FROM usuarios
    WHERE auth_user_id = v_auth_uid;

    IF v_usuario_id IS NULL THEN
        v_error_hint := 'usuario_no_encontrado';
        RAISE EXCEPTION 'Usuario no encontrado en el sistema';
    END IF;

    IF v_estado_usuario != 'aprobado' THEN
        v_error_hint := 'usuario_no_aprobado';
        RAISE EXCEPTION 'Usuario no tiene estado aprobado';
    END IF;

    -- ========================================
    -- 3. Obtener datos de la fecha
    -- ========================================
    SELECT
        f.id,
        f.estado,
        f.created_by,
        f.costo_por_jugador,
        f.limite_jugadores,
        f.num_equipos,
        TO_CHAR(f.fecha_hora_inicio, 'YYYY-MM-DD"T"HH24:MI:SS') AS fecha_hora_inicio,
        TO_CHAR(f.fecha_hora_inicio, 'DD/MM/YYYY') AS fecha_formato,
        TO_CHAR(f.fecha_hora_inicio, 'HH24:MI') AS hora_formato
    INTO v_fecha
    FROM fechas f
    WHERE f.id = p_fecha_id;

    IF NOT FOUND THEN
        v_error_hint := 'fecha_no_encontrada';
        RAISE EXCEPTION 'Fecha no encontrada';
    END IF;

    -- ========================================
    -- 4. Resolver grupo_id de la fecha
    --    Busca el grupo via el creador (created_by)
    --    buscando su membresia activa como admin/coadmin
    -- ========================================
    SELECT mg2.grupo_id
    INTO v_grupo_id
    FROM miembros_grupo mg2
    WHERE mg2.usuario_id = v_fecha.created_by
      AND mg2.rol IN ('admin', 'coadmin')
      AND mg2.activo = true
    LIMIT 1;

    -- ========================================
    -- 5. Obtener lista de inscritos
    --    CAMBIO: LEFT JOIN con miembros_grupo para obtener rol_grupo
    -- ========================================
    SELECT
        json_agg(
            json_build_object(
                'inscripcion_id',    i.id,
                'usuario_id',        u.id,
                'nombre_completo',   u.nombre_completo,
                'apodo',             u.apodo,
                'nombre_display',    COALESCE(u.apodo, u.nombre_completo),
                'foto_url',          u.foto_url,
                'posicion_preferida', u.posicion_preferida::TEXT,
                'estado_inscripcion', i.estado::TEXT,
                'inscripcion_tardia', COALESCE(i.inscripcion_tardia, false),
                'inscrito_por',      i.inscrito_por,
                'created_at',        i.created_at,
                'equipo_asignado',   ae.color_equipo::TEXT,
                'numero_equipo',     ae.numero_equipo,
                'estado_pago',       p.estado::TEXT,
                'monto_pago',        p.monto,
                -- CAMPO NUEVO: rol del inscrito en el grupo de la fecha
                'rol_grupo',         COALESCE(mg.rol::TEXT, 'jugador')
            )
            ORDER BY u.nombre_completo ASC
        ),
        COUNT(*)
    INTO v_inscritos, v_total
    FROM inscripciones i
    JOIN usuarios u ON u.id = i.usuario_id
    LEFT JOIN asignaciones_equipos ae
           ON ae.fecha_id = i.fecha_id
          AND ae.usuario_id = i.usuario_id
    LEFT JOIN pagos p
           ON p.inscripcion_id = i.id
    -- JOIN para obtener el rol en el grupo de la fecha
    LEFT JOIN miembros_grupo mg
           ON mg.usuario_id = i.usuario_id
          AND mg.grupo_id = v_grupo_id
          AND mg.activo = true
    WHERE i.fecha_id = p_fecha_id
      AND i.estado IN ('inscrito', 'ausente');

    -- ========================================
    -- 6. Manejar caso sin resultados
    -- ========================================
    IF v_total IS NULL OR v_total = 0 THEN
        v_total := 0;
        v_inscritos := '[]'::JSON;
    END IF;

    -- ========================================
    -- 7. Retornar respuesta exitosa
    -- ========================================
    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'fecha_id',        p_fecha_id,
            'estado_fecha',    v_fecha.estado::TEXT,
            'inscritos',       COALESCE(v_inscritos, '[]'::JSON),
            'total',           v_total,
            'costo_por_jugador', v_fecha.costo_por_jugador,
            'limite_jugadores',  v_fecha.limite_jugadores
        ),
        'message', v_total || ' inscrito' || CASE WHEN v_total != 1 THEN 's' ELSE '' END || ' encontrado' || CASE WHEN v_total != 1 THEN 's' ELSE '' END
    );

EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', json_build_object(
                'code', SQLSTATE,
                'message', SQLERRM,
                'hint', COALESCE(v_error_hint, 'unknown')
            )
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Permisos
GRANT EXECUTE ON FUNCTION obtener_inscritos_fecha(UUID) TO anon, authenticated, service_role;

-- Comentario
COMMENT ON FUNCTION obtener_inscritos_fecha IS
    'FIX 2026-02-23: Agrega campo rol_grupo al JSON de cada inscrito. El rol se resuelve via LEFT JOIN con miembros_grupo usando el grupo del creador de la fecha.';
