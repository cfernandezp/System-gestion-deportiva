-- ============================================
-- FIX: obtener_mi_actividad_vivo() - Buscar en TODOS los estados
-- Fecha: 2026-02-22
-- Descripcion: Reescribe la funcion para buscar pichangas en todos los estados
--              del ciclo de vida, no solo en_juego. Prioridad:
--              1. en_juego (logica actual completa sin cambios)
--              2. proxima pichanga (abierta/cerrada futura con inscripcion)
--              3. ultima finalizada (< 24 horas con inscripcion)
--              4. sin_actividad
-- ============================================
--
-- Ejecutar en: https://supabase.com/dashboard/project/tvvubzkqbksxvcjvivij/sql
--

-- ============================================
-- PASO 1: Eliminar version anterior
-- ============================================
DROP FUNCTION IF EXISTS obtener_mi_actividad_vivo();

-- ============================================
-- PASO 2: Crear la funcion reescrita
-- ============================================
CREATE OR REPLACE FUNCTION obtener_mi_actividad_vivo()
RETURNS JSON AS $$
DECLARE
    v_usuario_id UUID;
    v_fecha_activa RECORD;
    v_mi_equipo RECORD;
    v_mis_goles_totales INTEGER;
    v_partidos JSON;
    v_partido_en_curso JSON;
    v_proxima_fecha RECORD;
    v_finalizada_fecha RECORD;
    v_horas_desde_fin NUMERIC;
    v_total_inscritos INTEGER;
    v_error_hint TEXT;
    v_colores_hex CONSTANT JSON := '{
        "naranja": "#FF9800",
        "verde": "#4CAF50",
        "azul": "#2196F3",
        "rojo": "#F44336",
        "amarillo": "#FFEB3B",
        "blanco": "#FFFFFF"
    }'::JSON;
