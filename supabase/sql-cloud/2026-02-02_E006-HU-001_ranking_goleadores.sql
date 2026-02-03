-- ============================================
-- E006-HU-001: Ranking de Goleadores
-- Fecha: 2026-02-02
-- Descripcion: Funcion RPC para obtener el ranking de goleadores
--              con filtros por periodo de tiempo
-- ============================================

-- Funcion: obtener_ranking_goleadores
-- Reglas: RN-001, RN-002, RN-003, RN-004, RN-005
-- CA: CA-001, CA-002, CA-003, CA-004, CA-007
CREATE OR REPLACE FUNCTION obtener_ranking_goleadores(
    p_periodo TEXT DEFAULT 'historico'
) RETURNS JSON AS $$
DECLARE
    v_error_hint TEXT;
    v_fecha_inicio TIMESTAMPTZ;
    v_ultima_fecha_id UUID;
    v_ranking JSON;
    v_total_jugadores INTEGER;
BEGIN
    -- =============================================
    -- Validar parametro p_periodo
    -- =============================================
    IF p_periodo NOT IN ('historico', 'este_ano', 'este_mes', 'ultima_fecha') THEN
        v_error_hint := 'periodo_invalido';
        RAISE EXCEPTION 'Periodo invalido. Valores permitidos: historico, este_ano, este_mes, ultima_fecha';
    END IF;

    -- =============================================
    -- RN-005: Calcular fecha de inicio segun periodo
    -- Zona horaria Peru (America/Lima)
    -- =============================================
    CASE p_periodo
        WHEN 'historico' THEN
            -- Sin filtro de fecha
            v_fecha_inicio := NULL;

        WHEN 'este_ano' THEN
            -- Desde 1 de enero del ano actual (hora Peru)
            v_fecha_inicio := date_trunc('year', NOW() AT TIME ZONE 'America/Lima') AT TIME ZONE 'America/Lima';

        WHEN 'este_mes' THEN
            -- Desde 1 del mes actual (hora Peru)
            v_fecha_inicio := date_trunc('month', NOW() AT TIME ZONE 'America/Lima') AT TIME ZONE 'America/Lima';

        WHEN 'ultima_fecha' THEN
            -- Obtener la fecha finalizada mas reciente
            SELECT f.id INTO v_ultima_fecha_id
            FROM fechas f
            WHERE f.estado = 'finalizada'
            ORDER BY f.fecha_hora_inicio DESC
            LIMIT 1;

            IF v_ultima_fecha_id IS NULL THEN
                -- No hay fechas finalizadas
                RETURN json_build_object(
                    'success', true,
                    'data', json_build_object(
                        'periodo', p_periodo,
                        'ranking', '[]'::json,
                        'total_jugadores', 0,
                        'mensaje', 'No hay fechas finalizadas'
                    ),
                    'message', 'No hay fechas finalizadas para mostrar ranking'
                );
            END IF;
    END CASE;

    -- =============================================
    -- Construir ranking con CTE
    -- RN-001: Solo goles validos (anulado=false, es_autogol=false, jugador_id NOT NULL)
    -- RN-002: Solo fechas con estado='finalizada'
    -- RN-003: Desempate: goles DESC, partidos ASC, created_at ASC
    -- RN-004: Partidos jugados = donde jugador tenia equipo asignado y equipo participo
    -- =============================================
    WITH fechas_filtradas AS (
        -- Fechas finalizadas que cumplen el filtro de periodo
        SELECT f.id, f.fecha_hora_inicio
        FROM fechas f
        WHERE f.estado = 'finalizada'
          AND (
              -- Historico: sin filtro
              (p_periodo = 'historico')
              -- Este ano/mes: filtrar por fecha_hora_inicio
              OR (p_periodo IN ('este_ano', 'este_mes') AND f.fecha_hora_inicio >= v_fecha_inicio)
              -- Ultima fecha: solo la fecha especifica
              OR (p_periodo = 'ultima_fecha' AND f.id = v_ultima_fecha_id)
          )
    ),
    goles_validos AS (
        -- RN-001: Goles validos para el ranking
        SELECT
            g.jugador_id,
            COUNT(*) AS total_goles
        FROM goles g
        INNER JOIN partidos p ON g.partido_id = p.id
        INNER JOIN fechas_filtradas ff ON p.fecha_id = ff.id
        WHERE g.anulado = false
          AND g.es_autogol = false
          AND g.jugador_id IS NOT NULL
        GROUP BY g.jugador_id
    ),
    partidos_jugados AS (
        -- RN-004: Contar partidos donde el jugador participo
        -- El jugador debe tener asignacion de equipo en la fecha
        -- Y su equipo debe haber participado en el partido (como local o visitante)
        -- Y el partido debe estar finalizado
        SELECT
            ae.usuario_id AS jugador_id,
            COUNT(DISTINCT p.id) AS total_partidos
        FROM asignaciones_equipos ae
        INNER JOIN fechas_filtradas ff ON ae.fecha_id = ff.id
        INNER JOIN partidos p ON p.fecha_id = ff.id
            AND p.estado = 'finalizado'
            AND (
                (ae.color_equipo = p.equipo_local)
                OR (ae.color_equipo = p.equipo_visitante)
            )
        GROUP BY ae.usuario_id
    ),
    ranking_calculado AS (
        SELECT
            u.id AS jugador_id,
            u.apodo,
            u.foto_url AS avatar_url,
            COALESCE(gv.total_goles, 0) AS goles,
            COALESCE(pj.total_partidos, 0) AS partidos_jugados,
            CASE
                WHEN COALESCE(pj.total_partidos, 0) > 0
                THEN ROUND(COALESCE(gv.total_goles, 0)::NUMERIC / pj.total_partidos, 2)
                ELSE 0.00
            END AS promedio,
            u.created_at
        FROM goles_validos gv
        INNER JOIN usuarios u ON gv.jugador_id = u.id
        LEFT JOIN partidos_jugados pj ON gv.jugador_id = pj.jugador_id
        WHERE gv.total_goles > 0
    ),
    ranking_ordenado AS (
        -- RN-003: Ordenar por goles DESC, partidos ASC, created_at ASC
        SELECT
            ROW_NUMBER() OVER (
                ORDER BY goles DESC, partidos_jugados ASC, created_at ASC
            ) AS posicion,
            jugador_id,
            apodo,
            avatar_url,
            goles,
            partidos_jugados,
            promedio
        FROM ranking_calculado
    )
    SELECT
        json_agg(
            json_build_object(
                'posicion', posicion,
                'jugador_id', jugador_id,
                'apodo', COALESCE(apodo, 'Sin apodo'),
                'avatar_url', avatar_url,
                'goles', goles,
                'partidos_jugados', partidos_jugados,
                'promedio', promedio
            ) ORDER BY posicion
        ),
        COUNT(*)::INTEGER
    INTO v_ranking, v_total_jugadores
    FROM ranking_ordenado;

    -- CA-007: Si no hay goles, retornar array vacio con mensaje
    IF v_ranking IS NULL OR v_total_jugadores = 0 THEN
        RETURN json_build_object(
            'success', true,
            'data', json_build_object(
                'periodo', p_periodo,
                'ranking', '[]'::json,
                'total_jugadores', 0,
                'mensaje', 'No hay goles registrados en este periodo'
            ),
            'message', 'No hay goles registrados en el periodo seleccionado'
        );
    END IF;

    -- Retorno exitoso
    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'periodo', p_periodo,
            'ranking', v_ranking,
            'total_jugadores', v_total_jugadores
        ),
        'message', 'Ranking de goleadores obtenido exitosamente'
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

-- Permisos: accesible para usuarios autenticados (RN-006)
GRANT EXECUTE ON FUNCTION obtener_ranking_goleadores TO anon, authenticated, service_role;

-- Comentario descriptivo
COMMENT ON FUNCTION obtener_ranking_goleadores IS 'E006-HU-001: Obtiene el ranking de goleadores filtrado por periodo (historico, este_ano, este_mes, ultima_fecha)';
