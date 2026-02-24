-- ============================================================
-- E006-HU-004: Resultados por Fecha
-- Fecha: 2026-02-23
-- Descripcion: Dos RPCs para consultar historial de fechas
--              finalizadas y detalle de resultados por fecha.
--
-- RPC 1: obtener_historial_fechas
--   Lista de fechas finalizadas del grupo con info basica.
--   Filtros de anio/mes/solo_mias disponibles para Plan 5+.
--
-- RPC 2: obtener_detalle_fecha_resultados
--   Detalle completo de una fecha: partidos, tabla posiciones,
--   goleadores, asistentes por equipo.
--
-- Criterios de Aceptacion:
--   CA-001: Lista de fechas jugadas (estado='finalizada', orden DESC)
--   CA-002: Seleccionar fecha para ver detalle
--   CA-003: Resultados de partidos (equipos, marcador, estado)
--   CA-004: Tabla de posiciones de la fecha (Plan 5+)
--   CA-005: Goleadores de la fecha (Plan 5+)
--   CA-006: Lista de asistentes agrupados por equipo
--   CA-007: Filtros anio/mes/solo_mias (Plan 5+)
--   CA-008: Sin fechas = array vacio con mensaje
--
-- Reglas de Negocio:
--   RN-001: Solo fechas con estado = 'finalizada'
--   RN-002: Ordenar por fecha_hora_inicio DESC
--   RN-003: Tabla posiciones: PJ, PG, PE, PP, GF, GC, DIF, PTS (PG*3+PE)
--   RN-004: Orden tabla: PTS DESC, DIF DESC, GF DESC
--   RN-005: Goles validos: anulado=false, es_autogol=false, jugador_id NOT NULL
--   RN-006: Goleador fecha = MAX goles, co-goleadores posibles
--   RN-007: Asistentes = inscripcion 'inscrito' + asignacion equipo
--   RN-008: Plan Gratis: basico. Plan 5+: tabla posiciones + goleadores + filtros
-- ============================================================


-- ============================================================
-- RPC 1: obtener_historial_fechas
-- ============================================================

-- Eliminar version anterior si existe
DROP FUNCTION IF EXISTS obtener_historial_fechas(UUID, INTEGER, INTEGER, BOOLEAN);

CREATE OR REPLACE FUNCTION obtener_historial_fechas(
    p_grupo_id UUID,
    p_anio INTEGER DEFAULT NULL,
    p_mes INTEGER DEFAULT NULL,
    p_solo_mias BOOLEAN DEFAULT false
) RETURNS JSONB AS $$
DECLARE
    v_auth_uid UUID;
    v_usuario_id UUID;
    v_miembro_rol TEXT;
    v_stats_avanzadas BOOLEAN;
    v_error_hint TEXT;
    v_fechas JSONB;
    v_filtros JSONB;
    v_total_fechas INTEGER;
