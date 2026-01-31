-- ============================================
-- E004-HU-003: Registrar Gol
-- Fecha: 2026-01-30
-- Descripcion: Implementacion de tabla goles y funciones RPC para
--              registrar, eliminar y consultar goles de un partido
-- ============================================

-- ============================================
-- PARTE 1: TABLA goles
-- ============================================

-- Tabla: goles
-- Almacena los goles de cada partido con info del goleador
CREATE TABLE IF NOT EXISTS goles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    partido_id UUID NOT NULL REFERENCES partidos(id) ON DELETE CASCADE,
    equipo_anotador color_equipo NOT NULL,          -- Equipo que recibe el punto
    jugador_id UUID REFERENCES usuarios(id) ON DELETE SET NULL,  -- Quien anoto (NULL = sin asignar)
    minuto INTEGER NOT NULL CHECK (minuto >= 0),    -- Minuto del partido
    es_autogol BOOLEAN NOT NULL DEFAULT false,      -- Si es gol en contra
    created_by UUID NOT NULL REFERENCES usuarios(id) ON DELETE RESTRICT,  -- Admin que registro
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indices para optimizar consultas
CREATE INDEX IF NOT EXISTS idx_goles_partido_id ON goles(partido_id);
CREATE INDEX IF NOT EXISTS idx_goles_equipo_anotador ON goles(equipo_anotador);
CREATE INDEX IF NOT EXISTS idx_goles_jugador_id ON goles(jugador_id);
CREATE INDEX IF NOT EXISTS idx_goles_created_at ON goles(created_at DESC);

-- Comentarios
COMMENT ON TABLE goles IS 'E004-HU-003: Tabla de goles registrados en partidos';
COMMENT ON COLUMN goles.id IS 'Identificador unico del gol';
COMMENT ON COLUMN goles.partido_id IS 'ID del partido donde se anoto el gol';
COMMENT ON COLUMN goles.equipo_anotador IS 'Color del equipo que recibe el punto';
COMMENT ON COLUMN goles.jugador_id IS 'ID del jugador que anoto (NULL si no se asigno)';
COMMENT ON COLUMN goles.minuto IS 'Minuto del partido cuando se anoto';
COMMENT ON COLUMN goles.es_autogol IS 'True si es gol en contra (autogol)';
COMMENT ON COLUMN goles.created_by IS 'ID del admin que registro el gol';
COMMENT ON COLUMN goles.created_at IS 'Timestamp de registro (UTC)';

-- ============================================
-- PARTE 2: ROW LEVEL SECURITY (RLS)
-- ============================================

-- Habilitar RLS en tabla goles
ALTER TABLE goles ENABLE ROW LEVEL SECURITY;

-- Eliminar politicas existentes si existen (para re-ejecucion segura)
DROP POLICY IF EXISTS "Usuarios autenticados pueden ver goles" ON goles;
DROP POLICY IF EXISTS "Admins pueden insertar goles" ON goles;
DROP POLICY IF EXISTS "Admins pueden actualizar goles" ON goles;
DROP POLICY IF EXISTS "Admins pueden eliminar goles" ON goles;

-- SELECT: Todos los usuarios autenticados pueden ver goles
CREATE POLICY "Usuarios autenticados pueden ver goles"
ON goles FOR SELECT
TO authenticated
USING (true);

-- INSERT: Solo admin aprobado puede insertar goles
CREATE POLICY "Admins pueden insertar goles"
ON goles FOR INSERT
TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1 FROM usuarios u
        WHERE u.auth_user_id = auth.uid()
        AND u.rol = 'admin'
        AND u.estado = 'aprobado'
    )
);

-- UPDATE: Solo admin aprobado puede actualizar goles
CREATE POLICY "Admins pueden actualizar goles"
ON goles FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM usuarios u
        WHERE u.auth_user_id = auth.uid()
        AND u.rol = 'admin'
        AND u.estado = 'aprobado'
    )
);

-- DELETE: Solo admin aprobado puede eliminar goles
CREATE POLICY "Admins pueden eliminar goles"
ON goles FOR DELETE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM usuarios u
        WHERE u.auth_user_id = auth.uid()
        AND u.rol = 'admin'
        AND u.estado = 'aprobado'
    )
);

