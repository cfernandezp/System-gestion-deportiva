-- ============================================
-- E004-HU-001: Iniciar Partido
-- Fecha: 2026-01-29
-- Descripcion: Implementacion de tabla partidos, enum estado_partido
--              y funciones RPC para gestionar partidos en vivo
--              (iniciar, pausar, reanudar, obtener partido activo)
-- ============================================

-- ============================================
-- PARTE 1: TIPO ENUM estado_partido
-- ============================================

-- Tipo ENUM para estados de un partido
-- RN-005: Estados del ciclo de vida de un partido
DO $$ BEGIN
    CREATE TYPE estado_partido AS ENUM (
        'pendiente',    -- Partido creado pero no iniciado
        'en_curso',     -- Partido en progreso con temporizador activo
        'pausado',      -- Partido pausado temporalmente (RN-007)
        'finalizado',   -- Partido terminado normalmente
        'cancelado'     -- Partido cancelado
    );
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

COMMENT ON TYPE estado_partido IS 'E004-HU-001: Estados del ciclo de vida de un partido';

-- ============================================
-- PARTE 2: TABLA partidos
-- ============================================

-- Tabla: partidos
-- Almacena los partidos dentro de una fecha de pichanga
CREATE TABLE IF NOT EXISTS partidos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    fecha_id UUID NOT NULL REFERENCES fechas(id) ON DELETE CASCADE,
    equipo_local color_equipo NOT NULL,
    equipo_visitante color_equipo NOT NULL,
    duracion_minutos INTEGER NOT NULL CHECK (duracion_minutos IN (10, 20)),
    estado estado_partido NOT NULL DEFAULT 'pendiente',
    hora_inicio TIMESTAMPTZ,
    hora_fin_estimada TIMESTAMPTZ,
    tiempo_pausado_segundos INTEGER NOT NULL DEFAULT 0,
    pausado_at TIMESTAMPTZ,
    created_by UUID NOT NULL REFERENCES usuarios(id) ON DELETE RESTRICT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    -- RN-006: Un equipo no puede jugar contra si mismo
    CONSTRAINT chk_equipos_diferentes CHECK (equipo_local != equipo_visitante)
);

-- Indices para optimizar consultas
CREATE INDEX IF NOT EXISTS idx_partidos_fecha_id ON partidos(fecha_id);
CREATE INDEX IF NOT EXISTS idx_partidos_estado ON partidos(estado);
CREATE INDEX IF NOT EXISTS idx_partidos_created_by ON partidos(created_by);

-- Indice para buscar partidos activos (en_curso o pausado) por fecha
CREATE INDEX IF NOT EXISTS idx_partidos_activos
ON partidos(fecha_id)
WHERE estado IN ('en_curso', 'pausado');

-- Trigger para actualizar updated_at
DROP TRIGGER IF EXISTS trigger_partidos_updated_at ON partidos;
CREATE TRIGGER trigger_partidos_updated_at
    BEFORE UPDATE ON partidos
    FOR EACH ROW
    EXECUTE FUNCTION actualizar_updated_at();

-- ============================================
-- PARTE 3: ROW LEVEL SECURITY (RLS)
-- ============================================

-- Habilitar RLS en tabla partidos
ALTER TABLE partidos ENABLE ROW LEVEL SECURITY;

-- Eliminar politicas existentes si existen (para re-ejecucion segura)
DROP POLICY IF EXISTS "Usuarios autenticados pueden ver partidos" ON partidos;
DROP POLICY IF EXISTS "Admins pueden insertar partidos" ON partidos;
DROP POLICY IF EXISTS "Admins pueden actualizar partidos" ON partidos;
DROP POLICY IF EXISTS "Admins pueden eliminar partidos" ON partidos;

-- SELECT: Todos los usuarios autenticados pueden ver partidos
CREATE POLICY "Usuarios autenticados pueden ver partidos"
ON partidos FOR SELECT
TO authenticated
USING (true);

-- INSERT: Solo admin aprobado puede insertar partidos
CREATE POLICY "Admins pueden insertar partidos"
ON partidos FOR INSERT
TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1 FROM usuarios u
        WHERE u.auth_user_id = auth.uid()
        AND u.rol = 'admin'
        AND u.estado = 'aprobado'
    )
);

-- UPDATE: Solo admin aprobado puede actualizar partidos
CREATE POLICY "Admins pueden actualizar partidos"
ON partidos FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM usuarios u
        WHERE u.auth_user_id = auth.uid()
        AND u.rol = 'admin'
        AND u.estado = 'aprobado'
    )
);

