-- ============================================
-- E004-HU-005: Finalizar Partido
-- Fecha: 2026-01-30
-- Descripcion: Implementacion de funcion RPC para finalizar partido,
--              registrar resultado final, calcular estadisticas y
--              sugerir rotacion de equipos (3 equipos)
-- Dependencia: E004-HU-001 (tabla partidos), E004-HU-003 (tabla goles)
-- NOTA: La tabla goles usa columnas: equipo_anota, jugador_id
-- ============================================

-- ============================================
-- PARTE 1: AGREGAR COLUMNAS PARA FINALIZACION A PARTIDOS
-- ============================================

-- Columna para registrar hora real de finalizacion
ALTER TABLE partidos ADD COLUMN IF NOT EXISTS hora_fin TIMESTAMPTZ;

-- Columna para registrar resultado: 'local', 'visitante', 'empate'
-- Usando DO block para hacer el ALTER idempotente
DO $$ BEGIN
    ALTER TABLE partidos ADD COLUMN resultado VARCHAR(20);
EXCEPTION
    WHEN duplicate_column THEN NULL;
END $$;

-- Agregar constraint para valores validos de resultado
DO $$ BEGIN
    ALTER TABLE partidos ADD CONSTRAINT chk_resultado_valido
    CHECK (resultado IS NULL OR resultado IN ('local', 'visitante', 'empate'));
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

-- Columna para duracion real en segundos (descontando pausas)
ALTER TABLE partidos ADD COLUMN IF NOT EXISTS duracion_real_segundos INTEGER;

-- Columna para registrar quien finalizo el partido
DO $$ BEGIN
    ALTER TABLE partidos ADD COLUMN finalizado_por UUID REFERENCES usuarios(id) ON DELETE SET NULL;
EXCEPTION
    WHEN duplicate_column THEN NULL;
END $$;

-- Columna para registrar cuando se finalizo
ALTER TABLE partidos ADD COLUMN IF NOT EXISTS finalizado_at TIMESTAMPTZ;

-- Comentarios
COMMENT ON COLUMN partidos.hora_fin IS 'E004-HU-005: Timestamp real de finalizacion del partido';
COMMENT ON COLUMN partidos.resultado IS 'E004-HU-005: Resultado del partido: local, visitante, empate';
COMMENT ON COLUMN partidos.duracion_real_segundos IS 'E004-HU-005: Duracion real = hora_fin - hora_inicio - tiempo_pausado';
COMMENT ON COLUMN partidos.finalizado_por IS 'E004-HU-005: ID del admin que finalizo el partido';
COMMENT ON COLUMN partidos.finalizado_at IS 'E004-HU-005: Timestamp cuando se finalizo el partido';

-- ============================================
-- PARTE 2: FUNCION RPC finalizar_partido
-- ============================================

