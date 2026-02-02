-- ============================================
-- FUNCION: listar_partidos_fecha
-- Fecha: 2026-02-02
-- Descripcion: Retorna la lista de todos los partidos de una fecha
--              con informacion completa de equipos, marcadores y resultados.
-- ============================================
--
-- Ejecutar en: https://supabase.com/dashboard/project/tvvubzkqbksxvcjvivij/sql
--
-- Retorna:
--   - Lista de partidos con estado, equipos, goles, tiempos
--   - Total de partidos
--   - Flag puede_crear_partido (true si fecha en_juego y no hay partido activo)
--   - Para partidos finalizados: resultado textual (Gano X / Empate)
-- ============================================

-- ============================================
-- PASO 1: Eliminar version anterior si existe
-- ============================================
DROP FUNCTION IF EXISTS listar_partidos_fecha(UUID);

-- ============================================
-- PASO 2: Crear la funcion
-- ============================================
CREATE OR REPLACE FUNCTION listar_partidos_fecha(
    p_fecha_id UUID
) RETURNS JSON AS $$
DECLARE
    v_fecha RECORD;
    v_partidos JSON;
    v_total INTEGER;
    v_tiene_partido_activo BOOLEAN;
    v_puede_crear_partido BOOLEAN;
    v_error_hint TEXT;
BEGIN
    -- Validar que la fecha existe
    SELECT * INTO v_fecha
    FROM fechas
    WHERE id = p_fecha_id;

    IF NOT FOUND THEN
        v_error_hint := 'fecha_no_encontrada';
        RAISE EXCEPTION 'Fecha no encontrada: %', p_fecha_id;
    END IF;

    -- Verificar si hay partido activo (en_curso o pausado)
    SELECT EXISTS (
        SELECT 1 FROM partidos
        WHERE fecha_id = p_fecha_id
        AND estado IN ('en_curso', 'pausado')
    ) INTO v_tiene_partido_activo;

    -- Puede crear partido si: fecha en_juego Y no hay partido activo
    v_puede_crear_partido := (v_fecha.estado = 'en_juego' AND NOT v_tiene_partido_activo);

    -- Obtener total de partidos
    SELECT COUNT(*) INTO v_total
    FROM partidos
    WHERE fecha_id = p_fecha_id;

    -- Obtener lista de partidos con toda la informacion
    SELECT COALESCE(
        json_agg(
            json_build_object(
                'id', p.id,
                'estado', p.estado::text,
                'equipo_local', json_build_object(
                    'color', p.equipo_local::text,
                    'nombre', INITCAP(p.equipo_local::text)
                ),
                'equipo_visitante', json_build_object(
                    'color', p.equipo_visitante::text,
                    'nombre', INITCAP(p.equipo_visitante::text)
                ),
                'goles_local', p.goles_local,
                'goles_visitante', p.goles_visitante,
                'duracion_minutos', p.duracion_minutos,
                'hora_inicio', CASE
                    WHEN p.hora_inicio IS NOT NULL THEN
                        TO_CHAR(p.hora_inicio AT TIME ZONE 'America/Lima', 'HH24:MI')
                    ELSE NULL
                END,
                'hora_fin_estimada', CASE
                    WHEN p.hora_fin_estimada IS NOT NULL THEN
                        TO_CHAR(p.hora_fin_estimada AT TIME ZONE 'America/Lima', 'HH24:MI')
                    ELSE NULL
                END,
                'created_at', TO_CHAR(p.created_at AT TIME ZONE 'America/Lima', 'DD/MM/YYYY HH24:MI'),
                'resultado', CASE
                    WHEN p.estado = 'finalizado' THEN
                        CASE
                            WHEN p.goles_local > p.goles_visitante THEN
                                'Gano ' || INITCAP(p.equipo_local::text)
                            WHEN p.goles_visitante > p.goles_local THEN
                                'Gano ' || INITCAP(p.equipo_visitante::text)
                            ELSE
                                'Empate'
                        END
                    ELSE NULL
                END
            )
            ORDER BY p.created_at DESC
        ),
        '[]'::json
    ) INTO v_partidos
    FROM partidos p
    WHERE p.fecha_id = p_fecha_id;

    -- Retornar resultado exitoso
    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'partidos', v_partidos,
            'total', v_total,
            'puede_crear_partido', v_puede_crear_partido
        ),
        'message', CASE
            WHEN v_total = 0 THEN 'No hay partidos registrados en esta fecha'
            WHEN v_total = 1 THEN '1 partido encontrado'
            ELSE v_total || ' partidos encontrados'
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
GRANT EXECUTE ON FUNCTION listar_partidos_fecha(UUID) TO anon, authenticated, service_role;

-- Comentario
COMMENT ON FUNCTION listar_partidos_fecha IS 'Lista todos los partidos de una fecha con informacion completa de equipos, marcadores, tiempos y resultados. Ordenados por created_at DESC.';


-- ============================================
-- VERIFICACION
-- ============================================
-- Ejecuta esto para verificar que la funcion se creo correctamente:

SELECT
    routine_name as funcion,
    routine_type as tipo,
    (SELECT string_agg(parameter_name || ' ' || data_type, ', ' ORDER BY ordinal_position)
     FROM information_schema.parameters p
     WHERE p.specific_name = r.specific_name
     AND p.parameter_mode = 'IN') as parametros
FROM information_schema.routines r
WHERE routine_schema = 'public'
AND routine_name = 'listar_partidos_fecha';


-- ============================================
-- EJEMPLO DE USO
-- ============================================
--
-- SELECT listar_partidos_fecha('uuid-de-la-fecha');
--
-- Respuesta exitosa:
-- {
--   "success": true,
--   "data": {
--     "partidos": [
--       {
--         "id": "uuid-partido",
--         "estado": "finalizado",
--         "equipo_local": {"color": "naranja", "nombre": "Naranja"},
--         "equipo_visitante": {"color": "verde", "nombre": "Verde"},
--         "goles_local": 2,
--         "goles_visitante": 1,
--         "duracion_minutos": 10,
--         "hora_inicio": "15:30",
--         "hora_fin_estimada": "15:40",
--         "created_at": "02/02/2026 15:30",
--         "resultado": "Gano Naranja"
--       },
--       {
--         "id": "uuid-partido-2",
--         "estado": "en_curso",
--         "equipo_local": {"color": "azul", "nombre": "Azul"},
--         "equipo_visitante": {"color": "rojo", "nombre": "Rojo"},
--         "goles_local": 0,
--         "goles_visitante": 0,
--         "duracion_minutos": 10,
--         "hora_inicio": "15:45",
--         "hora_fin_estimada": "15:55",
--         "created_at": "02/02/2026 15:45",
--         "resultado": null
--       }
--     ],
--     "total": 2,
--     "puede_crear_partido": false
--   },
--   "message": "2 partidos encontrados"
-- }
--
-- ============================================
-- FIN DEL SCRIPT
-- ============================================
