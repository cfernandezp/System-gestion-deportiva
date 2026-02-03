-- ============================================
-- HU-007: Resumen de Jornada
-- Fecha: 2026-02-02
-- Descripcion: Funcion que retorna el resumen completo de una fecha/jornada
--              incluyendo partidos, tabla de posiciones, goleadores y estadisticas.
-- ============================================
--
-- Ejecutar en: https://supabase.com/dashboard/project/tvvubzkqbksxvcjvivij/sql
--
-- Criterios de Aceptacion:
--   CA-001: Lista de partidos con equipos, marcador, goleadores, duracion, estado
--   CA-002: Tabla de posiciones (PJ, PG, PE, PP, GF, GC, DIF, PTS)
--   CA-003: Ranking de goleadores (solo goles validos, sin autogoles ni anulados)
--   CA-005: Goleador de la fecha (o co-goleadores si hay empate)
--
-- Reglas de Negocio:
--   RN-001: Cualquier usuario inscrito puede ver (sin validacion estricta de permisos)
--   RN-002: Tabla ordenada por: puntos DESC, dif goles DESC, goles favor DESC
--   RN-003: Solo goles validos (no autogoles, no anulados)
--   RN-004: Datos en tiempo real (incluir partidos finalizados y en curso)
--   RN-007: Si no hay partidos, retornar estructura vacia con mensaje
--   RN-008: Sistema de puntos: Victoria=3pts, Empate=1pt, Derrota=0pts
-- ============================================

-- ============================================
-- PASO 1: Eliminar version anterior si existe
-- ============================================
DROP FUNCTION IF EXISTS obtener_resumen_jornada(UUID);

-- ============================================
-- PASO 2: Crear la funcion
-- ============================================
CREATE OR REPLACE FUNCTION obtener_resumen_jornada(
    p_fecha_id UUID
) RETURNS JSON AS $$
DECLARE
    v_fecha RECORD;
    v_partidos JSON;
    v_tabla_posiciones JSON;
    v_goleadores JSON;
    v_goleador_fecha JSON;
    v_estadisticas JSON;
    v_hay_partidos BOOLEAN;
    v_total_partidos INTEGER;
    v_partidos_finalizados INTEGER;
    v_total_goles INTEGER;
    v_promedio_goles NUMERIC(4,2);
    v_partido_mas_goles JSON;
    v_max_goles INTEGER;
    v_error_hint TEXT;