BEGIN
    -- ============================================================
    -- 1. Validar autenticacion
    -- ============================================================
    v_auth_uid := auth.uid();

    IF v_auth_uid IS NULL THEN
        v_error_hint := 'no_autenticado';
        RAISE EXCEPTION 'Usuario no autenticado';
    END IF;

    -- ============================================================
    -- 2. Obtener usuario aprobado
    -- ============================================================
    SELECT id
    INTO v_usuario_id
    FROM usuarios
    WHERE auth_user_id = v_auth_uid
      AND estado = 'aprobado';

    IF v_usuario_id IS NULL THEN
        v_error_hint := 'usuario_no_encontrado';
        RAISE EXCEPTION 'Usuario no encontrado o no aprobado';
    END IF;

    -- ============================================================
    -- 3. Validar miembro activo del grupo (invitados SI pueden ver - RN-008)
    -- ============================================================
    SELECT rol::TEXT
    INTO v_miembro_rol
    FROM miembros_grupo
    WHERE grupo_id = p_grupo_id
      AND usuario_id = v_usuario_id
      AND activo = true;

    IF v_miembro_rol IS NULL THEN
        v_error_hint := 'no_miembro_grupo';
        RAISE EXCEPTION 'No eres miembro activo de este grupo';
    END IF;

    -- ============================================================
    -- 4. Verificar plan del grupo (estadisticas_avanzadas)
    -- ============================================================
    SELECT COALESCE(p.estadisticas_avanzadas, false)
    INTO v_stats_avanzadas
    FROM grupos g
    JOIN planes p ON g.plan_id = p.id
    WHERE g.id = p_grupo_id;

    IF v_stats_avanzadas IS NULL THEN
        v_stats_avanzadas := false;
    END IF;

    -- ============================================================
    -- 5. Si no tiene plan avanzado, ignorar filtros (CA-007)
    -- ============================================================
    IF NOT v_stats_avanzadas THEN
        p_anio := NULL;
        p_mes := NULL;
        p_solo_mias := false;
    END IF;

    -- ============================================================
    -- 6. Obtener fechas finalizadas del grupo (RN-001, RN-002)
    --    Filtro grupo: created_by es admin/coadmin del grupo
    -- ============================================================
    WITH admins_grupo AS (
        SELECT usuario_id FROM miembros_grupo
        WHERE grupo_id = p_grupo_id
          AND rol IN ('admin', 'coadmin')
          AND activo = true
    ),
    fechas_grupo AS (
        SELECT
            f.id AS fecha_id,
            f.fecha_hora_inicio,
            f.lugar,
            -- Total asistentes: inscripcion 'inscrito'
            (
                SELECT COUNT(*)
                FROM inscripciones i
                WHERE i.fecha_id = f.id
                  AND i.estado = 'inscrito'
            ) AS total_asistentes,
            -- Total partidos finalizados
            (
                SELECT COUNT(*)
                FROM partidos p
                WHERE p.fecha_id = f.id
                  AND p.estado = 'finalizado'
            ) AS total_partidos
        FROM fechas f
        WHERE f.estado = 'finalizada'
          AND f.created_by IN (SELECT usuario_id FROM admins_grupo)
          -- Filtro anio (CA-007)
          AND (p_anio IS NULL OR EXTRACT(YEAR FROM f.fecha_hora_inicio AT TIME ZONE 'America/Lima') = p_anio)
          -- Filtro mes (CA-007)
          AND (p_mes IS NULL OR EXTRACT(MONTH FROM f.fecha_hora_inicio AT TIME ZONE 'America/Lima') = p_mes)
          -- Filtro solo mis fechas (CA-007)
          AND (
              NOT p_solo_mias
              OR EXISTS (
                  SELECT 1 FROM inscripciones i
                  WHERE i.fecha_id = f.id
                    AND i.usuario_id = v_usuario_id
                    AND i.estado = 'inscrito'
              )
          )
        ORDER BY f.fecha_hora_inicio DESC
    )
    SELECT
        COALESCE(
            jsonb_agg(
                jsonb_build_object(
                    'fecha_id', fg.fecha_id,
                    'fecha_formato', TO_CHAR(fg.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY'),
                    'fecha_hora', TO_CHAR(fg.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'HH24:MI'),
                    'lugar', fg.lugar,
                    'total_asistentes', fg.total_asistentes,
                    'total_partidos', fg.total_partidos
                )
                ORDER BY fg.fecha_hora_inicio DESC
            ),
            '[]'::JSONB
        ),
        COUNT(*)::INTEGER
    INTO v_fechas, v_total_fechas
    FROM fechas_grupo fg;

    -- ============================================================
    -- 7. Construir filtros disponibles (anios y meses con fechas)
    -- ============================================================
    WITH admins_grupo AS (
        SELECT usuario_id FROM miembros_grupo
        WHERE grupo_id = p_grupo_id
          AND rol IN ('admin', 'coadmin')
          AND activo = true
    )
    SELECT jsonb_build_object(
        'anios', COALESCE(
            (
                SELECT jsonb_agg(DISTINCT anio ORDER BY anio DESC)
                FROM (
                    SELECT EXTRACT(YEAR FROM f.fecha_hora_inicio AT TIME ZONE 'America/Lima')::INTEGER AS anio
                    FROM fechas f
                    WHERE f.estado = 'finalizada'
                      AND f.created_by IN (SELECT usuario_id FROM admins_grupo)
                ) sub
            ),
            '[]'::JSONB
        ),
        'meses', COALESCE(
            (
                SELECT jsonb_agg(DISTINCT mes ORDER BY mes ASC)
                FROM (
                    SELECT EXTRACT(MONTH FROM f.fecha_hora_inicio AT TIME ZONE 'America/Lima')::INTEGER AS mes
                    FROM fechas f
                    WHERE f.estado = 'finalizada'
                      AND f.created_by IN (SELECT usuario_id FROM admins_grupo)
                      -- Si hay filtro de anio activo, solo meses de ese anio
                      AND (p_anio IS NULL OR EXTRACT(YEAR FROM f.fecha_hora_inicio AT TIME ZONE 'America/Lima') = p_anio)
                ) sub
            ),
            '[]'::JSONB
        )
    )
    INTO v_filtros;

    -- ============================================================
    -- 8. Retornar respuesta (CA-008: array vacio si no hay)
    -- ============================================================
    RETURN jsonb_build_object(
        'success', true,
        'data', jsonb_build_object(
            'stats_avanzadas', v_stats_avanzadas,
            'fechas', v_fechas,
            'filtros_disponibles', v_filtros
        ),
        'message', CASE
            WHEN v_total_fechas = 0 THEN 'No hay fechas finalizadas aun'
            ELSE v_total_fechas || ' fechas encontradas'
        END
    );

EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', jsonb_build_object(
                'code', SQLSTATE,
                'message', SQLERRM,
                'hint', COALESCE(v_error_hint, 'unknown')
            )
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Permisos
GRANT EXECUTE ON FUNCTION obtener_historial_fechas(UUID, INTEGER, INTEGER, BOOLEAN) TO anon, authenticated, service_role;

