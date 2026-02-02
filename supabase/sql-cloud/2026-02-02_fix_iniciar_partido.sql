-- ============================================
-- FIX: Corregir funciones de partidos
-- Fecha: 2026-02-02
-- Error: column 'equipo' does not exist
-- Causa: Las funciones usan 'equipo' pero la columna real es 'color_equipo'
-- Solucion: Actualizar todas las referencias a usar 'color_equipo'
-- ============================================
--
-- Ejecutar en: https://supabase.com/dashboard/project/tvvubzkqbksxvcjvivij/sql
--
-- Schema real de asignaciones_equipos:
--   - id (uuid)
--   - fecha_id (uuid)
--   - usuario_id (uuid)
--   - color_equipo (color_equipo ENUM) <-- Esta es la columna correcta
--   - numero_equipo (integer)
--   - created_at, updated_at, asignado_por, asignado_at
-- ============================================

-- ============================================
-- 1. FUNCION: iniciar_partido
-- ============================================
CREATE OR REPLACE FUNCTION iniciar_partido(
    p_fecha_id UUID,
    p_equipo_local TEXT,
    p_equipo_visitante TEXT
) RETURNS JSON AS $$
DECLARE
    v_user_id UUID;
    v_usuario RECORD;
    v_fecha RECORD;
    v_partido_id UUID;
    v_duracion_minutos INTEGER;
    v_hora_inicio TIMESTAMPTZ;
    v_hora_fin_estimada TIMESTAMPTZ;
    v_equipo_local_info JSON;
    v_equipo_visitante_info JSON;
    v_jugadores_local INTEGER;
    v_jugadores_visitante INTEGER;
    v_error_hint TEXT;