BEGIN
    -- ============================================
    -- Validar que la fecha existe
    -- ============================================
    SELECT * INTO v_fecha
    FROM fechas
    WHERE id = p_fecha_id;

    IF NOT FOUND THEN
        v_error_hint := 'fecha_no_encontrada';
        RAISE EXCEPTION 'Fecha no encontrada: %', p_fecha_id;
    END IF;

    -- ============================================
    -- Contar partidos para validacion RN-007
    -- ============================================
    SELECT COUNT(*) INTO v_total_partidos
    FROM partidos
    WHERE fecha_id = p_fecha_id;

    v_hay_partidos := (v_total_partidos > 0);

    -- ============================================
    -- Si no hay partidos, retornar estructura vacia (RN-007)
    -- ============================================
    IF NOT v_hay_partidos THEN
        RETURN json_build_object(
            'success', true,
            'data', json_build_object(
                'fecha', json_build_object(
                    'id', v_fecha.id,
                    'lugar', v_fecha.lugar,
                    'fecha_programada', v_fecha.fecha_hora_inicio AT TIME ZONE 'America/Lima',
                    'fecha_formato', TO_CHAR(v_fecha.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY HH24:MI'),
                    'estado', v_fecha.estado::text,
                    'num_equipos', v_fecha.num_equipos
                ),
                'partidos', '[]'::json,
                'tabla_posiciones', '[]'::json,
                'goleadores', '[]'::json,
                'goleador_fecha', NULL,
                'estadisticas', json_build_object(
                    'total_partidos', 0,
                    'partidos_finalizados', 0,
                    'total_goles', 0,
                    'promedio_goles_partido', 0,
                    'partido_mas_goles', NULL
                ),
                'hay_partidos', false
            ),
            'message', 'No hay partidos programados para esta fecha'
        );
    END IF;

    -- ============================================
    -- CA-001: Obtener lista de partidos con goleadores
    -- ============================================
    SELECT COALESCE(
        json_agg(
            json_build_object(
                'id', p.id,
                'equipo_local', json_build_object(
                    'color', p.equipo_local::text,
                    'goles', p.goles_local
                ),
                'equipo_visitante', json_build_object(
                    'color', p.equipo_visitante::text,
                    'goles', p.goles_visitante
                ),
                'marcador', p.goles_local || ' - ' || p.goles_visitante,
                'goles_local', p.goles_local,
                'goles_visitante', p.goles_visitante,
                'estado', p.estado::text,
                'duracion_minutos', p.duracion_minutos,
                'hora_inicio', p.hora_inicio AT TIME ZONE 'America/Lima',
                'goleadores', COALESCE(
                    (
                        SELECT json_agg(
                            json_build_object(
                                'jugador_id', g.jugador_id,
                                'jugador_nombre', COALESCE(u.nombre_completo, 'Desconocido'),
                                'equipo', g.equipo_anotador::text,
                                'minuto', g.minuto,
                                'es_autogol', g.es_autogol
                            ) ORDER BY g.minuto
                        )
                        FROM goles g
                        LEFT JOIN usuarios u ON u.id = g.jugador_id
                        WHERE g.partido_id = p.id
                        AND g.anulado = false
                    ),
                    '[]'::json
                )
            ) ORDER BY p.hora_inicio NULLS LAST, p.created_at
        ),
        '[]'::json
    ) INTO v_partidos
    FROM partidos p
    WHERE p.fecha_id = p_fecha_id;

    -- ============================================
    -- CA-002, RN-002, RN-008: Tabla de posiciones
    -- Sistema: Victoria=3pts, Empate=1pt, Derrota=0pts
    -- Ordenado por: puntos DESC, dif goles DESC, goles favor DESC
    -- ============================================
    WITH partidos_finalizados AS (
        -- Solo considerar partidos finalizados para la tabla
        SELECT *
        FROM partidos
        WHERE fecha_id = p_fecha_id
        AND estado = 'finalizado'
    ),
    equipos_fecha AS (
        -- Obtener todos los equipos que participaron en la fecha
        SELECT DISTINCT equipo
        FROM (
            SELECT equipo_local AS equipo FROM partidos WHERE fecha_id = p_fecha_id
            UNION
            SELECT equipo_visitante AS equipo FROM partidos WHERE fecha_id = p_fecha_id
        ) equipos
    ),
    estadisticas_equipo AS (
        SELECT
            e.equipo,
            -- Partidos jugados (finalizados)
            COALESCE((
                SELECT COUNT(*)
                FROM partidos_finalizados p
                WHERE p.equipo_local = e.equipo OR p.equipo_visitante = e.equipo
            ), 0) AS pj,
            -- Partidos ganados
            COALESCE((
                SELECT COUNT(*)
                FROM partidos_finalizados p
                WHERE (p.equipo_local = e.equipo AND p.goles_local > p.goles_visitante)
                   OR (p.equipo_visitante = e.equipo AND p.goles_visitante > p.goles_local)
            ), 0) AS pg,
            -- Partidos empatados
            COALESCE((
                SELECT COUNT(*)
                FROM partidos_finalizados p
                WHERE (p.equipo_local = e.equipo OR p.equipo_visitante = e.equipo)
                  AND p.goles_local = p.goles_visitante
            ), 0) AS pe,
            -- Partidos perdidos
            COALESCE((
                SELECT COUNT(*)
                FROM partidos_finalizados p
                WHERE (p.equipo_local = e.equipo AND p.goles_local < p.goles_visitante)
                   OR (p.equipo_visitante = e.equipo AND p.goles_visitante < p.goles_local)
            ), 0) AS pp,
            -- Goles a favor
            COALESCE((
                SELECT SUM(
                    CASE
                        WHEN p.equipo_local = e.equipo THEN p.goles_local
                        ELSE p.goles_visitante
                    END
                )
                FROM partidos_finalizados p
                WHERE p.equipo_local = e.equipo OR p.equipo_visitante = e.equipo
            ), 0) AS gf,
            -- Goles en contra
            COALESCE((
                SELECT SUM(
                    CASE
                        WHEN p.equipo_local = e.equipo THEN p.goles_visitante
                        ELSE p.goles_local
                    END
                )
                FROM partidos_finalizados p
                WHERE p.equipo_local = e.equipo OR p.equipo_visitante = e.equipo
            ), 0) AS gc
        FROM equipos_fecha e
    ),
    tabla_calculada AS (
        SELECT
            equipo::text AS equipo,
            pj::integer,
            pg::integer,
            pe::integer,
            pp::integer,
            gf::integer,
            gc::integer,
            (gf - gc)::integer AS dif,
            (pg * 3 + pe)::integer AS pts
        FROM estadisticas_equipo
    )
    SELECT COALESCE(
        json_agg(
            json_build_object(
                'equipo', t.equipo,
                'pj', t.pj,
                'pg', t.pg,
                'pe', t.pe,
                'pp', t.pp,
                'gf', t.gf,
                'gc', t.gc,
                'dif', t.dif,
                'pts', t.pts,
                'posicion', row_number
            )
        ),
        '[]'::json
    ) INTO v_tabla_posiciones
    FROM (
        SELECT *,
            ROW_NUMBER() OVER (
                ORDER BY pts DESC, dif DESC, gf DESC, equipo
            ) AS row_number
        FROM tabla_calculada
    ) t;

    -- ============================================
    -- CA-003, RN-003: Ranking de goleadores
    -- Solo goles validos (no autogoles, no anulados)
    -- ============================================
    WITH goles_por_jugador AS (
        SELECT
            g.jugador_id,
            u.nombre_completo AS jugador_nombre,
            g.equipo_anotador::text AS equipo,
            COUNT(*) AS goles
        FROM goles g
        JOIN partidos p ON p.id = g.partido_id
        LEFT JOIN usuarios u ON u.id = g.jugador_id
        WHERE p.fecha_id = p_fecha_id
        AND g.anulado = false
        AND g.es_autogol = false
        AND g.jugador_id IS NOT NULL
        GROUP BY g.jugador_id, u.nombre_completo, g.equipo_anotador
    )
    SELECT COALESCE(
        json_agg(
            json_build_object(
                'jugador_id', jugador_id,
                'jugador_nombre', COALESCE(jugador_nombre, 'Desconocido'),
                'equipo', equipo,
                'goles', goles,
                'posicion', row_number
            )
        ),
        '[]'::json
    ) INTO v_goleadores
    FROM (
        SELECT *,
            ROW_NUMBER() OVER (ORDER BY goles DESC, jugador_nombre) AS row_number
        FROM goles_por_jugador
    ) ranking;

    -- ============================================
    -- CA-005: Goleador de la fecha (o co-goleadores si hay empate)
    -- ============================================
    WITH goles_por_jugador AS (
        SELECT
            g.jugador_id,
            u.nombre_completo AS jugador_nombre,
            g.equipo_anotador::text AS equipo,
            COUNT(*) AS goles
        FROM goles g
        JOIN partidos p ON p.id = g.partido_id
        LEFT JOIN usuarios u ON u.id = g.jugador_id
        WHERE p.fecha_id = p_fecha_id
        AND g.anulado = false
        AND g.es_autogol = false
        AND g.jugador_id IS NOT NULL
        GROUP BY g.jugador_id, u.nombre_completo, g.equipo_anotador
    ),
    max_goles AS (
        SELECT MAX(goles) AS max_goles FROM goles_por_jugador
    )
    SELECT
        CASE
            WHEN (SELECT max_goles FROM max_goles) IS NULL THEN NULL
            ELSE (
                SELECT json_agg(
                    json_build_object(
                        'jugador_id', jugador_id,
                        'jugador_nombre', COALESCE(jugador_nombre, 'Desconocido'),
                        'equipo', equipo,
                        'goles', goles
                    )
                )
                FROM goles_por_jugador
                WHERE goles = (SELECT max_goles FROM max_goles)
            )
        END
    INTO v_goleador_fecha;

    -- ============================================
    -- Estadisticas generales
    -- ============================================

    -- Contar partidos finalizados
    SELECT COUNT(*) INTO v_partidos_finalizados
    FROM partidos
    WHERE fecha_id = p_fecha_id
    AND estado = 'finalizado';

    -- Total de goles (solo de partidos no cancelados)
    SELECT COALESCE(SUM(goles_local + goles_visitante), 0) INTO v_total_goles
    FROM partidos
    WHERE fecha_id = p_fecha_id
    AND estado != 'cancelado';

    -- Promedio de goles por partido (solo partidos con goles posibles)
    IF v_partidos_finalizados > 0 THEN
        SELECT ROUND(
            SUM(goles_local + goles_visitante)::NUMERIC / v_partidos_finalizados,
            2
        ) INTO v_promedio_goles
        FROM partidos
        WHERE fecha_id = p_fecha_id
        AND estado = 'finalizado';
    ELSE
        v_promedio_goles := 0;
    END IF;

    -- Partido con mas goles
    SELECT json_build_object(
        'partido_id', p.id,
        'equipo_local', p.equipo_local::text,
        'equipo_visitante', p.equipo_visitante::text,
        'goles_local', p.goles_local,
        'goles_visitante', p.goles_visitante,
        'total_goles', p.goles_local + p.goles_visitante
    ) INTO v_partido_mas_goles
    FROM partidos p
    WHERE p.fecha_id = p_fecha_id
    AND p.estado != 'cancelado'
    ORDER BY (p.goles_local + p.goles_visitante) DESC, p.created_at
    LIMIT 1;

    -- Construir objeto de estadisticas
    v_estadisticas := json_build_object(
        'total_partidos', v_total_partidos,
        'partidos_finalizados', v_partidos_finalizados,
        'total_goles', v_total_goles,
        'promedio_goles_partido', COALESCE(v_promedio_goles, 0),
        'partido_mas_goles', v_partido_mas_goles
    );

    -- ============================================
    -- Retornar resumen completo
    -- ============================================
    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'fecha', json_build_object(
                'id', v_fecha.id,
                'lugar', v_fecha.lugar,
                'fecha_programada', v_fecha.fecha_hora_inicio AT TIME ZONE 'America/Lima',
                'fecha_formato', TO_CHAR(v_fecha.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY HH24:MI'),
                'estado', v_fecha.estado::text,
                'num_equipos', v_fecha.num_equipos,
                'duracion_horas', v_fecha.duracion_horas,
                'costo_por_jugador', v_fecha.costo_por_jugador
            ),
            'partidos', v_partidos,
            'tabla_posiciones', v_tabla_posiciones,
            'goleadores', v_goleadores,
            'goleador_fecha', v_goleador_fecha,
            'estadisticas', v_estadisticas,
            'hay_partidos', v_hay_partidos
        ),
        'message', 'Resumen de jornada generado'
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
-- PASO 3: Permisos
-- ============================================
GRANT EXECUTE ON FUNCTION obtener_resumen_jornada(UUID) TO anon, authenticated, service_role;

-- ============================================
-- PASO 4: Comentario de documentacion
-- ============================================
COMMENT ON FUNCTION obtener_resumen_jornada IS 'E004-HU-007: Retorna el resumen completo de una fecha/jornada incluyendo partidos, tabla de posiciones, goleadores y estadisticas.';

-- ============================================
-- PASO 5: Query de verificacion
-- ============================================
-- Despues de ejecutar, verificar que la funcion existe:
SELECT
    routine_name,
    routine_type,
    data_type AS return_type
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name = 'obtener_resumen_jornada';

-- ============================================
-- PASO 6: Query de prueba (usar un fecha_id real)
-- ============================================
-- Para probar, ejecutar con un fecha_id existente:
--
-- SELECT obtener_resumen_jornada('tu-fecha-id-aqui'::uuid);
--
-- O obtener una fecha existente primero:
-- SELECT id, lugar, estado FROM fechas LIMIT 5;
-- Luego usar ese ID en la llamada.
