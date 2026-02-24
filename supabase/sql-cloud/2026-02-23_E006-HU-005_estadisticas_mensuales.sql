-- ============================================================
-- E006-HU-005: Estadisticas Mensuales
-- Fecha: 2026-02-23
-- Descripcion: RPC que retorna estadisticas agregadas por mes
--              para un grupo deportivo: resumen de actividad,
--              goleador del mes, jugador mas constante, rankings
--              mensuales top 5, comparativa con mes anterior,
--              lista de fechas del mes y meses disponibles.
--
-- Criterios de Aceptacion:
--   CA-001: Seleccionar mes (default=mes actual, meses_disponibles)
--   CA-002: Resumen del mes (fechas, partidos, goles, asistentes unicos)
--   CA-003: Goleador del mes destacado (co-goleadores si empate)
--   CA-004: Ranking mensual top 5 goleadores + top 5 puntos
--   CA-005: Comparativa con mes anterior (diferencias + porcentajes)
--   CA-006: Jugador mas constante (desempate: goles > registro antiguo)
--   CA-007: Lista de fechas del mes con resultados resumidos
--   CA-008: Mes sin actividad = resumen en ceros + mensaje
--
-- Reglas de Negocio:
--   RN-001: Timezone America/Lima para definicion de mes
--   RN-002: Solo fechas con estado = 'finalizada'
--   RN-003: Goles validos: anulado=false, es_autogol=false
--   RN-004: Jugador constante: mas fechas > mas goles > registro mas antiguo
--   RN-005: Asistentes unicos: COUNT DISTINCT usuario_id inscrito
--   RN-006: Comparativa: (actual - anterior), porcentaje, null si no hay anterior
--   RN-007: Rankings mensuales top 5 (mismas reglas E006-HU-001/002)
--   RN-008: Plan Gratis NO tiene acceso (error plan_gratis)
-- ============================================================

