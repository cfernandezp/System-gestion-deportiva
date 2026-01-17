-- ============================================
-- FIX: Actualizar funcion crear_fecha con nuevos parametros
-- Fecha: 2026-01-17
-- Descripcion: Actualiza la funcion RPC crear_fecha para aceptar
--              p_num_equipos y p_costo_por_jugador directamente
--              en lugar de calcularlos desde la duracion
-- ============================================

-- ============================================
-- PARTE 1: ACTUALIZAR CHECK CONSTRAINT EN TABLA
-- Cambiar num_equipos de (2,3) a (2,3,4)
-- ============================================

-- Eliminar constraint existente y crear uno nuevo
ALTER TABLE fechas DROP CONSTRAINT IF EXISTS fechas_num_equipos_check;
ALTER TABLE fechas ADD CONSTRAINT fechas_num_equipos_check CHECK (num_equipos >= 2 AND num_equipos <= 4);

-- ============================================
-- PARTE 2: ACTUALIZAR FUNCION RPC crear_fecha
-- Ahora acepta 5 parametros incluyendo num_equipos y costo_por_jugador
-- ============================================

CREATE OR REPLACE FUNCTION crear_fecha(
    p_fecha_hora_inicio TIMESTAMPTZ,
    p_duracion_horas INTEGER,
    p_lugar TEXT,
    p_num_equipos INTEGER,
    p_costo_por_jugador NUMERIC
) RETURNS JSON AS $$
DECLARE
    v_error_hint TEXT;
    v_current_user_id UUID;
    v_current_user RECORD;
    v_fecha_id UUID;
    v_jugadores_aprobados RECORD;
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
    -- Validacion RN-001: Solo admin aprobado puede crear
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
        RAISE EXCEPTION 'Solo los administradores aprobados pueden crear fechas de pichanga';
    END IF;

    -- ========================================
    -- Validacion: Parametros obligatorios
    -- ========================================
    IF p_fecha_hora_inicio IS NULL THEN
        v_error_hint := 'fecha_requerida';
        RAISE EXCEPTION 'La fecha y hora de inicio son obligatorias';
    END IF;

    IF p_duracion_horas IS NULL THEN
        v_error_hint := 'duracion_requerida';
        RAISE EXCEPTION 'La duracion es obligatoria';
    END IF;

    IF p_lugar IS NULL OR LENGTH(TRIM(p_lugar)) < 3 THEN
        v_error_hint := 'lugar_invalido';
        RAISE EXCEPTION 'El lugar es obligatorio y debe tener al menos 3 caracteres';
    END IF;

    IF p_num_equipos IS NULL THEN
        v_error_hint := 'num_equipos_requerido';
        RAISE EXCEPTION 'El numero de equipos es obligatorio';
    END IF;

    IF p_costo_por_jugador IS NULL THEN
        v_error_hint := 'costo_requerido';
        RAISE EXCEPTION 'El costo por jugador es obligatorio';
    END IF;

    -- ========================================
    -- Validacion RN-002: Duracion valida (1, 2 o 3 horas)
    -- ========================================
    IF p_duracion_horas NOT IN (1, 2, 3) THEN
        v_error_hint := 'duracion_invalida';
        RAISE EXCEPTION 'La duracion debe ser 1, 2 o 3 horas';
    END IF;

    -- ========================================
    -- Validacion: Numero de equipos (2-4)
    -- ========================================
    IF p_num_equipos < 2 OR p_num_equipos > 4 THEN
        v_error_hint := 'num_equipos_invalido';
        RAISE EXCEPTION 'El numero de equipos debe estar entre 2 y 4';
    END IF;

    -- ========================================
    -- Validacion: Costo por jugador positivo
    -- ========================================
    IF p_costo_por_jugador <= 0 THEN
        v_error_hint := 'costo_invalido';
        RAISE EXCEPTION 'El costo por jugador debe ser mayor a 0';
    END IF;

    -- ========================================
    -- Validacion RN-004: Fecha futura obligatoria
    -- ========================================
    IF p_fecha_hora_inicio <= NOW() THEN
        v_error_hint := 'fecha_pasada';
        RAISE EXCEPTION 'La fecha y hora deben ser futuras';
    END IF;

    -- ========================================
    -- Validacion RN-005: No duplicados misma fecha/hora
    -- Solo considera fechas activas (no canceladas)
    -- ========================================
    IF EXISTS (
        SELECT 1 FROM fechas
        WHERE fecha_hora_inicio = p_fecha_hora_inicio
        AND estado != 'cancelada'
    ) THEN
        v_error_hint := 'fecha_duplicada';
        RAISE EXCEPTION 'Ya existe una fecha programada para ese dia y hora';
    END IF;

    -- ========================================
    -- Insertar fecha (RN-006: estado inicial = 'abierta')
    -- ========================================
    INSERT INTO fechas (
        fecha_hora_inicio,
        duracion_horas,
        lugar,
        num_equipos,
        costo_por_jugador,
        estado,
        created_by
    ) VALUES (
        p_fecha_hora_inicio,
        p_duracion_horas,
        TRIM(p_lugar),
        p_num_equipos,
        p_costo_por_jugador,
        'abierta',
        v_current_user.id
    )
    RETURNING id INTO v_fecha_id;

    -- ========================================
    -- Notificar a jugadores aprobados (CA-007)
    -- ========================================
    FOR v_jugadores_aprobados IN
        SELECT id, nombre_completo
        FROM usuarios
        WHERE estado = 'aprobado'
        AND id != v_current_user.id -- No notificar al creador
    LOOP
        INSERT INTO notificaciones (
            usuario_id,
            tipo,
            titulo,
            mensaje,
            metadata
        ) VALUES (
            v_jugadores_aprobados.id,
            'general',
            'Nueva fecha de pichanga',
            'Se ha programado una nueva pichanga para el ' ||
                TO_CHAR(p_fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY') ||
                ' a las ' ||
                TO_CHAR(p_fecha_hora_inicio AT TIME ZONE 'America/Lima', 'HH24:MI') ||
                ' en ' || TRIM(p_lugar) ||
                '. Costo: S/ ' || TO_CHAR(p_costo_por_jugador, 'FM990.00'),
            jsonb_build_object(
                'fecha_id', v_fecha_id,
                'fecha_hora_inicio', p_fecha_hora_inicio,
                'lugar', TRIM(p_lugar),
                'costo', p_costo_por_jugador,
                'duracion_horas', p_duracion_horas,
                'num_equipos', p_num_equipos
            )
        );
    END LOOP;

    -- ========================================
    -- Retorno exitoso
    -- ========================================
    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'fecha_id', v_fecha_id,
            'fecha_hora_inicio', p_fecha_hora_inicio,
            'fecha_hora_local', p_fecha_hora_inicio AT TIME ZONE 'America/Lima',
            'fecha_formato', TO_CHAR(p_fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY HH24:MI'),
            'duracion_horas', p_duracion_horas,
            'lugar', TRIM(p_lugar),
            'num_equipos', p_num_equipos,
            'costo_por_jugador', p_costo_por_jugador,
            'costo_formato', 'S/ ' || TO_CHAR(p_costo_por_jugador, 'FM990.00'),
            'estado', 'abierta',
            'formato_juego', CASE
                WHEN p_num_equipos = 2 THEN '2 equipos - partido continuo'
                WHEN p_num_equipos = 3 THEN '3 equipos con rotacion'
                ELSE p_num_equipos || ' equipos'
            END,
            'created_by', v_current_user.id,
            'created_by_nombre', v_current_user.nombre_completo
        ),
        'message', 'Fecha de pichanga creada exitosamente. Se ha notificado a los jugadores.'
    );

