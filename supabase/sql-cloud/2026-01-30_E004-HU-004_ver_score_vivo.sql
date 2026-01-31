-- ============================================
-- E004-HU-004: Ver Score en Vivo
-- Fecha: 2026-01-30
-- Descripcion: Columnas de score en partidos y funcion RPC para obtener score
-- Dependencia: E004-HU-001 (tabla partidos), tabla goles existente
-- NOTA: La tabla goles ya existe con columnas: equipo_anota, jugador_id
-- ============================================

-- ============================================
-- PARTE 1: AGREGAR COLUMNAS DE SCORE A PARTIDOS
-- ============================================

-- Columnas para almacenar el score actual (desnormalizacion para performance)
ALTER TABLE partidos
ADD COLUMN IF NOT EXISTS goles_local INTEGER NOT NULL DEFAULT 0;

ALTER TABLE partidos
ADD COLUMN IF NOT EXISTS goles_visitante INTEGER NOT NULL DEFAULT 0;

-- Constraints para validar scores no negativos (idempotente)
DO $$ BEGIN
    ALTER TABLE partidos ADD CONSTRAINT chk_goles_local_no_negativo CHECK (goles_local >= 0);
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    ALTER TABLE partidos ADD CONSTRAINT chk_goles_visitante_no_negativo CHECK (goles_visitante >= 0);
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

COMMENT ON COLUMN partidos.goles_local IS 'E004-HU-004: Goles del equipo local (desnormalizado)';
COMMENT ON COLUMN partidos.goles_visitante IS 'E004-HU-004: Goles del equipo visitante (desnormalizado)';

-- ============================================
-- PARTE 2: AGREGAR COLUMNAS FALTANTES A GOLES
-- La tabla goles ya existe con: id, partido_id, equipo_anota, jugador_id, minuto, es_autogol, created_by, created_at
-- ============================================

-- Agregar columnas para funcionalidad de "deshacer gol" si no existen
ALTER TABLE goles ADD COLUMN IF NOT EXISTS anulado BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE goles ADD COLUMN IF NOT EXISTS anulado_at TIMESTAMPTZ;
ALTER TABLE goles ADD COLUMN IF NOT EXISTS anulado_por UUID REFERENCES usuarios(id) ON DELETE SET NULL;

-- ============================================
-- PARTE 3: INDICES PARA OPTIMIZAR CONSULTAS
-- Usando nombres de columnas REALES: equipo_anota, jugador_id
-- ============================================

-- Indice principal: buscar goles por partido
CREATE INDEX IF NOT EXISTS idx_goles_partido_id ON goles(partido_id);

-- Eliminar indices si existen (para recrear)
DROP INDEX IF EXISTS idx_goles_partido_activos;
DROP INDEX IF EXISTS idx_goles_jugador_id;

-- Indice para filtrar goles activos (no anulados) por partido
CREATE INDEX idx_goles_partido_activos
ON goles(partido_id, minuto)
WHERE anulado = false;

-- Indice para estadisticas por jugador
CREATE INDEX idx_goles_jugador_id ON goles(jugador_id)
WHERE jugador_id IS NOT NULL AND anulado = false;

-- Indice para buscar goles recientes
CREATE INDEX IF NOT EXISTS idx_goles_created_at ON goles(created_at DESC);

-- ============================================
-- PARTE 4: ROW LEVEL SECURITY (RLS)
-- ============================================

ALTER TABLE goles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Usuarios autenticados pueden ver goles" ON goles;
DROP POLICY IF EXISTS "Admins pueden insertar goles" ON goles;
DROP POLICY IF EXISTS "Admins pueden actualizar goles" ON goles;
DROP POLICY IF EXISTS "Admins pueden eliminar goles" ON goles;

CREATE POLICY "Usuarios autenticados pueden ver goles"
ON goles FOR SELECT TO authenticated USING (true);

CREATE POLICY "Admins pueden insertar goles"
ON goles FOR INSERT TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1 FROM usuarios u
        WHERE u.auth_user_id = auth.uid()
        AND u.rol = 'admin' AND u.estado = 'aprobado'
    )
);

CREATE POLICY "Admins pueden actualizar goles"
ON goles FOR UPDATE TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM usuarios u
        WHERE u.auth_user_id = auth.uid()
        AND u.rol = 'admin' AND u.estado = 'aprobado'
    )
);

CREATE POLICY "Admins pueden eliminar goles"
ON goles FOR DELETE TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM usuarios u
        WHERE u.auth_user_id = auth.uid()
        AND u.rol = 'admin' AND u.estado = 'aprobado'
    )
);

-- ============================================
-- PARTE 5: HABILITAR REALTIME
-- ============================================

DO $$ BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE goles;
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

-- ============================================
-- PARTE 6: FUNCION RPC obtener_score_partido
-- IMPORTANTE: Usa columnas REALES: equipo_anota, jugador_id
-- ============================================