-- ============================================
-- PARTE 3: HABILITAR REALTIME
-- ============================================

-- Habilitar realtime para la tabla goles
-- Permite actualizaciones en vivo del marcador
ALTER PUBLICATION supabase_realtime ADD TABLE goles;

-- ============================================
-- PARTE 4: FUNCION RPC registrar_gol
-- ============================================

-- ============================================
-- Funcion: registrar_gol
-- Descripcion: Registra un gol en un partido en curso
-- Reglas: RN-001, RN-002, RN-003, RN-004, RN-006, RN-007, RN-008
-- CA: CA-001, CA-002, CA-003, CA-004, CA-006, CA-007
-- ============================================
CREATE OR REPLACE FUNCTION registrar_gol(
    p_partido_id UUID,
    p_equipo_anotador TEXT,
    p_jugador_id UUID DEFAULT NULL,
    p_es_autogol BOOLEAN DEFAULT false
) RETURNS JSON AS $$
DECLARE
    v_error_hint TEXT;
    v_current_user_id UUID;
    v_current_user RECORD;
    v_partido RECORD;
    v_fecha RECORD;
    v_equipo_anotador_enum color_equipo;
    v_equipo_real color_equipo;
    v_jugador RECORD;
    v_asignacion RECORD;
    v_minuto INTEGER;
    v_gol_id UUID;
    v_goles_local INTEGER;
    v_goles_visitante INTEGER;
    v_advertencia TEXT := NULL;
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
    -- Validacion: Parametros obligatorios
    -- ========================================
    IF p_partido_id IS NULL THEN
        v_error_hint := 'partido_id_requerido';
        RAISE EXCEPTION 'El ID del partido es obligatorio';
    END IF;

    IF p_equipo_anotador IS NULL OR TRIM(p_equipo_anotador) = '' THEN
        v_error_hint := 'equipo_anotador_requerido';
        RAISE EXCEPTION 'El equipo anotador es obligatorio';
    END IF;

    -- ========================================
    -- RN-001: Solo admin aprobado puede registrar goles
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
        RAISE EXCEPTION 'Solo los administradores aprobados pueden registrar goles';
    END IF;

    -- ========================================
    -- Obtener datos del partido
    -- ========================================
    SELECT id, fecha_id, equipo_local, equipo_visitante, duracion_minutos,
           estado, hora_inicio, hora_fin_estimada, tiempo_pausado_segundos, pausado_at
    INTO v_partido
    FROM partidos
    WHERE id = p_partido_id;

    IF NOT FOUND THEN
        v_error_hint := 'partido_no_encontrado';
        RAISE EXCEPTION 'Partido no encontrado';
    END IF;

    -- ========================================
    -- RN-002: Partido debe estar en estado 'en_curso'
    -- ========================================
    IF v_partido.estado != 'en_curso' THEN
        -- RN-007: No permitir si partido esta pausado
        IF v_partido.estado = 'pausado' THEN
            v_error_hint := 'partido_pausado';
            RAISE EXCEPTION 'No se pueden registrar goles mientras el partido esta pausado';
        ELSE
            v_error_hint := 'partido_no_en_curso';
            RAISE EXCEPTION 'Solo se pueden registrar goles en partidos en curso. Estado actual: %', v_partido.estado;
        END IF;
    END IF;

    -- ========================================
    -- Validar color del equipo anotador
    -- ========================================
    BEGIN
        v_equipo_anotador_enum := LOWER(TRIM(p_equipo_anotador))::color_equipo;
    EXCEPTION
        WHEN invalid_text_representation THEN
            v_error_hint := 'equipo_invalido';
            RAISE EXCEPTION 'Color de equipo invalido: %. Colores validos: naranja, verde, azul, rojo, amarillo, blanco', p_equipo_anotador;
    END;

    -- Validar que el equipo sea uno de los que juegan
    IF v_equipo_anotador_enum != v_partido.equipo_local AND v_equipo_anotador_enum != v_partido.equipo_visitante THEN
        v_error_hint := 'equipo_no_participa';
        RAISE EXCEPTION 'El equipo % no participa en este partido. Equipos: % vs %',
            v_equipo_anotador_enum, v_partido.equipo_local, v_partido.equipo_visitante;
    END IF;

    -- ========================================
    -- RN-006: Si es autogol, el gol suma al equipo contrario
    -- ========================================
    IF p_es_autogol THEN
        -- El equipo_anotador indicado es el equipo del jugador que hizo el autogol
        -- El gol real va al equipo contrario
        IF v_equipo_anotador_enum = v_partido.equipo_local THEN
            v_equipo_real := v_partido.equipo_visitante;
        ELSE
            v_equipo_real := v_partido.equipo_local;
        END IF;
    ELSE
        v_equipo_real := v_equipo_anotador_enum;
    END IF;

    -- ========================================
    -- RN-003: Si hay jugador_id, validar que pertenezca al equipo correcto
    -- ========================================
    IF p_jugador_id IS NOT NULL THEN
        -- Verificar que el jugador existe
        SELECT id, nombre_completo
        INTO v_jugador
        FROM usuarios
        WHERE id = p_jugador_id;

        IF NOT FOUND THEN
            v_error_hint := 'jugador_no_encontrado';
            RAISE EXCEPTION 'Jugador no encontrado';
        END IF;

        -- Verificar asignacion del jugador al equipo
        SELECT ae.id, ae.equipo
        INTO v_asignacion
        FROM asignaciones_equipos ae
        WHERE ae.fecha_id = v_partido.fecha_id
        AND ae.usuario_id = p_jugador_id;

        IF NOT FOUND THEN
            v_error_hint := 'jugador_sin_asignacion';
            RAISE EXCEPTION 'El jugador % no tiene equipo asignado en este partido', v_jugador.nombre_completo;
        END IF;

        -- Para gol normal: jugador debe ser del equipo que anota
        -- Para autogol: jugador debe ser del equipo contrario al que recibe el punto
        IF p_es_autogol THEN
            -- En autogol, el jugador es del equipo que "comete" el autogol (equipo_anotador original)
            IF v_asignacion.equipo != v_equipo_anotador_enum THEN
                v_error_hint := 'jugador_equipo_incorrecto_autogol';
                RAISE EXCEPTION 'Para autogol, el jugador debe ser del equipo %. El jugador % es del equipo %',
                    v_equipo_anotador_enum, v_jugador.nombre_completo, v_asignacion.equipo;
            END IF;
        ELSE
            -- En gol normal, jugador debe ser del equipo anotador
            IF v_asignacion.equipo != v_equipo_anotador_enum THEN
                v_error_hint := 'jugador_equipo_incorrecto';
                RAISE EXCEPTION 'El jugador % no pertenece al equipo %. Esta asignado al equipo %',
                    v_jugador.nombre_completo, v_equipo_anotador_enum, v_asignacion.equipo;
            END IF;
        END IF;
    END IF;

    -- ========================================
    -- Obtener datos de la fecha
    -- ========================================
    SELECT id, lugar
    INTO v_fecha
    FROM fechas
    WHERE id = v_partido.fecha_id;

    -- ========================================
    -- RN-004: Calcular minuto automaticamente
    -- Minuto = segundos transcurridos desde hora_inicio / 60, redondeado hacia arriba
    -- Considerando tiempo pausado
    -- ========================================
    v_minuto := CEIL(
        (EXTRACT(EPOCH FROM (NOW() - v_partido.hora_inicio)) - v_partido.tiempo_pausado_segundos) / 60.0
    )::INTEGER;

    -- Asegurar minuto minimo de 1
    IF v_minuto < 1 THEN
        v_minuto := 1;
    END IF;

    -- ========================================
    -- Insertar el gol
    -- ========================================
    INSERT INTO goles (
        partido_id,
        equipo_anotador,
        jugador_id,
        minuto,
        es_autogol,
        created_by
    ) VALUES (
        p_partido_id,
        v_equipo_real,  -- El equipo que realmente recibe el punto
        p_jugador_id,
        v_minuto,
        p_es_autogol,
        v_current_user.id
    )
    RETURNING id INTO v_gol_id;

    -- ========================================
    -- Calcular marcador actualizado
    -- ========================================
    SELECT COUNT(*) INTO v_goles_local
    FROM goles
    WHERE partido_id = p_partido_id
    AND equipo_anotador = v_partido.equipo_local;

    SELECT COUNT(*) INTO v_goles_visitante
    FROM goles
    WHERE partido_id = p_partido_id
    AND equipo_anotador = v_partido.equipo_visitante;

    -- ========================================
    -- RN-008: Advertencia si equipo llega a 10+ goles
    -- ========================================
    IF v_goles_local >= 10 OR v_goles_visitante >= 10 THEN
        v_advertencia := 'Marcador inusual: ' ||
            UPPER(v_partido.equipo_local::TEXT) || ' ' || v_goles_local || ' - ' ||
            v_goles_visitante || ' ' || UPPER(v_partido.equipo_visitante::TEXT);
    END IF;

    -- ========================================
    -- Retorno exitoso
    -- ========================================
    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'gol_id', v_gol_id,
            'partido_id', p_partido_id,
            'equipo_anotador', v_equipo_real,
            'equipo_jugador', CASE WHEN p_es_autogol THEN v_equipo_anotador_enum ELSE v_equipo_real END,
            'jugador_id', p_jugador_id,
            'jugador_nombre', CASE WHEN p_jugador_id IS NOT NULL THEN v_jugador.nombre_completo ELSE NULL END,
            'minuto', v_minuto,
            'es_autogol', p_es_autogol,
            'marcador', json_build_object(
                'equipo_local', v_partido.equipo_local,
                'goles_local', v_goles_local,
                'equipo_visitante', v_partido.equipo_visitante,
                'goles_visitante', v_goles_visitante
            ),
            'marcador_texto', UPPER(v_partido.equipo_local::TEXT) || ' ' || v_goles_local || ' - ' ||
                             v_goles_visitante || ' ' || UPPER(v_partido.equipo_visitante::TEXT),
            'registrado_por', v_current_user.id,
            'registrado_por_nombre', v_current_user.nombre_completo,
            'registrado_at', NOW(),
            'registrado_at_formato', TO_CHAR(NOW() AT TIME ZONE 'America/Lima', 'HH24:MI:SS'),
            'advertencia', v_advertencia
        ),
        'message', CASE
            WHEN p_es_autogol AND p_jugador_id IS NOT NULL THEN
                'Autogol de ' || v_jugador.nombre_completo || ' (min ' || v_minuto || ') - Punto para ' || UPPER(v_equipo_real::TEXT)
            WHEN p_es_autogol THEN
                'Autogol (min ' || v_minuto || ') - Punto para ' || UPPER(v_equipo_real::TEXT)
            WHEN p_jugador_id IS NOT NULL THEN
                'Gol de ' || v_jugador.nombre_completo || ' (min ' || v_minuto || ') para ' || UPPER(v_equipo_real::TEXT)
            ELSE
                'Gol para ' || UPPER(v_equipo_real::TEXT) || ' (min ' || v_minuto || ')'
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
-- PARTE 5: FUNCION RPC eliminar_gol
-- ============================================