-- Comentario
COMMENT ON FUNCTION obtener_historial_fechas IS 'E006-HU-004: Lista fechas finalizadas del grupo con filtros opcionales (anio, mes, solo_mias). Filtros avanzados solo para Plan 5+.';


-- ============================================================
-- RPC 2: obtener_detalle_fecha_resultados
-- ============================================================

-- Eliminar version anterior si existe
DROP FUNCTION IF EXISTS obtener_detalle_fecha_resultados(UUID, UUID);

CREATE OR REPLACE FUNCTION obtener_detalle_fecha_resultados(
    p_fecha_id UUID,
    p_grupo_id UUID
) RETURNS JSONB AS $$
DECLARE
    v_auth_uid UUID;
    v_usuario_id UUID;
    v_miembro_rol TEXT;
    v_stats_avanzadas BOOLEAN;
    v_error_hint TEXT;
    -- Fecha
    v_fecha RECORD;
    v_total_asistentes INTEGER;
    -- Partidos
    v_partidos JSONB;
    -- Tabla posiciones
    v_tabla_posiciones JSONB;
    -- Goleadores
    v_goleadores JSONB;
    -- Asistentes por equipo
    v_asistentes JSONB;
BEGIN
    -- ============================================================
    -- 1. Validar autenticacion
    -- ============================================================
    v_auth_uid := auth.uid();

    IF v_auth_uid IS NULL THEN
        v_error_hint := 'no_autenticado';
        RAISE EXCEPTION 'Usuario no autenticado';
    END IF;

    -- ============================================================
    -- 2. Obtener usuario aprobado
    -- ============================================================
    SELECT id
    INTO v_usuario_id
    FROM usuarios
    WHERE auth_user_id = v_auth_uid
      AND estado = 'aprobado';

    IF v_usuario_id IS NULL THEN
        v_error_hint := 'usuario_no_encontrado';
        RAISE EXCEPTION 'Usuario no encontrado o no aprobado';
    END IF;

    -- ============================================================
    -- 3. Validar miembro activo del grupo (invitados SI pueden ver - RN-008)
    -- ============================================================
    SELECT rol::TEXT
    INTO v_miembro_rol
    FROM miembros_grupo
    WHERE grupo_id = p_grupo_id
      AND usuario_id = v_usuario_id
      AND activo = true;

    IF v_miembro_rol IS NULL THEN
        v_error_hint := 'no_miembro_grupo';
        RAISE EXCEPTION 'No eres miembro activo de este grupo';
    END IF;

    -- ============================================================
    -- 4. Validar que la fecha existe y pertenece al grupo
    --    (created_by es admin/coadmin del grupo)
    -- ============================================================
    SELECT f.id, f.fecha_hora_inicio, f.lugar, f.estado
    INTO v_fecha
    FROM fechas f
    WHERE f.id = p_fecha_id
      AND f.estado = 'finalizada'
      AND f.created_by IN (
          SELECT usuario_id FROM miembros_grupo
          WHERE grupo_id = p_grupo_id
            AND rol IN ('admin', 'coadmin')
            AND activo = true
      );

    IF v_fecha.id IS NULL THEN
        v_error_hint := 'fecha_no_encontrada';
        RAISE EXCEPTION 'Fecha no encontrada, no finalizada, o no pertenece al grupo';
    END IF;

    -- ============================================================
    -- 5. Verificar plan del grupo (estadisticas_avanzadas)
    -- ============================================================
    SELECT COALESCE(p.estadisticas_avanzadas, false)
    INTO v_stats_avanzadas
    FROM grupos g
    JOIN planes p ON g.plan_id = p.id
    WHERE g.id = p_grupo_id;

    IF v_stats_avanzadas IS NULL THEN
        v_stats_avanzadas := false;
    END IF;

    -- ============================================================
    -- 6. Total asistentes (inscripcion 'inscrito')
    -- ============================================================
    SELECT COUNT(*)
    INTO v_total_asistentes
    FROM inscripciones i
    WHERE i.fecha_id = p_fecha_id
      AND i.estado = 'inscrito';

    -- ============================================================
    -- 7. CA-003: Partidos con marcador y estado (todos los planes)
    -- ============================================================
    SELECT COALESCE(
        jsonb_agg(
            jsonb_build_object(
                'partido_id', p.id,
                'equipo_local', p.equipo_local::TEXT,
                'equipo_visitante', p.equipo_visitante::TEXT,
                'goles_local', p.goles_local,
                'goles_visitante', p.goles_visitante,
                'estado', p.estado::TEXT
            )
            ORDER BY p.hora_inicio NULLS LAST, p.created_at
        ),
        '[]'::JSONB
    )
    INTO v_partidos
    FROM partidos p
    WHERE p.fecha_id = p_fecha_id;

    -- ============================================================
    -- 8. CA-004 / RN-003 / RN-004: Tabla de posiciones (Plan 5+)
    --    PJ, PG, PE, PP, GF, GC, DIF, PTS
    --    Orden: PTS DESC, DIF DESC, GF DESC
    -- ============================================================
    IF v_stats_avanzadas THEN
        WITH partidos_finalizados AS (
            SELECT *
            FROM partidos
            WHERE fecha_id = p_fecha_id
              AND estado = 'finalizado'
        ),
        equipos_fecha AS (
            SELECT DISTINCT equipo
            FROM (
                SELECT equipo_local AS equipo FROM partidos WHERE fecha_id = p_fecha_id
                UNION
                SELECT equipo_visitante AS equipo FROM partidos WHERE fecha_id = p_fecha_id
            ) eq
        ),
        estadisticas_equipo AS (
            SELECT
                e.equipo,
                -- PJ
                COALESCE((
                    SELECT COUNT(*)
                    FROM partidos_finalizados pf
                    WHERE pf.equipo_local = e.equipo OR pf.equipo_visitante = e.equipo
                ), 0) AS pj,
                -- PG
                COALESCE((
                    SELECT COUNT(*)
                    FROM partidos_finalizados pf
                    WHERE (pf.equipo_local = e.equipo AND pf.goles_local > pf.goles_visitante)
                       OR (pf.equipo_visitante = e.equipo AND pf.goles_visitante > pf.goles_local)
                ), 0) AS pg,
                -- PE
                COALESCE((
                    SELECT COUNT(*)
                    FROM partidos_finalizados pf
                    WHERE (pf.equipo_local = e.equipo OR pf.equipo_visitante = e.equipo)
                      AND pf.goles_local = pf.goles_visitante
                ), 0) AS pe,
                -- PP
                COALESCE((
                    SELECT COUNT(*)
                    FROM partidos_finalizados pf
                    WHERE (pf.equipo_local = e.equipo AND pf.goles_local < pf.goles_visitante)
                       OR (pf.equipo_visitante = e.equipo AND pf.goles_visitante < pf.goles_local)
                ), 0) AS pp,
                -- GF
                COALESCE((
                    SELECT SUM(
                        CASE
                            WHEN pf.equipo_local = e.equipo THEN pf.goles_local
                            ELSE pf.goles_visitante
                        END
                    )
                    FROM partidos_finalizados pf
                    WHERE pf.equipo_local = e.equipo OR pf.equipo_visitante = e.equipo
                ), 0) AS gf,
                -- GC
                COALESCE((
                    SELECT SUM(
                        CASE
                            WHEN pf.equipo_local = e.equipo THEN pf.goles_visitante
                            ELSE pf.goles_local
                        END
                    )
                    FROM partidos_finalizados pf
                    WHERE pf.equipo_local = e.equipo OR pf.equipo_visitante = e.equipo
                ), 0) AS gc
            FROM equipos_fecha e
        ),
        tabla_calculada AS (
            SELECT
                equipo::TEXT,
                pj::INTEGER,
                pg::INTEGER,
                pe::INTEGER,
                pp::INTEGER,
                gf::INTEGER,
                gc::INTEGER,
                (gf - gc)::INTEGER AS dif,
                (pg * 3 + pe)::INTEGER AS pts
            FROM estadisticas_equipo
        ),
        tabla_con_posicion AS (
            SELECT
                ROW_NUMBER() OVER (
                    ORDER BY pts DESC, dif DESC, gf DESC, equipo
                )::INTEGER AS posicion,
                equipo, pj, pg, pe, pp, gf, gc, dif, pts
            FROM tabla_calculada
        )
        SELECT COALESCE(
            jsonb_agg(
                jsonb_build_object(
                    'posicion', t.posicion,
                    'equipo', t.equipo,
                    'pj', t.pj,
                    'pg', t.pg,
                    'pe', t.pe,
                    'pp', t.pp,
                    'gf', t.gf,
                    'gc', t.gc,
                    'dif', t.dif,
                    'pts', t.pts
                )
                ORDER BY t.posicion
            ),
            '[]'::JSONB
        )
        INTO v_tabla_posiciones
        FROM tabla_con_posicion t;

    ELSE
        v_tabla_posiciones := NULL;
    END IF;

    -- ============================================================
    -- 9. CA-005 / RN-005 / RN-006: Goleadores de la fecha (Plan 5+)
    --    Solo goles validos, con maximo goleador destacado
    -- ============================================================
    IF v_stats_avanzadas THEN
        WITH goles_por_jugador AS (
            SELECT
                g.jugador_id,
                u.nombre_completo AS nombre,
                u.apodo,
                COUNT(*) AS goles
            FROM goles g
            JOIN partidos p ON p.id = g.partido_id
            LEFT JOIN usuarios u ON u.id = g.jugador_id
            WHERE p.fecha_id = p_fecha_id
              AND g.anulado = false
              AND g.es_autogol = false
              AND g.jugador_id IS NOT NULL
            GROUP BY g.jugador_id, u.nombre_completo, u.apodo
        ),
        max_goles AS (
            SELECT MAX(goles) AS max_val FROM goles_por_jugador
        )
        SELECT COALESCE(
            jsonb_agg(
                jsonb_build_object(
                    'jugador_id', gpj.jugador_id,
                    'nombre', COALESCE(gpj.nombre, 'Desconocido'),
                    'apodo', gpj.apodo,
                    'goles', gpj.goles,
                    'es_maximo_goleador', (gpj.goles = (SELECT max_val FROM max_goles))
                )
                ORDER BY gpj.goles DESC, gpj.nombre
            ),
            '[]'::JSONB
        )
        INTO v_goleadores
        FROM goles_por_jugador gpj;

    ELSE
        v_goleadores := NULL;
    END IF;

    -- ============================================================
    -- 10. CA-006 / RN-007: Asistentes agrupados por equipo (todos los planes)
    --     Inscripcion 'inscrito' + asignacion equipo
    --     Sin equipo = 'sin_equipo'
    -- ============================================================
    WITH asistentes_con_equipo AS (
        SELECT
            i.usuario_id AS jugador_id,
            u.nombre_completo AS nombre,
            u.apodo,
            COALESCE(ae.color_equipo::TEXT, 'sin_equipo') AS equipo,
            -- Goles del jugador en esta fecha (validos, no autogol)
            COALESCE((
                SELECT COUNT(*)
                FROM goles g
                JOIN partidos p ON g.partido_id = p.id
                WHERE g.jugador_id = i.usuario_id
                  AND p.fecha_id = p_fecha_id
                  AND g.anulado = false
                  AND g.es_autogol = false
            ), 0) AS goles
        FROM inscripciones i
        JOIN usuarios u ON u.id = i.usuario_id
        LEFT JOIN (
            -- Ultima asignacion de equipo por jugador en la fecha
            SELECT DISTINCT ON (ae2.usuario_id)
                ae2.usuario_id,
                ae2.color_equipo
            FROM asignaciones_equipos ae2
            WHERE ae2.fecha_id = p_fecha_id
            ORDER BY ae2.usuario_id, ae2.updated_at DESC
        ) ae ON ae.usuario_id = i.usuario_id
        WHERE i.fecha_id = p_fecha_id
          AND i.estado = 'inscrito'
    ),
    equipos_agrupados AS (
        SELECT
            ace.equipo,
            jsonb_agg(
                jsonb_build_object(
                    'jugador_id', ace.jugador_id,
                    'nombre', COALESCE(ace.nombre, 'Desconocido'),
                    'apodo', ace.apodo,
                    'goles', ace.goles
                )
                ORDER BY ace.goles DESC, ace.nombre
            ) AS jugadores
        FROM asistentes_con_equipo ace
        GROUP BY ace.equipo
    )
    SELECT COALESCE(
        jsonb_agg(
            jsonb_build_object(
                'equipo', ea.equipo,
                'jugadores', ea.jugadores
            )
            -- Poner equipos con color primero, 'sin_equipo' al final
            ORDER BY CASE WHEN ea.equipo = 'sin_equipo' THEN 1 ELSE 0 END, ea.equipo
        ),
        '[]'::JSONB
    )
    INTO v_asistentes
    FROM equipos_agrupados ea;

    -- ============================================================
    -- 11. Construir y retornar respuesta
    -- ============================================================
    RETURN jsonb_build_object(
        'success', true,
        'data', jsonb_build_object(
            'stats_avanzadas', v_stats_avanzadas,
            'fecha', jsonb_build_object(
                'fecha_id', v_fecha.id,
                'fecha_formato', TO_CHAR(v_fecha.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY'),
                'fecha_hora', TO_CHAR(v_fecha.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'HH24:MI'),
                'lugar', v_fecha.lugar,
                'total_asistentes', v_total_asistentes
            ),
            'partidos', v_partidos,
            'tabla_posiciones', v_tabla_posiciones,
            'goleadores', v_goleadores,
            'asistentes_por_equipo', v_asistentes
        ),
        'message', 'Resultados de la fecha'
    );

EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', jsonb_build_object(
                'code', SQLSTATE,
                'message', SQLERRM,
                'hint', COALESCE(v_error_hint, 'unknown')
            )
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Permisos
GRANT EXECUTE ON FUNCTION obtener_detalle_fecha_resultados(UUID, UUID) TO anon, authenticated, service_role;

-- Comentario
COMMENT ON FUNCTION obtener_detalle_fecha_resultados IS 'E006-HU-004: Detalle completo de una fecha finalizada con partidos, tabla de posiciones, goleadores y asistentes por equipo. Tabla y goleadores solo para Plan 5+.';


-- ============================================================
-- Verificacion: Confirmar que ambas funciones existen
-- ============================================================
SELECT
    routine_name,
    routine_type,
    data_type AS return_type
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name IN ('obtener_historial_fechas', 'obtener_detalle_fecha_resultados');
