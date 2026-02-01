-- ============================================
-- FIX: Mostrar nombre completo en equipos
-- Fecha: 2026-02-01
-- Problema: SPLIT_PART solo tomaba primera palabra
--           "Jugador 01" -> "Jugador" (mal)
-- Solucion: Usar nombre_completo completo
-- ============================================

-- ACTUALIZAR FUNCION obtener_equipos_fecha
CREATE OR REPLACE FUNCTION obtener_equipos_fecha(
    p_fecha_id UUID
) RETURNS JSON AS $$
DECLARE
    v_error_hint TEXT;
    v_current_user_id UUID;
    v_current_user RECORD;
    v_fecha RECORD;
    v_inscripcion RECORD;
    v_mi_equipo_numero INTEGER;
    v_mi_color_equipo TEXT;
    v_equipos JSON;
    v_equipos_asignados BOOLEAN;
BEGIN
    v_current_user_id := auth.uid();

    IF v_current_user_id IS NULL THEN
        v_error_hint := 'no_autenticado';
        RAISE EXCEPTION 'Debes iniciar sesion para realizar esta accion';
    END IF;

    IF p_fecha_id IS NULL THEN
        v_error_hint := 'fecha_id_requerido';
        RAISE EXCEPTION 'El ID de la fecha es obligatorio';
    END IF;

    SELECT id, rol, estado, nombre_completo
    INTO v_current_user
    FROM usuarios
    WHERE auth_user_id = v_current_user_id;

    IF NOT FOUND THEN
        v_error_hint := 'usuario_no_encontrado';
        RAISE EXCEPTION 'Usuario no encontrado en el sistema';
    END IF;

    SELECT id, fecha_hora_inicio, lugar, num_equipos, estado
    INTO v_fecha
    FROM fechas
    WHERE id = p_fecha_id;

    IF NOT FOUND THEN
        v_error_hint := 'fecha_no_encontrada';
        RAISE EXCEPTION 'Fecha de pichanga no encontrada';
    END IF;

    v_equipos_asignados := EXISTS (
        SELECT 1 FROM asignaciones_equipos
        WHERE fecha_id = p_fecha_id
    );

    IF NOT v_equipos_asignados THEN
        RETURN json_build_object(
            'success', true,
            'data', json_build_object(
                'equipos_asignados', false,
                'equipos', '[]'::json,
                'total_equipos', 0,
                'mensaje', 'Aun no se han asignado equipos para esta fecha'
            ),
            'message', 'No hay equipos asignados'
        );
    END IF;

    SELECT ae.numero_equipo, ae.color_equipo::text
    INTO v_mi_equipo_numero, v_mi_color_equipo
    FROM inscripciones i
    LEFT JOIN asignaciones_equipos ae ON ae.fecha_id = i.fecha_id AND ae.usuario_id = i.usuario_id
    WHERE i.fecha_id = p_fecha_id
    AND i.usuario_id = v_current_user.id
    AND i.estado = 'inscrito';

    SELECT json_agg(equipo_data ORDER BY es_mi_equipo DESC, numero_equipo ASC)
    INTO v_equipos
    FROM (
        SELECT
            json_build_object(
                'numero_equipo', ae.numero_equipo,
                'color_equipo', ae.color_equipo::text,
                'nombre_equipo', 'Equipo ' || INITCAP(ae.color_equipo::text),
                'color_hex', CASE ae.color_equipo::text
                    WHEN 'naranja' THEN '#FF9800'
                    WHEN 'verde' THEN '#4CAF50'
                    WHEN 'azul' THEN '#2196F3'
                    WHEN 'rojo' THEN '#F44336'
                    WHEN 'amarillo' THEN '#FFEB3B'
                    WHEN 'blanco' THEN '#FFFFFF'
                    ELSE '#9E9E9E'
                END,
                'es_mi_equipo', (ae.numero_equipo = v_mi_equipo_numero AND ae.color_equipo::text = v_mi_color_equipo),
                'jugadores', (
                    SELECT json_agg(
                        json_build_object(
                            'usuario_id', u.id,
                            -- FIX: Usar nombre_completo en lugar de SPLIT_PART
                            'nombre', COALESCE(u.apodo, u.nombre_completo),
                            'nombre_completo', u.nombre_completo,
                            'foto_url', u.foto_url,
                            'es_tu', u.id = v_current_user.id
                        ) ORDER BY
                            CASE WHEN u.id = v_current_user.id THEN 0 ELSE 1 END,
                            u.nombre_completo
                    )
                    FROM asignaciones_equipos ae2
                    JOIN usuarios u ON u.id = ae2.usuario_id
                    WHERE ae2.fecha_id = p_fecha_id
                    AND ae2.numero_equipo = ae.numero_equipo
                    AND ae2.color_equipo = ae.color_equipo
                ),
                'total_jugadores', (
                    SELECT COUNT(*)
                    FROM asignaciones_equipos ae2
                    WHERE ae2.fecha_id = p_fecha_id
                    AND ae2.numero_equipo = ae.numero_equipo
                    AND ae2.color_equipo = ae.color_equipo
                )
            ) as equipo_data,
            ae.numero_equipo,
            (ae.numero_equipo = v_mi_equipo_numero AND ae.color_equipo::text = v_mi_color_equipo) as es_mi_equipo
        FROM asignaciones_equipos ae
        WHERE ae.fecha_id = p_fecha_id
        GROUP BY ae.numero_equipo, ae.color_equipo
    ) subquery;

    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'equipos_asignados', true,
            'equipos', COALESCE(v_equipos, '[]'::json),
            'total_equipos', COALESCE(json_array_length(v_equipos), 0),
            'mi_equipo_numero', v_mi_equipo_numero,
            'mi_color_equipo', v_mi_color_equipo,
            'esta_inscrito', v_mi_equipo_numero IS NOT NULL OR EXISTS (
                SELECT 1 FROM inscripciones
                WHERE fecha_id = p_fecha_id
                AND usuario_id = v_current_user.id
                AND estado = 'inscrito'
            ),
            'fecha', json_build_object(
                'id', v_fecha.id,
                'fecha_hora_inicio', v_fecha.fecha_hora_inicio AT TIME ZONE 'America/Lima',
                'fecha_formato', TO_CHAR(v_fecha.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY'),
                'hora_formato', TO_CHAR(v_fecha.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'HH24:MI'),
                'lugar', v_fecha.lugar,
                'num_equipos', v_fecha.num_equipos,
                'estado', v_fecha.estado::text
            )
        ),
        'message', 'Equipos obtenidos exitosamente'
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