BEGIN
    -- RN-001: Validar autenticacion
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        v_error_hint := 'no_autenticado';
        RAISE EXCEPTION 'Usuario no autenticado';
    END IF;

    -- RN-001: Validar que es admin aprobado
    SELECT * INTO v_usuario
    FROM usuarios
    WHERE auth_user_id = v_user_id;

    IF NOT FOUND OR v_usuario.rol != 'admin' OR v_usuario.estado != 'aprobado' THEN
        v_error_hint := 'sin_permisos';
        RAISE EXCEPTION 'Solo administradores aprobados pueden iniciar partidos';
    END IF;

    -- RN-002: Validar que la fecha existe y esta en_juego
    SELECT * INTO v_fecha
    FROM fechas
    WHERE id = p_fecha_id;

    IF NOT FOUND THEN
        v_error_hint := 'fecha_no_encontrada';
        RAISE EXCEPTION 'Fecha no encontrada: %', p_fecha_id;
    END IF;

    IF v_fecha.estado != 'en_juego' THEN
        v_error_hint := 'fecha_no_en_juego';
        RAISE EXCEPTION 'La fecha debe estar en estado en_juego. Estado actual: %', v_fecha.estado;
    END IF;

    -- RN-005: Validar que no hay otro partido activo
    IF EXISTS (
        SELECT 1 FROM partidos
        WHERE fecha_id = p_fecha_id
        AND estado IN ('en_curso', 'pausado')
    ) THEN
        v_error_hint := 'partido_activo_existe';
        RAISE EXCEPTION 'Ya existe un partido activo en esta fecha';
    END IF;

    -- RN-006: Validar que los equipos son diferentes
    IF LOWER(p_equipo_local) = LOWER(p_equipo_visitante) THEN
        v_error_hint := 'equipos_iguales';
        RAISE EXCEPTION 'Los equipos deben ser diferentes';
    END IF;

    -- RN-003: Validar que el equipo local tiene jugadores
    -- CORREGIDO: Usar color_equipo en lugar de equipo
    SELECT COUNT(*) INTO v_jugadores_local
    FROM asignaciones_equipos
    WHERE fecha_id = p_fecha_id
    AND color_equipo::text = LOWER(p_equipo_local);

    IF v_jugadores_local = 0 THEN
        v_error_hint := 'equipo_local_sin_jugadores';
        RAISE EXCEPTION 'El equipo % no tiene jugadores asignados', p_equipo_local;
    END IF;

    -- RN-003: Validar que el equipo visitante tiene jugadores
    -- CORREGIDO: Usar color_equipo en lugar de equipo
    SELECT COUNT(*) INTO v_jugadores_visitante
    FROM asignaciones_equipos
    WHERE fecha_id = p_fecha_id
    AND color_equipo::text = LOWER(p_equipo_visitante);

    IF v_jugadores_visitante = 0 THEN
        v_error_hint := 'equipo_visitante_sin_jugadores';
        RAISE EXCEPTION 'El equipo % no tiene jugadores asignados', p_equipo_visitante;
    END IF;

    -- RN-004: Calcular duracion segun num_equipos
    IF v_fecha.num_equipos = 2 THEN
        v_duracion_minutos := 20;
    ELSE
        v_duracion_minutos := 10;
    END IF;

    -- Calcular tiempos
    v_hora_inicio := NOW();
    v_hora_fin_estimada := v_hora_inicio + (v_duracion_minutos || ' minutes')::INTERVAL;

    -- Crear el partido
    INSERT INTO partidos (
        fecha_id,
        equipo_local,
        equipo_visitante,
        duracion_minutos,
        estado,
        hora_inicio,
        hora_fin_estimada,
        tiempo_pausado_segundos,
        created_by
    ) VALUES (
        p_fecha_id,
        LOWER(p_equipo_local)::color_equipo,
        LOWER(p_equipo_visitante)::color_equipo,
        v_duracion_minutos,
        'en_curso',
        v_hora_inicio,
        v_hora_fin_estimada,
        0,
        v_usuario.id
    )
    RETURNING id INTO v_partido_id;

    -- Construir info del equipo local
    -- CORREGIDO: Usar color_equipo en lugar de equipo
    SELECT json_build_object(
        'color', LOWER(p_equipo_local),
        'jugadores_count', v_jugadores_local,
        'jugadores', COALESCE(
            (SELECT json_agg(json_build_object(
                'id', u.id,
                'nombre_completo', u.nombre_completo
            ))
            FROM asignaciones_equipos ae
            JOIN usuarios u ON u.id = ae.usuario_id
            WHERE ae.fecha_id = p_fecha_id
            AND ae.color_equipo::text = LOWER(p_equipo_local)),
            '[]'::json
        )
    ) INTO v_equipo_local_info;

    -- Construir info del equipo visitante
    -- CORREGIDO: Usar color_equipo en lugar de equipo
    SELECT json_build_object(
        'color', LOWER(p_equipo_visitante),
        'jugadores_count', v_jugadores_visitante,
        'jugadores', COALESCE(
            (SELECT json_agg(json_build_object(
                'id', u.id,
                'nombre_completo', u.nombre_completo
            ))
            FROM asignaciones_equipos ae
            JOIN usuarios u ON u.id = ae.usuario_id
            WHERE ae.fecha_id = p_fecha_id
            AND ae.color_equipo::text = LOWER(p_equipo_visitante)),
            '[]'::json
        )
    ) INTO v_equipo_visitante_info;

    -- Retornar resultado exitoso
    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'partido_id', v_partido_id,
            'fecha_id', p_fecha_id,
            'equipo_local', v_equipo_local_info,
            'equipo_visitante', v_equipo_visitante_info,
            'duracion_minutos', v_duracion_minutos,
            'estado', 'en_curso',
            'hora_inicio_formato', TO_CHAR(v_hora_inicio AT TIME ZONE 'America/Lima', 'HH24:MI:SS'),
            'hora_fin_estimada_formato', TO_CHAR(v_hora_fin_estimada AT TIME ZONE 'America/Lima', 'HH24:MI:SS'),
            'tiempo_restante_segundos', v_duracion_minutos * 60
        ),
        'message', 'Partido iniciado: ' || UPPER(p_equipo_local) || ' vs ' || UPPER(p_equipo_visitante) || ' - ' || v_duracion_minutos || ' minutos'
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
GRANT EXECUTE ON FUNCTION iniciar_partido(UUID, TEXT, TEXT) TO anon, authenticated, service_role;
COMMENT ON FUNCTION iniciar_partido IS 'E004-HU-001: Inicia un partido entre dos equipos. Corregido para usar color_equipo.';


