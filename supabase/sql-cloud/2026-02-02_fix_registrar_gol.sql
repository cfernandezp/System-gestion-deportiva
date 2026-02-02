-- ============================================
-- FIX: Corregir columna ae.equipo en registrar_gol
-- Fecha: 2026-02-02
-- Descripcion: La tabla asignaciones_equipos tiene columna 'color_equipo',
--              no 'equipo'. Se corrige la referencia en la funcion.
-- ============================================
--
-- Ejecutar en: https://supabase.com/dashboard/project/tvvubzkqbksxvcjvivij/sql
--
-- Error original: "column ae.equipo does not exist"
-- Fix: Cambiar ae.equipo por ae.color_equipo
--      Cambiar v_asignacion.equipo por v_asignacion.color_equipo
-- ============================================

-- ============================================
-- PASO 1: Eliminar version anterior
-- ============================================
DROP FUNCTION IF EXISTS registrar_gol(UUID, TEXT, UUID, BOOLEAN);

-- ============================================
-- PASO 2: Crear funcion corregida
-- ============================================
CREATE OR REPLACE FUNCTION registrar_gol(
    p_partido_id UUID,
    p_equipo_anotador TEXT,
    p_jugador_id UUID DEFAULT NULL,
    p_es_autogol BOOLEAN DEFAULT false
) RETURNS JSON AS $$
DECLARE
    v_error_hint TEXT;
    v_current_user_id UUID;
    v_current_user RECORD;
    v_partido RECORD;
    v_fecha RECORD;
    v_equipo_anotador_enum color_equipo;
    v_equipo_real color_equipo;
    v_jugador RECORD;
    v_asignacion RECORD;
    v_minuto INTEGER;
    v_gol_id UUID;
    v_goles_local INTEGER;
    v_goles_visitante INTEGER;
    v_advertencia TEXT := NULL;
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
    -- Validacion: Parametros obligatorios
    -- ========================================
    IF p_partido_id IS NULL THEN
        v_error_hint := 'partido_id_requerido';
        RAISE EXCEPTION 'El ID del partido es obligatorio';
    END IF;

    IF p_equipo_anotador IS NULL OR TRIM(p_equipo_anotador) = '' THEN
        v_error_hint := 'equipo_anotador_requerido';
        RAISE EXCEPTION 'El equipo anotador es obligatorio';
    END IF;

    -- ========================================
    -- RN-001: Solo admin aprobado puede registrar goles
    -- ========================================
    SELECT id, rol, estado, nombre_completo
    INTO v_current_user
    FROM usuarios
    WHERE auth_user_id = v_current_user_id;

    IF NOT FOUND THEN
        v_error_hint := 'usuario_no_encontrado';
        RAISE EXCEPTION 'Usuario no encontrado en el sistema';
    END IF;

    IF v_current_user.rol != 'admin' OR v_current_user.estado != 'aprobado' THEN
        v_error_hint := 'sin_permisos';
        RAISE EXCEPTION 'Solo los administradores aprobados pueden registrar goles';
    END IF;

    -- ========================================
    -- Obtener datos del partido
    -- ========================================
    SELECT id, fecha_id, equipo_local, equipo_visitante, duracion_minutos,
           estado, hora_inicio, hora_fin_estimada, tiempo_pausado_segundos, pausado_at
    INTO v_partido
    FROM partidos
    WHERE id = p_partido_id;

    IF NOT FOUND THEN
        v_error_hint := 'partido_no_encontrado';
        RAISE EXCEPTION 'Partido no encontrado';
    END IF;

    -- ========================================
    -- RN-002: Partido debe estar en estado 'en_curso'
    -- ========================================
    IF v_partido.estado != 'en_curso' THEN
        -- RN-007: No permitir si partido esta pausado
        IF v_partido.estado = 'pausado' THEN
            v_error_hint := 'partido_pausado';
            RAISE EXCEPTION 'No se pueden registrar goles mientras el partido esta pausado';
        ELSE
            v_error_hint := 'partido_no_en_curso';
            RAISE EXCEPTION 'Solo se pueden registrar goles en partidos en curso. Estado actual: %', v_partido.estado;
        END IF;
    END IF;

    -- ========================================
    -- Validar color del equipo anotador
    -- ========================================
    BEGIN
        v_equipo_anotador_enum := LOWER(TRIM(p_equipo_anotador))::color_equipo;
    EXCEPTION
        WHEN invalid_text_representation THEN
            v_error_hint := 'equipo_invalido';
            RAISE EXCEPTION 'Color de equipo invalido: %. Colores validos: naranja, verde, azul, rojo, amarillo, blanco', p_equipo_anotador;
    END;

    -- Validar que el equipo sea uno de los que juegan
    IF v_equipo_anotador_enum != v_partido.equipo_local AND v_equipo_anotador_enum != v_partido.equipo_visitante THEN
        v_error_hint := 'equipo_no_participa';
        RAISE EXCEPTION 'El equipo % no participa en este partido. Equipos: % vs %',
            v_equipo_anotador_enum, v_partido.equipo_local, v_partido.equipo_visitante;
    END IF;

    -- ========================================
    -- RN-006: Si es autogol, el gol suma al equipo contrario
    -- ========================================
    IF p_es_autogol THEN
        -- El equipo_anotador indicado es el equipo del jugador que hizo el autogol
        -- El gol real va al equipo contrario
        IF v_equipo_anotador_enum = v_partido.equipo_local THEN
            v_equipo_real := v_partido.equipo_visitante;
        ELSE
            v_equipo_real := v_partido.equipo_local;
        END IF;
    ELSE
        v_equipo_real := v_equipo_anotador_enum;
    END IF;

    -- ========================================
    -- RN-003: Si hay jugador_id, validar que pertenezca al equipo correcto
    -- ========================================
    IF p_jugador_id IS NOT NULL THEN
        -- Verificar que el jugador existe
        SELECT id, nombre_completo
        INTO v_jugador
        FROM usuarios
        WHERE id = p_jugador_id;

        IF NOT FOUND THEN
            v_error_hint := 'jugador_no_encontrado';
            RAISE EXCEPTION 'Jugador no encontrado';
        END IF;

        -- FIX: Cambio de ae.equipo a ae.color_equipo
        -- Verificar asignacion del jugador al equipo
        SELECT ae.id, ae.color_equipo
        INTO v_asignacion
        FROM asignaciones_equipos ae
        WHERE ae.fecha_id = v_partido.fecha_id
        AND ae.usuario_id = p_jugador_id;

        IF NOT FOUND THEN
            v_error_hint := 'jugador_sin_asignacion';
            RAISE EXCEPTION 'El jugador % no tiene equipo asignado en este partido', v_jugador.nombre_completo;
        END IF;

        -- Para gol normal: jugador debe ser del equipo que anota
        -- Para autogol: jugador debe ser del equipo contrario al que recibe el punto
        -- FIX: Cambio de v_asignacion.equipo a v_asignacion.color_equipo
        IF p_es_autogol THEN
            -- En autogol, el jugador es del equipo que "comete" el autogol (equipo_anotador original)
            IF v_asignacion.color_equipo != v_equipo_anotador_enum THEN
                v_error_hint := 'jugador_equipo_incorrecto_autogol';
                RAISE EXCEPTION 'Para autogol, el jugador debe ser del equipo %. El jugador % es del equipo %',
                    v_equipo_anotador_enum, v_jugador.nombre_completo, v_asignacion.color_equipo;
            END IF;
        ELSE
            -- En gol normal, jugador debe ser del equipo anotador
            IF v_asignacion.color_equipo != v_equipo_anotador_enum THEN
                v_error_hint := 'jugador_equipo_incorrecto';
                RAISE EXCEPTION 'El jugador % no pertenece al equipo %. Esta asignado al equipo %',
                    v_jugador.nombre_completo, v_equipo_anotador_enum, v_asignacion.color_equipo;
            END IF;
        END IF;
    END IF;

    -- ========================================
    -- Obtener datos de la fecha
    -- ========================================
    SELECT id, lugar
    INTO v_fecha
    FROM fechas
    WHERE id = v_partido.fecha_id;

    -- ========================================
    -- RN-004: Calcular minuto automaticamente
    -- Minuto = segundos transcurridos desde hora_inicio / 60, redondeado hacia arriba
    -- Considerando tiempo pausado
    -- ========================================
    v_minuto := CEIL(
        (EXTRACT(EPOCH FROM (NOW() - v_partido.hora_inicio)) - v_partido.tiempo_pausado_segundos) / 60.0
    )::INTEGER;

    -- Asegurar minuto minimo de 1
    IF v_minuto < 1 THEN
        v_minuto := 1;
    END IF;

    -- ========================================
    -- Insertar el gol
    -- ========================================
    INSERT INTO goles (
        partido_id,
        equipo_anotador,
        jugador_id,
        minuto,
        es_autogol,
        created_by
    ) VALUES (
        p_partido_id,
        v_equipo_real,  -- El equipo que realmente recibe el punto
        p_jugador_id,
        v_minuto,
        p_es_autogol,
        v_current_user.id
    )
    RETURNING id INTO v_gol_id;

    -- ========================================
    -- Calcular marcador actualizado
    -- ========================================
    SELECT COUNT(*) INTO v_goles_local
    FROM goles
    WHERE partido_id = p_partido_id
    AND equipo_anotador = v_partido.equipo_local
    AND anulado = false;

    SELECT COUNT(*) INTO v_goles_visitante
    FROM goles
    WHERE partido_id = p_partido_id
    AND equipo_anotador = v_partido.equipo_visitante
    AND anulado = false;

    -- ========================================
    -- Actualizar marcador en la tabla partidos
    -- ========================================
    UPDATE partidos
    SET goles_local = v_goles_local,
        goles_visitante = v_goles_visitante,
        updated_at = NOW()
    WHERE id = p_partido_id;

    -- ========================================
    -- RN-008: Advertencia si equipo llega a 10+ goles
    -- ========================================
    IF v_goles_local >= 10 OR v_goles_visitante >= 10 THEN
        v_advertencia := 'Marcador inusual: ' ||
            UPPER(v_partido.equipo_local::TEXT) || ' ' || v_goles_local || ' - ' ||
            v_goles_visitante || ' ' || UPPER(v_partido.equipo_visitante::TEXT);
    END IF;

    -- ========================================
    -- Retorno exitoso
    -- ========================================
    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'gol_id', v_gol_id,
            'partido_id', p_partido_id,
            'equipo_anotador', v_equipo_real,
            'equipo_jugador', CASE WHEN p_es_autogol THEN v_equipo_anotador_enum ELSE v_equipo_real END,
            'jugador_id', p_jugador_id,
            'jugador_nombre', CASE WHEN p_jugador_id IS NOT NULL THEN v_jugador.nombre_completo ELSE NULL END,
            'minuto', v_minuto,
            'es_autogol', p_es_autogol,
            'marcador', json_build_object(
                'equipo_local', v_partido.equipo_local,
                'goles_local', v_goles_local,
                'equipo_visitante', v_partido.equipo_visitante,
                'goles_visitante', v_goles_visitante
            ),
            'marcador_texto', UPPER(v_partido.equipo_local::TEXT) || ' ' || v_goles_local || ' - ' ||
                             v_goles_visitante || ' ' || UPPER(v_partido.equipo_visitante::TEXT),
            'registrado_por', v_current_user.id,
            'registrado_por_nombre', v_current_user.nombre_completo,
            'registrado_at', NOW(),
            'registrado_at_formato', TO_CHAR(NOW() AT TIME ZONE 'America/Lima', 'HH24:MI:SS'),
            'advertencia', v_advertencia
        ),
        'message', CASE
            WHEN p_es_autogol AND p_jugador_id IS NOT NULL THEN
                'Autogol de ' || v_jugador.nombre_completo || ' (min ' || v_minuto || ') - Punto para ' || UPPER(v_equipo_real::TEXT)
            WHEN p_es_autogol THEN
                'Autogol (min ' || v_minuto || ') - Punto para ' || UPPER(v_equipo_real::TEXT)
            WHEN p_jugador_id IS NOT NULL THEN
                'Gol de ' || v_jugador.nombre_completo || ' (min ' || v_minuto || ') para ' || UPPER(v_equipo_real::TEXT)
            ELSE
                'Gol para ' || UPPER(v_equipo_real::TEXT) || ' (min ' || v_minuto || ')'
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
GRANT EXECUTE ON FUNCTION registrar_gol(UUID, TEXT, UUID, BOOLEAN) TO anon, authenticated, service_role;

-- Comentario
COMMENT ON FUNCTION registrar_gol IS 'Registra un gol en un partido en curso. Valida equipos, jugadores y calcula minuto automaticamente. Soporta autogoles.';


-- ============================================
-- VERIFICACION
-- ============================================
-- Ejecuta esto para verificar que la funcion se actualizo:

SELECT
    routine_name as funcion,
    routine_type as tipo,
    (SELECT string_agg(parameter_name || ' ' || data_type, ', ' ORDER BY ordinal_position)
     FROM information_schema.parameters p
     WHERE p.specific_name = r.specific_name
     AND p.parameter_mode = 'IN') as parametros
FROM information_schema.routines r
WHERE routine_schema = 'public'
AND routine_name = 'registrar_gol';


-- ============================================
-- FIN DEL SCRIPT
-- ============================================