-- ============================================
-- Funcion: eliminar_gol
-- Descripcion: Elimina un gol (para deshacer errores)
-- Reglas: RN-001, RN-005
-- CA: CA-005
-- ============================================
CREATE OR REPLACE FUNCTION eliminar_gol(
    p_gol_id UUID
) RETURNS JSON AS $$
DECLARE
    v_error_hint TEXT;
    v_current_user_id UUID;
    v_current_user RECORD;
    v_gol RECORD;
    v_partido RECORD;
    v_jugador_nombre TEXT;
    v_goles_local INTEGER;
    v_goles_visitante INTEGER;
    v_segundos_desde_registro INTEGER;
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
    IF p_gol_id IS NULL THEN
        v_error_hint := 'gol_id_requerido';
        RAISE EXCEPTION 'El ID del gol es obligatorio';
    END IF;

    -- ========================================
    -- RN-001: Solo admin aprobado puede eliminar goles
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
        RAISE EXCEPTION 'Solo los administradores aprobados pueden eliminar goles';
    END IF;

    -- ========================================
    -- Obtener datos del gol
    -- ========================================
    SELECT g.id, g.partido_id, g.equipo_anotador, g.jugador_id, g.minuto, g.es_autogol, g.created_at
    INTO v_gol
    FROM goles g
    WHERE g.id = p_gol_id;

    IF NOT FOUND THEN
        v_error_hint := 'gol_no_encontrado';
        RAISE EXCEPTION 'Gol no encontrado';
    END IF;

    -- ========================================
    -- Obtener datos del partido
    -- ========================================
    SELECT id, fecha_id, equipo_local, equipo_visitante, estado
    INTO v_partido
    FROM partidos
    WHERE id = v_gol.partido_id;

    -- ========================================
    -- RN-005: Calcular tiempo desde registro (para info)
    -- ========================================
    v_segundos_desde_registro := EXTRACT(EPOCH FROM (NOW() - v_gol.created_at))::INTEGER;

    -- ========================================
    -- Obtener nombre del jugador si existe
    -- ========================================
    IF v_gol.jugador_id IS NOT NULL THEN
        SELECT nombre_completo INTO v_jugador_nombre
        FROM usuarios
        WHERE id = v_gol.jugador_id;
    END IF;

    -- ========================================
    -- Eliminar el gol
    -- ========================================
    DELETE FROM goles WHERE id = p_gol_id;

    -- ========================================
    -- Calcular marcador actualizado (despues de eliminar)
    -- ========================================
    SELECT COUNT(*) INTO v_goles_local
    FROM goles
    WHERE partido_id = v_gol.partido_id
    AND equipo_anotador = v_partido.equipo_local;

    SELECT COUNT(*) INTO v_goles_visitante
    FROM goles
    WHERE partido_id = v_gol.partido_id
    AND equipo_anotador = v_partido.equipo_visitante;

    -- ========================================
    -- Retorno exitoso
    -- ========================================
    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'gol_eliminado', json_build_object(
                'id', p_gol_id,
                'equipo_anotador', v_gol.equipo_anotador,
                'jugador_id', v_gol.jugador_id,
                'jugador_nombre', v_jugador_nombre,
                'minuto', v_gol.minuto,
                'es_autogol', v_gol.es_autogol,
                'segundos_desde_registro', v_segundos_desde_registro
            ),
            'partido_id', v_gol.partido_id,
            'marcador', json_build_object(
                'equipo_local', v_partido.equipo_local,
                'goles_local', v_goles_local,
                'equipo_visitante', v_partido.equipo_visitante,
                'goles_visitante', v_goles_visitante
            ),
            'marcador_texto', UPPER(v_partido.equipo_local::TEXT) || ' ' || v_goles_local || ' - ' ||
                             v_goles_visitante || ' ' || UPPER(v_partido.equipo_visitante::TEXT),
            'eliminado_por', v_current_user.id,
            'eliminado_por_nombre', v_current_user.nombre_completo,
            'eliminado_at', NOW(),
            'eliminado_at_formato', TO_CHAR(NOW() AT TIME ZONE 'America/Lima', 'HH24:MI:SS')
        ),
        'message', CASE
            WHEN v_jugador_nombre IS NOT NULL THEN
                'Gol de ' || v_jugador_nombre || ' (min ' || v_gol.minuto || ') eliminado'
            ELSE
                'Gol (min ' || v_gol.minuto || ') eliminado'
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
-- PARTE 6: FUNCION RPC obtener_goles_partido
-- ============================================