-- ============================================
-- 2. FUNCION: obtener_partido_activo
-- ============================================
CREATE OR REPLACE FUNCTION obtener_partido_activo(
    p_fecha_id UUID
) RETURNS JSON AS $$
DECLARE
    v_partido RECORD;
    v_tiempo_restante_segundos INTEGER;
    v_tiempo_transcurrido_segundos INTEGER;
    v_equipo_local_info JSON;
    v_equipo_visitante_info JSON;
    v_fecha RECORD;
BEGIN
    -- Obtener info de la fecha
    SELECT * INTO v_fecha
    FROM fechas
    WHERE id = p_fecha_id;

    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false,
            'error', json_build_object(
                'code', 'NOT_FOUND',
                'message', 'Fecha no encontrada',
                'hint', 'fecha_no_encontrada'
            )
        );
    END IF;

    -- Buscar partido activo (en_curso o pausado)
    SELECT * INTO v_partido
    FROM partidos
    WHERE fecha_id = p_fecha_id
    AND estado IN ('en_curso', 'pausado')
    ORDER BY created_at DESC
    LIMIT 1;

    -- Si no hay partido activo
    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', true,
            'data', json_build_object(
                'partido_activo', false,
                'partido', null,
                'fecha', json_build_object(
                    'id', v_fecha.id,
                    'estado', v_fecha.estado::text,
                    'num_equipos', v_fecha.num_equipos
                ),
                'puede_iniciar_partido', v_fecha.estado = 'en_juego'
            ),
            'message', 'No hay partido activo en esta fecha'
        );
    END IF;

    -- Calcular tiempo restante
    IF v_partido.estado = 'en_curso' THEN
        -- Tiempo transcurrido desde inicio menos pausas
        v_tiempo_transcurrido_segundos := EXTRACT(EPOCH FROM (NOW() - v_partido.hora_inicio))::INTEGER - v_partido.tiempo_pausado_segundos;
        v_tiempo_restante_segundos := (v_partido.duracion_minutos * 60) - v_tiempo_transcurrido_segundos;
        IF v_tiempo_restante_segundos < 0 THEN
            v_tiempo_restante_segundos := 0;
        END IF;
    ELSIF v_partido.estado = 'pausado' AND v_partido.pausado_at IS NOT NULL THEN
        -- Tiempo hasta que se pauso
        v_tiempo_transcurrido_segundos := EXTRACT(EPOCH FROM (v_partido.pausado_at - v_partido.hora_inicio))::INTEGER - v_partido.tiempo_pausado_segundos;
        v_tiempo_restante_segundos := (v_partido.duracion_minutos * 60) - v_tiempo_transcurrido_segundos;
        IF v_tiempo_restante_segundos < 0 THEN
            v_tiempo_restante_segundos := 0;
        END IF;
    ELSE
        v_tiempo_restante_segundos := v_partido.duracion_minutos * 60;
    END IF;

    -- Construir info equipo local
    -- CORREGIDO: Usar color_equipo en lugar de equipo
    SELECT json_build_object(
        'color', v_partido.equipo_local::text,
        'jugadores', COALESCE(
            (SELECT json_agg(json_build_object(
                'id', u.id,
                'nombre_completo', u.nombre_completo
            ))
            FROM asignaciones_equipos ae
            JOIN usuarios u ON u.id = ae.usuario_id
            WHERE ae.fecha_id = p_fecha_id
            AND ae.color_equipo = v_partido.equipo_local),
            '[]'::json
        )
    ) INTO v_equipo_local_info;

    -- Construir info equipo visitante
    -- CORREGIDO: Usar color_equipo en lugar de equipo
    SELECT json_build_object(
        'color', v_partido.equipo_visitante::text,
        'jugadores', COALESCE(
            (SELECT json_agg(json_build_object(
                'id', u.id,
                'nombre_completo', u.nombre_completo
            ))
            FROM asignaciones_equipos ae
            JOIN usuarios u ON u.id = ae.usuario_id
            WHERE ae.fecha_id = p_fecha_id
            AND ae.color_equipo = v_partido.equipo_visitante),
            '[]'::json
        )
    ) INTO v_equipo_visitante_info;

    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'partido_activo', true,
            'partido', json_build_object(
                'id', v_partido.id,
                'equipo_local', v_equipo_local_info,
                'equipo_visitante', v_equipo_visitante_info,
                'goles_local', v_partido.goles_local,
                'goles_visitante', v_partido.goles_visitante,
                'duracion_minutos', v_partido.duracion_minutos,
                'estado', v_partido.estado::text,
                'tiempo_restante_segundos', v_tiempo_restante_segundos,
                'tiempo_restante_formato', LPAD((v_tiempo_restante_segundos / 60)::TEXT, 2, '0') || ':' || LPAD((v_tiempo_restante_segundos % 60)::TEXT, 2, '0'),
                'tiempo_transcurrido_formato', LPAD((v_tiempo_transcurrido_segundos / 60)::TEXT, 2, '0') || ':' || LPAD((v_tiempo_transcurrido_segundos % 60)::TEXT, 2, '0'),
                'tiempo_terminado', v_tiempo_restante_segundos <= 0
            ),
            'puede_pausar', v_partido.estado = 'en_curso',
            'puede_reanudar', v_partido.estado = 'pausado'
        ),
        'message', 'Partido ' || CASE WHEN v_partido.estado = 'en_curso' THEN 'en curso' ELSE 'pausado' END || ': ' || UPPER(v_partido.equipo_local::text) || ' vs ' || UPPER(v_partido.equipo_visitante::text)
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Permisos
GRANT EXECUTE ON FUNCTION obtener_partido_activo(UUID) TO anon, authenticated, service_role;
COMMENT ON FUNCTION obtener_partido_activo IS 'E004-HU-001: Obtiene el partido activo de una fecha. Corregido para usar color_equipo.';


