-- ============================================
-- E003-HU-009: Listado de Fechas con Visibilidad por Rol
-- Fecha: 2026-01-29
-- Descripcion: Funcion RPC que lista fechas de pichanga
--              con diferentes vistas segun rol (jugador/admin)
--              y seccion solicitada (proximas, inscrito, historial, etc.)
-- ============================================

-- ============================================
-- FUNCION: listar_fechas_por_rol
-- ============================================
-- Parametros:
--   p_seccion: 'proximas', 'inscrito', 'historial', 'todas', 'en_curso'
--   p_filtro_estado: Solo admin - filtro por estado de fecha
--   p_fecha_desde: Solo admin - filtro fecha inicio
--   p_fecha_hasta: Solo admin - filtro fecha fin
--
-- Logica por rol:
--   JUGADOR:
--     - proximas: estado='abierta' AND fecha > NOW()
--     - inscrito: estado IN ('cerrada', 'en_juego') con inscripcion activa
--     - historial: estado='finalizada' con inscripcion activa
--   ADMIN:
--     - proximas: estado='abierta' AND fecha > NOW()
--     - en_curso: estado IN ('cerrada', 'en_juego')
--     - historial: estado='finalizada'
--     - todas: todas las fechas con filtros opcionales
-- ============================================

CREATE OR REPLACE FUNCTION listar_fechas_por_rol(
    p_seccion TEXT DEFAULT 'proximas',
    p_filtro_estado TEXT DEFAULT NULL,
    p_fecha_desde DATE DEFAULT NULL,
    p_fecha_hasta DATE DEFAULT NULL
) RETURNS JSON AS $$
DECLARE
    v_error_hint TEXT;
    v_current_user_id UUID;
    v_current_user RECORD;
    v_es_admin BOOLEAN;
    v_fechas JSON;
    v_total INTEGER;
    v_seccion_valida TEXT;
    v_filtros_aplicados JSON;