-- Eliminar version anterior si existe
DROP FUNCTION IF EXISTS obtener_estadisticas_mensuales(UUID, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION obtener_estadisticas_mensuales(
    p_grupo_id UUID,
    p_anio INTEGER DEFAULT NULL,
    p_mes INTEGER DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
    v_auth_uid UUID;
    v_usuario_id UUID;
    v_miembro_rol TEXT;
    v_stats_avanzadas BOOLEAN;
    v_error_hint TEXT;
    -- Periodo actual
    v_anio INTEGER;
    v_mes INTEGER;
    v_inicio_mes TIMESTAMPTZ;
    v_fin_mes TIMESTAMPTZ;
    -- Periodo anterior
    v_anio_ant INTEGER;
    v_mes_ant INTEGER;
    v_inicio_mes_ant TIMESTAMPTZ;
    v_fin_mes_ant TIMESTAMPTZ;
    -- Resumen (CA-002)
    v_fechas_jugadas INTEGER;
    v_total_partidos INTEGER;
    v_total_goles INTEGER;
    v_asistentes_unicos INTEGER;
    -- Goleador del mes (CA-003)
    v_goleador_mes JSONB;
    -- Jugador constante (CA-006)
    v_jugador_constante JSONB;
    -- Rankings (CA-004)
    v_ranking_goleadores JSONB;
    v_ranking_puntos JSONB;
    -- Comparativa (CA-005)
    v_comparativa JSONB;
    v_fechas_ant INTEGER;
    v_goles_ant INTEGER;
    v_asistentes_ant INTEGER;
    v_hay_datos_ant BOOLEAN;
    -- Fechas del mes (CA-007)
    v_fechas_mes JSONB;
    -- Meses disponibles (CA-001)
    v_meses_disponibles JSONB;
    -- Nombre mes para mensajes
    v_nombre_mes TEXT;
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
    -- 3. Validar miembro activo del grupo + bloquear invitados
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
    -- 4. Verificar plan del grupo (RN-008)
    -- ============================================================
    SELECT COALESCE(p.estadisticas_avanzadas, false)
    INTO v_stats_avanzadas
    FROM grupos g
    JOIN planes p ON g.plan_id = p.id
    WHERE g.id = p_grupo_id;

    IF v_stats_avanzadas IS NULL THEN
        v_stats_avanzadas := false;
    END IF;

    -- RN-008: Plan Gratis NO tiene acceso
    IF NOT v_stats_avanzadas THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', jsonb_build_object(
                'code', 'PLAN_GRATIS',
                'message', 'Estadisticas mensuales requieren Plan 5+',
                'hint', 'plan_gratis'
            )
        );
    END IF;

    -- ============================================================
    -- 5. Determinar periodo (RN-001: America/Lima)
    --    Si p_anio o p_mes son NULL, usar mes actual
    -- ============================================================
    IF p_anio IS NULL OR p_mes IS NULL THEN
        v_anio := EXTRACT(YEAR FROM NOW() AT TIME ZONE 'America/Lima')::INTEGER;
        v_mes := EXTRACT(MONTH FROM NOW() AT TIME ZONE 'America/Lima')::INTEGER;
    ELSE
        v_anio := p_anio;
        v_mes := p_mes;
    END IF;

    -- Rango del mes actual (inicio y fin en UTC para comparar con timestamptz)
    v_inicio_mes := (v_anio || '-' || LPAD(v_mes::TEXT, 2, '0') || '-01')::DATE::TIMESTAMPTZ
                    AT TIME ZONE 'America/Lima';
    v_fin_mes := (v_inicio_mes AT TIME ZONE 'America/Lima' + INTERVAL '1 month' - INTERVAL '1 second')
                 AT TIME ZONE 'America/Lima';

    -- Periodo anterior
    IF v_mes = 1 THEN
        v_anio_ant := v_anio - 1;
        v_mes_ant := 12;
    ELSE
        v_anio_ant := v_anio;
        v_mes_ant := v_mes - 1;
    END IF;

    v_inicio_mes_ant := (v_anio_ant || '-' || LPAD(v_mes_ant::TEXT, 2, '0') || '-01')::DATE::TIMESTAMPTZ
                        AT TIME ZONE 'America/Lima';
    v_fin_mes_ant := (v_inicio_mes_ant AT TIME ZONE 'America/Lima' + INTERVAL '1 month' - INTERVAL '1 second')
                     AT TIME ZONE 'America/Lima';

    -- Nombre del mes para mensajes
    v_nombre_mes := CASE v_mes
        WHEN 1 THEN 'Enero'
        WHEN 2 THEN 'Febrero'
        WHEN 3 THEN 'Marzo'
        WHEN 4 THEN 'Abril'
        WHEN 5 THEN 'Mayo'
        WHEN 6 THEN 'Junio'
        WHEN 7 THEN 'Julio'
        WHEN 8 THEN 'Agosto'
        WHEN 9 THEN 'Septiembre'
        WHEN 10 THEN 'Octubre'
        WHEN 11 THEN 'Noviembre'
        WHEN 12 THEN 'Diciembre'
    END;

    -- ============================================================
    -- 6. CA-002: Resumen del mes
    --    Filtro por grupo: fechas creadas por admin/coadmin del grupo
    -- ============================================================

    -- Fechas jugadas (RN-002: solo finalizadas)
    WITH admins_grupo AS (
        SELECT usuario_id FROM miembros_grupo
        WHERE grupo_id = p_grupo_id
          AND rol IN ('admin', 'coadmin')
          AND activo = true
    )
    SELECT COALESCE(COUNT(*), 0)
    INTO v_fechas_jugadas
    FROM fechas f
    WHERE f.estado = 'finalizada'
      AND f.created_by IN (SELECT usuario_id FROM admins_grupo)
      AND f.fecha_hora_inicio >= v_inicio_mes
      AND f.fecha_hora_inicio <= v_fin_mes;

    -- Total partidos finalizados del mes
    WITH admins_grupo AS (
        SELECT usuario_id FROM miembros_grupo
        WHERE grupo_id = p_grupo_id
          AND rol IN ('admin', 'coadmin')
          AND activo = true
    )
    SELECT COALESCE(COUNT(*), 0)
    INTO v_total_partidos
    FROM partidos p
    JOIN fechas f ON p.fecha_id = f.id
    WHERE p.estado = 'finalizado'
      AND f.estado = 'finalizada'
      AND f.created_by IN (SELECT usuario_id FROM admins_grupo)
      AND f.fecha_hora_inicio >= v_inicio_mes
      AND f.fecha_hora_inicio <= v_fin_mes;

    -- Total goles validos del mes (RN-003)
    WITH admins_grupo AS (
        SELECT usuario_id FROM miembros_grupo
        WHERE grupo_id = p_grupo_id
          AND rol IN ('admin', 'coadmin')
          AND activo = true
    )
    SELECT COALESCE(COUNT(*), 0)
    INTO v_total_goles
    FROM goles g
    JOIN partidos p ON g.partido_id = p.id
    JOIN fechas f ON p.fecha_id = f.id
    WHERE g.anulado = false
      AND g.es_autogol = false
      AND f.estado = 'finalizada'
      AND f.created_by IN (SELECT usuario_id FROM admins_grupo)
      AND f.fecha_hora_inicio >= v_inicio_mes
      AND f.fecha_hora_inicio <= v_fin_mes;

    -- Asistentes unicos del mes (RN-005)
    WITH admins_grupo AS (
        SELECT usuario_id FROM miembros_grupo
        WHERE grupo_id = p_grupo_id
          AND rol IN ('admin', 'coadmin')
          AND activo = true
    )
    SELECT COALESCE(COUNT(DISTINCT i.usuario_id), 0)
    INTO v_asistentes_unicos
    FROM inscripciones i
    JOIN fechas f ON i.fecha_id = f.id
    WHERE i.estado = 'inscrito'
      AND f.estado = 'finalizada'
      AND f.created_by IN (SELECT usuario_id FROM admins_grupo)
      AND f.fecha_hora_inicio >= v_inicio_mes
      AND f.fecha_hora_inicio <= v_fin_mes;

    -- ============================================================
    -- 7. CA-008: Si no hay fechas en el mes, retornar datos vacios
    -- ============================================================
    IF v_fechas_jugadas = 0 THEN

        -- Aun asi calcular meses_disponibles
        WITH admins_grupo AS (
            SELECT usuario_id FROM miembros_grupo
            WHERE grupo_id = p_grupo_id
              AND rol IN ('admin', 'coadmin')
              AND activo = true
        )
        SELECT COALESCE(
            jsonb_agg(
                jsonb_build_object(
                    'anio', sub.anio,
                    'mes', sub.mes,
                    'nombre_mes', CASE sub.mes
                        WHEN 1 THEN 'Enero'
                        WHEN 2 THEN 'Febrero'
                        WHEN 3 THEN 'Marzo'
                        WHEN 4 THEN 'Abril'
                        WHEN 5 THEN 'Mayo'
                        WHEN 6 THEN 'Junio'
                        WHEN 7 THEN 'Julio'
                        WHEN 8 THEN 'Agosto'
                        WHEN 9 THEN 'Septiembre'
                        WHEN 10 THEN 'Octubre'
                        WHEN 11 THEN 'Noviembre'
                        WHEN 12 THEN 'Diciembre'
                    END
                )
                ORDER BY sub.anio DESC, sub.mes DESC
            ),
            '[]'::JSONB
        )
        INTO v_meses_disponibles
        FROM (
            SELECT DISTINCT
                EXTRACT(YEAR FROM f.fecha_hora_inicio AT TIME ZONE 'America/Lima')::INTEGER AS anio,
                EXTRACT(MONTH FROM f.fecha_hora_inicio AT TIME ZONE 'America/Lima')::INTEGER AS mes
            FROM fechas f
            WHERE f.estado = 'finalizada'
              AND f.created_by IN (SELECT usuario_id FROM admins_grupo)
        ) sub;

        RETURN jsonb_build_object(
            'success', true,
            'data', jsonb_build_object(
                'periodo', jsonb_build_object(
                    'anio', v_anio,
                    'mes', v_mes,
                    'nombre_mes', v_nombre_mes
                ),
                'resumen', jsonb_build_object(
                    'fechas_jugadas', 0,
                    'total_partidos', 0,
                    'total_goles', 0,
                    'asistentes_unicos', 0
                ),
                'goleador_mes', NULL,
                'jugador_constante', NULL,
                'ranking_goleadores', '[]'::JSONB,
                'ranking_puntos', '[]'::JSONB,
                'comparativa', NULL,
                'fechas_mes', '[]'::JSONB,
                'meses_disponibles', v_meses_disponibles
            ),
            'message', 'No hubo actividad en ' || v_nombre_mes || ' ' || v_anio
        );
    END IF;

    -- ============================================================
    -- 8. CA-003 / RN-003: Goleador del mes
    --    Si empate: retornar TODOS como co-goleadores (array)
    -- ============================================================
    WITH admins_grupo AS (
        SELECT usuario_id FROM miembros_grupo
        WHERE grupo_id = p_grupo_id
          AND rol IN ('admin', 'coadmin')
          AND activo = true
    ),
    goles_mes_por_jugador AS (
        SELECT
            g.jugador_id,
            u.nombre_completo AS nombre,
            u.apodo,
            u.foto_url,
            COUNT(*) AS goles
        FROM goles g
        JOIN partidos p ON g.partido_id = p.id
        JOIN fechas f ON p.fecha_id = f.id
        LEFT JOIN usuarios u ON u.id = g.jugador_id
        WHERE g.anulado = false
          AND g.es_autogol = false
          AND g.jugador_id IS NOT NULL
          AND f.estado = 'finalizada'
          AND f.created_by IN (SELECT usuario_id FROM admins_grupo)
          AND f.fecha_hora_inicio >= v_inicio_mes
          AND f.fecha_hora_inicio <= v_fin_mes
        GROUP BY g.jugador_id, u.nombre_completo, u.apodo, u.foto_url
    ),
    max_goles AS (
        SELECT MAX(goles) AS max_val FROM goles_mes_por_jugador
    ),
    co_goleadores AS (
        SELECT
            gmpj.jugador_id,
            gmpj.nombre,
            gmpj.apodo,
            gmpj.foto_url,
            gmpj.goles,
            -- Promedio por fecha: goles / fechas asistidas en el mes
            ROUND(
                gmpj.goles::NUMERIC / GREATEST(
                    (
                        SELECT COUNT(DISTINCT i.fecha_id)
                        FROM inscripciones i
                        JOIN fechas f2 ON i.fecha_id = f2.id
                        WHERE i.usuario_id = gmpj.jugador_id
                          AND i.estado = 'inscrito'
                          AND f2.estado = 'finalizada'
                          AND f2.created_by IN (SELECT usuario_id FROM admins_grupo)
                          AND f2.fecha_hora_inicio >= v_inicio_mes
                          AND f2.fecha_hora_inicio <= v_fin_mes
                    ),
                    1
                ),
                2
            ) AS promedio_por_fecha
        FROM goles_mes_por_jugador gmpj
        WHERE gmpj.goles = (SELECT max_val FROM max_goles)
    )
    SELECT CASE
        WHEN (SELECT max_val FROM max_goles) IS NULL THEN NULL
        ELSE (
            SELECT jsonb_agg(
                jsonb_build_object(
                    'jugador_id', cg.jugador_id,
                    'nombre', COALESCE(cg.nombre, 'Desconocido'),
                    'apodo', cg.apodo,
                    'foto_url', cg.foto_url,
                    'goles', cg.goles,
                    'promedio_por_fecha', cg.promedio_por_fecha
                )
                ORDER BY cg.nombre
            )
            FROM co_goleadores cg
        )
    END
    INTO v_goleador_mes;

    -- ============================================================
    -- 9. CA-006 / RN-004: Jugador mas constante
    --    Mas fechas asistidas del mes
    --    Desempate: mas goles > fecha registro mas antigua
    -- ============================================================
    WITH admins_grupo AS (
        SELECT usuario_id FROM miembros_grupo
        WHERE grupo_id = p_grupo_id
          AND rol IN ('admin', 'coadmin')
          AND activo = true
    ),
    asistencias_mes AS (
        SELECT
            i.usuario_id AS jugador_id,
            u.nombre_completo AS nombre,
            u.apodo,
            u.created_at AS fecha_registro,
            COUNT(DISTINCT i.fecha_id) AS fechas_asistidas
        FROM inscripciones i
        JOIN fechas f ON i.fecha_id = f.id
        JOIN usuarios u ON u.id = i.usuario_id
        WHERE i.estado = 'inscrito'
          AND f.estado = 'finalizada'
          AND f.created_by IN (SELECT usuario_id FROM admins_grupo)
          AND f.fecha_hora_inicio >= v_inicio_mes
          AND f.fecha_hora_inicio <= v_fin_mes
        GROUP BY i.usuario_id, u.nombre_completo, u.apodo, u.created_at
    ),
    asistencias_con_goles AS (
        SELECT
            am.*,
            COALESCE((
                SELECT COUNT(*)
                FROM goles g
                JOIN partidos p ON g.partido_id = p.id
                JOIN fechas f ON p.fecha_id = f.id
                WHERE g.jugador_id = am.jugador_id
                  AND g.anulado = false
                  AND g.es_autogol = false
                  AND f.estado = 'finalizada'
                  AND f.created_by IN (SELECT usuario_id FROM admins_grupo)
                  AND f.fecha_hora_inicio >= v_inicio_mes
                  AND f.fecha_hora_inicio <= v_fin_mes
            ), 0) AS goles_mes
        FROM asistencias_mes am
    ),
    max_asistencias AS (
        SELECT MAX(fechas_asistidas) AS max_val FROM asistencias_con_goles
    ),
    constante AS (
        SELECT
            acg.jugador_id,
            acg.nombre,
            acg.apodo,
            acg.fechas_asistidas
        FROM asistencias_con_goles acg
        WHERE acg.fechas_asistidas = (SELECT max_val FROM max_asistencias)
        ORDER BY
            acg.goles_mes DESC,
            acg.fecha_registro ASC
        LIMIT 1
    )
    SELECT CASE
        WHEN (SELECT max_val FROM max_asistencias) IS NULL THEN NULL
        ELSE (
            SELECT jsonb_build_object(
                'jugador_id', c.jugador_id,
                'nombre', COALESCE(c.nombre, 'Desconocido'),
                'apodo', c.apodo,
                'fechas_asistidas', c.fechas_asistidas
            )
            FROM constante c
        )
    END
    INTO v_jugador_constante;

    -- ============================================================
    -- 10. CA-004 / RN-007: Ranking goleadores top 5 del mes
    -- ============================================================
    WITH admins_grupo AS (
        SELECT usuario_id FROM miembros_grupo
        WHERE grupo_id = p_grupo_id
          AND rol IN ('admin', 'coadmin')
          AND activo = true
    ),
    goles_mes AS (
        SELECT
            g.jugador_id,
            u.nombre_completo AS nombre,
            u.apodo,
            COUNT(*) AS goles
        FROM goles g
        JOIN partidos p ON g.partido_id = p.id
        JOIN fechas f ON p.fecha_id = f.id
        LEFT JOIN usuarios u ON u.id = g.jugador_id
        WHERE g.anulado = false
          AND g.es_autogol = false
          AND g.jugador_id IS NOT NULL
          AND f.estado = 'finalizada'
          AND f.created_by IN (SELECT usuario_id FROM admins_grupo)
          AND f.fecha_hora_inicio >= v_inicio_mes
          AND f.fecha_hora_inicio <= v_fin_mes
        GROUP BY g.jugador_id, u.nombre_completo, u.apodo
    ),
    ranking AS (
        SELECT
            gm.jugador_id,
            gm.nombre,
            gm.apodo,
            gm.goles,
            RANK() OVER (ORDER BY gm.goles DESC) AS posicion
        FROM goles_mes gm
    )
    SELECT COALESCE(
        jsonb_agg(
            jsonb_build_object(
                'posicion', r.posicion,
                'jugador_id', r.jugador_id,
                'nombre', COALESCE(r.nombre, 'Desconocido'),
                'apodo', r.apodo,
                'goles', r.goles
            )
            ORDER BY r.posicion ASC, r.nombre
        ),
        '[]'::JSONB
    )
    INTO v_ranking_goleadores
    FROM ranking r
    WHERE r.posicion <= 5;

    -- ============================================================
    -- 11. CA-004 / RN-007: Ranking puntos top 5 del mes
    --     Puntos: Victoria=3, Empate=1, Derrota=0
    -- ============================================================
    WITH admins_grupo AS (
        SELECT usuario_id FROM miembros_grupo
        WHERE grupo_id = p_grupo_id
          AND rol IN ('admin', 'coadmin')
          AND activo = true
    ),
    puntos_mes AS (
        SELECT
            ae.usuario_id AS jugador_id,
            u.nombre_completo AS nombre,
            u.apodo,
            SUM(
                CASE
                    WHEN (ae.color_equipo = p.equipo_local AND p.goles_local > p.goles_visitante)
                      OR (ae.color_equipo = p.equipo_visitante AND p.goles_visitante > p.goles_local)
                    THEN 3
                    WHEN p.goles_local = p.goles_visitante
                    THEN 1
                    ELSE 0
                END
            ) AS puntos
        FROM asignaciones_equipos ae
        JOIN fechas f ON ae.fecha_id = f.id
        JOIN partidos p ON p.fecha_id = f.id
            AND p.estado = 'finalizado'
            AND (ae.color_equipo = p.equipo_local OR ae.color_equipo = p.equipo_visitante)
        LEFT JOIN usuarios u ON u.id = ae.usuario_id
        WHERE f.estado = 'finalizada'
          AND f.created_by IN (SELECT usuario_id FROM admins_grupo)
          AND f.fecha_hora_inicio >= v_inicio_mes
          AND f.fecha_hora_inicio <= v_fin_mes
        GROUP BY ae.usuario_id, u.nombre_completo, u.apodo
    ),
    ranking AS (
        SELECT
            pm.jugador_id,
            pm.nombre,
            pm.apodo,
            pm.puntos,
            RANK() OVER (ORDER BY pm.puntos DESC) AS posicion
        FROM puntos_mes pm
    )
    SELECT COALESCE(
        jsonb_agg(
            jsonb_build_object(
                'posicion', r.posicion,
                'jugador_id', r.jugador_id,
                'nombre', COALESCE(r.nombre, 'Desconocido'),
                'apodo', r.apodo,
                'puntos', r.puntos
            )
            ORDER BY r.posicion ASC, r.nombre
        ),
        '[]'::JSONB
    )
    INTO v_ranking_puntos
    FROM ranking r
    WHERE r.posicion <= 5;

    -- ============================================================
    -- 12. CA-005 / RN-006: Comparativa con mes anterior
    -- ============================================================

    -- Verificar si hay datos del mes anterior
    WITH admins_grupo AS (
        SELECT usuario_id FROM miembros_grupo
        WHERE grupo_id = p_grupo_id
          AND rol IN ('admin', 'coadmin')
          AND activo = true
    )
    SELECT COALESCE(COUNT(*), 0)
    INTO v_fechas_ant
    FROM fechas f
    WHERE f.estado = 'finalizada'
      AND f.created_by IN (SELECT usuario_id FROM admins_grupo)
      AND f.fecha_hora_inicio >= v_inicio_mes_ant
      AND f.fecha_hora_inicio <= v_fin_mes_ant;

    v_hay_datos_ant := (v_fechas_ant > 0);

    IF v_hay_datos_ant THEN
        -- Goles mes anterior
        WITH admins_grupo AS (
            SELECT usuario_id FROM miembros_grupo
            WHERE grupo_id = p_grupo_id
              AND rol IN ('admin', 'coadmin')
              AND activo = true
        )
        SELECT COALESCE(COUNT(*), 0)
        INTO v_goles_ant
        FROM goles g
        JOIN partidos p ON g.partido_id = p.id
        JOIN fechas f ON p.fecha_id = f.id
        WHERE g.anulado = false
          AND g.es_autogol = false
          AND f.estado = 'finalizada'
          AND f.created_by IN (SELECT usuario_id FROM admins_grupo)
          AND f.fecha_hora_inicio >= v_inicio_mes_ant
          AND f.fecha_hora_inicio <= v_fin_mes_ant;

        -- Asistentes unicos mes anterior
        WITH admins_grupo AS (
            SELECT usuario_id FROM miembros_grupo
            WHERE grupo_id = p_grupo_id
              AND rol IN ('admin', 'coadmin')
              AND activo = true
        )
        SELECT COALESCE(COUNT(DISTINCT i.usuario_id), 0)
        INTO v_asistentes_ant
        FROM inscripciones i
        JOIN fechas f ON i.fecha_id = f.id
        WHERE i.estado = 'inscrito'
          AND f.estado = 'finalizada'
          AND f.created_by IN (SELECT usuario_id FROM admins_grupo)
          AND f.fecha_hora_inicio >= v_inicio_mes_ant
          AND f.fecha_hora_inicio <= v_fin_mes_ant;

        -- Construir comparativa
        v_comparativa := jsonb_build_object(
            'fechas_actual', v_fechas_jugadas,
            'fechas_anterior', v_fechas_ant,
            'dif_fechas', v_fechas_jugadas - v_fechas_ant,
            'goles_actual', v_total_goles,
            'goles_anterior', v_goles_ant,
            'dif_goles', v_total_goles - v_goles_ant,
            'asistentes_actual', v_asistentes_unicos,
            'asistentes_anterior', v_asistentes_ant,
            'dif_asistentes', v_asistentes_unicos - v_asistentes_ant,
            -- Porcentajes: si anterior=0 y actual>0 -> null (UI muestra "Nuevo")
            'porcentaje_fechas', CASE
                WHEN v_fechas_ant = 0 AND v_fechas_jugadas > 0 THEN NULL
                WHEN v_fechas_ant = 0 THEN 0
                ELSE ROUND(((v_fechas_jugadas - v_fechas_ant)::NUMERIC / v_fechas_ant) * 100, 1)
            END,
            'porcentaje_goles', CASE
                WHEN v_goles_ant = 0 AND v_total_goles > 0 THEN NULL
                WHEN v_goles_ant = 0 THEN 0
                ELSE ROUND(((v_total_goles - v_goles_ant)::NUMERIC / v_goles_ant) * 100, 1)
            END,
            'porcentaje_asistentes', CASE
                WHEN v_asistentes_ant = 0 AND v_asistentes_unicos > 0 THEN NULL
                WHEN v_asistentes_ant = 0 THEN 0
                ELSE ROUND(((v_asistentes_unicos - v_asistentes_ant)::NUMERIC / v_asistentes_ant) * 100, 1)
            END
        );
    ELSE
        -- RN-006: Si no hay datos del mes anterior, comparativa = null
        v_comparativa := NULL;
    END IF;

    -- ============================================================
    -- 13. CA-007: Lista de fechas del mes con resultados resumidos
    -- ============================================================
    WITH admins_grupo AS (
        SELECT usuario_id FROM miembros_grupo
        WHERE grupo_id = p_grupo_id
          AND rol IN ('admin', 'coadmin')
          AND activo = true
    )
    SELECT COALESCE(
        jsonb_agg(
            jsonb_build_object(
                'fecha_id', sub.fecha_id,
                'fecha_formato', TO_CHAR(sub.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY'),
                'lugar', sub.lugar,
                'total_partidos', sub.total_partidos,
                'total_goles', sub.total_goles
            )
            ORDER BY sub.fecha_hora_inicio DESC
        ),
        '[]'::JSONB
    )
    INTO v_fechas_mes
    FROM (
        SELECT
            f.id AS fecha_id,
            f.fecha_hora_inicio,
            f.lugar,
            (
                SELECT COUNT(*)
                FROM partidos p
                WHERE p.fecha_id = f.id
                  AND p.estado = 'finalizado'
            ) AS total_partidos,
            (
                SELECT COUNT(*)
                FROM goles g
                JOIN partidos p ON g.partido_id = p.id
                WHERE p.fecha_id = f.id
                  AND g.anulado = false
                  AND g.es_autogol = false
            ) AS total_goles
        FROM fechas f
        WHERE f.estado = 'finalizada'
          AND f.created_by IN (SELECT usuario_id FROM admins_grupo)
          AND f.fecha_hora_inicio >= v_inicio_mes
          AND f.fecha_hora_inicio <= v_fin_mes
    ) sub;

    -- ============================================================
    -- 14. CA-001: Meses disponibles (para selector de mes)
    -- ============================================================
    WITH admins_grupo AS (
        SELECT usuario_id FROM miembros_grupo
        WHERE grupo_id = p_grupo_id
          AND rol IN ('admin', 'coadmin')
          AND activo = true
    )
    SELECT COALESCE(
        jsonb_agg(
            jsonb_build_object(
                'anio', sub.anio,
                'mes', sub.mes,
                'nombre_mes', CASE sub.mes
                    WHEN 1 THEN 'Enero'
                    WHEN 2 THEN 'Febrero'
                    WHEN 3 THEN 'Marzo'
                    WHEN 4 THEN 'Abril'
                    WHEN 5 THEN 'Mayo'
                    WHEN 6 THEN 'Junio'
                    WHEN 7 THEN 'Julio'
                    WHEN 8 THEN 'Agosto'
                    WHEN 9 THEN 'Septiembre'
                    WHEN 10 THEN 'Octubre'
                    WHEN 11 THEN 'Noviembre'
                    WHEN 12 THEN 'Diciembre'
                END
            )
            ORDER BY sub.anio DESC, sub.mes DESC
        ),
        '[]'::JSONB
    )
    INTO v_meses_disponibles
    FROM (
        SELECT DISTINCT
            EXTRACT(YEAR FROM f.fecha_hora_inicio AT TIME ZONE 'America/Lima')::INTEGER AS anio,
            EXTRACT(MONTH FROM f.fecha_hora_inicio AT TIME ZONE 'America/Lima')::INTEGER AS mes
        FROM fechas f
        WHERE f.estado = 'finalizada'
          AND f.created_by IN (SELECT usuario_id FROM admins_grupo)
    ) sub;

    -- ============================================================
    -- 15. Construir y retornar respuesta completa
    -- ============================================================
    RETURN jsonb_build_object(
        'success', true,
        'data', jsonb_build_object(
            'periodo', jsonb_build_object(
                'anio', v_anio,
                'mes', v_mes,
                'nombre_mes', v_nombre_mes
            ),
            'resumen', jsonb_build_object(
                'fechas_jugadas', v_fechas_jugadas,
                'total_partidos', v_total_partidos,
                'total_goles', v_total_goles,
                'asistentes_unicos', v_asistentes_unicos
            ),
            'goleador_mes', v_goleador_mes,
            'jugador_constante', v_jugador_constante,
            'ranking_goleadores', v_ranking_goleadores,
            'ranking_puntos', v_ranking_puntos,
            'comparativa', v_comparativa,
            'fechas_mes', v_fechas_mes,
            'meses_disponibles', v_meses_disponibles
        ),
        'message', 'Estadisticas de ' || v_nombre_mes || ' ' || v_anio
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
GRANT EXECUTE ON FUNCTION obtener_estadisticas_mensuales(UUID, INTEGER, INTEGER) TO anon, authenticated, service_role;

-- ============================================================
-- Comentario
-- ============================================================
COMMENT ON FUNCTION obtener_estadisticas_mensuales IS 'E006-HU-005: Estadisticas mensuales del grupo. Resumen, goleador del mes, jugador constante, rankings top 5, comparativa con mes anterior, fechas del mes y meses disponibles. Solo Plan 5+.';

-- ============================================================
-- Verificacion: Confirmar que la funcion existe
-- ============================================================
SELECT
    routine_name,
    routine_type,
    data_type AS return_type
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name = 'obtener_estadisticas_mensuales';
