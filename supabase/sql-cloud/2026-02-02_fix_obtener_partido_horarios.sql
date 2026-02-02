-- ============================================
-- FIX: Agregar horarios a obtener_partido_activo
-- Fecha: 2026-02-02
-- Problema: El frontend necesita hora_inicio_formato y hora_fin_estimada_formato
--           pero obtener_partido_activo no los envia
-- Solucion: Agregar estos campos a la respuesta JSON
-- ============================================
--
-- Ejecutar en: https://supabase.com/dashboard/project/tvvubzkqbksxvcjvivij/sql
--
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
        -- NOTA: Ya no forzamos a 0, permitimos tiempo negativo para "tiempo extra"
    ELSIF v_partido.estado = 'pausado' AND v_partido.pausado_at IS NOT NULL THEN
        -- Tiempo hasta que se pauso
        v_tiempo_transcurrido_segundos := EXTRACT(EPOCH FROM (v_partido.pausado_at - v_partido.hora_inicio))::INTEGER - v_partido.tiempo_pausado_segundos;
        v_tiempo_restante_segundos := (v_partido.duracion_minutos * 60) - v_tiempo_transcurrido_segundos;
    ELSE
        v_tiempo_restante_segundos := v_partido.duracion_minutos * 60;
        v_tiempo_transcurrido_segundos := 0;
    END IF;

    -- Construir info equipo local
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
                -- NUEVO: Agregar horarios formateados en zona horaria Peru
                'hora_inicio_formato', TO_CHAR(v_partido.hora_inicio AT TIME ZONE 'America/Lima', 'HH24:MI'),
                'hora_fin_estimada_formato', TO_CHAR(v_partido.hora_fin_estimada AT TIME ZONE 'America/Lima', 'HH24:MI'),
                -- Tiempos calculados
                'tiempo_restante_segundos', v_tiempo_restante_segundos,
                'tiempo_restante_formato',
                    CASE
                        WHEN v_tiempo_restante_segundos < 0 THEN
                            '-' || LPAD((ABS(v_tiempo_restante_segundos) / 60)::TEXT, 2, '0') || ':' || LPAD((ABS(v_tiempo_restante_segundos) % 60)::TEXT, 2, '0')
                        ELSE
                            LPAD((v_tiempo_restante_segundos / 60)::TEXT, 2, '0') || ':' || LPAD((v_tiempo_restante_segundos % 60)::TEXT, 2, '0')
                    END,
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
COMMENT ON FUNCTION obtener_partido_activo IS 'E004-HU-001: Obtiene el partido activo de una fecha. Incluye horarios formateados.';

-- ============================================
-- VERIFICACION
-- ============================================
-- Ejecuta esto para verificar:
SELECT routine_name FROM information_schema.routines
WHERE routine_schema = 'public' AND routine_name = 'obtener_partido_activo';

-- ============================================
-- FIN DEL SCRIPT
-- ============================================
