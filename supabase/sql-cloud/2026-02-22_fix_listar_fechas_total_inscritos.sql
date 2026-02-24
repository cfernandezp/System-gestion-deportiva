-- ============================================
-- FIX: listar_fechas_por_rol - total_inscritos
-- Fecha: 2026-02-22
-- Descripcion: Corrige el calculo de total_inscritos que retornaba "1"
--              en vez del conteo real de inscripciones activas.
--              Se recrea la funcion completa basada en la especificacion
--              E003-HU-009 ya que el SQL original no esta versionado.
--
-- Bug: total_inscritos mostraba "1" en lugar de "12" (el conteo real).
-- Causa probable: EXISTS o subquery sin COUNT, o COUNT mal correlacionado.
-- Fix: Se usa un subquery correlacionado con COUNT(*) filtrando
--       inscripciones.estado = 'inscrito' para cada fecha.
-- ============================================

CREATE OR REPLACE FUNCTION listar_fechas_por_rol(
    p_seccion TEXT DEFAULT 'proximas',
    p_filtro_estado TEXT DEFAULT NULL,
    p_fecha_desde TEXT DEFAULT NULL,
    p_fecha_hasta TEXT DEFAULT NULL
) RETURNS JSON AS $$
DECLARE
    v_auth_uid UUID;
    v_usuario_id UUID;
    v_rol TEXT;
    v_estado_usuario TEXT;
    v_error_hint TEXT;
    v_fechas JSON;
    v_total INT;
    v_es_admin BOOLEAN;
    v_mensaje TEXT;
    v_orden TEXT;
    v_fecha_desde_parsed TIMESTAMPTZ;
    v_fecha_hasta_parsed TIMESTAMPTZ;
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
    -- 2. Obtener datos del usuario
    -- ========================================
    SELECT id, rol::TEXT, estado::TEXT
    INTO v_usuario_id, v_rol, v_estado_usuario
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

    v_es_admin := (v_rol = 'admin');

    -- ========================================
    -- 3. Validar seccion segun rol
    -- ========================================
    -- Secciones permitidas para admin: proximas, en_curso, historial, todas
    -- Secciones permitidas para jugador: proximas, inscrito, historial
    IF v_es_admin THEN
        IF p_seccion NOT IN ('proximas', 'en_curso', 'historial', 'todas') THEN
            v_error_hint := 'seccion_invalida';
            RAISE EXCEPTION 'Seccion invalida para admin: %', p_seccion;
        END IF;
    ELSE
        IF p_seccion NOT IN ('proximas', 'inscrito', 'historial') THEN
            IF p_seccion IN ('en_curso', 'todas') THEN
                v_error_hint := 'seccion_no_permitida';
                RAISE EXCEPTION 'Seccion "%" solo disponible para administradores', p_seccion;
            ELSE
                v_error_hint := 'seccion_invalida';
                RAISE EXCEPTION 'Seccion invalida: %', p_seccion;
            END IF;
        END IF;
    END IF;

    -- ========================================
    -- 4. Parsear fechas de filtro (solo admin)
    -- ========================================
    IF p_fecha_desde IS NOT NULL THEN
        BEGIN
            v_fecha_desde_parsed := p_fecha_desde::TIMESTAMPTZ;
        EXCEPTION WHEN OTHERS THEN
            v_fecha_desde_parsed := (p_fecha_desde || ' 00:00:00')::TIMESTAMPTZ;
        END;
    END IF;

    IF p_fecha_hasta IS NOT NULL THEN
        BEGIN
            v_fecha_hasta_parsed := p_fecha_hasta::TIMESTAMPTZ;
        EXCEPTION WHEN OTHERS THEN
            -- Si es solo fecha, agregar fin del dia
            v_fecha_hasta_parsed := (p_fecha_hasta || ' 23:59:59')::TIMESTAMPTZ;
        END;
    END IF;

    -- ========================================
    -- 5. Construir query segun seccion y rol
    -- ========================================

    -- ----------------------------------------
    -- SECCION: proximas (admin y jugador)
    -- Fechas abiertas con fecha futura
    -- RN-001: estado = 'abierta' AND fecha_hora_inicio > NOW()
    -- Orden: fecha_hora_inicio ASC (mas cercana primero)
    -- ----------------------------------------
    IF p_seccion = 'proximas' THEN
        SELECT json_agg(fecha_row ORDER BY fecha_row_sort ASC), COUNT(*)
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
                    'costo_formato', 'S/ ' || TO_CHAR(f.costo_por_jugador, 'FM999,999,990.00'),
                    'estado', f.estado::TEXT,
                    'total_inscritos', (
                        SELECT COUNT(*)
                        FROM inscripciones i
                        WHERE i.fecha_id = f.id
                          AND i.estado = 'inscrito'
                    ),
                    'usuario_inscrito', EXISTS(
                        SELECT 1 FROM inscripciones i
                        WHERE i.fecha_id = f.id
                          AND i.usuario_id = v_usuario_id
                          AND i.estado = 'inscrito'
                    ),
                    'equipo_asignado', (
                        SELECT ae.color_equipo::TEXT FROM asignaciones_equipos ae
                        WHERE ae.fecha_id = f.id AND ae.usuario_id = v_usuario_id
                        LIMIT 1
                    ),
                    'numero_equipo', (
                        SELECT ae.numero_equipo FROM asignaciones_equipos ae
                        WHERE ae.fecha_id = f.id AND ae.usuario_id = v_usuario_id
                        LIMIT 1
                    ),
                    'puede_inscribirse', (
                        f.estado::TEXT = 'abierta'
                        AND f.fecha_hora_inicio > NOW()
                        AND NOT EXISTS(
                            SELECT 1 FROM inscripciones i
                            WHERE i.fecha_id = f.id
                              AND i.usuario_id = v_usuario_id
                              AND i.estado = 'inscrito'
                        )
                    ),
                    'puede_cancelar', (
                        f.estado::TEXT = 'abierta'
                        AND EXISTS(
                            SELECT 1 FROM inscripciones i
                            WHERE i.fecha_id = f.id
                              AND i.usuario_id = v_usuario_id
                              AND i.estado = 'inscrito'
                        )
                    ),
                    'indicador', json_build_object(
                        'tipo', 'abierta',
                        'texto', 'Inscripciones Abiertas',
                        'color', '#4CAF50',
                        'icono', 'group'
                    )
                ) AS fecha_row,
                f.fecha_hora_inicio AS fecha_row_sort
            FROM fechas f
            WHERE f.estado = 'abierta'
              AND f.fecha_hora_inicio > NOW()
        ) sub;

    -- ----------------------------------------
    -- SECCION: inscrito (solo jugador)
    -- Fechas cerradas/en_juego donde el jugador tiene inscripcion activa
    -- RN-002: estado IN ('cerrada', 'en_juego') con inscripcion activa
    -- Orden: fecha_hora_inicio ASC
    -- ----------------------------------------
    ELSIF p_seccion = 'inscrito' THEN
        SELECT json_agg(fecha_row ORDER BY fecha_row_sort ASC), COUNT(*)
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
                    'costo_formato', 'S/ ' || TO_CHAR(f.costo_por_jugador, 'FM999,999,990.00'),
                    'estado', f.estado::TEXT,
                    'total_inscritos', (
                        SELECT COUNT(*)
                        FROM inscripciones i
                        WHERE i.fecha_id = f.id
                          AND i.estado = 'inscrito'
                    ),
                    'usuario_inscrito', true,
                    'equipo_asignado', (
                        SELECT ae.color_equipo::TEXT FROM asignaciones_equipos ae
                        WHERE ae.fecha_id = f.id AND ae.usuario_id = v_usuario_id
                        LIMIT 1
                    ),
                    'numero_equipo', (
                        SELECT ae.numero_equipo FROM asignaciones_equipos ae
                        WHERE ae.fecha_id = f.id AND ae.usuario_id = v_usuario_id
                        LIMIT 1
                    ),
                    'puede_inscribirse', false,
                    'puede_cancelar', (f.estado::TEXT = 'cerrada'),
                    'indicador', CASE f.estado::TEXT
                        WHEN 'cerrada' THEN json_build_object(
                            'tipo', 'cerrada',
                            'texto', 'Inscripciones Cerradas',
                            'color', '#FFC107',
                            'icono', 'lock'
                        )
                        WHEN 'en_juego' THEN json_build_object(
                            'tipo', 'en_juego',
                            'texto', 'En Juego',
                            'color', '#2196F3',
                            'icono', 'sports_soccer'
                        )
                        ELSE json_build_object(
                            'tipo', f.estado::TEXT,
                            'texto', f.estado::TEXT,
                            'color', '#9E9E9E',
                            'icono', 'info'
                        )
                    END
                ) AS fecha_row,
                f.fecha_hora_inicio AS fecha_row_sort
            FROM fechas f
            WHERE f.estado IN ('cerrada', 'en_juego')
              AND EXISTS(
                  SELECT 1 FROM inscripciones i
                  WHERE i.fecha_id = f.id
                    AND i.usuario_id = v_usuario_id
                    AND i.estado = 'inscrito'
              )
        ) sub;

    -- ----------------------------------------
    -- SECCION: en_curso (solo admin)
    -- Fechas cerradas/en_juego (todas, sin filtro de inscripcion)
    -- Orden: fecha_hora_inicio ASC
    -- ----------------------------------------
    ELSIF p_seccion = 'en_curso' THEN
        SELECT json_agg(fecha_row ORDER BY fecha_row_sort ASC), COUNT(*)
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
                    'costo_formato', 'S/ ' || TO_CHAR(f.costo_por_jugador, 'FM999,999,990.00'),
                    'estado', f.estado::TEXT,
                    'total_inscritos', (
                        SELECT COUNT(*)
                        FROM inscripciones i
                        WHERE i.fecha_id = f.id
                          AND i.estado = 'inscrito'
                    ),
                    'usuario_inscrito', EXISTS(
                        SELECT 1 FROM inscripciones i
                        WHERE i.fecha_id = f.id
                          AND i.usuario_id = v_usuario_id
                          AND i.estado = 'inscrito'
                    ),
                    'equipo_asignado', (
                        SELECT ae.color_equipo::TEXT FROM asignaciones_equipos ae
                        WHERE ae.fecha_id = f.id AND ae.usuario_id = v_usuario_id
                        LIMIT 1
                    ),
                    'numero_equipo', (
                        SELECT ae.numero_equipo FROM asignaciones_equipos ae
                        WHERE ae.fecha_id = f.id AND ae.usuario_id = v_usuario_id
                        LIMIT 1
                    ),
                    'puede_inscribirse', false,
                    'puede_cancelar', false,
                    'indicador', CASE f.estado::TEXT
                        WHEN 'cerrada' THEN json_build_object(
                            'tipo', 'cerrada',
                            'texto', 'Inscripciones Cerradas',
                            'color', '#FFC107',
                            'icono', 'lock'
                        )
                        WHEN 'en_juego' THEN json_build_object(
                            'tipo', 'en_juego',
                            'texto', 'En Juego',
                            'color', '#2196F3',
                            'icono', 'sports_soccer'
                        )
                        ELSE json_build_object(
                            'tipo', f.estado::TEXT,
                            'texto', f.estado::TEXT,
                            'color', '#9E9E9E',
                            'icono', 'info'
                        )
                    END
                ) AS fecha_row,
                f.fecha_hora_inicio AS fecha_row_sort
            FROM fechas f
            WHERE f.estado IN ('cerrada', 'en_juego')
        ) sub;

    -- ----------------------------------------
    -- SECCION: historial
    -- Admin: todas las fechas finalizadas
    -- Jugador: solo fechas finalizadas donde participo (inscripcion activa)
    -- RN-003: Jugador con inscripcion estado = 'inscrito' en fecha finalizada
    -- RN-006: Jugador NO ve fechas finalizadas donde no participo
    -- Orden: fecha_hora_inicio DESC (mas reciente primero)
    -- ----------------------------------------
    ELSIF p_seccion = 'historial' THEN
        SELECT json_agg(fecha_row ORDER BY fecha_row_sort DESC), COUNT(*)
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
                    'costo_formato', 'S/ ' || TO_CHAR(f.costo_por_jugador, 'FM999,999,990.00'),
                    'estado', f.estado::TEXT,
                    'total_inscritos', (
                        SELECT COUNT(*)
                        FROM inscripciones i
                        WHERE i.fecha_id = f.id
                          AND i.estado = 'inscrito'
                    ),
                    'usuario_inscrito', EXISTS(
                        SELECT 1 FROM inscripciones i
                        WHERE i.fecha_id = f.id
                          AND i.usuario_id = v_usuario_id
                          AND i.estado = 'inscrito'
                    ),
                    'equipo_asignado', (
                        SELECT ae.color_equipo::TEXT FROM asignaciones_equipos ae
                        WHERE ae.fecha_id = f.id AND ae.usuario_id = v_usuario_id
                        LIMIT 1
                    ),
                    'numero_equipo', (
                        SELECT ae.numero_equipo FROM asignaciones_equipos ae
                        WHERE ae.fecha_id = f.id AND ae.usuario_id = v_usuario_id
                        LIMIT 1
                    ),
                    'puede_inscribirse', false,
                    'puede_cancelar', false,
                    'indicador', json_build_object(
                        'tipo', 'finalizada',
                        'texto', 'Finalizada',
                        'color', '#9E9E9E',
                        'icono', 'check_circle'
                    )
                ) AS fecha_row,
                f.fecha_hora_inicio AS fecha_row_sort
            FROM fechas f
            WHERE f.estado = 'finalizada'
              -- RN-003/RN-006: Jugador solo ve fechas donde participo
              AND (
                  v_es_admin = true
                  OR EXISTS(
                      SELECT 1 FROM inscripciones i
                      WHERE i.fecha_id = f.id
                        AND i.usuario_id = v_usuario_id
                        AND i.estado = 'inscrito'
                  )
              )
        ) sub;

    -- ----------------------------------------
    -- SECCION: todas (solo admin)
    -- Todas las fechas con filtros opcionales
    -- RN-004: Admin ve todas sin restriccion
    -- RN-005: Filtros exclusivos de admin
    -- Orden: fecha_hora_inicio DESC
    -- ----------------------------------------
    ELSIF p_seccion = 'todas' THEN
        SELECT json_agg(fecha_row ORDER BY fecha_row_sort DESC), COUNT(*)
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
                    'costo_formato', 'S/ ' || TO_CHAR(f.costo_por_jugador, 'FM999,999,990.00'),
                    'estado', f.estado::TEXT,
                    'total_inscritos', (
                        SELECT COUNT(*)
                        FROM inscripciones i
                        WHERE i.fecha_id = f.id
                          AND i.estado = 'inscrito'
                    ),
                    'usuario_inscrito', EXISTS(
                        SELECT 1 FROM inscripciones i
                        WHERE i.fecha_id = f.id
                          AND i.usuario_id = v_usuario_id
                          AND i.estado = 'inscrito'
                    ),
                    'equipo_asignado', (
                        SELECT ae.color_equipo::TEXT FROM asignaciones_equipos ae
                        WHERE ae.fecha_id = f.id AND ae.usuario_id = v_usuario_id
                        LIMIT 1
                    ),
                    'numero_equipo', (
                        SELECT ae.numero_equipo FROM asignaciones_equipos ae
                        WHERE ae.fecha_id = f.id AND ae.usuario_id = v_usuario_id
                        LIMIT 1
                    ),
                    'puede_inscribirse', (
                        f.estado::TEXT = 'abierta'
                        AND f.fecha_hora_inicio > NOW()
                        AND NOT EXISTS(
                            SELECT 1 FROM inscripciones i
                            WHERE i.fecha_id = f.id
                              AND i.usuario_id = v_usuario_id
                              AND i.estado = 'inscrito'
                        )
                    ),
                    'puede_cancelar', (
                        f.estado::TEXT IN ('abierta', 'cerrada')
                        AND EXISTS(
                            SELECT 1 FROM inscripciones i
                            WHERE i.fecha_id = f.id
                              AND i.usuario_id = v_usuario_id
                              AND i.estado = 'inscrito'
                        )
                    ),
                    'indicador', CASE f.estado::TEXT
                        WHEN 'abierta' THEN json_build_object(
                            'tipo', 'abierta',
                            'texto', 'Inscripciones Abiertas',
                            'color', '#4CAF50',
                            'icono', 'group'
                        )
                        WHEN 'cerrada' THEN json_build_object(
                            'tipo', 'cerrada',
                            'texto', 'Inscripciones Cerradas',
                            'color', '#FFC107',
                            'icono', 'lock'
                        )
                        WHEN 'en_juego' THEN json_build_object(
                            'tipo', 'en_juego',
                            'texto', 'En Juego',
                            'color', '#2196F3',
                            'icono', 'sports_soccer'
                        )
                        WHEN 'finalizada' THEN json_build_object(
                            'tipo', 'finalizada',
                            'texto', 'Finalizada',
                            'color', '#9E9E9E',
                            'icono', 'check_circle'
                        )
                        WHEN 'cancelada' THEN json_build_object(
                            'tipo', 'cancelada',
                            'texto', 'Cancelada',
                            'color', '#F44336',
                            'icono', 'cancel'
                        )
                        ELSE json_build_object(
                            'tipo', f.estado::TEXT,
                            'texto', f.estado::TEXT,
                            'color', '#9E9E9E',
                            'icono', 'info'
                        )
                    END
                ) AS fecha_row,
                f.fecha_hora_inicio AS fecha_row_sort
            FROM fechas f
            WHERE
                -- Filtro por estado (opcional, solo admin)
                (p_filtro_estado IS NULL OR f.estado::TEXT = p_filtro_estado)
                -- Filtro por fecha desde (opcional)
                AND (v_fecha_desde_parsed IS NULL OR f.fecha_hora_inicio >= v_fecha_desde_parsed)
                -- Filtro por fecha hasta (opcional)
                AND (v_fecha_hasta_parsed IS NULL OR f.fecha_hora_inicio <= v_fecha_hasta_parsed)
        ) sub;

    END IF;

    -- ========================================
    -- 6. Manejar caso sin resultados
    -- ========================================
    IF v_total IS NULL OR v_total = 0 THEN
        v_total := 0;
        v_fechas := '[]'::JSON;

        -- CA-010: Mensajes contextuales segun seccion
        CASE p_seccion
            WHEN 'proximas' THEN v_mensaje := 'No hay pichangas programadas';
            WHEN 'inscrito' THEN v_mensaje := 'No tienes inscripciones activas';
            WHEN 'historial' THEN v_mensaje := 'Aun no has participado en pichangas';
            WHEN 'en_curso' THEN v_mensaje := 'No hay pichangas en curso';
            WHEN 'todas' THEN v_mensaje := 'No se encontraron fechas con los filtros aplicados';
            ELSE v_mensaje := 'No hay fechas disponibles';
        END CASE;
    ELSE
        v_mensaje := v_total || ' fecha' || CASE WHEN v_total > 1 THEN 's' ELSE '' END || ' encontrada' || CASE WHEN v_total > 1 THEN 's' ELSE '' END;
    END IF;

    -- ========================================
    -- 7. Retornar respuesta exitosa
    -- ========================================
    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'fechas', v_fechas,
            'seccion', p_seccion,
            'total', v_total,
            'es_admin', v_es_admin,
            'filtros_aplicados', CASE
                WHEN p_seccion = 'todas' AND v_es_admin THEN
                    json_build_object(
                        'estado', p_filtro_estado,
                        'fecha_desde', p_fecha_desde,
                        'fecha_hasta', p_fecha_hasta
                    )
                ELSE NULL
            END
        ),
        'message', v_mensaje
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
GRANT EXECUTE ON FUNCTION listar_fechas_por_rol TO anon, authenticated, service_role;

-- Comentario
COMMENT ON FUNCTION listar_fechas_por_rol IS 'E003-HU-009: Lista fechas con visibilidad por rol. FIX 2026-02-22: Corregido total_inscritos para contar inscripciones activas correctamente.';
