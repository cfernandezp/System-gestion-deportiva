-- ============================================================
-- E006-HU-003: Mis Estadisticas - Dashboard Personal
-- Fecha: 2026-02-23
-- Descripcion: RPC que retorna estadisticas personales del jugador
--              logueado dentro de un grupo especifico.
--
-- Criterios de Aceptacion:
--   CA-001: Acceso a mis estadisticas
--   CA-002: Metricas principales (goles, fechas, partidos, puntos)
--   CA-003: Posicion en rankings (Plan 5+)
--   CA-004: Promedio de goles + comparativa grupo (Plan 5+)
--   CA-005: Historial por fecha (Plan 5+)
--   CA-006: Mejor fecha destacada (Plan 5+)
--   CA-007: Racha de asistencia (Plan 5+)
--   CA-008: Sin datos = mensaje informativo
--
-- Reglas de Negocio:
--   RN-001: Solo datos del usuario logueado
--   RN-002: Solo fechas finalizadas
--   RN-003: Goles validos (anulado=false, es_autogol=false)
--   RN-004: Puntos: Victoria=3, Empate=1, Derrota=0
--   RN-005: Fechas asistidas = inscripcion 'inscrito' + fecha finalizada
--   RN-006: Partidos jugados = equipo asignado que participo + finalizado
--   RN-007: Posicion en ranking con RANK()
--   RN-008: Mejor fecha: mas goles > equipo campeon > mas reciente
--   RN-009: Stats avanzadas segun plan del grupo
-- ============================================================

-- Eliminar version anterior si existe
DROP FUNCTION IF EXISTS obtener_mis_estadisticas(UUID);

