-- ============================================
-- FIX: Actualizar finalizar_partido con confirmacion anticipada
-- Fecha: 2026-02-02
-- Descripcion: Agrega parametro opcional para permitir finalizar
--              un partido antes de que termine el tiempo.
--              Si el tiempo no ha terminado, requiere confirmacion.
-- ============================================
--
-- Ejecutar en: https://supabase.com/dashboard/project/tvvubzkqbksxvcjvivij/sql
--
-- Cambios:
--   - Nuevo parametro: p_confirmar_anticipado BOOLEAN DEFAULT false
--   - Si tiempo NO ha terminado y p_confirmar_anticipado = false:
--     retorna error con hint 'requiere_confirmacion'
--   - Si tiempo YA termino O p_confirmar_anticipado = true:
--     finaliza el partido normalmente
--   - Retorna resumen completo: marcador, goleadores, duracion
-- ============================================

-- ============================================
-- PASO 1: Eliminar versiones anteriores
-- Especificamos todas las posibles firmas para evitar conflictos
-- ============================================
DROP FUNCTION IF EXISTS finalizar_partido(UUID);
DROP FUNCTION IF EXISTS finalizar_partido(UUID, BOOLEAN);

-- ============================================
-- PASO 2: Crear la funcion con el nuevo parametro
-- ============================================
CREATE OR REPLACE FUNCTION finalizar_partido(
    p_partido_id UUID,
    p_confirmar_anticipado BOOLEAN DEFAULT false
) RETURNS JSON AS $$
DECLARE
    v_user_id UUID;
    v_usuario RECORD;
    v_partido RECORD;
    v_tiempo_restante_segundos INTEGER;
    v_tiempo_transcurrido_segundos INTEGER;
    v_duracion_real_segundos INTEGER;
    v_tiempo_terminado BOOLEAN;
    v_goleadores JSON;
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

    -- Calcular tiempo restante y transcurrido
    IF v_partido.estado = 'en_curso' THEN
        -- Partido en curso: calcular desde ahora
        v_tiempo_transcurrido_segundos := EXTRACT(EPOCH FROM (NOW() - v_partido.hora_inicio))::INTEGER
                                          - v_partido.tiempo_pausado_segundos;
    ELSIF v_partido.estado = 'pausado' AND v_partido.pausado_at IS NOT NULL THEN
        -- Partido pausado: calcular hasta el momento de la pausa
        v_tiempo_transcurrido_segundos := EXTRACT(EPOCH FROM (v_partido.pausado_at - v_partido.hora_inicio))::INTEGER
                                          - v_partido.tiempo_pausado_segundos;
    ELSE
        v_tiempo_transcurrido_segundos := 0;
    END IF;

    v_tiempo_restante_segundos := (v_partido.duracion_minutos * 60) - v_tiempo_transcurrido_segundos;

    -- Asegurar que no sea negativo
    IF v_tiempo_restante_segundos < 0 THEN
        v_tiempo_restante_segundos := 0;
    END IF;

    -- Determinar si el tiempo ya termino
    v_tiempo_terminado := (v_tiempo_restante_segundos <= 0);

    -- VALIDACION: Si el tiempo NO ha terminado, requiere confirmacion
    IF NOT v_tiempo_terminado AND NOT p_confirmar_anticipado THEN
        v_error_hint := 'requiere_confirmacion';
        RAISE EXCEPTION 'El tiempo del partido aun no ha terminado. Quedan % minutos y % segundos. Use p_confirmar_anticipado = true para finalizar anticipadamente.',
            (v_tiempo_restante_segundos / 60),
            (v_tiempo_restante_segundos % 60);
    END IF;

    -- Calcular duracion real del partido (tiempo efectivo jugado)
    v_duracion_real_segundos := LEAST(v_tiempo_transcurrido_segundos, v_partido.duracion_minutos * 60);
    IF v_duracion_real_segundos < 0 THEN
        v_duracion_real_segundos := 0;
    END IF;

    -- Obtener lista de goleadores del partido
    SELECT COALESCE(
        json_agg(
            json_build_object(
                'jugador_id', g.jugador_id,
                'jugador_nombre', COALESCE(u.nombre_completo, 'Desconocido'),
                'equipo', g.equipo_anotador::text,
                'minuto', g.minuto,
                'es_autogol', g.es_autogol
            ) ORDER BY g.minuto
        ),
        '[]'::json
    ) INTO v_goleadores
    FROM goles g
    LEFT JOIN usuarios u ON u.id = g.jugador_id
    WHERE g.partido_id = p_partido_id
    AND g.anulado = false;

    -- Finalizar el partido
    UPDATE partidos
    SET estado = 'finalizado',
        pausado_at = NULL,
        updated_at = NOW()
    WHERE id = p_partido_id;

    -- Retornar resumen completo del partido
    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'partido_id', v_partido.id,
            'estado', 'finalizado',
            'equipo_local', v_partido.equipo_local::text,
            'equipo_visitante', v_partido.equipo_visitante::text,
            'marcador', json_build_object(
                'local', v_partido.goles_local,
                'visitante', v_partido.goles_visitante,
                'texto', v_partido.goles_local || ' - ' || v_partido.goles_visitante
            ),
            'goleadores', v_goleadores,
            'duracion', json_build_object(
                'programada_minutos', v_partido.duracion_minutos,
                'real_segundos', v_duracion_real_segundos,
                'real_formato', LPAD((v_duracion_real_segundos / 60)::TEXT, 2, '0') || ':' || LPAD((v_duracion_real_segundos % 60)::TEXT, 2, '0')
            ),
            'finalizado_anticipadamente', NOT v_tiempo_terminado,
            'finalizado_por_nombre', v_usuario.nombre_completo,
            'finalizado_at_formato', TO_CHAR(NOW() AT TIME ZONE 'America/Lima', 'HH24:MI:SS')
        ),
        'message', CASE
            WHEN NOT v_tiempo_terminado THEN
                'Partido finalizado anticipadamente: ' || UPPER(v_partido.equipo_local::text) || ' ' || v_partido.goles_local || ' - ' || v_partido.goles_visitante || ' ' || UPPER(v_partido.equipo_visitante::text)
            ELSE
                'Partido finalizado: ' || UPPER(v_partido.equipo_local::text) || ' ' || v_partido.goles_local || ' - ' || v_partido.goles_visitante || ' ' || UPPER(v_partido.equipo_visitante::text)
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

