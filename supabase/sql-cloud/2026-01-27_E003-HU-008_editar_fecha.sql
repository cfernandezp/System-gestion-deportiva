-- ============================================
-- E003-HU-008: Editar Fecha
-- Fecha: 2026-01-27
-- Descripcion: Funcion RPC para editar fechas de pichanga existentes
--              con validaciones, recalculo de costos, ajuste de deudas
--              y notificaciones a inscritos
-- ============================================

-- ============================================
-- FUNCION RPC: editar_fecha
-- Descripcion: Edita una fecha de pichanga existente
-- Reglas: RN-001, RN-002, RN-003, RN-004, RN-005, RN-006, RN-007, RN-008
-- ============================================
CREATE OR REPLACE FUNCTION editar_fecha(
    p_fecha_id UUID,
    p_fecha_hora_inicio TIMESTAMPTZ,
    p_duracion_horas INTEGER,
    p_lugar TEXT
) RETURNS JSON AS $$
DECLARE
    v_error_hint TEXT;
    v_current_user_id UUID;
    v_current_user RECORD;
    v_fecha_actual RECORD;
    v_num_equipos_nuevo INTEGER;
    v_costo_nuevo DECIMAL(10,2);
    v_costo_anterior DECIMAL(10,2);
    v_cambio_fecha BOOLEAN := false;
    v_cambio_hora BOOLEAN := false;
    v_cambio_duracion BOOLEAN := false;
    v_cambio_lugar BOOLEAN := false;
    v_cambio_costo BOOLEAN := false;
    v_hay_cambios BOOLEAN := false;
    v_total_inscritos INTEGER;
    v_deudas_actualizadas INTEGER := 0;
    v_inscrito RECORD;
    v_cambios_texto TEXT := '';
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

    IF p_fecha_hora_inicio IS NULL THEN
        v_error_hint := 'fecha_hora_requerida';
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

    -- ========================================
    -- RN-001: Validacion - Solo admin aprobado puede editar
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
        RAISE EXCEPTION 'Solo los administradores aprobados pueden editar fechas de pichanga';
    END IF;

    -- ========================================
    -- Obtener datos actuales de la fecha
    -- ========================================
    SELECT id, fecha_hora_inicio, duracion_horas, lugar, num_equipos,
           costo_por_jugador, estado, created_by
    INTO v_fecha_actual
    FROM fechas
    WHERE id = p_fecha_id;

    IF NOT FOUND THEN
        v_error_hint := 'fecha_no_encontrada';
        RAISE EXCEPTION 'Fecha de pichanga no encontrada';
    END IF;

    -- ========================================
    -- RN-002: Validacion - Solo fechas con estado 'abierta'
    -- ========================================
    IF v_fecha_actual.estado != 'abierta' THEN
        v_error_hint := 'fecha_no_editable';
        RAISE EXCEPTION 'Solo se pueden editar fechas con estado "abierta". Estado actual: %', v_fecha_actual.estado;
    END IF;

    -- ========================================
    -- Validacion: Duracion valida (1 o 2 horas)
    -- ========================================
    IF p_duracion_horas NOT IN (1, 2) THEN
        v_error_hint := 'duracion_invalida';
        RAISE EXCEPTION 'La duracion debe ser 1 o 2 horas';
    END IF;

    -- ========================================
    -- RN-004: Validacion - Fecha futura obligatoria
    -- ========================================
    IF p_fecha_hora_inicio <= NOW() THEN
        v_error_hint := 'fecha_pasada';
        RAISE EXCEPTION 'La fecha y hora deben ser futuras';
    END IF;

    -- ========================================
    -- RN-005: Validacion - Unicidad de fecha/hora (excluyendo la propia)
    -- ========================================
    IF EXISTS (
        SELECT 1 FROM fechas
        WHERE fecha_hora_inicio = p_fecha_hora_inicio
        AND estado != 'cancelada'
        AND id != p_fecha_id  -- Excluir la fecha que se esta editando
    ) THEN
        v_error_hint := 'fecha_duplicada';
        RAISE EXCEPTION 'Ya existe otra fecha programada para ese dia y hora';
    END IF;

    -- ========================================
    -- RN-003: Calcular num_equipos y costo segun duracion
    -- 1 hora = 2 equipos, S/8.00 por jugador
    -- 2 horas = 3 equipos, S/10.00 por jugador
    -- ========================================
    IF p_duracion_horas = 1 THEN
        v_num_equipos_nuevo := 2;
        v_costo_nuevo := 8.00;
    ELSE -- p_duracion_horas = 2
        v_num_equipos_nuevo := 3;
        v_costo_nuevo := 10.00;
    END IF;

    v_costo_anterior := v_fecha_actual.costo_por_jugador;

    -- ========================================
    -- Detectar cambios para notificacion
    -- ========================================
    -- Cambio de fecha (solo dia)
    IF (p_fecha_hora_inicio AT TIME ZONE 'America/Lima')::date !=
       (v_fecha_actual.fecha_hora_inicio AT TIME ZONE 'America/Lima')::date THEN
        v_cambio_fecha := true;
        v_hay_cambios := true;
        v_cambios_texto := v_cambios_texto ||
            'Fecha: ' || TO_CHAR(v_fecha_actual.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY') ||
            ' -> ' || TO_CHAR(p_fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY') || '. ';
    END IF;

    -- Cambio de hora
    IF TO_CHAR(p_fecha_hora_inicio AT TIME ZONE 'America/Lima', 'HH24:MI') !=
       TO_CHAR(v_fecha_actual.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'HH24:MI') THEN
        v_cambio_hora := true;
        v_hay_cambios := true;
        v_cambios_texto := v_cambios_texto ||
            'Hora: ' || TO_CHAR(v_fecha_actual.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'HH24:MI') ||
            ' -> ' || TO_CHAR(p_fecha_hora_inicio AT TIME ZONE 'America/Lima', 'HH24:MI') || '. ';
    END IF;

    -- Cambio de duracion
    IF p_duracion_horas != v_fecha_actual.duracion_horas THEN
        v_cambio_duracion := true;
        v_hay_cambios := true;
        v_cambios_texto := v_cambios_texto ||
            'Duracion: ' || v_fecha_actual.duracion_horas || 'h -> ' || p_duracion_horas || 'h. ';
    END IF;

    -- Cambio de lugar
    IF TRIM(p_lugar) != v_fecha_actual.lugar THEN
        v_cambio_lugar := true;
        v_hay_cambios := true;
        v_cambios_texto := v_cambios_texto ||
            'Lugar: ' || v_fecha_actual.lugar || ' -> ' || TRIM(p_lugar) || '. ';
    END IF;

    -- Cambio de costo (derivado de duracion)
    IF v_costo_nuevo != v_costo_anterior THEN
        v_cambio_costo := true;
        v_cambios_texto := v_cambios_texto ||
            'Costo: S/ ' || TO_CHAR(v_costo_anterior, 'FM990.00') ||
            ' -> S/ ' || TO_CHAR(v_costo_nuevo, 'FM990.00') || '. ';
    END IF;

    -- Si no hay cambios, retornar sin hacer nada
    IF NOT v_hay_cambios THEN
        RETURN json_build_object(
            'success', true,
            'data', json_build_object(
                'fecha_id', p_fecha_id,
                'cambios_realizados', false
            ),
            'message', 'No se detectaron cambios en la fecha'
        );
    END IF;

    -- ========================================
    -- Actualizar la fecha (RN-008: updated_at se actualiza por trigger)
    -- ========================================
    UPDATE fechas
    SET fecha_hora_inicio = p_fecha_hora_inicio,
        duracion_horas = p_duracion_horas,
        lugar = TRIM(p_lugar),
        num_equipos = v_num_equipos_nuevo,
        costo_por_jugador = v_costo_nuevo
    WHERE id = p_fecha_id;

    -- ========================================
    -- RN-006: Ajustar deudas pendientes si cambio el costo
    -- Solo actualiza deudas con estado 'pendiente'
    -- Las pagadas o anuladas NO se modifican
    -- ========================================
    IF v_cambio_costo THEN
        UPDATE pagos
        SET monto = v_costo_nuevo,
            notas = COALESCE(notas, '') ||
                    CASE WHEN notas IS NOT NULL AND notas != '' THEN ' | ' ELSE '' END ||
                    'Monto ajustado por edicion de fecha (anterior: S/ ' ||
                    TO_CHAR(v_costo_anterior, 'FM990.00') || ')'
        WHERE fecha_id = p_fecha_id
        AND estado = 'pendiente';

        GET DIAGNOSTICS v_deudas_actualizadas = ROW_COUNT;
    END IF;

    -- ========================================
    -- RN-007: Notificar a inscritos si hay cambios
    -- ========================================
    SELECT COUNT(*) INTO v_total_inscritos
    FROM inscripciones
    WHERE fecha_id = p_fecha_id
    AND estado = 'inscrito';

    IF v_total_inscritos > 0 THEN
        FOR v_inscrito IN
            SELECT i.usuario_id, u.nombre_completo
            FROM inscripciones i
            JOIN usuarios u ON u.id = i.usuario_id
            WHERE i.fecha_id = p_fecha_id
            AND i.estado = 'inscrito'
        LOOP
            INSERT INTO notificaciones (
                usuario_id,
                tipo,
                titulo,
                mensaje,
                metadata
            ) VALUES (
                v_inscrito.usuario_id,
                'general',
                'Cambios en pichanga',
                'La pichanga del ' ||
                    TO_CHAR(p_fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY') ||
                    ' ha sido modificada. ' || v_cambios_texto,
                jsonb_build_object(
                    'fecha_id', p_fecha_id,
                    'tipo_evento', 'edicion_fecha',
                    'cambio_fecha', v_cambio_fecha,
                    'cambio_hora', v_cambio_hora,
                    'cambio_duracion', v_cambio_duracion,
                    'cambio_lugar', v_cambio_lugar,
                    'cambio_costo', v_cambio_costo,
                    'costo_anterior', v_costo_anterior,
                    'costo_nuevo', v_costo_nuevo,
                    'editado_por', v_current_user.nombre_completo
                )
            );
        END LOOP;
    END IF;

    -- ========================================
    -- Retorno exitoso
    -- ========================================
    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'fecha_id', p_fecha_id,
            'cambios_realizados', true,
            'fecha_hora_inicio', p_fecha_hora_inicio,
            'fecha_hora_local', p_fecha_hora_inicio AT TIME ZONE 'America/Lima',
            'fecha_formato', TO_CHAR(p_fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY'),
            'hora_formato', TO_CHAR(p_fecha_hora_inicio AT TIME ZONE 'America/Lima', 'HH24:MI'),
            'duracion_horas', p_duracion_horas,
            'lugar', TRIM(p_lugar),
            'num_equipos', v_num_equipos_nuevo,
            'costo_por_jugador', v_costo_nuevo,
            'costo_formato', 'S/ ' || TO_CHAR(v_costo_nuevo, 'FM990.00'),
            'estado', 'abierta',
            'formato_juego', CASE
                WHEN v_num_equipos_nuevo = 2 THEN '2 equipos - partido continuo'
                WHEN v_num_equipos_nuevo = 3 THEN '3 equipos con rotacion'
                ELSE v_num_equipos_nuevo || ' equipos'
            END,
            'cambios', json_build_object(
                'fecha', v_cambio_fecha,
                'hora', v_cambio_hora,
                'duracion', v_cambio_duracion,
                'lugar', v_cambio_lugar,
                'costo', v_cambio_costo
            ),
            'costo_anterior', v_costo_anterior,
            'deudas_actualizadas', v_deudas_actualizadas,
            'inscritos_notificados', v_total_inscritos,
            'resumen_cambios', v_cambios_texto
        ),
        'message', 'Fecha actualizada exitosamente.' ||
            CASE WHEN v_total_inscritos > 0
                 THEN ' Se notificaron ' || v_total_inscritos || ' jugador(es) inscrito(s).'
                 ELSE ''
            END ||
            CASE WHEN v_deudas_actualizadas > 0
                 THEN ' Se ajustaron ' || v_deudas_actualizadas || ' deuda(s) pendiente(s).'
                 ELSE ''
            END
    );

EXCEPTION
    WHEN unique_violation THEN
        RETURN json_build_object(
            'success', false,
            'error', json_build_object(
                'code', 'UNIQUE_VIOLATION',
                'message', 'Ya existe otra fecha programada para ese dia y hora',
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
-- PERMISOS
-- ============================================

GRANT EXECUTE ON FUNCTION editar_fecha(UUID, TIMESTAMPTZ, INTEGER, TEXT) TO authenticated, service_role;

-- ============================================
-- COMENTARIOS DE DOCUMENTACION
-- ============================================

COMMENT ON FUNCTION editar_fecha IS 'E003-HU-008: Edita fecha de pichanga con validaciones (RN-001 a RN-008), ajuste de deudas y notificaciones';

-- ============================================
-- FIN DEL SCRIPT
-- ============================================
