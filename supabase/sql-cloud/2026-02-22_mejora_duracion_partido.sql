-- ============================================
-- Mejora: Duracion configurable por partido
-- Fecha: 2026-02-22
-- Descripcion: Agrega parametro opcional p_duracion_minutos
--   a iniciar_partido. Si se pasa un valor (5-60), se usa
--   ese valor. Si es NULL, se usa la logica por defecto
--   (20 min para 2 equipos, 10 min para 3+).
--   Como la firma cambia, se hace DROP + CREATE.
-- ============================================

-- 1. DROP de la firma vieja (3 parametros)
DROP FUNCTION IF EXISTS iniciar_partido(UUID, TEXT, TEXT);

-- 2. CREATE con la nueva firma (4 parametros, ultimo opcional)
CREATE OR REPLACE FUNCTION iniciar_partido(
    p_fecha_id UUID,
    p_equipo_local TEXT,
    p_equipo_visitante TEXT,
    p_duracion_minutos INTEGER DEFAULT NULL
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

    -- RN-001: Validar que es admin o coadmin
    SELECT * INTO v_usuario
    FROM usuarios
    WHERE auth_user_id = v_user_id;

    IF NOT FOUND THEN
        v_error_hint := 'usuario_no_encontrado';
        RAISE EXCEPTION 'Usuario no encontrado';
    END IF;

    -- Verificar permisos: admin global o coadmin
    IF NOT (v_usuario.rol = 'admin' AND v_usuario.estado = 'aprobado') THEN
        IF NOT EXISTS (
            SELECT 1 FROM miembros_grupo
            WHERE usuario_id = v_usuario.id AND activo = true AND rol IN ('admin', 'coadmin')
        ) THEN
            v_error_hint := 'sin_permisos';
            RAISE EXCEPTION 'Solo administradores o co-administradores pueden iniciar partidos';
        END IF;
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

    -- RN-003: Validar que el equipo local tiene jugadores (>= 1)
    SELECT COUNT(*) INTO v_jugadores_local
    FROM asignaciones_equipos ae
    WHERE ae.fecha_id = p_fecha_id
    AND ae.color_equipo::text = LOWER(p_equipo_local)
    -- Solo contar jugadores con inscripcion activa
    AND EXISTS (
      SELECT 1 FROM inscripciones i
      WHERE i.fecha_id = p_fecha_id
      AND i.usuario_id = ae.usuario_id
      AND i.estado = 'inscrito'
    );

    IF v_jugadores_local = 0 THEN
        v_error_hint := 'EQUIPO_SIN_JUGADORES';
        RAISE EXCEPTION 'El equipo % no tiene jugadores asignados', p_equipo_local;
    END IF;

    -- RN-003: Validar que el equipo visitante tiene jugadores (>= 1)
    SELECT COUNT(*) INTO v_jugadores_visitante
    FROM asignaciones_equipos ae
    WHERE ae.fecha_id = p_fecha_id
    AND ae.color_equipo::text = LOWER(p_equipo_visitante)
    AND EXISTS (
      SELECT 1 FROM inscripciones i
      WHERE i.fecha_id = p_fecha_id
      AND i.usuario_id = ae.usuario_id
      AND i.estado = 'inscrito'
    );

    IF v_jugadores_visitante = 0 THEN
        v_error_hint := 'EQUIPO_SIN_JUGADORES';
        RAISE EXCEPTION 'El equipo % no tiene jugadores asignados', p_equipo_visitante;
    END IF;

    -- RN-004: Duracion custom o calculada segun num_equipos
    IF p_duracion_minutos IS NOT NULL THEN
        -- Validar rango: 5-60 minutos
        IF p_duracion_minutos < 5 OR p_duracion_minutos > 60 THEN
            v_error_hint := 'duracion_invalida';
            RAISE EXCEPTION 'La duracion debe ser entre 5 y 60 minutos. Valor recibido: %', p_duracion_minutos;
        END IF;
        v_duracion_minutos := p_duracion_minutos;
    ELSE
        IF v_fecha.num_equipos = 2 THEN
            v_duracion_minutos := 20;
        ELSE
            v_duracion_minutos := 10;
        END IF;
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

-- 3. Permisos (nueva firma con 4 parametros)
GRANT EXECUTE ON FUNCTION iniciar_partido(UUID, TEXT, TEXT, INTEGER) TO anon, authenticated, service_role;

-- 4. Comentario actualizado
COMMENT ON FUNCTION iniciar_partido IS
  'E004-HU-001: Inicia partido. V3: parametro opcional p_duracion_minutos (5-60), hint duracion_invalida. Si NULL usa default (20min/2eq, 10min/3+eq).';

-- 5. Verificacion
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'public'
        AND p.proname = 'iniciar_partido'
        AND pg_get_function_arguments(p.oid) = 'p_fecha_id uuid, p_equipo_local text, p_equipo_visitante text, p_duracion_minutos integer DEFAULT NULL::integer'
    ) THEN
        RAISE NOTICE '** VERIFICACION OK: iniciar_partido con 4 parametros (ultimo opcional) creada correctamente **';
    ELSE
        RAISE WARNING '** VERIFICACION FALLO: iniciar_partido no tiene la firma esperada **';
    END IF;
END $$;