-- Permisos
GRANT EXECUTE ON FUNCTION finalizar_partido(UUID, BOOLEAN) TO anon, authenticated, service_role;

-- Comentario
COMMENT ON FUNCTION finalizar_partido IS 'Finaliza un partido activo. Requiere confirmacion si el tiempo no ha terminado (hint: requiere_confirmacion). Retorna resumen con marcador, goleadores y duracion.';


-- ============================================
-- VERIFICACION
-- ============================================
-- Ejecuta esto para verificar que la funcion se actualizo correctamente:

SELECT
    routine_name as funcion,
    routine_type as tipo,
    (SELECT string_agg(parameter_name || ' ' || data_type, ', ' ORDER BY ordinal_position)
     FROM information_schema.parameters p
     WHERE p.specific_name = r.specific_name
     AND p.parameter_mode = 'IN') as parametros
FROM information_schema.routines r
WHERE routine_schema = 'public'
AND routine_name = 'finalizar_partido';

-- ============================================
-- EJEMPLOS DE USO
-- ============================================
--
-- 1. Finalizar cuando el tiempo ya termino (normal):
--    SELECT finalizar_partido('uuid-del-partido');
--
-- 2. Intentar finalizar antes de tiempo (retorna error requiere_confirmacion):
--    SELECT finalizar_partido('uuid-del-partido');
--    -> Error: hint = 'requiere_confirmacion'
--
-- 3. Finalizar anticipadamente con confirmacion:
--    SELECT finalizar_partido('uuid-del-partido', true);
--
-- ============================================
-- FIN DEL SCRIPT
-- ============================================