BEGIN
    -- ========================================
    -- Validacion: Usuario autenticado
    -- ========================================
    v_current_user_id := auth.uid();

    IF v_current_user_id IS NULL THEN
        v_error_hint := 'no_autenticado';
        RAISE EXCEPTION 'Debes iniciar sesion para realizar esta accion';
    END IF;

    -- ========================================
    -- Obtener usuario actual
    -- ========================================
    SELECT id, rol, estado, nombre_completo
    INTO v_current_user
    FROM usuarios
    WHERE auth_user_id = v_current_user_id;

    IF NOT FOUND THEN
        v_error_hint := 'usuario_no_encontrado';
        RAISE EXCEPTION 'Usuario no encontrado en el sistema';
    END IF;

    -- ========================================
    -- Validar usuario aprobado
    -- ========================================
    IF v_current_user.estado != 'aprobado' THEN
        v_error_hint := 'usuario_no_aprobado';
        RAISE EXCEPTION 'Tu cuenta debe estar aprobada para ver las fechas de pichanga';
    END IF;

    -- ========================================
    -- Determinar si es admin
    -- ========================================
    v_es_admin := v_current_user.rol = 'admin';

    -- ========================================
    -- Validar seccion segun rol
    -- ========================================
    v_seccion_valida := LOWER(TRIM(COALESCE(p_seccion, 'proximas')));

    -- Secciones validas para jugador
    IF NOT v_es_admin AND v_seccion_valida NOT IN ('proximas', 'inscrito', 'historial') THEN
        v_error_hint := 'seccion_no_permitida';
        RAISE EXCEPTION 'Seccion no permitida para jugadores. Secciones validas: proximas, inscrito, historial';
    END IF;

    -- Secciones validas para admin
    IF v_es_admin AND v_seccion_valida NOT IN ('proximas', 'en_curso', 'historial', 'todas') THEN
        v_error_hint := 'seccion_invalida';
        RAISE EXCEPTION 'Seccion invalida. Secciones validas para admin: proximas, en_curso, historial, todas';
    END IF;

    -- ========================================
    -- Construir filtros aplicados (solo admin)
    -- ========================================
    IF v_es_admin AND (p_filtro_estado IS NOT NULL OR p_fecha_desde IS NOT NULL OR p_fecha_hasta IS NOT NULL) THEN
        v_filtros_aplicados := json_build_object(
            'estado', p_filtro_estado,
            'fecha_desde', p_fecha_desde,
            'fecha_hasta', p_fecha_hasta
        );
    ELSE
        v_filtros_aplicados := NULL;
    END IF;

    -- ========================================
    -- CONSULTA PRINCIPAL SEGUN SECCION Y ROL
    -- ========================================

    -- -----------------------------------------
    -- SECCION: PROXIMAS (JUGADOR Y ADMIN)
    -- Estado: abierta, fecha > NOW()
    -- -----------------------------------------
    IF v_seccion_valida = 'proximas' THEN
        SELECT json_agg(fecha_data ORDER BY fecha_hora_inicio ASC), COUNT(*)
        INTO v_fechas, v_total
        FROM (
            SELECT
                json_build_object(
                    'id', f.id,
                    'fecha_hora_inicio', f.fecha_hora_inicio,
                    'fecha_formato', TO_CHAR(f.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY'),
                    'hora_formato', TO_CHAR(f.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'HH24:MI'),
                    'lugar', f.lugar,
                    'duracion_horas', f.duracion_horas,
                    'num_equipos', f.num_equipos,
                    'costo_por_jugador', f.costo_por_jugador,
                    'costo_formato', 'S/ ' || TO_CHAR(f.costo_por_jugador, 'FM990.00'),
                    'estado', f.estado,
                    'total_inscritos', (
                        SELECT COUNT(*) FROM inscripciones i
                        WHERE i.fecha_id = f.id AND i.estado = 'inscrito'
                    ),
                    'usuario_inscrito', EXISTS (
                        SELECT 1 FROM inscripciones i
                        WHERE i.fecha_id = f.id
                        AND i.usuario_id = v_current_user.id
                        AND i.estado = 'inscrito'
                    ),
                    'equipo_asignado', NULL,
                    'numero_equipo', NULL,
                    'puede_inscribirse', NOT EXISTS (
                        SELECT 1 FROM inscripciones i
                        WHERE i.fecha_id = f.id
                        AND i.usuario_id = v_current_user.id
                        AND i.estado = 'inscrito'
                    ),
                    'puede_cancelar', EXISTS (
                        SELECT 1 FROM inscripciones i
                        WHERE i.fecha_id = f.id
                        AND i.usuario_id = v_current_user.id
                        AND i.estado = 'inscrito'
                    ),
                    'indicador', json_build_object(
                        'color', '#4CAF50',
                        'icono', 'group',
                        'texto', 'Inscripciones Abiertas'
                    )
                ) as fecha_data,
                f.fecha_hora_inicio
            FROM fechas f
            WHERE f.estado = 'abierta'
            AND f.fecha_hora_inicio > NOW()
        ) subquery;

    -- -----------------------------------------
    -- SECCION: INSCRITO (SOLO JUGADOR)
    -- Estado: cerrada o en_juego, con inscripcion activa
    -- -----------------------------------------
    ELSIF v_seccion_valida = 'inscrito' AND NOT v_es_admin THEN
        SELECT json_agg(fecha_data ORDER BY fecha_hora_inicio ASC), COUNT(*)
        INTO v_fechas, v_total
        FROM (
            SELECT
                json_build_object(
                    'id', f.id,
                    'fecha_hora_inicio', f.fecha_hora_inicio,
                    'fecha_formato', TO_CHAR(f.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY'),
                    'hora_formato', TO_CHAR(f.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'HH24:MI'),
                    'lugar', f.lugar,
                    'duracion_horas', f.duracion_horas,
                    'num_equipos', f.num_equipos,
                    'costo_por_jugador', f.costo_por_jugador,
                    'costo_formato', 'S/ ' || TO_CHAR(f.costo_por_jugador, 'FM990.00'),
                    'estado', f.estado,
                    'total_inscritos', (
                        SELECT COUNT(*) FROM inscripciones i2
                        WHERE i2.fecha_id = f.id AND i2.estado = 'inscrito'
                    ),
                    'usuario_inscrito', true,
                    'equipo_asignado', ae.color_equipo,
                    'numero_equipo', ae.numero_equipo,
                    'puede_inscribirse', false,
                    'puede_cancelar', f.estado = 'cerrada',
                    'indicador', CASE f.estado
                        WHEN 'cerrada' THEN json_build_object(
                            'color', '#FFC107',
                            'icono', 'lock',
                            'texto', 'Inscripciones Cerradas'
                        )
                        WHEN 'en_juego' THEN json_build_object(
                            'color', '#2196F3',
                            'icono', 'sports_soccer',
                            'texto', 'En Juego'
                        )
                    END
                ) as fecha_data,
                f.fecha_hora_inicio
            FROM fechas f
            INNER JOIN inscripciones i ON i.fecha_id = f.id
                AND i.usuario_id = v_current_user.id
                AND i.estado = 'inscrito'
            LEFT JOIN asignaciones_equipos ae ON ae.fecha_id = f.id
                AND ae.usuario_id = v_current_user.id
            WHERE f.estado IN ('cerrada', 'en_juego')
        ) subquery;

    -- -----------------------------------------
    -- SECCION: EN_CURSO (SOLO ADMIN)
    -- Estado: cerrada o en_juego
    -- -----------------------------------------
    ELSIF v_seccion_valida = 'en_curso' AND v_es_admin THEN
        SELECT json_agg(fecha_data ORDER BY fecha_hora_inicio ASC), COUNT(*)
        INTO v_fechas, v_total
        FROM (
            SELECT
                json_build_object(
                    'id', f.id,
                    'fecha_hora_inicio', f.fecha_hora_inicio,
                    'fecha_formato', TO_CHAR(f.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY'),
                    'hora_formato', TO_CHAR(f.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'HH24:MI'),
                    'lugar', f.lugar,
                    'duracion_horas', f.duracion_horas,
                    'num_equipos', f.num_equipos,
                    'costo_por_jugador', f.costo_por_jugador,
                    'costo_formato', 'S/ ' || TO_CHAR(f.costo_por_jugador, 'FM990.00'),
                    'estado', f.estado,
                    'total_inscritos', (
                        SELECT COUNT(*) FROM inscripciones i
                        WHERE i.fecha_id = f.id AND i.estado = 'inscrito'
                    ),
                    'usuario_inscrito', EXISTS (
                        SELECT 1 FROM inscripciones i
                        WHERE i.fecha_id = f.id
                        AND i.usuario_id = v_current_user.id
                        AND i.estado = 'inscrito'
                    ),
                    'equipo_asignado', (
                        SELECT ae.color_equipo FROM asignaciones_equipos ae
                        WHERE ae.fecha_id = f.id AND ae.usuario_id = v_current_user.id
                    ),
                    'numero_equipo', (
                        SELECT ae.numero_equipo FROM asignaciones_equipos ae
                        WHERE ae.fecha_id = f.id AND ae.usuario_id = v_current_user.id
                    ),
                    'puede_inscribirse', false,
                    'puede_cancelar', false,
                    'indicador', CASE f.estado
                        WHEN 'cerrada' THEN json_build_object(
                            'color', '#FFC107',
                            'icono', 'lock',
                            'texto', 'Inscripciones Cerradas'
                        )
                        WHEN 'en_juego' THEN json_build_object(
                            'color', '#2196F3',
                            'icono', 'sports_soccer',
                            'texto', 'En Juego'
                        )
                    END
                ) as fecha_data,
                f.fecha_hora_inicio
            FROM fechas f
            WHERE f.estado IN ('cerrada', 'en_juego')
        ) subquery;

    -- -----------------------------------------
    -- SECCION: HISTORIAL (JUGADOR Y ADMIN)
    -- Jugador: estado='finalizada' con inscripcion activa
    -- Admin: estado='finalizada'
    -- -----------------------------------------
    ELSIF v_seccion_valida = 'historial' THEN
        IF v_es_admin THEN
            -- Admin ve todo el historial
            SELECT json_agg(fecha_data ORDER BY fecha_hora_inicio DESC), COUNT(*)
            INTO v_fechas, v_total
            FROM (
                SELECT
                    json_build_object(
                        'id', f.id,
                        'fecha_hora_inicio', f.fecha_hora_inicio,
                        'fecha_formato', TO_CHAR(f.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY'),
                        'hora_formato', TO_CHAR(f.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'HH24:MI'),
                        'lugar', f.lugar,
                        'duracion_horas', f.duracion_horas,
                        'num_equipos', f.num_equipos,
                        'costo_por_jugador', f.costo_por_jugador,
                        'costo_formato', 'S/ ' || TO_CHAR(f.costo_por_jugador, 'FM990.00'),
                        'estado', f.estado,
                        'total_inscritos', (
                            SELECT COUNT(*) FROM inscripciones i
                            WHERE i.fecha_id = f.id AND i.estado = 'inscrito'
                        ),
                        'usuario_inscrito', EXISTS (
                            SELECT 1 FROM inscripciones i
                            WHERE i.fecha_id = f.id
                            AND i.usuario_id = v_current_user.id
                            AND i.estado = 'inscrito'
                        ),
                        'equipo_asignado', (
                            SELECT ae.color_equipo FROM asignaciones_equipos ae
                            WHERE ae.fecha_id = f.id AND ae.usuario_id = v_current_user.id
                        ),
                        'numero_equipo', (
                            SELECT ae.numero_equipo FROM asignaciones_equipos ae
                            WHERE ae.fecha_id = f.id AND ae.usuario_id = v_current_user.id
                        ),
                        'puede_inscribirse', false,
                        'puede_cancelar', false,
                        'indicador', json_build_object(
                            'color', '#9E9E9E',
                            'icono', 'check_circle',
                            'texto', 'Finalizada'
                        )
                    ) as fecha_data,
                    f.fecha_hora_inicio
                FROM fechas f
                WHERE f.estado = 'finalizada'
            ) subquery;
        ELSE
            -- Jugador solo ve historial donde participo
            SELECT json_agg(fecha_data ORDER BY fecha_hora_inicio DESC), COUNT(*)
            INTO v_fechas, v_total
            FROM (
                SELECT
                    json_build_object(
                        'id', f.id,
                        'fecha_hora_inicio', f.fecha_hora_inicio,
                        'fecha_formato', TO_CHAR(f.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY'),
                        'hora_formato', TO_CHAR(f.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'HH24:MI'),
                        'lugar', f.lugar,
                        'duracion_horas', f.duracion_horas,
                        'num_equipos', f.num_equipos,
                        'costo_por_jugador', f.costo_por_jugador,
                        'costo_formato', 'S/ ' || TO_CHAR(f.costo_por_jugador, 'FM990.00'),
                        'estado', f.estado,
                        'total_inscritos', (
                            SELECT COUNT(*) FROM inscripciones i2
                            WHERE i2.fecha_id = f.id AND i2.estado = 'inscrito'
                        ),
                        'usuario_inscrito', true,
                        'equipo_asignado', ae.color_equipo,
                        'numero_equipo', ae.numero_equipo,
                        'puede_inscribirse', false,
                        'puede_cancelar', false,
                        'indicador', json_build_object(
                            'color', '#9E9E9E',
                            'icono', 'check_circle',
                            'texto', 'Finalizada'
                        )
                    ) as fecha_data,
                    f.fecha_hora_inicio
                FROM fechas f
                INNER JOIN inscripciones i ON i.fecha_id = f.id
                    AND i.usuario_id = v_current_user.id
                    AND i.estado = 'inscrito'
                LEFT JOIN asignaciones_equipos ae ON ae.fecha_id = f.id
                    AND ae.usuario_id = v_current_user.id
                WHERE f.estado = 'finalizada'
            ) subquery;
        END IF;

    -- -----------------------------------------
    -- SECCION: TODAS (SOLO ADMIN)
    -- Todas las fechas con filtros opcionales
    -- -----------------------------------------
    ELSIF v_seccion_valida = 'todas' AND v_es_admin THEN
        SELECT json_agg(fecha_data ORDER BY fecha_hora_inicio DESC), COUNT(*)
        INTO v_fechas, v_total
        FROM (
            SELECT
                json_build_object(
                    'id', f.id,
                    'fecha_hora_inicio', f.fecha_hora_inicio,
                    'fecha_formato', TO_CHAR(f.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY'),
                    'hora_formato', TO_CHAR(f.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'HH24:MI'),
                    'lugar', f.lugar,
                    'duracion_horas', f.duracion_horas,
                    'num_equipos', f.num_equipos,
                    'costo_por_jugador', f.costo_por_jugador,
                    'costo_formato', 'S/ ' || TO_CHAR(f.costo_por_jugador, 'FM990.00'),
                    'estado', f.estado,
                    'total_inscritos', (
                        SELECT COUNT(*) FROM inscripciones i
                        WHERE i.fecha_id = f.id AND i.estado = 'inscrito'
                    ),
                    'usuario_inscrito', EXISTS (
                        SELECT 1 FROM inscripciones i
                        WHERE i.fecha_id = f.id
                        AND i.usuario_id = v_current_user.id
                        AND i.estado = 'inscrito'
                    ),
                    'equipo_asignado', (
                        SELECT ae.color_equipo FROM asignaciones_equipos ae
                        WHERE ae.fecha_id = f.id AND ae.usuario_id = v_current_user.id
                    ),
                    'numero_equipo', (
                        SELECT ae.numero_equipo FROM asignaciones_equipos ae
                        WHERE ae.fecha_id = f.id AND ae.usuario_id = v_current_user.id
                    ),
                    'puede_inscribirse', f.estado = 'abierta' AND f.fecha_hora_inicio > NOW() AND NOT EXISTS (
                        SELECT 1 FROM inscripciones i
                        WHERE i.fecha_id = f.id
                        AND i.usuario_id = v_current_user.id
                        AND i.estado = 'inscrito'
                    ),
                    'puede_cancelar', f.estado = 'abierta' AND EXISTS (
                        SELECT 1 FROM inscripciones i
                        WHERE i.fecha_id = f.id
                        AND i.usuario_id = v_current_user.id
                        AND i.estado = 'inscrito'
                    ),
                    'indicador', CASE f.estado
                        WHEN 'abierta' THEN json_build_object(
                            'color', '#4CAF50',
                            'icono', 'group',
                            'texto', 'Inscripciones Abiertas'
                        )
                        WHEN 'cerrada' THEN json_build_object(
                            'color', '#FFC107',
                            'icono', 'lock',
                            'texto', 'Inscripciones Cerradas'
                        )
                        WHEN 'en_juego' THEN json_build_object(
                            'color', '#2196F3',
                            'icono', 'sports_soccer',
                            'texto', 'En Juego'
                        )
                        WHEN 'finalizada' THEN json_build_object(
                            'color', '#9E9E9E',
                            'icono', 'check_circle',
                            'texto', 'Finalizada'
                        )
                        WHEN 'cancelada' THEN json_build_object(
                            'color', '#F44336',
                            'icono', 'cancel',
                            'texto', 'Cancelada'
                        )
                    END
                ) as fecha_data,
                f.fecha_hora_inicio
            FROM fechas f
            WHERE
                -- Filtro por estado (solo si se especifica)
                (p_filtro_estado IS NULL OR f.estado::TEXT = p_filtro_estado)
                -- Filtro por fecha desde (solo si se especifica)
                AND (p_fecha_desde IS NULL OR (f.fecha_hora_inicio AT TIME ZONE 'America/Lima')::DATE >= p_fecha_desde)
                -- Filtro por fecha hasta (solo si se especifica)
                AND (p_fecha_hasta IS NULL OR (f.fecha_hora_inicio AT TIME ZONE 'America/Lima')::DATE <= p_fecha_hasta)
        ) subquery;

    ELSE
        v_error_hint := 'seccion_invalida';
        RAISE EXCEPTION 'Seccion no reconocida: %', v_seccion_valida;
    END IF;

    -- ========================================
    -- Manejar caso de lista vacia
    -- ========================================
    IF v_total IS NULL THEN
        v_total := 0;
    END IF;

    -- ========================================
    -- Retorno exitoso
    -- ========================================
    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'fechas', COALESCE(v_fechas, '[]'::json),
            'seccion', v_seccion_valida,
            'total', v_total,
            'es_admin', v_es_admin,
            'filtros_aplicados', v_filtros_aplicados
        ),
        'message', CASE
            WHEN v_total = 0 THEN 'No se encontraron fechas para esta seccion'
            WHEN v_total = 1 THEN '1 fecha encontrada'
            ELSE v_total || ' fechas encontradas'
        END
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
-- PERMISOS
-- ============================================
GRANT EXECUTE ON FUNCTION listar_fechas_por_rol TO authenticated, service_role;

-- ============================================
-- COMENTARIO DE DOCUMENTACION
-- ============================================
COMMENT ON FUNCTION listar_fechas_por_rol IS 'E003-HU-009: Lista fechas de pichanga con visibilidad diferenciada por rol (jugador/admin) y seccion (proximas, inscrito, historial, en_curso, todas)';

-- ============================================
-- FIN DEL SCRIPT
-- ============================================