-- ============================================
-- Funcion: finalizar_partido
-- Descripcion: Finaliza un partido, registra resultado final y estadisticas
-- Reglas: RN-001, RN-002, RN-003, RN-004, RN-005, RN-006, RN-007, RN-008
-- CA: CA-001, CA-002, CA-003, CA-004, CA-005, CA-006, CA-007
-- ============================================
CREATE OR REPLACE FUNCTION finalizar_partido(
    p_partido_id UUID,
    p_confirmar_anticipado BOOLEAN DEFAULT false
) RETURNS JSON AS $$
DECLARE
    v_error_hint TEXT;
    v_current_user_id UUID;
    v_current_user RECORD;
    v_partido RECORD;
    v_fecha RECORD;
    v_goles_local INTEGER;
    v_goles_visitante INTEGER;
    v_resultado VARCHAR(20);
    v_equipo_ganador color_equipo;
    v_duracion_real_segundos INTEGER;
    v_tiempo_restante_segundos INTEGER;
    v_hora_fin TIMESTAMPTZ;
    v_goleadores JSON;
    v_goleadores_local JSON;
    v_goleadores_visitante JSON;
    v_sugerencia_siguiente JSON;
    v_equipo_descansando color_equipo;
    v_equipos_fecha RECORD;
    v_es_tiempo_extra BOOLEAN;
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
    -- Validacion: Parametro obligatorio
    -- ========================================
    IF p_partido_id IS NULL THEN
        v_error_hint := 'partido_id_requerido';
        RAISE EXCEPTION 'El ID del partido es obligatorio';
    END IF;

    -- ========================================
    -- RN-001: Solo admin aprobado puede finalizar partidos
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
        RAISE EXCEPTION 'Solo los administradores aprobados pueden finalizar partidos';
    END IF;

    -- ========================================
    -- Obtener datos del partido
    -- ========================================
    SELECT id, fecha_id, equipo_local, equipo_visitante, duracion_minutos,
           estado, hora_inicio, hora_fin_estimada, tiempo_pausado_segundos,
           pausado_at, goles_local, goles_visitante
    INTO v_partido
    FROM partidos
    WHERE id = p_partido_id;

    IF NOT FOUND THEN
        v_error_hint := 'partido_no_encontrado';
        RAISE EXCEPTION 'Partido no encontrado';
    END IF;

    -- ========================================
    -- RN-002: Partido debe estar 'en_curso' o 'pausado'
    -- RN-003: No puede finalizarse si ya esta finalizado
    -- ========================================
    IF v_partido.estado = 'finalizado' THEN
        v_error_hint := 'partido_ya_finalizado';
        RAISE EXCEPTION 'El partido ya fue finalizado. El resultado no puede modificarse (RN-003)';
    END IF;

    IF v_partido.estado NOT IN ('en_curso', 'pausado') THEN
        v_error_hint := 'partido_no_activo';
        RAISE EXCEPTION 'Solo se pueden finalizar partidos en curso o pausados. Estado actual: %', v_partido.estado;
    END IF;

    -- ========================================
    -- Obtener datos de la fecha
    -- ========================================
    SELECT id, fecha_hora_inicio, duracion_horas, lugar, num_equipos, estado
    INTO v_fecha
    FROM fechas
    WHERE id = v_partido.fecha_id;

    -- ========================================
    -- CA-006: Verificar si es finalizacion anticipada
    -- RN-006: Requiere confirmacion explicita si tiempo no ha terminado
    -- ========================================
    -- Calcular tiempo restante
    IF v_partido.estado = 'pausado' THEN
        -- Si esta pausado, calcular desde el momento de pausa
        v_tiempo_restante_segundos := EXTRACT(EPOCH FROM (v_partido.hora_fin_estimada - v_partido.pausado_at))::INTEGER;
    ELSE
        -- Si esta en curso, calcular desde ahora
        v_tiempo_restante_segundos := EXTRACT(EPOCH FROM (v_partido.hora_fin_estimada - NOW()))::INTEGER;
    END IF;

    v_es_tiempo_extra := v_tiempo_restante_segundos < 0;

    -- Si aun queda tiempo y no se confirmo, pedir confirmacion
    IF v_tiempo_restante_segundos > 0 AND NOT p_confirmar_anticipado THEN
        v_error_hint := 'requiere_confirmacion_anticipado';
        RAISE EXCEPTION 'El partido tiene % segundos restantes (% minutos). Para finalizar anticipadamente, confirma con p_confirmar_anticipado = true',
            v_tiempo_restante_segundos,
            ROUND(v_tiempo_restante_segundos / 60.0, 1);
    END IF;

    -- ========================================
    -- Registrar hora de finalizacion
    -- ========================================
    v_hora_fin := NOW();

    -- ========================================
    -- RN-005: Calcular duracion real
    -- Duracion = hora_fin - hora_inicio - tiempo_pausado
    -- ========================================
    v_duracion_real_segundos := EXTRACT(EPOCH FROM (v_hora_fin - v_partido.hora_inicio))::INTEGER
                                - v_partido.tiempo_pausado_segundos;

    -- Si estaba pausado, descontar el tiempo de la ultima pausa
    IF v_partido.estado = 'pausado' AND v_partido.pausado_at IS NOT NULL THEN
        v_duracion_real_segundos := v_duracion_real_segundos
                                    - EXTRACT(EPOCH FROM (v_hora_fin - v_partido.pausado_at))::INTEGER;
    END IF;

    -- Asegurar que duracion no sea negativa
    v_duracion_real_segundos := GREATEST(0, v_duracion_real_segundos);

    -- ========================================
    -- Contar goles de tabla goles (usando columnas reales)
    -- RN-007: Solo contar goles no anulados
    -- RN-007: Autogoles ya estan contabilizados al equipo correcto
    -- ========================================
    SELECT COUNT(*) INTO v_goles_local
    FROM goles
    WHERE partido_id = p_partido_id
    AND equipo_anota = v_partido.equipo_local
    AND anulado = false;

    SELECT COUNT(*) INTO v_goles_visitante
    FROM goles
    WHERE partido_id = p_partido_id
    AND equipo_anota = v_partido.equipo_visitante
    AND anulado = false;

    -- ========================================
    -- RN-004: Determinar resultado
    -- RN-008: Empate 0-0 es valido
    -- ========================================
    IF v_goles_local > v_goles_visitante THEN
        v_resultado := 'local';
        v_equipo_ganador := v_partido.equipo_local;
    ELSIF v_goles_local < v_goles_visitante THEN
        v_resultado := 'visitante';
        v_equipo_ganador := v_partido.equipo_visitante;
    ELSE
        v_resultado := 'empate';
        v_equipo_ganador := NULL;
    END IF;

    -- ========================================
    -- CA-002 & CA-005: Obtener lista de goleadores
    -- Usando columnas reales: equipo_anota, jugador_id
    -- ========================================
    -- Goleadores del equipo local
    SELECT json_agg(
        json_build_object(
            'jugador_id', g.jugador_id,
            'jugador_nombre', COALESCE(u.nombre_completo, 'Gol anonimo'),
            'minuto', g.minuto,
            'es_autogol', g.es_autogol
        ) ORDER BY g.minuto ASC
    )
    INTO v_goleadores_local
    FROM goles g
    LEFT JOIN usuarios u ON u.id = g.jugador_id
    WHERE g.partido_id = p_partido_id
    AND g.equipo_anota = v_partido.equipo_local
    AND g.anulado = false;

    -- Goleadores del equipo visitante
    SELECT json_agg(
        json_build_object(
            'jugador_id', g.jugador_id,
            'jugador_nombre', COALESCE(u.nombre_completo, 'Gol anonimo'),
            'minuto', g.minuto,
            'es_autogol', g.es_autogol
        ) ORDER BY g.minuto ASC
    )
    INTO v_goleadores_visitante
    FROM goles g
    LEFT JOIN usuarios u ON u.id = g.jugador_id
    WHERE g.partido_id = p_partido_id
    AND g.equipo_anota = v_partido.equipo_visitante
    AND g.anulado = false;

    -- Todos los goleadores ordenados por minuto
    SELECT json_agg(
        json_build_object(
            'jugador_id', g.jugador_id,
            'jugador_nombre', COALESCE(u.nombre_completo, 'Gol anonimo'),
            'equipo', g.equipo_anota,
            'minuto', g.minuto,
            'es_autogol', g.es_autogol
        ) ORDER BY g.minuto ASC, g.created_at ASC
    )
    INTO v_goleadores
    FROM goles g
    LEFT JOIN usuarios u ON u.id = g.jugador_id
    WHERE g.partido_id = p_partido_id
    AND g.anulado = false;

    -- ========================================
    -- CA-004: Sugerir siguiente partido (solo para 3 equipos)
    -- El equipo que estaba descansando entra vs el ganador
    -- Si empate, entra vs cualquiera de los dos
    -- ========================================
    v_sugerencia_siguiente := NULL;

    IF v_fecha.num_equipos = 3 THEN
        -- Buscar equipos asignados en esta fecha
        SELECT ARRAY_AGG(DISTINCT equipo) as equipos
        INTO v_equipos_fecha
        FROM asignaciones_equipos
        WHERE fecha_id = v_partido.fecha_id;

        -- Encontrar el equipo que NO jugo en este partido
        SELECT equipo INTO v_equipo_descansando
        FROM (
            SELECT DISTINCT equipo
            FROM asignaciones_equipos
            WHERE fecha_id = v_partido.fecha_id
        ) sub
        WHERE equipo NOT IN (v_partido.equipo_local, v_partido.equipo_visitante)
        LIMIT 1;

        IF v_equipo_descansando IS NOT NULL THEN
            v_sugerencia_siguiente := json_build_object(
                'equipo_entra', v_equipo_descansando,
                'equipo_continua', CASE
                    WHEN v_resultado = 'local' THEN v_partido.equipo_local
                    WHEN v_resultado = 'visitante' THEN v_partido.equipo_visitante
                    ELSE v_partido.equipo_local  -- Si empate, el local continua
                END,
                'equipo_sale', CASE
                    WHEN v_resultado = 'local' THEN v_partido.equipo_visitante
                    WHEN v_resultado = 'visitante' THEN v_partido.equipo_local
                    ELSE v_partido.equipo_visitante  -- Si empate, el visitante sale
                END,
                'razon', CASE
                    WHEN v_resultado = 'empate' THEN 'Empate: el equipo local continua por convencion'
                    ELSE 'El ganador continua en cancha'
                END,
                'sugerencia_texto', CASE
                    WHEN v_resultado = 'local' THEN
                        UPPER(v_equipo_descansando::TEXT) || ' vs ' || UPPER(v_partido.equipo_local::TEXT)
                    WHEN v_resultado = 'visitante' THEN
                        UPPER(v_equipo_descansando::TEXT) || ' vs ' || UPPER(v_partido.equipo_visitante::TEXT)
                    ELSE
                        UPPER(v_equipo_descansando::TEXT) || ' vs ' || UPPER(v_partido.equipo_local::TEXT)
                END
            );
        END IF;
    END IF;

    -- ========================================
    -- CA-001 & CA-002: Actualizar partido con resultado final
    -- ========================================
    UPDATE partidos
    SET estado = 'finalizado',
        hora_fin = v_hora_fin,
        resultado = v_resultado,
        duracion_real_segundos = v_duracion_real_segundos,
        goles_local = v_goles_local,
        goles_visitante = v_goles_visitante,
        finalizado_por = v_current_user.id,
        finalizado_at = v_hora_fin,
        pausado_at = NULL  -- Limpiar si estaba pausado
    WHERE id = p_partido_id;

    -- ========================================
    -- CA-005 & CA-007: Retorno con resumen completo
    -- ========================================
    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'partido_id', p_partido_id,
            'fecha_id', v_partido.fecha_id,
            'estado', 'finalizado',
            'resultado', json_build_object(
                'codigo', v_resultado,
                'descripcion', CASE v_resultado
                    WHEN 'local' THEN 'Victoria ' || UPPER(v_partido.equipo_local::TEXT)
                    WHEN 'visitante' THEN 'Victoria ' || UPPER(v_partido.equipo_visitante::TEXT)
                    ELSE 'Empate'
                END,
                'equipo_ganador', v_equipo_ganador,
                'es_empate', v_resultado = 'empate'
            ),
            'marcador', json_build_object(
                'equipo_local', v_partido.equipo_local,
                'goles_local', v_goles_local,
                'equipo_visitante', v_partido.equipo_visitante,
                'goles_visitante', v_goles_visitante
            ),
            'marcador_texto', UPPER(v_partido.equipo_local::TEXT) || ' ' || v_goles_local || ' - ' ||
                             v_goles_visitante || ' ' || UPPER(v_partido.equipo_visitante::TEXT),
            'goleadores', json_build_object(
                'lista_completa', COALESCE(v_goleadores, '[]'::json),
                'equipo_local', COALESCE(v_goleadores_local, '[]'::json),
                'equipo_visitante', COALESCE(v_goleadores_visitante, '[]'::json),
                'total_goles', v_goles_local + v_goles_visitante
            ),
            'duracion', json_build_object(
                'programada_minutos', v_partido.duracion_minutos,
                'real_segundos', v_duracion_real_segundos,
                'real_minutos', ROUND(v_duracion_real_segundos / 60.0, 1),
                'real_formato', LPAD((v_duracion_real_segundos / 60)::TEXT, 2, '0') || ':' ||
                               LPAD((v_duracion_real_segundos % 60)::TEXT, 2, '0'),
                'tiempo_pausado_segundos', v_partido.tiempo_pausado_segundos,
                'finalizado_anticipadamente', v_tiempo_restante_segundos > 0,
                'tiempo_extra', v_es_tiempo_extra
            ),
            'tiempos', json_build_object(
                'hora_inicio', v_partido.hora_inicio,
                'hora_inicio_formato', TO_CHAR(v_partido.hora_inicio AT TIME ZONE 'America/Lima', 'HH24:MI:SS'),
                'hora_fin', v_hora_fin,
                'hora_fin_formato', TO_CHAR(v_hora_fin AT TIME ZONE 'America/Lima', 'HH24:MI:SS')
            ),
            'sugerencia_siguiente', v_sugerencia_siguiente,
            'fecha', json_build_object(
                'id', v_fecha.id,
                'lugar', v_fecha.lugar,
                'num_equipos', v_fecha.num_equipos,
                'fecha_formato', TO_CHAR(v_fecha.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY')
            ),
            'finalizado_por', json_build_object(
                'id', v_current_user.id,
                'nombre', v_current_user.nombre_completo
            )
        ),
        'message', CASE v_resultado
            WHEN 'local' THEN
                'Partido finalizado: ' || UPPER(v_partido.equipo_local::TEXT) || ' ' || v_goles_local ||
                ' - ' || v_goles_visitante || ' ' || UPPER(v_partido.equipo_visitante::TEXT) ||
                '. Victoria para ' || UPPER(v_partido.equipo_local::TEXT)
            WHEN 'visitante' THEN
                'Partido finalizado: ' || UPPER(v_partido.equipo_local::TEXT) || ' ' || v_goles_local ||
                ' - ' || v_goles_visitante || ' ' || UPPER(v_partido.equipo_visitante::TEXT) ||
                '. Victoria para ' || UPPER(v_partido.equipo_visitante::TEXT)
            ELSE
                'Partido finalizado: ' || UPPER(v_partido.equipo_local::TEXT) || ' ' || v_goles_local ||
                ' - ' || v_goles_visitante || ' ' || UPPER(v_partido.equipo_visitante::TEXT) ||
                '. Empate'
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
-- PARTE 3: FUNCION RPC obtener_resumen_partido
-- Para consultar resultado de partido finalizado
-- ============================================

