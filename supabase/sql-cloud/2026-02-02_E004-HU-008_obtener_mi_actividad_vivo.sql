-- ============================================
-- HU-008: Mi Actividad en Vivo
-- Fecha: 2026-02-02
-- Descripcion: Funcion que retorna la actividad del jugador actual en una pichanga activa,
--              incluyendo su equipo, goles totales, partidos de la jornada y detalle de sus goles.
-- ============================================
--
-- Ejecutar en: https://supabase.com/dashboard/project/tvvubzkqbksxvcjvivij/sql
--
-- Criterios de Aceptacion:
--   CA-001: Widget visible solo cuando hay pichanga activa donde estoy inscrito
--   CA-002: Muestra nombre pichanga, mi equipo asignado, mis goles totales
--   CA-003: Lista todos los partidos ordenados: en_curso, finalizados DESC, pendientes
--   CA-004: Partidos donde participe resaltados (es_mi_partido = true)
--   CA-005: Partidos donde NO participe visibles (es_mi_partido = false)
--   CA-006: Mis goles totales de la jornada
--   CA-007: Detalle de mis goles por partido (minuto)
--   CA-010: Si no hay pichanga activa, retornar pichanga_activa = null
--
-- Reglas de Negocio:
--   RN-001: Pichanga activa = estado='en_juego' AND inscripcion con estado='inscrito'
--   RN-002: Es mi partido si mi color_equipo = equipo_local O equipo_visitante
--   RN-003: Solo contar goles validos (anulado=false) y NO autogoles (es_autogol=false)
--   RN-004: Orden de partidos: en_curso primero, finalizados por hora_fin DESC, pendientes al final
--   RN-009: Mostrar solo MIS goles, no los de otros jugadores
-- ============================================

-- ============================================
-- PASO 1: Eliminar version anterior si existe
-- ============================================
DROP FUNCTION IF EXISTS obtener_mi_actividad_vivo();

-- ============================================
-- PASO 2: Crear la funcion
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
    -- ============================================
    v_usuario_id := auth.uid();

    IF v_usuario_id IS NULL THEN
        v_error_hint := 'no_autenticado';
        RAISE EXCEPTION 'Usuario no autenticado';
    END IF;

    -- ============================================
    -- RN-001: Buscar pichanga activa donde estoy inscrito
    -- estado='en_juego' AND inscripcion con estado='inscrito'
    -- Si hay multiples, tomar la mas reciente
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

    -- ============================================
    -- CA-010: Si no hay pichanga activa, retornar null
    -- ============================================
    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', true,
            'data', json_build_object(
                'pichanga_activa', NULL,
                'mensaje', 'No hay pichanga activa donde estes inscrito'
            ),
            'message', 'Sin actividad'
        );
    END IF;

    -- ============================================
    -- Obtener mi equipo asignado (color_equipo)
    -- ============================================
    SELECT
        ae.color_equipo,
        ae.numero_equipo
    INTO v_mi_equipo
    FROM asignaciones_equipos ae
    WHERE ae.fecha_id = v_fecha_activa.id
    AND ae.usuario_id = v_usuario_id
    LIMIT 1;

    -- ============================================
    -- CA-006 / RN-003: Calcular mis goles totales de la jornada
    -- Solo goles validos (anulado=false) y NO autogoles (es_autogol=false)
    -- ============================================
    SELECT COALESCE(COUNT(*), 0)
    INTO v_mis_goles_totales
    FROM goles g
    INNER JOIN partidos p ON p.id = g.partido_id
    WHERE p.fecha_id = v_fecha_activa.id
    AND g.jugador_id = v_usuario_id
    AND g.anulado = false
    AND g.es_autogol = false;

    -- ============================================
    -- CA-003, CA-004, CA-005, CA-007, RN-002, RN-004:
    -- Lista de todos los partidos de la jornada
    -- Ordenados: en_curso primero, finalizados DESC, pendientes al final
    -- Para cada partido: es_mi_partido, mis_goles, mis_goles_detalle
    -- ============================================
    SELECT COALESCE(
        json_agg(
            json_build_object(
                'partido_id', p.id,
                'equipo_local', p.equipo_local::text,
                'equipo_visitante', p.equipo_visitante::text,
                'goles_local', p.goles_local,
                'goles_visitante', p.goles_visitante,
                'estado', p.estado::text,
                'minuto_actual', p.minuto_actual,
                'hora_inicio', p.hora_inicio AT TIME ZONE 'America/Lima',
                'hora_fin', p.hora_fin AT TIME ZONE 'America/Lima',
                -- RN-002: Es mi partido si mi color_equipo coincide con equipo_local O equipo_visitante
                'es_mi_partido', CASE
                    WHEN v_mi_equipo.color_equipo IS NOT NULL AND
                         (p.equipo_local::text = v_mi_equipo.color_equipo::text OR
                          p.equipo_visitante::text = v_mi_equipo.color_equipo::text)
                    THEN true
                    ELSE false
                END,
                -- CA-007: Contar mis goles en este partido especifico
                'mis_goles', COALESCE((
                    SELECT COUNT(*)
                    FROM goles g
                    WHERE g.partido_id = p.id
                    AND g.jugador_id = v_usuario_id
                    AND g.anulado = false
                    AND g.es_autogol = false
                ), 0),
                -- CA-007: Detalle de mis goles por partido (minuto)
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
                -- RN-004: Orden logico
                CASE WHEN p.estado = 'en_curso' THEN 1
                     WHEN p.estado = 'finalizado' THEN 2
                     ELSE 3
                END,
                p.hora_fin DESC NULLS LAST,
                p.hora_inicio NULLS LAST,
                p.created_at
        ),
        '[]'::json
    ) INTO v_partidos
    FROM partidos p
    WHERE p.fecha_id = v_fecha_activa.id;

    -- ============================================
    -- Identificar partido en curso (si existe)
    -- ============================================
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

    -- ============================================
    -- Retornar actividad completa
    -- ============================================
    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            -- CA-002: Informacion de la pichanga activa
            'pichanga_activa', json_build_object(
                'fecha_id', v_fecha_activa.id,
                'fecha', TO_CHAR(v_fecha_activa.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY'),
                'fecha_hora', TO_CHAR(v_fecha_activa.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY HH24:MI'),
                'lugar', v_fecha_activa.lugar,
                'estado', v_fecha_activa.estado::text,
                'iniciado_at', v_fecha_activa.iniciado_at AT TIME ZONE 'America/Lima'
            ),
            -- CA-002: Mi equipo asignado
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
            -- CA-006: Mis goles totales
            'mis_goles_totales', v_mis_goles_totales,
            -- CA-003, CA-004, CA-005, CA-007: Lista de partidos
            'partidos', v_partidos,
            -- Partido en curso (si existe)
            'partido_en_curso', v_partido_en_curso
        ),
        'message', 'Actividad en vivo obtenida'
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
COMMENT ON FUNCTION obtener_mi_actividad_vivo IS 'E004-HU-008: Retorna la actividad en vivo del jugador actual incluyendo su equipo, goles totales, partidos de la jornada y detalle de sus goles. Solo funciona si hay pichanga activa donde el usuario esta inscrito.';

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

-- ============================================
-- PASO 6: Query de prueba
-- ============================================
-- Para probar, ejecutar estando autenticado:
--
-- SELECT obtener_mi_actividad_vivo();
--
-- Asegurate de:
-- 1. Estar autenticado como usuario con inscripcion activa
-- 2. Tener una fecha con estado='en_juego'
-- 3. Tener inscripcion con estado='inscrito' en esa fecha
-- 4. (Opcional) Tener equipo asignado en asignaciones_equipos