-- ============================================
-- 3. FUNCION: pausar_partido
-- ============================================
CREATE OR REPLACE FUNCTION pausar_partido(
    p_partido_id UUID
) RETURNS JSON AS $$
DECLARE
    v_user_id UUID;
    v_usuario RECORD;
    v_partido RECORD;
    v_tiempo_restante_segundos INTEGER;
    v_tiempo_transcurrido_segundos INTEGER;
    v_error_hint TEXT;
BEGIN
    -- Validar autenticacion
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        v_error_hint := 'no_autenticado';
        RAISE EXCEPTION 'Usuario no autenticado';
    END IF;

    -- Validar que es admin aprobado
    SELECT * INTO v_usuario
    FROM usuarios
    WHERE auth_user_id = v_user_id;

    IF NOT FOUND OR v_usuario.rol != 'admin' OR v_usuario.estado != 'aprobado' THEN
        v_error_hint := 'sin_permisos';
        RAISE EXCEPTION 'Solo administradores aprobados pueden pausar partidos';
    END IF;

    -- Obtener el partido
    SELECT * INTO v_partido
    FROM partidos
    WHERE id = p_partido_id;

    IF NOT FOUND THEN
        v_error_hint := 'partido_no_encontrado';
        RAISE EXCEPTION 'Partido no encontrado: %', p_partido_id;
    END IF;

    IF v_partido.estado != 'en_curso' THEN
        v_error_hint := 'partido_no_en_curso';
        RAISE EXCEPTION 'El partido no esta en curso. Estado actual: %', v_partido.estado;
    END IF;

    -- Calcular tiempo restante antes de pausar
    v_tiempo_transcurrido_segundos := EXTRACT(EPOCH FROM (NOW() - v_partido.hora_inicio))::INTEGER - v_partido.tiempo_pausado_segundos;
    v_tiempo_restante_segundos := (v_partido.duracion_minutos * 60) - v_tiempo_transcurrido_segundos;
    IF v_tiempo_restante_segundos < 0 THEN
        v_tiempo_restante_segundos := 0;
    END IF;

    -- Pausar el partido
    UPDATE partidos
    SET estado = 'pausado',
        pausado_at = NOW(),
        updated_at = NOW()
    WHERE id = p_partido_id;

    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'partido_id', v_partido.id,
            'estado', 'pausado',
            'pausado_at_formato', TO_CHAR(NOW() AT TIME ZONE 'America/Lima', 'HH24:MI:SS'),
            'tiempo_restante_segundos', v_tiempo_restante_segundos,
            'pausado_por_nombre', v_usuario.nombre_completo
        ),
        'message', 'Partido pausado: ' || UPPER(v_partido.equipo_local::text) || ' vs ' || UPPER(v_partido.equipo_visitante::text) || '. Tiempo restante: ' || (v_tiempo_restante_segundos / 60) || ' minutos'
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
GRANT EXECUTE ON FUNCTION pausar_partido(UUID) TO anon, authenticated, service_role;
COMMENT ON FUNCTION pausar_partido IS 'E004-HU-001: Pausa un partido en curso.';