-- DELETE: Solo admin aprobado puede eliminar partidos
CREATE POLICY "Admins pueden eliminar partidos"
ON partidos FOR DELETE
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
-- PARTE 4: HABILITAR REALTIME
-- ============================================

-- Habilitar realtime para la tabla partidos
-- Esto permite que los usuarios vean en tiempo real el estado del partido
ALTER PUBLICATION supabase_realtime ADD TABLE partidos;

-- ============================================
-- PARTE 5: FUNCION RPC iniciar_partido
-- ============================================

-- ============================================
-- Funcion: iniciar_partido
-- Descripcion: Inicia un nuevo partido seleccionando 2 equipos
-- Reglas: RN-001, RN-002, RN-003, RN-004, RN-005, RN-006
-- CA: CA-001, CA-002, CA-003, CA-006
-- ============================================
CREATE OR REPLACE FUNCTION iniciar_partido(
    p_fecha_id UUID,
    p_equipo_local TEXT,
    p_equipo_visitante TEXT
) RETURNS JSON AS $$
DECLARE
    v_error_hint TEXT;
    v_current_user_id UUID;
    v_current_user RECORD;
    v_fecha RECORD;
    v_equipo_local_enum color_equipo;
    v_equipo_visitante_enum color_equipo;
    v_duracion_minutos INTEGER;
    v_partido_activo RECORD;
    v_jugadores_local INTEGER;
    v_jugadores_visitante INTEGER;
    v_partido_id UUID;
    v_hora_inicio TIMESTAMPTZ;
    v_hora_fin_estimada TIMESTAMPTZ;
    v_jugadores_local_lista JSON;
    v_jugadores_visitante_lista JSON;
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
    IF p_fecha_id IS NULL THEN
        v_error_hint := 'fecha_id_requerido';
        RAISE EXCEPTION 'El ID de la fecha es obligatorio';
    END IF;

    IF p_equipo_local IS NULL OR TRIM(p_equipo_local) = '' THEN
        v_error_hint := 'equipo_local_requerido';
        RAISE EXCEPTION 'El equipo local es obligatorio';
    END IF;

    IF p_equipo_visitante IS NULL OR TRIM(p_equipo_visitante) = '' THEN
        v_error_hint := 'equipo_visitante_requerido';
        RAISE EXCEPTION 'El equipo visitante es obligatorio';
    END IF;

    -- ========================================
    -- RN-001: Solo admin aprobado puede iniciar partidos
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
        RAISE EXCEPTION 'Solo los administradores aprobados pueden iniciar partidos';
    END IF;

    -- ========================================
    -- Obtener datos de la fecha
    -- ========================================
    SELECT id, fecha_hora_inicio, duracion_horas, lugar, num_equipos, estado
    INTO v_fecha
    FROM fechas
    WHERE id = p_fecha_id;

    IF NOT FOUND THEN
        v_error_hint := 'fecha_no_encontrada';
        RAISE EXCEPTION 'Fecha de pichanga no encontrada';
    END IF;

    -- ========================================
    -- RN-002: Solo se puede iniciar partido si fecha.estado = 'en_juego'
    -- ========================================
    IF v_fecha.estado != 'en_juego' THEN
        v_error_hint := 'fecha_no_en_juego';
        RAISE EXCEPTION 'Solo se pueden iniciar partidos cuando la fecha esta en juego. Estado actual: %', v_fecha.estado;
    END IF;

    -- ========================================
    -- Validar colores de equipo
    -- ========================================
    BEGIN
        v_equipo_local_enum := LOWER(TRIM(p_equipo_local))::color_equipo;
    EXCEPTION
        WHEN invalid_text_representation THEN
            v_error_hint := 'equipo_local_invalido';
            RAISE EXCEPTION 'Color de equipo local invalido: %. Colores validos: naranja, verde, azul, rojo, amarillo, blanco', p_equipo_local;
    END;

    BEGIN
        v_equipo_visitante_enum := LOWER(TRIM(p_equipo_visitante))::color_equipo;
    EXCEPTION
        WHEN invalid_text_representation THEN
            v_error_hint := 'equipo_visitante_invalido';
            RAISE EXCEPTION 'Color de equipo visitante invalido: %. Colores validos: naranja, verde, azul, rojo, amarillo, blanco', p_equipo_visitante;
    END;

    -- ========================================
    -- RN-006: Los equipos deben ser diferentes
    -- ========================================
    IF v_equipo_local_enum = v_equipo_visitante_enum THEN
        v_error_hint := 'equipos_iguales';
        RAISE EXCEPTION 'El equipo local y visitante deben ser diferentes. Ambos son: %', p_equipo_local;
    END IF;

    -- ========================================
    -- RN-005: Solo un partido activo por fecha
    -- ========================================
    SELECT id, estado, equipo_local, equipo_visitante
    INTO v_partido_activo
    FROM partidos
    WHERE fecha_id = p_fecha_id
    AND estado IN ('en_curso', 'pausado')
    LIMIT 1;

    IF FOUND THEN
        v_error_hint := 'partido_activo_existe';
        RAISE EXCEPTION 'Ya hay un partido % para esta fecha (% vs %). Debes finalizarlo antes de iniciar otro.',
            v_partido_activo.estado,
            v_partido_activo.equipo_local,
            v_partido_activo.equipo_visitante;
    END IF;

    -- ========================================
    -- RN-003: Ambos equipos deben tener jugadores asignados
    -- ========================================
    SELECT COUNT(*) INTO v_jugadores_local
    FROM asignaciones_equipos
    WHERE fecha_id = p_fecha_id
    AND equipo = v_equipo_local_enum;

    IF v_jugadores_local = 0 THEN
        v_error_hint := 'equipo_local_sin_jugadores';
        RAISE EXCEPTION 'El equipo % no tiene jugadores asignados', v_equipo_local_enum;
    END IF;

    SELECT COUNT(*) INTO v_jugadores_visitante
    FROM asignaciones_equipos
    WHERE fecha_id = p_fecha_id
    AND equipo = v_equipo_visitante_enum;

    IF v_jugadores_visitante = 0 THEN
        v_error_hint := 'equipo_visitante_sin_jugadores';
        RAISE EXCEPTION 'El equipo % no tiene jugadores asignados', v_equipo_visitante_enum;
    END IF;

    -- ========================================
    -- RN-004: Calcular duracion segun num_equipos
    -- 2 equipos (1 hora) = 20 minutos
    -- 3 equipos (2 horas) = 10 minutos
    -- ========================================
    IF v_fecha.num_equipos = 2 THEN
        v_duracion_minutos := 20;
    ELSE -- 3 equipos
        v_duracion_minutos := 10;
    END IF;

    -- ========================================
    -- Calcular hora inicio y fin estimada
    -- ========================================
    v_hora_inicio := NOW();
    v_hora_fin_estimada := v_hora_inicio + (v_duracion_minutos || ' minutes')::INTERVAL;

    -- ========================================
    -- Insertar partido con estado 'en_curso'
    -- ========================================
    INSERT INTO partidos (
        fecha_id,
        equipo_local,
        equipo_visitante,
        duracion_minutos,
        estado,
        hora_inicio,
        hora_fin_estimada,
        tiempo_pausado_segundos,
        created_by
    ) VALUES (
        p_fecha_id,
        v_equipo_local_enum,
        v_equipo_visitante_enum,
        v_duracion_minutos,
        'en_curso',
        v_hora_inicio,
        v_hora_fin_estimada,
        0,
        v_current_user.id
    )
    RETURNING id INTO v_partido_id;

    -- ========================================
    -- Obtener lista de jugadores de cada equipo
    -- ========================================
    SELECT json_agg(
        json_build_object(
            'usuario_id', u.id,
            'nombre_completo', u.nombre_completo
        ) ORDER BY u.nombre_completo
    )
    INTO v_jugadores_local_lista
    FROM asignaciones_equipos ae
    JOIN usuarios u ON u.id = ae.usuario_id
    WHERE ae.fecha_id = p_fecha_id
    AND ae.equipo = v_equipo_local_enum;

    SELECT json_agg(
        json_build_object(
            'usuario_id', u.id,
            'nombre_completo', u.nombre_completo
        ) ORDER BY u.nombre_completo
    )
    INTO v_jugadores_visitante_lista
    FROM asignaciones_equipos ae
    JOIN usuarios u ON u.id = ae.usuario_id
    WHERE ae.fecha_id = p_fecha_id
    AND ae.equipo = v_equipo_visitante_enum;

    -- ========================================
    -- Retorno exitoso
    -- ========================================
    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'partido_id', v_partido_id,
            'fecha_id', p_fecha_id,
            'equipo_local', json_build_object(
                'color', v_equipo_local_enum,
                'jugadores_count', v_jugadores_local,
                'jugadores', COALESCE(v_jugadores_local_lista, '[]'::json)
            ),
            'equipo_visitante', json_build_object(
                'color', v_equipo_visitante_enum,
                'jugadores_count', v_jugadores_visitante,
                'jugadores', COALESCE(v_jugadores_visitante_lista, '[]'::json)
            ),
            'duracion_minutos', v_duracion_minutos,
            'estado', 'en_curso',
            'hora_inicio', v_hora_inicio,
            'hora_inicio_local', v_hora_inicio AT TIME ZONE 'America/Lima',
            'hora_inicio_formato', TO_CHAR(v_hora_inicio AT TIME ZONE 'America/Lima', 'HH24:MI:SS'),
            'hora_fin_estimada', v_hora_fin_estimada,
            'hora_fin_estimada_local', v_hora_fin_estimada AT TIME ZONE 'America/Lima',
            'hora_fin_estimada_formato', TO_CHAR(v_hora_fin_estimada AT TIME ZONE 'America/Lima', 'HH24:MI:SS'),
            'tiempo_restante_segundos', EXTRACT(EPOCH FROM (v_hora_fin_estimada - NOW()))::INTEGER,
            'tiempo_pausado_segundos', 0,
            'created_by', v_current_user.id,
            'created_by_nombre', v_current_user.nombre_completo,
            'lugar', v_fecha.lugar,
            'fecha_formato', TO_CHAR(v_fecha.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY')
        ),
        'message', 'Partido iniciado: ' || UPPER(v_equipo_local_enum::TEXT) || ' vs ' || UPPER(v_equipo_visitante_enum::TEXT) || ' - ' || v_duracion_minutos || ' minutos'
    );