-- ============================================
-- TAMBIEN CORREGIR obtener_mi_equipo
-- ============================================
CREATE OR REPLACE FUNCTION obtener_mi_equipo(
    p_fecha_id UUID
) RETURNS JSON AS $$
DECLARE
    v_error_hint TEXT;
    v_current_user_id UUID;
    v_current_user RECORD;
    v_inscripcion RECORD;
    v_asignacion RECORD;
    v_companeros JSON;
    v_equipos_asignados BOOLEAN;
BEGIN
    v_current_user_id := auth.uid();

    IF v_current_user_id IS NULL THEN
        v_error_hint := 'no_autenticado';
        RAISE EXCEPTION 'Debes iniciar sesion para realizar esta accion';
    END IF;

    IF p_fecha_id IS NULL THEN
        v_error_hint := 'fecha_id_requerido';
        RAISE EXCEPTION 'El ID de la fecha es obligatorio';
    END IF;

    SELECT id, rol, estado, nombre_completo, apodo, foto_url
    INTO v_current_user
    FROM usuarios
    WHERE auth_user_id = v_current_user_id;

    IF NOT FOUND THEN
        v_error_hint := 'usuario_no_encontrado';
        RAISE EXCEPTION 'Usuario no encontrado en el sistema';
    END IF;

    SELECT i.id, i.fecha_id, i.usuario_id, i.estado
    INTO v_inscripcion
    FROM inscripciones i
    WHERE i.fecha_id = p_fecha_id
    AND i.usuario_id = v_current_user.id
    AND i.estado = 'inscrito';

    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', true,
            'data', json_build_object(
                'esta_inscrito', false,
                'tiene_equipo', false,
                'equipos_asignados', false,
                'mensaje', 'No estas inscrito en esta fecha'
            ),
            'message', 'Usuario no inscrito'
        );
    END IF;

    v_equipos_asignados := EXISTS (
        SELECT 1 FROM asignaciones_equipos
        WHERE fecha_id = p_fecha_id
    );

    IF NOT v_equipos_asignados THEN
        RETURN json_build_object(
            'success', true,
            'data', json_build_object(
                'esta_inscrito', true,
                'tiene_equipo', false,
                'equipos_asignados', false,
                'mensaje', 'Los equipos aun no han sido asignados'
            ),
            'message', 'Equipos pendientes'
        );
    END IF;

    SELECT ae.id, ae.numero_equipo, ae.color_equipo::text, ae.asignado_at
    INTO v_asignacion
    FROM asignaciones_equipos ae
    WHERE ae.fecha_id = p_fecha_id
    AND ae.usuario_id = v_current_user.id;

    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', true,
            'data', json_build_object(
                'esta_inscrito', true,
                'tiene_equipo', false,
                'equipos_asignados', true,
                'mensaje', 'Aun no te han asignado un equipo'
            ),
            'message', 'Sin equipo asignado'
        );
    END IF;

    SELECT json_agg(
        json_build_object(
            'usuario_id', u.id,
            -- FIX: Usar nombre_completo en lugar de SPLIT_PART
            'nombre', COALESCE(u.apodo, u.nombre_completo),
            'nombre_completo', u.nombre_completo,
            'foto_url', u.foto_url,
            'es_tu', u.id = v_current_user.id
        ) ORDER BY
            CASE WHEN u.id = v_current_user.id THEN 0 ELSE 1 END,
            u.nombre_completo
    )
    INTO v_companeros
    FROM asignaciones_equipos ae
    JOIN usuarios u ON u.id = ae.usuario_id
    WHERE ae.fecha_id = p_fecha_id
    AND ae.numero_equipo = v_asignacion.numero_equipo
    AND ae.color_equipo::text = v_asignacion.color_equipo;

    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'esta_inscrito', true,
            'tiene_equipo', true,
            'equipos_asignados', true,
            'mi_equipo', json_build_object(
                'color_equipo', v_asignacion.color_equipo,
                'numero_equipo', v_asignacion.numero_equipo,
                'nombre_equipo', 'Equipo ' || INITCAP(v_asignacion.color_equipo),
                'color_hex', CASE v_asignacion.color_equipo
                    WHEN 'naranja' THEN '#FF9800'
                    WHEN 'verde' THEN '#4CAF50'
                    WHEN 'azul' THEN '#2196F3'
                    WHEN 'rojo' THEN '#F44336'
                    WHEN 'amarillo' THEN '#FFEB3B'
                    WHEN 'blanco' THEN '#FFFFFF'
                    ELSE '#9E9E9E'
                END,
                'asignado_at', v_asignacion.asignado_at AT TIME ZONE 'America/Lima',
                'asignado_at_formato', TO_CHAR(v_asignacion.asignado_at AT TIME ZONE 'America/Lima', 'DD/MM/YYYY HH24:MI')
            ),
            'companeros', COALESCE(v_companeros, '[]'::json),
            'total_companeros', COALESCE(json_array_length(v_companeros), 0)
        ),
        'message', 'Equipo obtenido exitosamente'
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

-- ============================================
-- FIN DEL FIX
-- ============================================