-- ============================================
-- 4. FUNCION: reanudar_partido
-- ============================================
CREATE OR REPLACE FUNCTION reanudar_partido(
    p_partido_id UUID
) RETURNS JSON AS $$
DECLARE
    v_user_id UUID;
    v_usuario RECORD;
    v_partido RECORD;
    v_tiempo_pausa_actual INTEGER;
    v_nuevo_tiempo_pausado INTEGER;
    v_tiempo_restante_segundos INTEGER;
    v_tiempo_transcurrido_segundos INTEGER;
    v_nueva_hora_fin TIMESTAMPTZ;
    v_error_hint TEXT;
BEGIN
    -- Validar autenticacion
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        v_error_hint := 'no_autenticado';
        RAISE EXCEPTION 'Usuario no autenticado';
    END IF;

    -- Validar que es admin aprobado
    SELECT * INTO v_usuario
    FROM usuarios
    WHERE auth_user_id = v_user_id;

    IF NOT FOUND OR v_usuario.rol != 'admin' OR v_usuario.estado != 'aprobado' THEN
        v_error_hint := 'sin_permisos';
        RAISE EXCEPTION 'Solo administradores aprobados pueden reanudar partidos';
    END IF;

    -- Obtener el partido
    SELECT * INTO v_partido
    FROM partidos
    WHERE id = p_partido_id;

    IF NOT FOUND THEN
        v_error_hint := 'partido_no_encontrado';
        RAISE EXCEPTION 'Partido no encontrado: %', p_partido_id;
    END IF;

    IF v_partido.estado != 'pausado' THEN
        v_error_hint := 'partido_no_pausado';
        RAISE EXCEPTION 'El partido no esta pausado. Estado actual: %', v_partido.estado;
    END IF;

    -- Calcular tiempo de esta pausa
    IF v_partido.pausado_at IS NOT NULL THEN
        v_tiempo_pausa_actual := EXTRACT(EPOCH FROM (NOW() - v_partido.pausado_at))::INTEGER;
    ELSE
        v_tiempo_pausa_actual := 0;
    END IF;

    -- Nuevo total de tiempo pausado
    v_nuevo_tiempo_pausado := v_partido.tiempo_pausado_segundos + v_tiempo_pausa_actual;

    -- Calcular nueva hora de fin (extender por el tiempo pausado)
    v_nueva_hora_fin := v_partido.hora_fin_estimada + (v_tiempo_pausa_actual || ' seconds')::INTERVAL;

    -- Calcular tiempo restante
    v_tiempo_transcurrido_segundos := EXTRACT(EPOCH FROM (NOW() - v_partido.hora_inicio))::INTEGER - v_nuevo_tiempo_pausado;
    v_tiempo_restante_segundos := (v_partido.duracion_minutos * 60) - v_tiempo_transcurrido_segundos;
    IF v_tiempo_restante_segundos < 0 THEN
        v_tiempo_restante_segundos := 0;
    END IF;

    -- Reanudar el partido
    UPDATE partidos
    SET estado = 'en_curso',
        pausado_at = NULL,
        tiempo_pausado_segundos = v_nuevo_tiempo_pausado,
        hora_fin_estimada = v_nueva_hora_fin,
        updated_at = NOW()
    WHERE id = p_partido_id;

    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'partido_id', v_partido.id,
            'estado', 'en_curso',
            'hora_fin_estimada_formato', TO_CHAR(v_nueva_hora_fin AT TIME ZONE 'America/Lima', 'HH24:MI:SS'),
            'tiempo_restante_segundos', v_tiempo_restante_segundos,
            'tiempo_pausa_actual_segundos', v_tiempo_pausa_actual,
            'tiempo_pausado_total_segundos', v_nuevo_tiempo_pausado
        ),
        'message', 'Partido reanudado: ' || UPPER(v_partido.equipo_local::text) || ' vs ' || UPPER(v_partido.equipo_visitante::text) || '. Tiempo restante: ' || (v_tiempo_restante_segundos / 60) || ' minutos. Estuvo pausado ' || (v_tiempo_pausa_actual / 60) || ' minutos.'
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
GRANT EXECUTE ON FUNCTION reanudar_partido(UUID) TO anon, authenticated, service_role;
COMMENT ON FUNCTION reanudar_partido IS 'E004-HU-001: Reanuda un partido pausado.';