EXCEPTION
    WHEN check_violation THEN
        RETURN json_build_object(
            'success', false,
            'error', json_build_object(
                'code', 'CHECK_VIOLATION',
                'message', 'Los equipos deben ser diferentes',
                'hint', 'equipos_iguales'
            )
        );
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
-- PARTE 6: FUNCION RPC pausar_partido
-- ============================================

-- ============================================
-- Funcion: pausar_partido
-- Descripcion: Pausa un partido en curso
-- Reglas: RN-001, RN-007
-- CA: CA-005
-- ============================================
CREATE OR REPLACE FUNCTION pausar_partido(
    p_partido_id UUID
) RETURNS JSON AS $$
DECLARE
    v_error_hint TEXT;
    v_current_user_id UUID;
    v_current_user RECORD;
    v_partido RECORD;
    v_fecha RECORD;
    v_tiempo_restante_segundos INTEGER;
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
    -- RN-001: Solo admin aprobado puede pausar partidos
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
        RAISE EXCEPTION 'Solo los administradores aprobados pueden pausar partidos';
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
    -- Validar que el partido esta en_curso
    -- ========================================
    IF v_partido.estado != 'en_curso' THEN
        v_error_hint := 'partido_no_en_curso';
        RAISE EXCEPTION 'Solo se pueden pausar partidos en curso. Estado actual: %', v_partido.estado;
    END IF;

    -- ========================================
    -- Obtener datos de la fecha para el response
    -- ========================================
    SELECT lugar, fecha_hora_inicio
    INTO v_fecha
    FROM fechas
    WHERE id = v_partido.fecha_id;

    -- ========================================
    -- RN-007: Registrar momento de pausa
    -- Calcular tiempo restante al momento de pausar
    -- ========================================
    v_tiempo_restante_segundos := GREATEST(0,
        EXTRACT(EPOCH FROM (v_partido.hora_fin_estimada - NOW()))::INTEGER
    );

    -- ========================================
    -- Actualizar partido: estado = 'pausado', registrar pausado_at
    -- ========================================
    UPDATE partidos
    SET estado = 'pausado',
        pausado_at = NOW()
    WHERE id = p_partido_id;

    -- ========================================
    -- Retorno exitoso
    -- ========================================
    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'partido_id', p_partido_id,
            'fecha_id', v_partido.fecha_id,
            'equipo_local', v_partido.equipo_local,
            'equipo_visitante', v_partido.equipo_visitante,
            'estado', 'pausado',
            'hora_inicio', v_partido.hora_inicio,
            'hora_inicio_formato', TO_CHAR(v_partido.hora_inicio AT TIME ZONE 'America/Lima', 'HH24:MI:SS'),
            'hora_fin_estimada', v_partido.hora_fin_estimada,
            'hora_fin_estimada_formato', TO_CHAR(v_partido.hora_fin_estimada AT TIME ZONE 'America/Lima', 'HH24:MI:SS'),
            'pausado_at', NOW(),
            'pausado_at_local', NOW() AT TIME ZONE 'America/Lima',
            'pausado_at_formato', TO_CHAR(NOW() AT TIME ZONE 'America/Lima', 'HH24:MI:SS'),
            'tiempo_restante_segundos', v_tiempo_restante_segundos,
            'tiempo_pausado_segundos', v_partido.tiempo_pausado_segundos,
            'duracion_minutos', v_partido.duracion_minutos,
            'lugar', v_fecha.lugar,
            'pausado_por', v_current_user.id,
            'pausado_por_nombre', v_current_user.nombre_completo
        ),
        'message', 'Partido pausado: ' || UPPER(v_partido.equipo_local::TEXT) || ' vs ' || UPPER(v_partido.equipo_visitante::TEXT) || '. Tiempo restante: ' || (v_tiempo_restante_segundos / 60) || ' minutos'
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
-- PARTE 7: FUNCION RPC reanudar_partido
-- ============================================

