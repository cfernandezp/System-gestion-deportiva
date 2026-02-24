-- ============================================
-- FIX: Agregar plan_nombre a obtener_mis_grupos
-- Fecha: 2026-02-21
-- Descripcion: Modifica la RPC obtener_mis_grupos para incluir
--              el nombre del plan del grupo (join con tabla planes)
-- Dependencia: E002-HU-002 (obtener_mis_grupos), E000-HU-002 (tabla planes)
-- ============================================

CREATE OR REPLACE FUNCTION obtener_mis_grupos()
RETURNS JSON AS $$
DECLARE
    v_auth_uid UUID;
    v_usuario_id UUID;
    v_grupos JSON;
BEGIN
    -- Verificar autenticacion
    v_auth_uid := auth.uid();
    IF v_auth_uid IS NULL THEN
        RETURN json_build_object(
            'success', FALSE,
            'error', json_build_object(
                'message', 'No autenticado',
                'hint', 'no_autenticado'
            )
        );
    END IF;

    -- Obtener usuario_id
    SELECT id INTO v_usuario_id
    FROM usuarios
    WHERE auth_user_id = v_auth_uid;

    IF v_usuario_id IS NULL THEN
        RETURN json_build_object(
            'success', FALSE,
            'error', json_build_object(
                'message', 'Usuario no encontrado',
                'hint', 'usuario_no_encontrado'
            )
        );
    END IF;

    -- RN-001: Solo grupos donde es miembro activo
    -- RN-002: Logo, nombre, rol, cantidad miembros, plan_nombre
    -- RN-003: Ordenados por ultimo_acceso DESC (NULL al final)
    SELECT COALESCE(json_agg(grupo_data ORDER BY orden_acceso), '[]'::json)
    INTO v_grupos
    FROM (
        SELECT
            g.id AS grupo_id,
            g.nombre,
            g.logo_url,
            g.lema,
            g.tipo_deporte,
            g.activo,
            mg.rol::TEXT AS mi_rol,
            mg.ultimo_acceso,
            -- Nombre del plan del grupo (join con planes)
            COALESCE(p.nombre, 'Gratis') AS plan_nombre,
            -- Contar miembros activos del grupo
            (
                SELECT COUNT(*)
                FROM miembros_grupo m2
                WHERE m2.grupo_id = g.id
                AND m2.activo = TRUE
            ) AS cantidad_miembros,
            -- RN-003: NULL ultimo_acceso va al final
            CASE
                WHEN mg.ultimo_acceso IS NULL THEN 1
                ELSE 0
            END AS orden_acceso,
            COALESCE(mg.ultimo_acceso, mg.created_at) AS fecha_orden
        FROM miembros_grupo mg
        JOIN grupos g ON g.id = mg.grupo_id
        LEFT JOIN planes p ON p.id = g.plan_id
        WHERE mg.usuario_id = v_usuario_id
        AND mg.activo = TRUE
        AND g.activo = TRUE
        ORDER BY orden_acceso ASC, COALESCE(mg.ultimo_acceso, mg.created_at) DESC
    ) AS grupo_data;

    RETURN json_build_object(
        'success', TRUE,
        'data', v_grupos
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION obtener_mis_grupos TO authenticated;