CREATE OR REPLACE FUNCTION obtener_score_partido(
    p_partido_id UUID
) RETURNS JSON AS $$
DECLARE
    v_error_hint TEXT;
    v_current_user_id UUID;
    v_current_user RECORD;
    v_partido RECORD;
    v_fecha RECORD;
    v_goles_lista JSON;
    v_tiempo_restante_segundos INTEGER;
    v_tiempo_transcurrido_segundos INTEGER;
    v_minuto_actual INTEGER;
    v_indicador_estado TEXT;
    v_color_estado TEXT;
    v_quien_gana TEXT;
    v_es_empate BOOLEAN;
    v_diferencia_goles INTEGER;
    v_ultimo_gol RECORD;
    v_gol_reciente BOOLEAN;
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

    -- Obtener usuario actual
    SELECT id, rol, estado, nombre_completo
    INTO v_current_user
    FROM usuarios
    WHERE auth_user_id = v_current_user_id;

    IF NOT FOUND THEN
        v_error_hint := 'usuario_no_encontrado';
        RAISE EXCEPTION 'Usuario no encontrado en el sistema';
    END IF;

    -- Obtener datos del partido
    SELECT
        p.id, p.fecha_id, p.equipo_local, p.equipo_visitante,
        p.goles_local, p.goles_visitante, p.duracion_minutos,
        p.estado, p.hora_inicio, p.hora_fin_estimada,
        p.tiempo_pausado_segundos, p.pausado_at, p.created_by, p.created_at
    INTO v_partido
    FROM partidos p
    WHERE p.id = p_partido_id;

    IF NOT FOUND THEN
        v_error_hint := 'partido_no_encontrado';
        RAISE EXCEPTION 'Partido no encontrado';
    END IF;

    -- Obtener datos de la fecha
    SELECT id, fecha_hora_inicio, duracion_horas, lugar, num_equipos, estado
    INTO v_fecha
    FROM fechas
    WHERE id = v_partido.fecha_id;

    -- Calcular tiempo restante y transcurrido
    IF v_partido.estado = 'pausado' THEN
        v_tiempo_restante_segundos := GREATEST(0,
            EXTRACT(EPOCH FROM (v_partido.hora_fin_estimada - v_partido.pausado_at))::INTEGER
        );
    ELSIF v_partido.estado = 'en_curso' THEN
        v_tiempo_restante_segundos := EXTRACT(EPOCH FROM (v_partido.hora_fin_estimada - NOW()))::INTEGER;
    ELSE
        v_tiempo_restante_segundos := 0;
    END IF;

    v_tiempo_transcurrido_segundos := (v_partido.duracion_minutos * 60) - v_tiempo_restante_segundos;
    v_minuto_actual := GREATEST(1, CEIL(v_tiempo_transcurrido_segundos::NUMERIC / 60)::INTEGER);

    -- Indicadores visuales de estado
    CASE v_partido.estado
        WHEN 'en_curso' THEN
            IF v_tiempo_restante_segundos < 0 THEN
                v_indicador_estado := 'tiempo_extra';
                v_color_estado := 'rojo';
            ELSE
                v_indicador_estado := 'en_vivo';
                v_color_estado := 'verde';
            END IF;
        WHEN 'pausado' THEN
            v_indicador_estado := 'pausado';
            v_color_estado := 'amarillo';
        WHEN 'finalizado' THEN
            v_indicador_estado := 'finalizado';
            v_color_estado := 'gris';
        ELSE
            v_indicador_estado := 'pendiente';
            v_color_estado := 'gris';
    END CASE;

    -- Indicador de quien gana
    v_diferencia_goles := v_partido.goles_local - v_partido.goles_visitante;

    IF v_diferencia_goles > 0 THEN
        v_quien_gana := 'local';
        v_es_empate := false;
    ELSIF v_diferencia_goles < 0 THEN
        v_quien_gana := 'visitante';
        v_es_empate := false;
    ELSE
        v_quien_gana := 'empate';
        v_es_empate := true;
    END IF;

    -- Lista de goles (usando columnas REALES: equipo_anota, jugador_id)
    SELECT json_agg(
        json_build_object(
            'id', g.id,
            'equipo', g.equipo_anota,
            'usuario_id', g.jugador_id,
            'jugador_nombre', COALESCE(u.nombre_completo, 'Gol de ' || UPPER(g.equipo_anota::TEXT)),
            'minuto', g.minuto,
            'es_autogol', g.es_autogol,
            'created_at', g.created_at,
            'created_at_formato', TO_CHAR(g.created_at AT TIME ZONE 'America/Lima', 'HH24:MI:SS'),
            'es_reciente', (EXTRACT(EPOCH FROM (NOW() - g.created_at)) <= 5)
        ) ORDER BY g.minuto ASC, g.created_at ASC
    )
    INTO v_goles_lista
    FROM goles g
    LEFT JOIN usuarios u ON u.id = g.jugador_id
    WHERE g.partido_id = p_partido_id
    AND g.anulado = false;

    -- Gol reciente (usando columnas REALES)
    SELECT g.id, g.equipo_anota as equipo, g.minuto, u.nombre_completo as jugador_nombre, g.es_autogol
    INTO v_ultimo_gol
    FROM goles g
    LEFT JOIN usuarios u ON u.id = g.jugador_id
    WHERE g.partido_id = p_partido_id
    AND g.anulado = false
    ORDER BY g.created_at DESC
    LIMIT 1;

    IF FOUND THEN
        SELECT (EXTRACT(EPOCH FROM (NOW() - g.created_at)) <= 5)
        INTO v_gol_reciente
        FROM goles g
        WHERE g.id = v_ultimo_gol.id;
    ELSE
        v_gol_reciente := false;
    END IF;

    -- Retorno exitoso
    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'score', json_build_object(
                'goles_local', v_partido.goles_local,
                'goles_visitante', v_partido.goles_visitante,
                'marcador_formato', v_partido.goles_local::TEXT || ' - ' || v_partido.goles_visitante::TEXT
            ),
            'equipo_local', json_build_object(
                'color', v_partido.equipo_local,
                'goles', v_partido.goles_local,
                'ganando', v_quien_gana = 'local'
            ),
            'equipo_visitante', json_build_object(
                'color', v_partido.equipo_visitante,
                'goles', v_partido.goles_visitante,
                'ganando', v_quien_gana = 'visitante'
            ),
            'indicadores', json_build_object(
                'quien_gana', v_quien_gana,
                'es_empate', v_es_empate,
                'diferencia_goles', ABS(v_diferencia_goles),
                'equipo_ganando_color', CASE
                    WHEN v_quien_gana = 'local' THEN v_partido.equipo_local
                    WHEN v_quien_gana = 'visitante' THEN v_partido.equipo_visitante
                    ELSE NULL
                END
            ),
            'tiempo', json_build_object(
                'restante_segundos', GREATEST(0, v_tiempo_restante_segundos),
                'restante_formato', CASE
                    WHEN v_tiempo_restante_segundos < 0 THEN
                        '+' || LPAD((ABS(v_tiempo_restante_segundos) / 60)::TEXT, 2, '0') || ':' || LPAD((ABS(v_tiempo_restante_segundos) % 60)::TEXT, 2, '0')
                    ELSE
                        LPAD((v_tiempo_restante_segundos / 60)::TEXT, 2, '0') || ':' || LPAD((v_tiempo_restante_segundos % 60)::TEXT, 2, '0')
                END,
                'transcurrido_segundos', v_tiempo_transcurrido_segundos,
                'transcurrido_formato', LPAD((GREATEST(0, v_tiempo_transcurrido_segundos) / 60)::TEXT, 2, '0') || ':' || LPAD((GREATEST(0, v_tiempo_transcurrido_segundos) % 60)::TEXT, 2, '0'),
                'minuto_actual', v_minuto_actual,
                'duracion_minutos', v_partido.duracion_minutos,
                'tiempo_extra', v_tiempo_restante_segundos < 0
            ),
            'estado', json_build_object(
                'codigo', v_partido.estado,
                'indicador', v_indicador_estado,
                'color', v_color_estado,
                'en_curso', v_partido.estado = 'en_curso',
                'pausado', v_partido.estado = 'pausado',
                'finalizado', v_partido.estado = 'finalizado'
            ),
            'goles', json_build_object(
                'lista', COALESCE(v_goles_lista, '[]'::json),
                'total', v_partido.goles_local + v_partido.goles_visitante
            ),
            'gol_reciente', json_build_object(
                'hay_gol_reciente', v_gol_reciente,
                'ultimo_gol', CASE
                    WHEN v_ultimo_gol.id IS NOT NULL THEN
                        json_build_object(
                            'id', v_ultimo_gol.id,
                            'equipo', v_ultimo_gol.equipo,
                            'minuto', v_ultimo_gol.minuto,
                            'jugador_nombre', COALESCE(v_ultimo_gol.jugador_nombre, 'Gol de ' || UPPER(v_ultimo_gol.equipo::TEXT)),
                            'es_autogol', v_ultimo_gol.es_autogol
                        )
                    ELSE NULL
                END
            ),
            'partido', json_build_object(
                'id', v_partido.id,
                'fecha_id', v_partido.fecha_id,
                'hora_inicio', v_partido.hora_inicio,
                'hora_fin_estimada', v_partido.hora_fin_estimada
            ),
            'fecha', json_build_object(
                'id', v_fecha.id,
                'lugar', v_fecha.lugar
            ),
            'permisos', json_build_object(
                'es_admin', v_current_user.rol = 'admin' AND v_current_user.estado = 'aprobado',
                'puede_registrar_gol', v_partido.estado = 'en_curso' AND v_current_user.rol = 'admin' AND v_current_user.estado = 'aprobado'
            )
        ),
        'message', UPPER(v_partido.equipo_local::TEXT) || ' ' || v_partido.goles_local || ' - ' || v_partido.goles_visitante || ' ' || UPPER(v_partido.equipo_visitante::TEXT)
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
-- PARTE 7: PERMISOS
-- ============================================

GRANT EXECUTE ON FUNCTION obtener_score_partido TO authenticated, service_role;

-- ============================================
-- FIN DEL SCRIPT
-- ============================================