-- ============================================
-- Funcion: reanudar_partido
-- Descripcion: Reanuda un partido pausado
-- Reglas: RN-001, RN-007
-- CA: CA-005
-- ============================================
CREATE OR REPLACE FUNCTION reanudar_partido(
    p_partido_id UUID
) RETURNS JSON AS $$
DECLARE
    v_error_hint TEXT;
    v_current_user_id UUID;
    v_current_user RECORD;
    v_partido RECORD;
    v_fecha RECORD;
    v_tiempo_pausa_actual INTEGER;
    v_nuevo_tiempo_pausado INTEGER;
    v_nueva_hora_fin_estimada TIMESTAMPTZ;
    v_tiempo_restante_segundos INTEGER;
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
    -- RN-001: Solo admin aprobado puede reanudar partidos
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
        RAISE EXCEPTION 'Solo los administradores aprobados pueden reanudar partidos';
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
    -- Validar que el partido esta pausado
    -- ========================================
    IF v_partido.estado != 'pausado' THEN
        v_error_hint := 'partido_no_pausado';
        RAISE EXCEPTION 'Solo se pueden reanudar partidos pausados. Estado actual: %', v_partido.estado;
    END IF;

    -- ========================================
    -- Obtener datos de la fecha para el response
    -- ========================================
    SELECT lugar, fecha_hora_inicio
    INTO v_fecha
    FROM fechas
    WHERE id = v_partido.fecha_id;

    -- ========================================
    -- RN-007: Calcular tiempo pausado y nueva hora fin
    -- ========================================
    -- Calcular cuanto tiempo estuvo pausado
    v_tiempo_pausa_actual := EXTRACT(EPOCH FROM (NOW() - v_partido.pausado_at))::INTEGER;
    v_nuevo_tiempo_pausado := v_partido.tiempo_pausado_segundos + v_tiempo_pausa_actual;

    -- Ajustar hora_fin_estimada agregando el tiempo de pausa
    v_nueva_hora_fin_estimada := v_partido.hora_fin_estimada + (v_tiempo_pausa_actual || ' seconds')::INTERVAL;

    -- Calcular tiempo restante desde ahora
    v_tiempo_restante_segundos := GREATEST(0,
        EXTRACT(EPOCH FROM (v_nueva_hora_fin_estimada - NOW()))::INTEGER
    );

    -- ========================================
    -- Actualizar partido: estado = 'en_curso', limpiar pausado_at
    -- ========================================
    UPDATE partidos
    SET estado = 'en_curso',
        pausado_at = NULL,
        tiempo_pausado_segundos = v_nuevo_tiempo_pausado,
        hora_fin_estimada = v_nueva_hora_fin_estimada
    WHERE id = p_partido_id;

    -- ========================================
    -- Retorno exitoso
    -- ========================================
    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'partido_id', p_partido_id,
            'fecha_id', v_partido.fecha_id,
            'equipo_local', v_partido.equipo_local,
            'equipo_visitante', v_partido.equipo_visitante,
            'estado', 'en_curso',
            'hora_inicio', v_partido.hora_inicio,
            'hora_inicio_formato', TO_CHAR(v_partido.hora_inicio AT TIME ZONE 'America/Lima', 'HH24:MI:SS'),
            'hora_fin_estimada', v_nueva_hora_fin_estimada,
            'hora_fin_estimada_local', v_nueva_hora_fin_estimada AT TIME ZONE 'America/Lima',
            'hora_fin_estimada_formato', TO_CHAR(v_nueva_hora_fin_estimada AT TIME ZONE 'America/Lima', 'HH24:MI:SS'),
            'tiempo_restante_segundos', v_tiempo_restante_segundos,
            'tiempo_pausa_actual_segundos', v_tiempo_pausa_actual,
            'tiempo_pausado_total_segundos', v_nuevo_tiempo_pausado,
            'duracion_minutos', v_partido.duracion_minutos,
            'lugar', v_fecha.lugar,
            'reanudado_at', NOW(),
            'reanudado_at_local', NOW() AT TIME ZONE 'America/Lima',
            'reanudado_at_formato', TO_CHAR(NOW() AT TIME ZONE 'America/Lima', 'HH24:MI:SS'),
            'reanudado_por', v_current_user.id,
            'reanudado_por_nombre', v_current_user.nombre_completo
        ),
        'message', 'Partido reanudado: ' || UPPER(v_partido.equipo_local::TEXT) || ' vs ' || UPPER(v_partido.equipo_visitante::TEXT) || '. Tiempo restante: ' || (v_tiempo_restante_segundos / 60) || ' minutos. Estuvo pausado ' || (v_tiempo_pausa_actual / 60) || ' minutos.'
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
-- PARTE 8: FUNCION RPC obtener_partido_activo
-- ============================================