-- ============================================
-- Funcion: obtener_goles_partido
-- Descripcion: Obtiene la lista de goles de un partido con marcador
-- CA: CA-003, CA-006
-- ============================================
CREATE OR REPLACE FUNCTION obtener_goles_partido(
    p_partido_id UUID
) RETURNS JSON AS $$
DECLARE
    v_error_hint TEXT;
    v_current_user_id UUID;
    v_partido RECORD;
    v_fecha RECORD;
    v_goles JSON;
    v_goles_local INTEGER;
    v_goles_visitante INTEGER;
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
    -- Obtener datos del partido
    -- ========================================
    SELECT id, fecha_id, equipo_local, equipo_visitante, duracion_minutos,
           estado, hora_inicio, hora_fin_estimada
    INTO v_partido
    FROM partidos
    WHERE id = p_partido_id;

    IF NOT FOUND THEN
        v_error_hint := 'partido_no_encontrado';
        RAISE EXCEPTION 'Partido no encontrado';
    END IF;

    -- ========================================
    -- Obtener datos de la fecha
    -- ========================================
    SELECT id, lugar, fecha_hora_inicio
    INTO v_fecha
    FROM fechas
    WHERE id = v_partido.fecha_id;

    -- ========================================
    -- Obtener lista de goles
    -- ========================================
    SELECT json_agg(
        json_build_object(
            'id', g.id,
            'equipo_anotador', g.equipo_anotador,
            'jugador_id', g.jugador_id,
            'jugador_nombre', u.nombre_completo,
            'minuto', g.minuto,
            'es_autogol', g.es_autogol,
            'created_at', g.created_at,
            'created_at_formato', TO_CHAR(g.created_at AT TIME ZONE 'America/Lima', 'HH24:MI:SS')
        )
        ORDER BY g.minuto ASC, g.created_at ASC
    )
    INTO v_goles
    FROM goles g
    LEFT JOIN usuarios u ON u.id = g.jugador_id
    WHERE g.partido_id = p_partido_id;

    -- ========================================
    -- Calcular marcador
    -- ========================================
    SELECT COUNT(*) INTO v_goles_local
    FROM goles
    WHERE partido_id = p_partido_id
    AND equipo_anotador = v_partido.equipo_local;

    SELECT COUNT(*) INTO v_goles_visitante
    FROM goles
    WHERE partido_id = p_partido_id
    AND equipo_anotador = v_partido.equipo_visitante;

    -- ========================================
    -- Retorno exitoso
    -- ========================================
    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'partido_id', p_partido_id,
            'partido', json_build_object(
                'equipo_local', v_partido.equipo_local,
                'equipo_visitante', v_partido.equipo_visitante,
                'duracion_minutos', v_partido.duracion_minutos,
                'estado', v_partido.estado,
                'hora_inicio_formato', TO_CHAR(v_partido.hora_inicio AT TIME ZONE 'America/Lima', 'HH24:MI:SS')
            ),
            'fecha', json_build_object(
                'id', v_fecha.id,
                'lugar', v_fecha.lugar,
                'fecha_formato', TO_CHAR(v_fecha.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY')
            ),
            'marcador', json_build_object(
                'equipo_local', v_partido.equipo_local,
                'goles_local', v_goles_local,
                'equipo_visitante', v_partido.equipo_visitante,
                'goles_visitante', v_goles_visitante
            ),
            'marcador_texto', UPPER(v_partido.equipo_local::TEXT) || ' ' || v_goles_local || ' - ' ||
                             v_goles_visitante || ' ' || UPPER(v_partido.equipo_visitante::TEXT),
            'goles', COALESCE(v_goles, '[]'::json),
            'total_goles', v_goles_local + v_goles_visitante
        ),
        'message', 'Goles obtenidos exitosamente'
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

GRANT EXECUTE ON FUNCTION registrar_gol TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION eliminar_gol TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION obtener_goles_partido TO authenticated, service_role;

-- ============================================
-- PARTE 8: COMENTARIOS DE DOCUMENTACION
-- ============================================

COMMENT ON FUNCTION registrar_gol IS 'E004-HU-003: Registra un gol en partido en curso (RN-001 a RN-008)';
COMMENT ON FUNCTION eliminar_gol IS 'E004-HU-003: Elimina un gol para deshacer errores (RN-001, RN-005)';
COMMENT ON FUNCTION obtener_goles_partido IS 'E004-HU-003: Obtiene lista de goles y marcador de un partido';

-- ============================================
-- FIN DEL SCRIPT
-- ============================================