CREATE OR REPLACE FUNCTION obtener_resumen_partido(
    p_partido_id UUID
) RETURNS JSON AS $$
DECLARE
    v_error_hint TEXT;
    v_current_user_id UUID;
    v_partido RECORD;
    v_fecha RECORD;
    v_goleadores JSON;
    v_goleadores_local JSON;
    v_goleadores_visitante JSON;
BEGIN
    -- Validacion: Usuario autenticado
    v_current_user_id := auth.uid();

    IF v_current_user_id IS NULL THEN
        v_error_hint := 'no_autenticado';
        RAISE EXCEPTION 'Debes iniciar sesion para realizar esta accion';
    END IF;

    IF p_partido_id IS NULL THEN
        v_error_hint := 'partido_id_requerido';
        RAISE EXCEPTION 'El ID del partido es obligatorio';
    END IF;

    -- Obtener datos del partido
    SELECT p.id, p.fecha_id, p.equipo_local, p.equipo_visitante, p.duracion_minutos,
           p.estado, p.hora_inicio, p.hora_fin, p.tiempo_pausado_segundos,
           p.goles_local, p.goles_visitante, p.resultado, p.duracion_real_segundos,
           p.finalizado_por, p.finalizado_at,
           u.nombre_completo as finalizado_por_nombre
    INTO v_partido
    FROM partidos p
    LEFT JOIN usuarios u ON u.id = p.finalizado_por
    WHERE p.id = p_partido_id;

    IF NOT FOUND THEN
        v_error_hint := 'partido_no_encontrado';
        RAISE EXCEPTION 'Partido no encontrado';
    END IF;

    -- Obtener datos de la fecha
    SELECT id, fecha_hora_inicio, lugar, num_equipos
    INTO v_fecha
    FROM fechas
    WHERE id = v_partido.fecha_id;

    -- Goleadores del equipo local
    SELECT json_agg(
        json_build_object(
            'jugador_id', g.jugador_id,
            'jugador_nombre', COALESCE(u.nombre_completo, 'Gol anonimo'),
            'minuto', g.minuto,
            'es_autogol', g.es_autogol
        ) ORDER BY g.minuto ASC
    )
    INTO v_goleadores_local
    FROM goles g
    LEFT JOIN usuarios u ON u.id = g.jugador_id
    WHERE g.partido_id = p_partido_id
    AND g.equipo_anota = v_partido.equipo_local
    AND g.anulado = false;

    -- Goleadores del equipo visitante
    SELECT json_agg(
        json_build_object(
            'jugador_id', g.jugador_id,
            'jugador_nombre', COALESCE(u.nombre_completo, 'Gol anonimo'),
            'minuto', g.minuto,
            'es_autogol', g.es_autogol
        ) ORDER BY g.minuto ASC
    )
    INTO v_goleadores_visitante
    FROM goles g
    LEFT JOIN usuarios u ON u.id = g.jugador_id
    WHERE g.partido_id = p_partido_id
    AND g.equipo_anota = v_partido.equipo_visitante
    AND g.anulado = false;

    -- Todos los goleadores
    SELECT json_agg(
        json_build_object(
            'jugador_id', g.jugador_id,
            'jugador_nombre', COALESCE(u.nombre_completo, 'Gol anonimo'),
            'equipo', g.equipo_anota,
            'minuto', g.minuto,
            'es_autogol', g.es_autogol
        ) ORDER BY g.minuto ASC, g.created_at ASC
    )
    INTO v_goleadores
    FROM goles g
    LEFT JOIN usuarios u ON u.id = g.jugador_id
    WHERE g.partido_id = p_partido_id
    AND g.anulado = false;

    -- Retorno exitoso
    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'partido_id', p_partido_id,
            'fecha_id', v_partido.fecha_id,
            'estado', v_partido.estado,
            'equipos', json_build_object(
                'local', v_partido.equipo_local,
                'visitante', v_partido.equipo_visitante
            ),
            'marcador', json_build_object(
                'equipo_local', v_partido.equipo_local,
                'goles_local', COALESCE(v_partido.goles_local, 0),
                'equipo_visitante', v_partido.equipo_visitante,
                'goles_visitante', COALESCE(v_partido.goles_visitante, 0)
            ),
            'marcador_texto', UPPER(v_partido.equipo_local::TEXT) || ' ' ||
                             COALESCE(v_partido.goles_local, 0) || ' - ' ||
                             COALESCE(v_partido.goles_visitante, 0) || ' ' ||
                             UPPER(v_partido.equipo_visitante::TEXT),
            'resultado', CASE
                WHEN v_partido.estado = 'finalizado' THEN json_build_object(
                    'codigo', v_partido.resultado,
                    'descripcion', CASE v_partido.resultado
                        WHEN 'local' THEN 'Victoria ' || UPPER(v_partido.equipo_local::TEXT)
                        WHEN 'visitante' THEN 'Victoria ' || UPPER(v_partido.equipo_visitante::TEXT)
                        ELSE 'Empate'
                    END,
                    'es_empate', v_partido.resultado = 'empate'
                )
                ELSE NULL
            END,
            'goleadores', json_build_object(
                'lista_completa', COALESCE(v_goleadores, '[]'::json),
                'equipo_local', COALESCE(v_goleadores_local, '[]'::json),
                'equipo_visitante', COALESCE(v_goleadores_visitante, '[]'::json),
                'total_goles', COALESCE(v_partido.goles_local, 0) + COALESCE(v_partido.goles_visitante, 0)
            ),
            'duracion', json_build_object(
                'programada_minutos', v_partido.duracion_minutos,
                'real_segundos', v_partido.duracion_real_segundos,
                'real_minutos', CASE
                    WHEN v_partido.duracion_real_segundos IS NOT NULL
                    THEN ROUND(v_partido.duracion_real_segundos / 60.0, 1)
                    ELSE NULL
                END,
                'real_formato', CASE
                    WHEN v_partido.duracion_real_segundos IS NOT NULL
                    THEN LPAD((v_partido.duracion_real_segundos / 60)::TEXT, 2, '0') || ':' ||
                         LPAD((v_partido.duracion_real_segundos % 60)::TEXT, 2, '0')
                    ELSE NULL
                END,
                'tiempo_pausado_segundos', v_partido.tiempo_pausado_segundos
            ),
            'tiempos', json_build_object(
                'hora_inicio', v_partido.hora_inicio,
                'hora_inicio_formato', TO_CHAR(v_partido.hora_inicio AT TIME ZONE 'America/Lima', 'HH24:MI:SS'),
                'hora_fin', v_partido.hora_fin,
                'hora_fin_formato', CASE
                    WHEN v_partido.hora_fin IS NOT NULL
                    THEN TO_CHAR(v_partido.hora_fin AT TIME ZONE 'America/Lima', 'HH24:MI:SS')
                    ELSE NULL
                END
            ),
            'finalizacion', CASE
                WHEN v_partido.estado = 'finalizado' THEN json_build_object(
                    'finalizado_por_id', v_partido.finalizado_por,
                    'finalizado_por_nombre', v_partido.finalizado_por_nombre,
                    'finalizado_at', v_partido.finalizado_at,
                    'finalizado_at_formato', TO_CHAR(v_partido.finalizado_at AT TIME ZONE 'America/Lima', 'DD/MM/YYYY HH24:MI:SS')
                )
                ELSE NULL
            END,
            'fecha', json_build_object(
                'id', v_fecha.id,
                'lugar', v_fecha.lugar,
                'num_equipos', v_fecha.num_equipos,
                'fecha_formato', TO_CHAR(v_fecha.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY')
            )
        ),
        'message', CASE
            WHEN v_partido.estado = 'finalizado' THEN
                'Resultado: ' || UPPER(v_partido.equipo_local::TEXT) || ' ' ||
                COALESCE(v_partido.goles_local, 0) || ' - ' ||
                COALESCE(v_partido.goles_visitante, 0) || ' ' ||
                UPPER(v_partido.equipo_visitante::TEXT)
            ELSE
                'Partido ' || v_partido.estado
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
-- PARTE 4: FUNCION RPC obtener_sugerencia_rotacion
-- Para CA-004: Consultar sugerencia de rotacion sin finalizar
-- ============================================