BEGIN
    -- ============================================
    -- Obtener usuario autenticado
    -- IMPORTANTE: auth.uid() devuelve el ID de auth.users,
    -- pero las inscripciones usan el ID de la tabla usuarios.
    -- Debemos mapear auth_user_id -> usuario_id
    -- ============================================
    IF auth.uid() IS NULL THEN
        v_error_hint := 'no_autenticado';
        RAISE EXCEPTION 'Usuario no autenticado';
    END IF;

    -- Obtener el usuario_id de la tabla usuarios basado en auth_user_id
    SELECT id INTO v_usuario_id
    FROM usuarios
    WHERE auth_user_id = auth.uid();

    IF v_usuario_id IS NULL THEN
        v_error_hint := 'usuario_no_encontrado';
        RAISE EXCEPTION 'Usuario no encontrado en tabla usuarios';
    END IF;

    -- ============================================
    -- PRIORIDAD 1: Pichanga EN VIVO (en_juego)
    -- Logica IDENTICA a la version original
    -- ============================================
    SELECT f.*
    INTO v_fecha_activa
    FROM fechas f
    INNER JOIN inscripciones i ON i.fecha_id = f.id
    WHERE f.estado = 'en_juego'
    AND i.usuario_id = v_usuario_id
    AND i.estado = 'inscrito'
    ORDER BY f.fecha_hora_inicio DESC
    LIMIT 1;

    IF FOUND THEN
        -- ============================================
        -- LOGICA EN VIVO: Equipo, goles, partidos, partido_en_curso
        -- (sin cambios respecto a la version original)
        -- ============================================

        -- Obtener mi equipo asignado (color_equipo)
        SELECT
            ae.color_equipo,
            ae.numero_equipo
        INTO v_mi_equipo
        FROM asignaciones_equipos ae
        WHERE ae.fecha_id = v_fecha_activa.id
        AND ae.usuario_id = v_usuario_id
        LIMIT 1;

        -- Calcular mis goles totales de la jornada
        -- Solo goles validos (anulado=false) y NO autogoles (es_autogol=false)
        SELECT COALESCE(COUNT(*), 0)
        INTO v_mis_goles_totales
        FROM goles g
        INNER JOIN partidos p ON p.id = g.partido_id
        WHERE p.fecha_id = v_fecha_activa.id
        AND g.jugador_id = v_usuario_id
        AND g.anulado = false
        AND g.es_autogol = false;

        -- Lista de todos los partidos de la jornada
        -- Ordenados: en_curso primero, finalizados DESC, pendientes al final
        -- Para cada partido: es_mi_partido, mis_goles, mis_goles_detalle
        SELECT COALESCE(
            json_agg(
                json_build_object(
                    'partido_id', p.id,
                    'equipo_local', p.equipo_local::text,
                    'equipo_visitante', p.equipo_visitante::text,
                    'goles_local', p.goles_local,
                    'goles_visitante', p.goles_visitante,
                    'estado', p.estado::text,
                    'duracion_minutos', p.duracion_minutos,
                    'tiempo_pausado_segundos', p.tiempo_pausado_segundos,
                    'hora_inicio', p.hora_inicio AT TIME ZONE 'America/Lima',
                    'hora_fin_estimada', p.hora_fin_estimada AT TIME ZONE 'America/Lima',
                    -- Es mi partido si mi color_equipo coincide con equipo_local O equipo_visitante
                    'es_mi_partido', CASE
                        WHEN v_mi_equipo.color_equipo IS NOT NULL AND
                             (p.equipo_local::text = v_mi_equipo.color_equipo::text OR
                              p.equipo_visitante::text = v_mi_equipo.color_equipo::text)
                        THEN true
                        ELSE false
                    END,
                    -- Contar mis goles en este partido especifico
                    'mis_goles', COALESCE((
                        SELECT COUNT(*)
                        FROM goles g
                        WHERE g.partido_id = p.id
                        AND g.jugador_id = v_usuario_id
                        AND g.anulado = false
                        AND g.es_autogol = false
                    ), 0),
                    -- Detalle de mis goles por partido (minuto)
                    'mis_goles_detalle', COALESCE((
                        SELECT json_agg(
                            json_build_object(
                                'minuto', g.minuto,
                                'es_autogol', g.es_autogol
                            ) ORDER BY g.minuto
                        )
                        FROM goles g
                        WHERE g.partido_id = p.id
                        AND g.jugador_id = v_usuario_id
                        AND g.anulado = false
                    ), '[]'::json)
                ) ORDER BY
                    -- Orden logico: en_curso primero, finalizados DESC, pendientes al final
                    CASE WHEN p.estado = 'en_curso' THEN 1
                         WHEN p.estado = 'finalizado' THEN 2
                         ELSE 3
                    END,
                    p.hora_fin_estimada DESC NULLS LAST,
                    p.hora_inicio NULLS LAST,
                    p.created_at
            ),
            '[]'::json
        ) INTO v_partidos
        FROM partidos p
        WHERE p.fecha_id = v_fecha_activa.id;

        -- Identificar partido en curso (si existe)
        SELECT json_build_object(
            'partido_id', p.id,
            'estoy_jugando', CASE
                WHEN v_mi_equipo.color_equipo IS NOT NULL AND
                     (p.equipo_local::text = v_mi_equipo.color_equipo::text OR
                      p.equipo_visitante::text = v_mi_equipo.color_equipo::text)
                THEN true
                ELSE false
            END
        ) INTO v_partido_en_curso
        FROM partidos p
        WHERE p.fecha_id = v_fecha_activa.id
        AND p.estado = 'en_curso'
        ORDER BY p.hora_inicio DESC NULLS LAST
        LIMIT 1;

        -- Retornar actividad EN VIVO
        RETURN json_build_object(
            'success', true,
            'data', json_build_object(
                'tipo_actividad', 'en_vivo',
                -- Informacion de la pichanga activa
                'pichanga_activa', json_build_object(
                    'fecha_id', v_fecha_activa.id,
                    'fecha', TO_CHAR(v_fecha_activa.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY'),
                    'fecha_hora', TO_CHAR(v_fecha_activa.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY HH24:MI'),
                    'lugar', v_fecha_activa.lugar,
                    'estado', v_fecha_activa.estado::text,
                    'iniciado_at', v_fecha_activa.iniciado_at AT TIME ZONE 'America/Lima'
                ),
                -- Mi equipo asignado
                'mi_equipo', CASE
                    WHEN v_mi_equipo.color_equipo IS NOT NULL THEN
                        json_build_object(
                            'color', v_mi_equipo.color_equipo::text,
                            'color_hex', COALESCE(
                                (v_colores_hex->>v_mi_equipo.color_equipo::text),
                                '#CCCCCC'
                            ),
                            'numero', v_mi_equipo.numero_equipo
                        )
                    ELSE NULL
                END,
                -- Mis goles totales
                'mis_goles_totales', v_mis_goles_totales,
                -- Lista de partidos
                'partidos', v_partidos,
                -- Partido en curso (si existe)
                'partido_en_curso', v_partido_en_curso,
                -- Campos nuevos en null para este tipo
                'proxima_pichanga', NULL,
                'pichanga_finalizada', NULL,
                'mensaje', NULL
            ),
            'message', 'Actividad en vivo obtenida'
        );
    END IF;

    -- ============================================
    -- PRIORIDAD 2: Proxima pichanga (abierta/cerrada futura)
    -- Solo si el jugador tiene inscripcion con estado = 'inscrito'
    -- Ordenar por fecha_hora_inicio ASC, tomar la mas proxima
    -- ============================================
    SELECT f.*
    INTO v_proxima_fecha
    FROM fechas f
    INNER JOIN inscripciones i ON i.fecha_id = f.id
    WHERE f.estado IN ('abierta', 'cerrada')
    AND f.fecha_hora_inicio > NOW()
    AND i.usuario_id = v_usuario_id
    AND i.estado = 'inscrito'
    ORDER BY f.fecha_hora_inicio ASC
    LIMIT 1;

    IF FOUND THEN
        -- Contar total de inscritos en esta pichanga
        SELECT COUNT(*)
        INTO v_total_inscritos
        FROM inscripciones i
        WHERE i.fecha_id = v_proxima_fecha.id
        AND i.estado = 'inscrito';

        -- Retornar proxima pichanga
        RETURN json_build_object(
            'success', true,
            'data', json_build_object(
                'tipo_actividad', 'proxima',
                -- Campos de en_vivo en null
                'pichanga_activa', NULL,
                'mi_equipo', NULL,
                'mis_goles_totales', NULL,
                'partidos', NULL,
                'partido_en_curso', NULL,
                -- Datos de la proxima pichanga
                'proxima_pichanga', json_build_object(
                    'fecha_id', v_proxima_fecha.id,
                    'fecha', TO_CHAR(v_proxima_fecha.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY'),
                    'fecha_hora', TO_CHAR(v_proxima_fecha.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'YYYY-MM-DD"T"HH24:MI:SS"-05:00"'),
                    'lugar', v_proxima_fecha.lugar,
                    'costo_formato', 'S/ ' || TO_CHAR(v_proxima_fecha.costo_por_jugador, 'FM999,999,990.00'),
                    'num_equipos', v_proxima_fecha.num_equipos,
                    'total_inscritos', v_total_inscritos,
                    'estado', v_proxima_fecha.estado::text,
                    'mi_inscripcion', 'inscrito'
                ),
                'pichanga_finalizada', NULL,
                'mensaje', NULL
            ),
            'message', 'Proxima pichanga encontrada'
        );
    END IF;

    -- ============================================
    -- PRIORIDAD 3: Ultima pichanga finalizada (< 24 horas)
    -- Solo si el jugador tiene inscripcion con estado = 'inscrito'
    -- Ordenar por finalizado_at DESC, tomar la mas reciente
    -- ============================================
    SELECT f.*
    INTO v_finalizada_fecha
    FROM fechas f
    INNER JOIN inscripciones i ON i.fecha_id = f.id
    WHERE f.estado = 'finalizada'
    AND f.finalizado_at IS NOT NULL
    AND f.finalizado_at >= (NOW() - INTERVAL '24 hours')
    AND i.usuario_id = v_usuario_id
    AND i.estado = 'inscrito'
    ORDER BY f.finalizado_at DESC
    LIMIT 1;

    IF FOUND THEN
        -- Calcular horas desde que finalizo
        v_horas_desde_fin := EXTRACT(EPOCH FROM (NOW() - v_finalizada_fecha.finalizado_at)) / 3600.0;

        -- Obtener mi equipo en esa pichanga
        SELECT
            ae.color_equipo,
            ae.numero_equipo
        INTO v_mi_equipo
        FROM asignaciones_equipos ae
        WHERE ae.fecha_id = v_finalizada_fecha.id
        AND ae.usuario_id = v_usuario_id
        LIMIT 1;

        -- Calcular mis goles en esa pichanga
        SELECT COALESCE(COUNT(*), 0)
        INTO v_mis_goles_totales
        FROM goles g
        INNER JOIN partidos p ON p.id = g.partido_id
        WHERE p.fecha_id = v_finalizada_fecha.id
        AND g.jugador_id = v_usuario_id
        AND g.anulado = false
        AND g.es_autogol = false;

        -- Retornar pichanga finalizada
        RETURN json_build_object(
            'success', true,
            'data', json_build_object(
                'tipo_actividad', 'finalizada',
                -- Campos de en_vivo en null
                'pichanga_activa', NULL,
                'mi_equipo', NULL,
                'mis_goles_totales', NULL,
                'partidos', NULL,
                'partido_en_curso', NULL,
                'proxima_pichanga', NULL,
                -- Datos de la pichanga finalizada
                'pichanga_finalizada', json_build_object(
                    'fecha_id', v_finalizada_fecha.id,
                    'fecha', TO_CHAR(v_finalizada_fecha.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY'),
                    'fecha_hora', TO_CHAR(v_finalizada_fecha.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'YYYY-MM-DD"T"HH24:MI:SS"-05:00"'),
                    'lugar', v_finalizada_fecha.lugar,
                    'mi_equipo_color', CASE
                        WHEN v_mi_equipo.color_equipo IS NOT NULL THEN v_mi_equipo.color_equipo::text
                        ELSE NULL
                    END,
                    'mi_equipo_numero', CASE
                        WHEN v_mi_equipo.numero_equipo IS NOT NULL THEN v_mi_equipo.numero_equipo
                        ELSE NULL
                    END,
                    'mis_goles', v_mis_goles_totales,
                    'total_partidos', (
                        SELECT COUNT(*)
                        FROM partidos p
                        WHERE p.fecha_id = v_finalizada_fecha.id
                    ),
                    'finalizada_hace_horas', ROUND(v_horas_desde_fin)
                ),
                'mensaje', NULL
            ),
            'message', 'Ultima pichanga finalizada encontrada'
        );
    END IF;

    -- ============================================
    -- PRIORIDAD 4: Sin actividad
    -- No hay pichanga en ningun estado relevante
    -- ============================================
    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'tipo_actividad', 'sin_actividad',
            'pichanga_activa', NULL,
            'mi_equipo', NULL,
            'mis_goles_totales', NULL,
            'partidos', NULL,
            'partido_en_curso', NULL,
            'proxima_pichanga', NULL,
            'pichanga_finalizada', NULL,
            'mensaje', 'No hay pichanga activa, proxima ni reciente donde estes inscrito'
        ),
        'message', 'Sin actividad'
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
GRANT EXECUTE ON FUNCTION obtener_mi_actividad_vivo() TO anon, authenticated, service_role;

-- ============================================
-- PASO 4: Comentario de documentacion
-- ============================================
COMMENT ON FUNCTION obtener_mi_actividad_vivo IS 'E004-HU-008: Retorna la actividad del jugador en todos los estados del ciclo de vida. Prioridad: 1) en_vivo (en_juego), 2) proxima (abierta/cerrada futura), 3) finalizada (<24h), 4) sin_actividad. El campo tipo_actividad indica al frontend que renderizar.';

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
AND routine_name = 'obtener_mi_actividad_vivo';