EXCEPTION
    WHEN unique_violation THEN
        RETURN json_build_object(
            'success', false,
            'error', json_build_object(
                'code', 'UNIQUE_VIOLATION',
                'message', 'Ya existe una fecha programada para ese dia y hora',
                'hint', 'fecha_duplicada'
            )
        );
    WHEN check_violation THEN
        RETURN json_build_object(
            'success', false,
            'error', json_build_object(
                'code', 'CHECK_VIOLATION',
                'message', SQLERRM,
                'hint', 'validacion_fallida'
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
-- PARTE 3: PERMISOS
-- ============================================

GRANT EXECUTE ON FUNCTION crear_fecha(TIMESTAMPTZ, INTEGER, TEXT, INTEGER, NUMERIC) TO authenticated, service_role;

-- ============================================
-- PARTE 4: ACTUALIZAR COMENTARIOS
-- ============================================

COMMENT ON FUNCTION crear_fecha(TIMESTAMPTZ, INTEGER, TEXT, INTEGER, NUMERIC) IS 'E003-HU-001: Crea nueva fecha de pichanga con parametros directos (num_equipos, costo_por_jugador)';

-- ============================================
-- PARTE 5: ACTUALIZAR CHECK CONSTRAINT DE duracion_horas
-- Permitir 1, 2 o 3 horas
-- ============================================

ALTER TABLE fechas DROP CONSTRAINT IF EXISTS fechas_duracion_horas_check;
ALTER TABLE fechas ADD CONSTRAINT fechas_duracion_horas_check CHECK (duracion_horas >= 1 AND duracion_horas <= 3);

-- ============================================
-- FIN DEL SCRIPT
-- ============================================