CREATE OR REPLACE FUNCTION obtener_mis_estadisticas(
    p_grupo_id UUID
) RETURNS JSONB AS $$
DECLARE
    v_auth_uid UUID;
    v_usuario_id UUID;
    v_usuario_nombre TEXT;
    v_usuario_apodo TEXT;
    v_usuario_foto TEXT;
    v_miembro_rol TEXT;
    v_stats_avanzadas BOOLEAN;
    v_error_hint TEXT;
    -- Metricas basicas
    v_goles_totales INTEGER;
    v_fechas_asistidas INTEGER;
    v_partidos_jugados INTEGER;
    v_puntos_acumulados INTEGER;
    -- Avanzadas
    v_ranking_goleadores JSONB;
    v_ranking_puntos JSONB;
    v_promedio JSONB;
    v_racha_asistencia INTEGER;
    v_mejor_fecha JSONB;
    v_historial JSONB;
    v_tiene_datos BOOLEAN;
    -- Promedio
    v_mi_promedio NUMERIC(6,2);
    v_promedio_grupo NUMERIC(6,2);
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
    -- 2. Obtener datos del usuario (RN-001)
    -- ============================================================
    SELECT id, nombre_completo, apodo, foto_url
    INTO v_usuario_id, v_usuario_nombre, v_usuario_apodo, v_usuario_foto
    FROM usuarios
    WHERE auth_user_id = v_auth_uid
      AND estado = 'aprobado';

    IF v_usuario_id IS NULL THEN
        v_error_hint := 'usuario_no_encontrado';
        RAISE EXCEPTION 'Usuario no encontrado o no aprobado';
    END IF;

    -- ============================================================
    -- 3. Validar miembro activo del grupo + bloquear invitados (RN-009)
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

    IF v_miembro_rol = 'invitado' THEN
        v_error_hint := 'invitado_sin_acceso';
        RAISE EXCEPTION 'Los invitados no tienen acceso a estadisticas';
    END IF;

    -- ============================================================
    -- 4. Verificar plan del grupo (estadisticas_avanzadas)
    -- ============================================================
    SELECT p.estadisticas_avanzadas
    INTO v_stats_avanzadas
    FROM grupos g
    JOIN planes p ON g.plan_id = p.id
    WHERE g.id = p_grupo_id;

    IF v_stats_avanzadas IS NULL THEN
        v_stats_avanzadas := false;
    END IF;

    -- ============================================================
    -- 5. Metricas basicas (todos los planes)
    --    Filtro por grupo: fechas creadas por admin/coadmin del grupo
    -- ============================================================

    -- RN-003: Goles totales (validos, no autogol, fechas finalizadas del grupo)
    SELECT COALESCE(COUNT(*), 0)
    INTO v_goles_totales
    FROM goles g
    JOIN partidos p ON g.partido_id = p.id
    JOIN fechas f ON p.fecha_id = f.id
    WHERE g.jugador_id = v_usuario_id
      AND g.anulado = false
      AND g.es_autogol = false
      AND f.estado = 'finalizada'
      AND f.created_by IN (
          SELECT usuario_id FROM miembros_grupo
          WHERE grupo_id = p_grupo_id
            AND rol IN ('admin', 'coadmin')
            AND activo = true
      );

    -- RN-005: Fechas asistidas (inscripcion 'inscrito' + fecha finalizada)
    SELECT COALESCE(COUNT(DISTINCT i.fecha_id), 0)
    INTO v_fechas_asistidas
    FROM inscripciones i
    JOIN fechas f ON i.fecha_id = f.id
    WHERE i.usuario_id = v_usuario_id
      AND i.estado = 'inscrito'
      AND f.estado = 'finalizada'
      AND f.created_by IN (
          SELECT usuario_id FROM miembros_grupo
          WHERE grupo_id = p_grupo_id
            AND rol IN ('admin', 'coadmin')
            AND activo = true
      );

    -- RN-006: Partidos jugados (equipo asignado que participo, partido finalizado)
    SELECT COALESCE(COUNT(DISTINCT p.id), 0)
    INTO v_partidos_jugados
    FROM asignaciones_equipos ae
    JOIN fechas f ON ae.fecha_id = f.id
    JOIN partidos p ON p.fecha_id = f.id
        AND p.estado = 'finalizado'
        AND (ae.color_equipo = p.equipo_local OR ae.color_equipo = p.equipo_visitante)
    WHERE ae.usuario_id = v_usuario_id
      AND f.estado = 'finalizada'
      AND f.created_by IN (
          SELECT usuario_id FROM miembros_grupo
          WHERE grupo_id = p_grupo_id
            AND rol IN ('admin', 'coadmin')
            AND activo = true
      );

    -- RN-004: Puntos acumulados (Victoria=3, Empate=1, Derrota=0)
    SELECT COALESCE(SUM(
        CASE
            WHEN (ae.color_equipo = p.equipo_local AND p.goles_local > p.goles_visitante)
              OR (ae.color_equipo = p.equipo_visitante AND p.goles_visitante > p.goles_local)
            THEN 3
            WHEN p.goles_local = p.goles_visitante
            THEN 1
            ELSE 0
        END
    ), 0)
    INTO v_puntos_acumulados
    FROM asignaciones_equipos ae
    JOIN fechas f ON ae.fecha_id = f.id
    JOIN partidos p ON p.fecha_id = f.id
        AND p.estado = 'finalizado'
        AND (ae.color_equipo = p.equipo_local OR ae.color_equipo = p.equipo_visitante)
    WHERE ae.usuario_id = v_usuario_id
      AND f.estado = 'finalizada'
      AND f.created_by IN (
          SELECT usuario_id FROM miembros_grupo
          WHERE grupo_id = p_grupo_id
            AND rol IN ('admin', 'coadmin')
            AND activo = true
      );

    -- Determinar si tiene datos
    v_tiene_datos := (v_goles_totales > 0 OR v_fechas_asistidas > 0 OR v_partidos_jugados > 0);

    -- ============================================================
    -- 6. Stats avanzadas (solo Plan 5+)
    -- ============================================================
    IF v_stats_avanzadas AND v_tiene_datos THEN

        -- ========================================
        -- CA-003 / RN-007: Rankings con RANK()
        -- ========================================

        -- Ranking de goleadores en el grupo
        WITH admins_grupo AS (
            SELECT usuario_id FROM miembros_grupo
            WHERE grupo_id = p_grupo_id
              AND rol IN ('admin', 'coadmin')
              AND activo = true
        ),
        goles_grupo AS (
            SELECT
                g.jugador_id,
                COUNT(*) AS total_goles
            FROM goles g
            JOIN partidos p ON g.partido_id = p.id
            JOIN fechas f ON p.fecha_id = f.id
            WHERE g.anulado = false
              AND g.es_autogol = false
              AND g.jugador_id IS NOT NULL
              AND f.estado = 'finalizada'
              AND f.created_by IN (SELECT usuario_id FROM admins_grupo)
            GROUP BY g.jugador_id
        ),
        ranking AS (
            SELECT
                jugador_id,
                total_goles,
                RANK() OVER (ORDER BY total_goles DESC) AS posicion
            FROM goles_grupo
        )
        SELECT jsonb_build_object(
            'posicion', COALESCE((SELECT r.posicion FROM ranking r WHERE r.jugador_id = v_usuario_id), NULL),
            'total', (SELECT COUNT(*) FROM ranking)
        )
        INTO v_ranking_goleadores;

        -- Ranking de puntos en el grupo
        WITH admins_grupo AS (
            SELECT usuario_id FROM miembros_grupo
            WHERE grupo_id = p_grupo_id
              AND rol IN ('admin', 'coadmin')
              AND activo = true
        ),
        puntos_grupo AS (
            SELECT
                ae.usuario_id AS jugador_id,
                SUM(
                    CASE
                        WHEN (ae.color_equipo = p.equipo_local AND p.goles_local > p.goles_visitante)
                          OR (ae.color_equipo = p.equipo_visitante AND p.goles_visitante > p.goles_local)
                        THEN 3
                        WHEN p.goles_local = p.goles_visitante
                        THEN 1
                        ELSE 0
                    END
                ) AS total_puntos
            FROM asignaciones_equipos ae
            JOIN fechas f ON ae.fecha_id = f.id
            JOIN partidos p ON p.fecha_id = f.id
                AND p.estado = 'finalizado'
                AND (ae.color_equipo = p.equipo_local OR ae.color_equipo = p.equipo_visitante)
            WHERE f.estado = 'finalizada'
              AND f.created_by IN (SELECT usuario_id FROM admins_grupo)
            GROUP BY ae.usuario_id
        ),
        ranking AS (
            SELECT
                jugador_id,
                total_puntos,
                RANK() OVER (ORDER BY total_puntos DESC) AS posicion
            FROM puntos_grupo
        )
        SELECT jsonb_build_object(
            'posicion', COALESCE((SELECT r.posicion FROM ranking r WHERE r.jugador_id = v_usuario_id), NULL),
            'total', (SELECT COUNT(*) FROM ranking)
        )
        INTO v_ranking_puntos;

        -- ========================================
        -- CA-004: Promedio de goles + comparativa grupo
        -- ========================================

        -- Mi promedio
        IF v_partidos_jugados > 0 THEN
            v_mi_promedio := ROUND(v_goles_totales::NUMERIC / v_partidos_jugados, 2);
        ELSE
            v_mi_promedio := 0.00;
        END IF;

        -- Promedio del grupo
        WITH admins_grupo AS (
            SELECT usuario_id FROM miembros_grupo
            WHERE grupo_id = p_grupo_id
              AND rol IN ('admin', 'coadmin')
              AND activo = true
        ),
        jugadores_stats AS (
            SELECT
                ae.usuario_id,
                COUNT(DISTINCT p.id) AS partidos,
                COALESCE((
                    SELECT COUNT(*)
                    FROM goles g2
                    JOIN partidos p2 ON g2.partido_id = p2.id
                    JOIN fechas f2 ON p2.fecha_id = f2.id
                    WHERE g2.jugador_id = ae.usuario_id
                      AND g2.anulado = false
                      AND g2.es_autogol = false
                      AND f2.estado = 'finalizada'
                      AND f2.created_by IN (SELECT usuario_id FROM admins_grupo)
                ), 0) AS goles
            FROM asignaciones_equipos ae
            JOIN fechas f ON ae.fecha_id = f.id
            JOIN partidos p ON p.fecha_id = f.id
                AND p.estado = 'finalizado'
                AND (ae.color_equipo = p.equipo_local OR ae.color_equipo = p.equipo_visitante)
            WHERE f.estado = 'finalizada'
              AND f.created_by IN (SELECT usuario_id FROM admins_grupo)
            GROUP BY ae.usuario_id
            HAVING COUNT(DISTINCT p.id) > 0
        )
        SELECT COALESCE(
            ROUND(SUM(goles)::NUMERIC / NULLIF(SUM(partidos), 0), 2),
            0.00
        )
        INTO v_promedio_grupo
        FROM jugadores_stats;

        v_promedio := jsonb_build_object(
            'goles_por_partido', v_mi_promedio,
            'promedio_grupo', COALESCE(v_promedio_grupo, 0.00)
        );

        -- ========================================
        -- CA-007: Racha de asistencia
        -- ========================================
        WITH admins_grupo AS (
            SELECT usuario_id FROM miembros_grupo
            WHERE grupo_id = p_grupo_id
              AND rol IN ('admin', 'coadmin')
              AND activo = true
        ),
        fechas_grupo_ordenadas AS (
            SELECT
                f.id AS fecha_id,
                f.fecha_hora_inicio,
                ROW_NUMBER() OVER (ORDER BY f.fecha_hora_inicio DESC) AS rn
            FROM fechas f
            WHERE f.estado = 'finalizada'
              AND f.created_by IN (SELECT usuario_id FROM admins_grupo)
        ),
        asistencias AS (
            SELECT
                fgo.rn,
                CASE WHEN i.id IS NOT NULL THEN true ELSE false END AS asistio
            FROM fechas_grupo_ordenadas fgo
            LEFT JOIN inscripciones i ON i.fecha_id = fgo.fecha_id
                AND i.usuario_id = v_usuario_id
                AND i.estado = 'inscrito'
            ORDER BY fgo.rn
        ),
        primera_falta AS (
            SELECT MIN(rn) AS rn_falta
            FROM asistencias
            WHERE asistio = false
        )
        SELECT COALESCE(
            CASE
                WHEN (SELECT rn_falta FROM primera_falta) IS NULL
                THEN (SELECT COUNT(*) FROM asistencias WHERE asistio = true)
                WHEN (SELECT rn_falta FROM primera_falta) = 1
                THEN 0
                ELSE (SELECT rn_falta - 1 FROM primera_falta)
            END,
            0
        )
        INTO v_racha_asistencia;

        -- ========================================
        -- CA-006 / RN-008: Mejor fecha
        -- ========================================
        WITH admins_grupo AS (
            SELECT usuario_id FROM miembros_grupo
            WHERE grupo_id = p_grupo_id
              AND rol IN ('admin', 'coadmin')
              AND activo = true
        ),
        mis_fechas AS (
            SELECT DISTINCT f.id AS fecha_id, f.fecha_hora_inicio, f.lugar
            FROM inscripciones i
            JOIN fechas f ON i.fecha_id = f.id
            WHERE i.usuario_id = v_usuario_id
              AND i.estado = 'inscrito'
              AND f.estado = 'finalizada'
              AND f.created_by IN (SELECT usuario_id FROM admins_grupo)
        ),
        goles_por_fecha AS (
            SELECT
                mf.fecha_id,
                COALESCE(COUNT(g.id), 0) AS mis_goles
            FROM mis_fechas mf
            LEFT JOIN partidos p ON p.fecha_id = mf.fecha_id
            LEFT JOIN goles g ON g.partido_id = p.id
                AND g.jugador_id = v_usuario_id
                AND g.anulado = false
                AND g.es_autogol = false
            GROUP BY mf.fecha_id
        ),
        mi_equipo_por_fecha AS (
            SELECT DISTINCT ON (ae.fecha_id)
                ae.fecha_id,
                ae.color_equipo
            FROM asignaciones_equipos ae
            WHERE ae.usuario_id = v_usuario_id
              AND ae.fecha_id IN (SELECT fecha_id FROM mis_fechas)
            ORDER BY ae.fecha_id, ae.created_at DESC
        ),
        posicion_equipo_por_fecha AS (
            SELECT
                mef.fecha_id,
                mef.color_equipo,
                (
                    SELECT pos FROM (
                        SELECT
                            eq_color,
                            ROW_NUMBER() OVER (ORDER BY pts DESC, dif DESC) AS pos
                        FROM (
                            SELECT
                                eq.eq_color,
                                COALESCE(SUM(CASE
                                    WHEN (eq.eq_color = pf.equipo_local AND pf.goles_local > pf.goles_visitante)
                                      OR (eq.eq_color = pf.equipo_visitante AND pf.goles_visitante > pf.goles_local)
                                    THEN 3
                                    WHEN pf.goles_local = pf.goles_visitante THEN 1
                                    ELSE 0
                                END), 0) AS pts,
                                COALESCE(SUM(CASE
                                    WHEN eq.eq_color = pf.equipo_local THEN pf.goles_local - pf.goles_visitante
                                    ELSE pf.goles_visitante - pf.goles_local
                                END), 0) AS dif
                            FROM (
                                SELECT DISTINCT equipo_local AS eq_color FROM partidos WHERE fecha_id = mef.fecha_id
                                UNION
                                SELECT DISTINCT equipo_visitante FROM partidos WHERE fecha_id = mef.fecha_id
                            ) eq
                            LEFT JOIN partidos pf ON (eq.eq_color = pf.equipo_local OR eq.eq_color = pf.equipo_visitante)
                                AND pf.fecha_id = mef.fecha_id
                                AND pf.estado = 'finalizado'
                            GROUP BY eq.eq_color
                        ) stats
                    ) ranked
                    WHERE eq_color = mef.color_equipo
                ) AS posicion_equipo
            FROM mi_equipo_por_fecha mef
        ),
        mejor AS (
            SELECT
                mf.fecha_id,
                mf.fecha_hora_inicio,
                mf.lugar,
                gpf.mis_goles,
                mef.color_equipo,
                COALESCE(pef.posicion_equipo, 99) AS posicion_equipo
            FROM mis_fechas mf
            JOIN goles_por_fecha gpf ON mf.fecha_id = gpf.fecha_id
            LEFT JOIN mi_equipo_por_fecha mef ON mf.fecha_id = mef.fecha_id
            LEFT JOIN posicion_equipo_por_fecha pef ON mf.fecha_id = pef.fecha_id
            ORDER BY
                gpf.mis_goles DESC,
                COALESCE(pef.posicion_equipo, 99) ASC,
                mf.fecha_hora_inicio DESC
            LIMIT 1
        )
        SELECT
            CASE WHEN m.fecha_id IS NOT NULL THEN
                jsonb_build_object(
                    'fecha_id', m.fecha_id,
                    'fecha_formato', TO_CHAR(m.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY'),
                    'lugar', m.lugar,
                    'goles', m.mis_goles,
                    'equipo', m.color_equipo::TEXT,
                    'resultado', CASE m.posicion_equipo
                        WHEN 1 THEN 'Campeon'
                        WHEN 2 THEN '2do'
                        WHEN 3 THEN '3ro'
                        WHEN 4 THEN '4to'
                        ELSE 'Sin clasificacion'
                    END
                )
            ELSE NULL
            END
        INTO v_mejor_fecha
        FROM (SELECT 1) dummy
        LEFT JOIN mejor m ON true;

        -- ========================================
        -- CA-005: Historial (ultimas 20 fechas)
        -- ========================================
        WITH admins_grupo AS (
            SELECT usuario_id FROM miembros_grupo
            WHERE grupo_id = p_grupo_id
              AND rol IN ('admin', 'coadmin')
              AND activo = true
        ),
        mis_fechas AS (
            SELECT DISTINCT f.id AS fecha_id, f.fecha_hora_inicio, f.lugar
            FROM inscripciones i
            JOIN fechas f ON i.fecha_id = f.id
            WHERE i.usuario_id = v_usuario_id
              AND i.estado = 'inscrito'
              AND f.estado = 'finalizada'
              AND f.created_by IN (SELECT usuario_id FROM admins_grupo)
            ORDER BY f.fecha_hora_inicio DESC
            LIMIT 20
        ),
        mi_equipo AS (
            SELECT DISTINCT ON (ae.fecha_id)
                ae.fecha_id,
                ae.color_equipo
            FROM asignaciones_equipos ae
            WHERE ae.usuario_id = v_usuario_id
              AND ae.fecha_id IN (SELECT fecha_id FROM mis_fechas)
            ORDER BY ae.fecha_id, ae.created_at DESC
        ),
        goles_fecha AS (
            SELECT
                mf.fecha_id,
                COALESCE(COUNT(g.id), 0) AS mis_goles
            FROM mis_fechas mf
            LEFT JOIN partidos p ON p.fecha_id = mf.fecha_id
            LEFT JOIN goles g ON g.partido_id = p.id
                AND g.jugador_id = v_usuario_id
                AND g.anulado = false
                AND g.es_autogol = false
            GROUP BY mf.fecha_id
        ),
        puntos_fecha AS (
            SELECT
                mf.fecha_id,
                COALESCE(SUM(
                    CASE
                        WHEN (me.color_equipo = p.equipo_local AND p.goles_local > p.goles_visitante)
                          OR (me.color_equipo = p.equipo_visitante AND p.goles_visitante > p.goles_local)
                        THEN 3
                        WHEN p.goles_local = p.goles_visitante THEN 1
                        ELSE 0
                    END
                ), 0) AS mis_puntos
            FROM mis_fechas mf
            LEFT JOIN mi_equipo me ON mf.fecha_id = me.fecha_id
            LEFT JOIN partidos p ON p.fecha_id = mf.fecha_id
                AND p.estado = 'finalizado'
                AND (me.color_equipo = p.equipo_local OR me.color_equipo = p.equipo_visitante)
            GROUP BY mf.fecha_id
        ),
        resultado_equipo AS (
            SELECT
                me.fecha_id,
                (
                    SELECT pos FROM (
                        SELECT
                            eq_color,
                            ROW_NUMBER() OVER (ORDER BY pts DESC, dif DESC) AS pos
                        FROM (
                            SELECT
                                eq.eq_color,
                                COALESCE(SUM(CASE
                                    WHEN (eq.eq_color = pf.equipo_local AND pf.goles_local > pf.goles_visitante)
                                      OR (eq.eq_color = pf.equipo_visitante AND pf.goles_visitante > pf.goles_local)
                                    THEN 3
                                    WHEN pf.goles_local = pf.goles_visitante THEN 1
                                    ELSE 0
                                END), 0) AS pts,
                                COALESCE(SUM(CASE
                                    WHEN eq.eq_color = pf.equipo_local THEN pf.goles_local - pf.goles_visitante
                                    ELSE pf.goles_visitante - pf.goles_local
                                END), 0) AS dif
                            FROM (
                                SELECT DISTINCT equipo_local AS eq_color FROM partidos WHERE fecha_id = me.fecha_id
                                UNION
                                SELECT DISTINCT equipo_visitante FROM partidos WHERE fecha_id = me.fecha_id
                            ) eq
                            LEFT JOIN partidos pf ON (eq.eq_color = pf.equipo_local OR eq.eq_color = pf.equipo_visitante)
                                AND pf.fecha_id = me.fecha_id
                                AND pf.estado = 'finalizado'
                            GROUP BY eq.eq_color
                        ) stats
                    ) ranked
                    WHERE eq_color = me.color_equipo
                ) AS posicion
            FROM mi_equipo me
        )
        SELECT COALESCE(
            jsonb_agg(
                jsonb_build_object(
                    'fecha_id', mf.fecha_id,
                    'fecha_formato', TO_CHAR(mf.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY'),
                    'lugar', mf.lugar,
                    'equipo', me.color_equipo::TEXT,
                    'goles', gf.mis_goles,
                    'puntos', pf.mis_puntos,
                    'resultado', CASE re.posicion
                        WHEN 1 THEN 'Campeon'
                        WHEN 2 THEN '2do'
                        WHEN 3 THEN '3ro'
                        WHEN 4 THEN '4to'
                        ELSE 'Sin clasificacion'
                    END
                )
                ORDER BY mf.fecha_hora_inicio DESC
            ),
            '[]'::JSONB
        )
        INTO v_historial
        FROM mis_fechas mf
        LEFT JOIN mi_equipo me ON mf.fecha_id = me.fecha_id
        LEFT JOIN goles_fecha gf ON mf.fecha_id = gf.fecha_id
        LEFT JOIN puntos_fecha pf ON mf.fecha_id = pf.fecha_id
        LEFT JOIN resultado_equipo re ON mf.fecha_id = re.fecha_id;

    END IF; -- fin stats avanzadas

    -- ============================================================
    -- 7. Construir respuesta
    -- ============================================================

    -- CA-008: Si no tiene datos, mensaje informativo
    IF NOT v_tiene_datos THEN
        RETURN jsonb_build_object(
            'success', true,
            'data', jsonb_build_object(
                'jugador', jsonb_build_object(
                    'id', v_usuario_id,
                    'nombre', v_usuario_nombre,
                    'apodo', v_usuario_apodo,
                    'foto_url', v_usuario_foto
                ),
                'stats_avanzadas', v_stats_avanzadas,
                'metricas', jsonb_build_object(
                    'goles_totales', 0,
                    'fechas_asistidas', 0,
                    'partidos_jugados', 0,
                    'puntos_acumulados', 0
                ),
                'rankings', NULL,
                'promedio', NULL,
                'racha_asistencia', NULL,
                'mejor_fecha', NULL,
                'historial', NULL
            ),
            'message', 'Aun no tienes estadisticas. Inscribete a tu primera pichanga!'
        );
    END IF;

    -- Respuesta con datos
    RETURN jsonb_build_object(
        'success', true,
        'data', jsonb_build_object(
            'jugador', jsonb_build_object(
                'id', v_usuario_id,
                'nombre', v_usuario_nombre,
                'apodo', v_usuario_apodo,
                'foto_url', v_usuario_foto
            ),
            'stats_avanzadas', v_stats_avanzadas,
            'metricas', jsonb_build_object(
                'goles_totales', v_goles_totales,
                'fechas_asistidas', v_fechas_asistidas,
                'partidos_jugados', v_partidos_jugados,
                'puntos_acumulados', v_puntos_acumulados
            ),
            'rankings', CASE WHEN v_stats_avanzadas THEN
                jsonb_build_object(
                    'goleadores', v_ranking_goleadores,
                    'puntos', v_ranking_puntos
                )
            ELSE NULL END,
            'promedio', CASE WHEN v_stats_avanzadas THEN v_promedio ELSE NULL END,
            'racha_asistencia', CASE WHEN v_stats_avanzadas THEN v_racha_asistencia ELSE NULL END,
            'mejor_fecha', CASE WHEN v_stats_avanzadas THEN v_mejor_fecha ELSE NULL END,
            'historial', CASE WHEN v_stats_avanzadas THEN v_historial ELSE NULL END
        ),
        'message', 'Estadisticas obtenidas exitosamente'
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

-- ============================================================
-- Permisos
-- ============================================================
GRANT EXECUTE ON FUNCTION obtener_mis_estadisticas(UUID) TO anon, authenticated, service_role;

-- ============================================================
-- Comentario
-- ============================================================
COMMENT ON FUNCTION obtener_mis_estadisticas IS 'E006-HU-003: Dashboard de estadisticas personales del jugador en un grupo. Metricas basicas para todos, avanzadas para Plan 5+.';

-- ============================================================
-- Verificacion: Confirmar que la funcion existe
-- ============================================================
SELECT
    routine_name,
    routine_type,
    data_type AS return_type
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name = 'obtener_mis_estadisticas';