CREATE OR REPLACE FUNCTION obtener_sugerencia_rotacion(
    p_fecha_id UUID
) RETURNS JSON AS $$
DECLARE
    v_error_hint TEXT;
    v_current_user_id UUID;
    v_fecha RECORD;
    v_ultimo_partido RECORD;
    v_equipo_descansando color_equipo;
    v_equipos_en_fecha color_equipo[];
BEGIN
    -- Validacion: Usuario autenticado
    v_current_user_id := auth.uid();

    IF v_current_user_id IS NULL THEN
        v_error_hint := 'no_autenticado';
        RAISE EXCEPTION 'Debes iniciar sesion para realizar esta accion';
    END IF;

    IF p_fecha_id IS NULL THEN
        v_error_hint := 'fecha_id_requerido';
        RAISE EXCEPTION 'El ID de la fecha es obligatorio';
    END IF;

    -- Obtener datos de la fecha
    SELECT id, num_equipos, lugar
    INTO v_fecha
    FROM fechas
    WHERE id = p_fecha_id;

    IF NOT FOUND THEN
        v_error_hint := 'fecha_no_encontrada';
        RAISE EXCEPTION 'Fecha no encontrada';
    END IF;

    -- Solo aplica para 3 equipos
    IF v_fecha.num_equipos != 3 THEN
        RETURN json_build_object(
            'success', true,
            'data', json_build_object(
                'aplica_rotacion', false,
                'razon', 'La rotacion solo aplica para fechas con 3 equipos'
            ),
            'message', 'Esta fecha tiene ' || v_fecha.num_equipos || ' equipos, no aplica rotacion'
        );
    END IF;

    -- Obtener equipos asignados a esta fecha
    SELECT ARRAY_AGG(DISTINCT equipo)
    INTO v_equipos_en_fecha
    FROM asignaciones_equipos
    WHERE fecha_id = p_fecha_id;

    IF v_equipos_en_fecha IS NULL OR array_length(v_equipos_en_fecha, 1) < 3 THEN
        RETURN json_build_object(
            'success', true,
            'data', json_build_object(
                'aplica_rotacion', false,
                'razon', 'No hay suficientes equipos asignados'
            ),
            'message', 'Se necesitan 3 equipos asignados para rotacion'
        );
    END IF;

    -- Obtener ultimo partido finalizado o activo
    SELECT id, equipo_local, equipo_visitante, estado, resultado,
           goles_local, goles_visitante
    INTO v_ultimo_partido
    FROM partidos
    WHERE fecha_id = p_fecha_id
    AND estado IN ('en_curso', 'pausado', 'finalizado')
    ORDER BY created_at DESC
    LIMIT 1;

    IF NOT FOUND THEN
        -- No hay partidos, sugerir primeros dos equipos
        RETURN json_build_object(
            'success', true,
            'data', json_build_object(
                'aplica_rotacion', true,
                'tiene_partido_previo', false,
                'sugerencia', json_build_object(
                    'equipo_local', v_equipos_en_fecha[1],
                    'equipo_visitante', v_equipos_en_fecha[2],
                    'equipo_descansa', v_equipos_en_fecha[3]
                ),
                'sugerencia_texto', UPPER(v_equipos_en_fecha[1]::TEXT) || ' vs ' || UPPER(v_equipos_en_fecha[2]::TEXT),
                'equipos_disponibles', v_equipos_en_fecha
            ),
            'message', 'Sugerencia para primer partido: ' || UPPER(v_equipos_en_fecha[1]::TEXT) || ' vs ' || UPPER(v_equipos_en_fecha[2]::TEXT)
        );
    END IF;

    -- Encontrar equipo que descansa (no jugo en ultimo partido)
    SELECT equipo INTO v_equipo_descansando
    FROM unnest(v_equipos_en_fecha) as equipo
    WHERE equipo NOT IN (v_ultimo_partido.equipo_local, v_ultimo_partido.equipo_visitante)
    LIMIT 1;

    -- Retornar sugerencia de rotacion
    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'aplica_rotacion', true,
            'tiene_partido_previo', true,
            'partido_previo', json_build_object(
                'id', v_ultimo_partido.id,
                'equipo_local', v_ultimo_partido.equipo_local,
                'equipo_visitante', v_ultimo_partido.equipo_visitante,
                'estado', v_ultimo_partido.estado,
                'resultado', v_ultimo_partido.resultado,
                'marcador_texto', UPPER(v_ultimo_partido.equipo_local::TEXT) || ' ' ||
                                 COALESCE(v_ultimo_partido.goles_local, 0) || ' - ' ||
                                 COALESCE(v_ultimo_partido.goles_visitante, 0) || ' ' ||
                                 UPPER(v_ultimo_partido.equipo_visitante::TEXT)
            ),
            'equipo_descansando', v_equipo_descansando,
            'sugerencia', CASE
                WHEN v_ultimo_partido.estado = 'finalizado' THEN
                    json_build_object(
                        'equipo_entra', v_equipo_descansando,
                        'equipo_continua', CASE
                            WHEN v_ultimo_partido.resultado = 'local' THEN v_ultimo_partido.equipo_local
                            WHEN v_ultimo_partido.resultado = 'visitante' THEN v_ultimo_partido.equipo_visitante
                            ELSE v_ultimo_partido.equipo_local
                        END,
                        'equipo_sale', CASE
                            WHEN v_ultimo_partido.resultado = 'local' THEN v_ultimo_partido.equipo_visitante
                            WHEN v_ultimo_partido.resultado = 'visitante' THEN v_ultimo_partido.equipo_local
                            ELSE v_ultimo_partido.equipo_visitante
                        END,
                        'razon', CASE
                            WHEN v_ultimo_partido.resultado = 'empate' THEN 'Empate: el local continua por convencion'
                            ELSE 'El ganador continua'
                        END
                    )
                ELSE
                    json_build_object(
                        'equipo_entra', v_equipo_descansando,
                        'mensaje', 'Esperar a que finalice el partido actual'
                    )
            END,
            'sugerencia_texto', CASE
                WHEN v_ultimo_partido.estado = 'finalizado' THEN
                    UPPER(v_equipo_descansando::TEXT) || ' vs ' ||
                    UPPER((CASE
                        WHEN v_ultimo_partido.resultado = 'local' THEN v_ultimo_partido.equipo_local
                        WHEN v_ultimo_partido.resultado = 'visitante' THEN v_ultimo_partido.equipo_visitante
                        ELSE v_ultimo_partido.equipo_local
                    END)::TEXT)
                ELSE
                    'Partido en curso - esperar finalizacion'
            END,
            'equipos_disponibles', v_equipos_en_fecha
        ),
        'message', CASE
            WHEN v_ultimo_partido.estado = 'finalizado' THEN
                'Siguiente partido sugerido: ' || UPPER(v_equipo_descansando::TEXT) || ' entra a la cancha'
            ELSE
                'Hay un partido ' || v_ultimo_partido.estado || '. ' || UPPER(v_equipo_descansando::TEXT) || ' espera para entrar'
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
-- PARTE 5: PERMISOS
-- ============================================

GRANT EXECUTE ON FUNCTION finalizar_partido TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION obtener_resumen_partido TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION obtener_sugerencia_rotacion TO authenticated, service_role;

-- ============================================
-- PARTE 6: COMENTARIOS DE DOCUMENTACION
-- ============================================

COMMENT ON FUNCTION finalizar_partido IS 'E004-HU-005: Finaliza partido, registra resultado y estadisticas (RN-001 a RN-008, CA-001 a CA-007)';
COMMENT ON FUNCTION obtener_resumen_partido IS 'E004-HU-005: Obtiene resumen de partido (cualquier estado) con goleadores y resultado';
COMMENT ON FUNCTION obtener_sugerencia_rotacion IS 'E004-HU-005: Obtiene sugerencia de rotacion para fechas con 3 equipos (CA-004)';

-- ============================================
-- FIN DEL SCRIPT
-- ============================================