-- ============================================
-- 5. FUNCION: finalizar_partido
-- ============================================
CREATE OR REPLACE FUNCTION finalizar_partido(
    p_partido_id UUID
) RETURNS JSON AS $$
DECLARE
    v_user_id UUID;
    v_usuario RECORD;
    v_partido RECORD;
    v_error_hint TEXT;
BEGIN
    -- Validar autenticacion
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        v_error_hint := 'no_autenticado';
        RAISE EXCEPTION 'Usuario no autenticado';
    END IF;

    -- Validar que es admin aprobado
    SELECT * INTO v_usuario
    FROM usuarios
    WHERE auth_user_id = v_user_id;

    IF NOT FOUND OR v_usuario.rol != 'admin' OR v_usuario.estado != 'aprobado' THEN
        v_error_hint := 'sin_permisos';
        RAISE EXCEPTION 'Solo administradores aprobados pueden finalizar partidos';
    END IF;

    -- Obtener el partido
    SELECT * INTO v_partido
    FROM partidos
    WHERE id = p_partido_id;

    IF NOT FOUND THEN
        v_error_hint := 'partido_no_encontrado';
        RAISE EXCEPTION 'Partido no encontrado: %', p_partido_id;
    END IF;

    IF v_partido.estado NOT IN ('en_curso', 'pausado') THEN
        v_error_hint := 'partido_no_activo';
        RAISE EXCEPTION 'El partido no esta activo. Estado actual: %', v_partido.estado;
    END IF;

    -- Finalizar el partido
    UPDATE partidos
    SET estado = 'finalizado',
        pausado_at = NULL,
        updated_at = NOW()
    WHERE id = p_partido_id;

    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'partido_id', v_partido.id,
            'estado', 'finalizado',
            'equipo_local', v_partido.equipo_local::text,
            'equipo_visitante', v_partido.equipo_visitante::text,
            'goles_local', v_partido.goles_local,
            'goles_visitante', v_partido.goles_visitante,
            'resultado', v_partido.goles_local || ' - ' || v_partido.goles_visitante
        ),
        'message', 'Partido finalizado: ' || UPPER(v_partido.equipo_local::text) || ' ' || v_partido.goles_local || ' - ' || v_partido.goles_visitante || ' ' || UPPER(v_partido.equipo_visitante::text)
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
GRANT EXECUTE ON FUNCTION finalizar_partido(UUID) TO anon, authenticated, service_role;
COMMENT ON FUNCTION finalizar_partido IS 'E004-HU-001: Finaliza un partido activo.';


-- ============================================
-- VERIFICACION
-- ============================================
-- Ejecuta esto para verificar que las funciones se crearon correctamente:

SELECT
    routine_name as funcion,
    routine_type as tipo
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name IN ('iniciar_partido', 'obtener_partido_activo', 'pausar_partido', 'reanudar_partido', 'finalizar_partido')
ORDER BY routine_name;

-- ============================================
-- FIN DEL SCRIPT
-- ============================================