-- ============================================
-- Funcion: obtener_partido_activo
-- Descripcion: Obtiene el partido activo (en_curso o pausado) de una fecha
--              Incluye tiempo restante calculado dinamicamente y jugadores de cada equipo
-- CA: CA-004
-- ============================================
CREATE OR REPLACE FUNCTION obtener_partido_activo(
    p_fecha_id UUID
) RETURNS JSON AS $$
DECLARE
    v_error_hint TEXT;
    v_current_user_id UUID;
    v_current_user RECORD;
    v_fecha RECORD;
    v_partido RECORD;
    v_tiempo_restante_segundos INTEGER;
    v_tiempo_transcurrido_segundos INTEGER;
    v_jugadores_local JSON;
    v_jugadores_visitante JSON;
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
    IF p_fecha_id IS NULL THEN
        v_error_hint := 'fecha_id_requerido';
        RAISE EXCEPTION 'El ID de la fecha es obligatorio';
    END IF;

    -- ========================================
    -- Obtener usuario actual
    -- ========================================
    SELECT id, rol, estado, nombre_completo
    INTO v_current_user
    FROM usuarios
    WHERE auth_user_id = v_current_user_id;

    IF NOT FOUND THEN
        v_error_hint := 'usuario_no_encontrado';
        RAISE EXCEPTION 'Usuario no encontrado en el sistema';
    END IF;

    -- ========================================
    -- Obtener datos de la fecha
    -- ========================================
    SELECT id, fecha_hora_inicio, duracion_horas, lugar, num_equipos, estado
    INTO v_fecha
    FROM fechas
    WHERE id = p_fecha_id;

    IF NOT FOUND THEN
        v_error_hint := 'fecha_no_encontrada';
        RAISE EXCEPTION 'Fecha de pichanga no encontrada';
    END IF;

    -- ========================================
    -- Buscar partido activo (en_curso o pausado)
    -- ========================================
    SELECT id, fecha_id, equipo_local, equipo_visitante, duracion_minutos,
           estado, hora_inicio, hora_fin_estimada, tiempo_pausado_segundos, pausado_at,
           created_by, created_at
    INTO v_partido
    FROM partidos
    WHERE fecha_id = p_fecha_id
    AND estado IN ('en_curso', 'pausado')
    ORDER BY created_at DESC
    LIMIT 1;

    IF NOT FOUND THEN
        -- No hay partido activo, retornar info de la fecha
        RETURN json_build_object(
            'success', true,
            'data', json_build_object(
                'partido_activo', false,
                'partido', NULL,
                'fecha', json_build_object(
                    'id', v_fecha.id,
                    'fecha_formato', TO_CHAR(v_fecha.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY'),
                    'hora_formato', TO_CHAR(v_fecha.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'HH24:MI'),
                    'lugar', v_fecha.lugar,
                    'num_equipos', v_fecha.num_equipos,
                    'duracion_horas', v_fecha.duracion_horas,
                    'estado', v_fecha.estado
                ),
                'puede_iniciar_partido', v_fecha.estado = 'en_juego' AND v_current_user.rol = 'admin' AND v_current_user.estado = 'aprobado'
            ),
            'message', 'No hay partido activo en esta fecha'
        );
    END IF;

    -- ========================================
    -- Calcular tiempo restante dinamicamente
    -- Si esta pausado, calcular desde el momento de pausa
    -- Si esta en_curso, calcular desde ahora
    -- ========================================
    IF v_partido.estado = 'pausado' THEN
        -- Tiempo restante al momento de pausar
        v_tiempo_restante_segundos := GREATEST(0,
            EXTRACT(EPOCH FROM (v_partido.hora_fin_estimada - v_partido.pausado_at))::INTEGER
        );
        v_tiempo_transcurrido_segundos := (v_partido.duracion_minutos * 60) - v_tiempo_restante_segundos;
    ELSE
        -- Tiempo restante ahora
        v_tiempo_restante_segundos := GREATEST(0,
            EXTRACT(EPOCH FROM (v_partido.hora_fin_estimada - NOW()))::INTEGER
        );
        v_tiempo_transcurrido_segundos := (v_partido.duracion_minutos * 60) - v_tiempo_restante_segundos;
    END IF;

    -- ========================================
    -- Obtener jugadores de cada equipo
    -- ========================================
    SELECT json_agg(
        json_build_object(
            'usuario_id', u.id,
            'nombre_completo', u.nombre_completo
        ) ORDER BY u.nombre_completo
    )
    INTO v_jugadores_local
    FROM asignaciones_equipos ae
    JOIN usuarios u ON u.id = ae.usuario_id
    WHERE ae.fecha_id = p_fecha_id
    AND ae.equipo = v_partido.equipo_local;

    SELECT json_agg(
        json_build_object(
            'usuario_id', u.id,
            'nombre_completo', u.nombre_completo
        ) ORDER BY u.nombre_completo
    )
    INTO v_jugadores_visitante
    FROM asignaciones_equipos ae
    JOIN usuarios u ON u.id = ae.usuario_id
    WHERE ae.fecha_id = p_fecha_id
    AND ae.equipo = v_partido.equipo_visitante;

    -- ========================================
    -- Retorno exitoso con partido activo
    -- ========================================
    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'partido_activo', true,
            'partido', json_build_object(
                'id', v_partido.id,
                'fecha_id', v_partido.fecha_id,
                'equipo_local', json_build_object(
                    'color', v_partido.equipo_local,
                    'jugadores', COALESCE(v_jugadores_local, '[]'::json)
                ),
                'equipo_visitante', json_build_object(
                    'color', v_partido.equipo_visitante,
                    'jugadores', COALESCE(v_jugadores_visitante, '[]'::json)
                ),
                'duracion_minutos', v_partido.duracion_minutos,
                'estado', v_partido.estado,
                'hora_inicio', v_partido.hora_inicio,
                'hora_inicio_local', v_partido.hora_inicio AT TIME ZONE 'America/Lima',
                'hora_inicio_formato', TO_CHAR(v_partido.hora_inicio AT TIME ZONE 'America/Lima', 'HH24:MI:SS'),
                'hora_fin_estimada', v_partido.hora_fin_estimada,
                'hora_fin_estimada_local', v_partido.hora_fin_estimada AT TIME ZONE 'America/Lima',
                'hora_fin_estimada_formato', TO_CHAR(v_partido.hora_fin_estimada AT TIME ZONE 'America/Lima', 'HH24:MI:SS'),
                'tiempo_restante_segundos', v_tiempo_restante_segundos,
                'tiempo_restante_minutos', v_tiempo_restante_segundos / 60,
                'tiempo_restante_formato', LPAD((v_tiempo_restante_segundos / 60)::TEXT, 2, '0') || ':' || LPAD((v_tiempo_restante_segundos % 60)::TEXT, 2, '0'),
                'tiempo_transcurrido_segundos', v_tiempo_transcurrido_segundos,
                'tiempo_transcurrido_formato', LPAD((v_tiempo_transcurrido_segundos / 60)::TEXT, 2, '0') || ':' || LPAD((v_tiempo_transcurrido_segundos % 60)::TEXT, 2, '0'),
                'tiempo_pausado_segundos', v_partido.tiempo_pausado_segundos,
                'pausado_at', v_partido.pausado_at,
                'pausado_at_formato', CASE
                    WHEN v_partido.pausado_at IS NOT NULL THEN
                        TO_CHAR(v_partido.pausado_at AT TIME ZONE 'America/Lima', 'HH24:MI:SS')
                    ELSE NULL
                END,
                'created_at', v_partido.created_at,
                'tiempo_terminado', v_tiempo_restante_segundos <= 0
            ),
            'fecha', json_build_object(
                'id', v_fecha.id,
                'fecha_formato', TO_CHAR(v_fecha.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY'),
                'hora_formato', TO_CHAR(v_fecha.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'HH24:MI'),
                'lugar', v_fecha.lugar,
                'num_equipos', v_fecha.num_equipos,
                'duracion_horas', v_fecha.duracion_horas,
                'estado', v_fecha.estado
            ),
            'es_admin', v_current_user.rol = 'admin' AND v_current_user.estado = 'aprobado',
            'puede_pausar', v_partido.estado = 'en_curso' AND v_current_user.rol = 'admin' AND v_current_user.estado = 'aprobado',
            'puede_reanudar', v_partido.estado = 'pausado' AND v_current_user.rol = 'admin' AND v_current_user.estado = 'aprobado'
        ),
        'message', CASE
            WHEN v_partido.estado = 'pausado' THEN
                'Partido pausado: ' || UPPER(v_partido.equipo_local::TEXT) || ' vs ' || UPPER(v_partido.equipo_visitante::TEXT)
            ELSE
                'Partido en curso: ' || UPPER(v_partido.equipo_local::TEXT) || ' vs ' || UPPER(v_partido.equipo_visitante::TEXT)
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
-- PARTE 9: PERMISOS
-- ============================================

GRANT EXECUTE ON FUNCTION iniciar_partido TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION pausar_partido TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION reanudar_partido TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION obtener_partido_activo TO authenticated, service_role;

-- ============================================
-- PARTE 10: COMENTARIOS DE DOCUMENTACION
-- ============================================

COMMENT ON TABLE partidos IS 'E004-HU-001: Tabla de partidos dentro de una fecha de pichanga';
COMMENT ON COLUMN partidos.id IS 'Identificador unico del partido';
COMMENT ON COLUMN partidos.fecha_id IS 'ID de la fecha de pichanga donde se juega el partido';
COMMENT ON COLUMN partidos.equipo_local IS 'Color del equipo local';
COMMENT ON COLUMN partidos.equipo_visitante IS 'Color del equipo visitante';
COMMENT ON COLUMN partidos.duracion_minutos IS 'Duracion en minutos: 10 (3 equipos) o 20 (2 equipos)';
COMMENT ON COLUMN partidos.estado IS 'Estado del partido: pendiente, en_curso, pausado, finalizado, cancelado';
COMMENT ON COLUMN partidos.hora_inicio IS 'Timestamp cuando inicio el partido (UTC)';
COMMENT ON COLUMN partidos.hora_fin_estimada IS 'Timestamp estimado de fin (se ajusta con pausas)';
COMMENT ON COLUMN partidos.tiempo_pausado_segundos IS 'Total de segundos acumulados en pausas';
COMMENT ON COLUMN partidos.pausado_at IS 'Timestamp cuando se pauso (NULL si no esta pausado)';
COMMENT ON COLUMN partidos.created_by IS 'ID del admin que inicio el partido';
COMMENT ON COLUMN partidos.created_at IS 'Timestamp de creacion (UTC)';
COMMENT ON COLUMN partidos.updated_at IS 'Timestamp de ultima actualizacion (UTC)';

COMMENT ON FUNCTION iniciar_partido IS 'E004-HU-001: Inicia un partido seleccionando 2 equipos (RN-001 a RN-006)';
COMMENT ON FUNCTION pausar_partido IS 'E004-HU-001: Pausa un partido en curso (RN-001, RN-007)';
COMMENT ON FUNCTION reanudar_partido IS 'E004-HU-001: Reanuda un partido pausado (RN-001, RN-007)';
COMMENT ON FUNCTION obtener_partido_activo IS 'E004-HU-001: Obtiene partido activo de una fecha con tiempo restante dinamico';

-- ============================================
-- FIN DEL SCRIPT
-- ============================================
