-- ============================================
-- FIX: crear_fecha y editar_fecha - Campos independientes
-- Fecha: 2026-02-21
-- Descripcion: Reemplaza la logica de auto-calculo de num_equipos
--   y costo_por_jugador por parametros directos del admin.
--   Tambien cambia duracion_horas de INTEGER a NUMERIC(3,1)
--   para soportar valores como 1.0, 1.5, 2.0 ... 5.0
-- ============================================

-- ============================================
-- PASO 1: ALTER tabla fechas - duracion_horas a NUMERIC(3,1)
-- Permite valores: 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0
-- ============================================
ALTER TABLE fechas ALTER COLUMN duracion_horas TYPE NUMERIC(3,1)
    USING duracion_horas::NUMERIC(3,1);

-- ============================================
-- PASO 2: DROP de funciones anteriores
-- Se hace DROP explicito para eliminar la firma vieja (INTEGER)
-- y evitar conflicto de overload con la nueva (NUMERIC)
-- ============================================
DROP FUNCTION IF EXISTS crear_fecha(TIMESTAMPTZ, INTEGER, TEXT);
DROP FUNCTION IF EXISTS crear_fecha(TIMESTAMPTZ, INTEGER, TEXT, INTEGER, NUMERIC);
DROP FUNCTION IF EXISTS crear_fecha(TIMESTAMPTZ, NUMERIC, TEXT, INTEGER, NUMERIC);

DROP FUNCTION IF EXISTS editar_fecha(UUID, TIMESTAMPTZ, INTEGER, TEXT);
DROP FUNCTION IF EXISTS editar_fecha(UUID, TIMESTAMPTZ, INTEGER, TEXT, INTEGER, NUMERIC);
DROP FUNCTION IF EXISTS editar_fecha(UUID, TIMESTAMPTZ, NUMERIC, TEXT, INTEGER, NUMERIC);

-- ============================================
-- PASO 3: RPC crear_fecha (nueva firma)
-- Parametros independientes: admin elige num_equipos y costo
-- Validacion de num_equipos contra plan del usuario
-- ============================================
CREATE OR REPLACE FUNCTION crear_fecha(
    p_fecha_hora_inicio  TIMESTAMPTZ,
    p_duracion_horas     NUMERIC(3,1),
    p_lugar              TEXT,
    p_num_equipos        INTEGER DEFAULT 2,
    p_costo_por_jugador  NUMERIC(10,2) DEFAULT 0.00
) RETURNS JSON AS $$
DECLARE
    v_usuario_id UUID;
    v_auth_uid UUID;
    v_fecha_id UUID;
    v_lugar_limpio TEXT;
    v_max_equipos INTEGER;
    v_plan_nombre TEXT;
    v_formato_juego TEXT;
    v_error_hint TEXT;
BEGIN
    -- =============================================
    -- Verificar autenticacion
    -- =============================================
    v_auth_uid := auth.uid();
    IF v_auth_uid IS NULL THEN
        v_error_hint := 'no_autenticado';
        RAISE EXCEPTION 'Debes iniciar sesion para crear una fecha';
    END IF;

    -- Obtener usuario_id
    SELECT id INTO v_usuario_id
    FROM usuarios
    WHERE auth_user_id = v_auth_uid;

    IF v_usuario_id IS NULL THEN
        v_error_hint := 'usuario_no_encontrado';
        RAISE EXCEPTION 'No se encontro el perfil de usuario';
    END IF;

    -- =============================================
    -- Verificar rol: admin o coadmin en algun grupo activo
    -- =============================================
    IF NOT EXISTS (
        SELECT 1 FROM miembros_grupo
        WHERE usuario_id = v_usuario_id
        AND rol IN ('admin', 'coadmin')
        AND activo = TRUE
    ) THEN
        v_error_hint := 'sin_permisos';
        RAISE EXCEPTION 'Solo administradores o co-administradores pueden crear fechas';
    END IF;

    -- =============================================
    -- Validar duracion_horas
    -- Valores permitidos: 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0
    -- =============================================
    IF p_duracion_horas NOT IN (1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0) THEN
        v_error_hint := 'duracion_invalida';
        RAISE EXCEPTION 'La duracion debe ser 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5 o 5.0 horas';
    END IF;

    -- =============================================
    -- Validar lugar (min 3 caracteres)
    -- =============================================
    v_lugar_limpio := TRIM(p_lugar);

    IF v_lugar_limpio IS NULL OR LENGTH(v_lugar_limpio) < 3 THEN
        v_error_hint := 'lugar_invalido';
        RAISE EXCEPTION 'El lugar debe tener al menos 3 caracteres';
    END IF;

    -- =============================================
    -- Validar num_equipos (2 a 4)
    -- =============================================
    IF p_num_equipos < 2 OR p_num_equipos > 4 THEN
        v_error_hint := 'num_equipos_invalido';
        RAISE EXCEPTION 'El numero de equipos debe ser entre 2 y 4';
    END IF;

    -- =============================================
    -- Validar num_equipos contra plan del usuario
    -- =============================================
    SELECT p.max_equipos_por_fecha, p.nombre
    INTO v_max_equipos, v_plan_nombre
    FROM usuarios u
    JOIN planes p ON p.id = u.plan_id
    WHERE u.id = v_usuario_id;

    -- Si no tiene plan asignado, usar plan Gratis
    IF v_max_equipos IS NULL THEN
        SELECT p.max_equipos_por_fecha, p.nombre
        INTO v_max_equipos, v_plan_nombre
        FROM planes p
        WHERE p.slug = 'gratis'
        LIMIT 1;
    END IF;

    IF p_num_equipos > v_max_equipos THEN
        v_error_hint := 'limite_plan_equipos';
        RAISE EXCEPTION 'Tu plan (%) permite maximo % equipos por fecha. Actualiza tu plan para usar mas equipos.',
            v_plan_nombre, v_max_equipos;
    END IF;

    -- =============================================
    -- Validar costo_por_jugador (0.00 a 100.00)
    -- =============================================
    IF p_costo_por_jugador < 0.00 OR p_costo_por_jugador > 100.00 THEN
        v_error_hint := 'costo_invalido';
        RAISE EXCEPTION 'El costo por jugador debe ser entre S/ 0.00 y S/ 100.00';
    END IF;

    -- =============================================
    -- Validar fecha futura (hora Peru: UTC-5)
    -- =============================================
    IF p_fecha_hora_inicio <= NOW() THEN
        v_error_hint := 'fecha_pasada';
        RAISE EXCEPTION 'La fecha y hora de inicio debe ser futura';
    END IF;

    -- =============================================
    -- Determinar formato de juego (solo informativo)
    -- =============================================
    IF p_num_equipos = 2 THEN
        v_formato_juego := '2 equipos - Partido continuo';
    ELSE
        v_formato_juego := p_num_equipos || ' equipos - Rotacion';
    END IF;

    -- =============================================
    -- INSERT en tabla fechas
    -- Sin auto-calculo: usa los valores directos del admin
    -- =============================================
    INSERT INTO fechas (
        fecha_hora_inicio,
        duracion_horas,
        lugar,
        num_equipos,
        costo_por_jugador,
        estado,
        created_by,
        created_at,
        updated_at
    ) VALUES (
        p_fecha_hora_inicio,
        p_duracion_horas,
        v_lugar_limpio,
        p_num_equipos,
        p_costo_por_jugador,
        'abierta',
        v_usuario_id,
        NOW(),
        NOW()
    )
    RETURNING id INTO v_fecha_id;

    -- =============================================
    -- Retornar resultado exitoso
    -- Formato compatible con FechaModel.fromJson del Flutter
    -- =============================================
    RETURN json_build_object(
        'success', TRUE,
        'message', 'Fecha creada exitosamente',
        'data', json_build_object(
            'fecha_id', v_fecha_id,
            'fecha_hora_inicio', p_fecha_hora_inicio,
            'fecha_hora_local', p_fecha_hora_inicio AT TIME ZONE 'America/Lima',
            'fecha_formato', TO_CHAR(p_fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY'),
            'hora_formato', TO_CHAR(p_fecha_hora_inicio AT TIME ZONE 'America/Lima', 'HH24:MI'),
            'duracion_horas', p_duracion_horas,
            'lugar', v_lugar_limpio,
            'num_equipos', p_num_equipos,
            'costo_por_jugador', p_costo_por_jugador,
            'costo_formato', 'S/ ' || TO_CHAR(p_costo_por_jugador, 'FM999,999,990.00'),
            'estado', 'abierta',
            'formato_juego', v_formato_juego,
            'created_by', v_usuario_id,
            'created_by_nombre', (SELECT nombre_completo FROM usuarios WHERE id = v_usuario_id),
            'created_at', NOW()
        )
    );

EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', FALSE,
            'error', json_build_object(
                'message', SQLERRM,
                'code', SQLSTATE,
                'hint', COALESCE(v_error_hint, 'error_desconocido')
            )
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Permisos crear_fecha
GRANT EXECUTE ON FUNCTION crear_fecha(TIMESTAMPTZ, NUMERIC, TEXT, INTEGER, NUMERIC) TO authenticated;

COMMENT ON FUNCTION crear_fecha IS 'Crea una fecha/pichanga. Admin elige duracion, equipos y costo independientemente.';

-- ============================================
-- PASO 4: RPC editar_fecha (nueva firma)
-- Mismas validaciones que crear_fecha
-- Ademas: solo fechas 'abierta', actualiza deudas si cambia costo
-- ============================================
CREATE OR REPLACE FUNCTION editar_fecha(
    p_fecha_id           UUID,
    p_fecha_hora_inicio  TIMESTAMPTZ,
    p_duracion_horas     NUMERIC(3,1),
    p_lugar              TEXT,
    p_num_equipos        INTEGER DEFAULT 2,
    p_costo_por_jugador  NUMERIC(10,2) DEFAULT 0.00
) RETURNS JSON AS $$
DECLARE
    v_usuario_id UUID;
    v_auth_uid UUID;
    v_fecha RECORD;
    v_lugar_limpio TEXT;
    v_max_equipos INTEGER;
    v_plan_nombre TEXT;
    v_formato_juego TEXT;
    v_cambio_fecha BOOLEAN := FALSE;
    v_cambio_hora BOOLEAN := FALSE;
    v_cambio_duracion BOOLEAN := FALSE;
    v_cambio_lugar BOOLEAN := FALSE;
    v_cambio_costo BOOLEAN := FALSE;
    v_cambio_equipos BOOLEAN := FALSE;
    v_costo_anterior NUMERIC(10,2);
    v_deudas_actualizadas INTEGER := 0;
    v_inscritos_count INTEGER := 0;
    v_resumen_cambios TEXT := '';
    v_cambios_realizados BOOLEAN := FALSE;
    v_error_hint TEXT;
BEGIN
    -- =============================================
    -- Verificar autenticacion
    -- =============================================
    v_auth_uid := auth.uid();
    IF v_auth_uid IS NULL THEN
        v_error_hint := 'no_autenticado';
        RAISE EXCEPTION 'Debes iniciar sesion para editar una fecha';
    END IF;

    -- Obtener usuario_id
    SELECT id INTO v_usuario_id
    FROM usuarios
    WHERE auth_user_id = v_auth_uid;

    IF v_usuario_id IS NULL THEN
        v_error_hint := 'usuario_no_encontrado';
        RAISE EXCEPTION 'No se encontro el perfil de usuario';
    END IF;

    -- =============================================
    -- Obtener fecha actual
    -- =============================================
    SELECT f.id, f.fecha_hora_inicio, f.duracion_horas, f.lugar,
           f.num_equipos, f.costo_por_jugador, f.estado, f.created_by
    INTO v_fecha
    FROM fechas f
    WHERE f.id = p_fecha_id;

    IF v_fecha IS NULL THEN
        v_error_hint := 'fecha_no_encontrada';
        RAISE EXCEPTION 'No se encontro la fecha indicada';
    END IF;

    -- =============================================
    -- Verificar estado: solo fechas 'abierta' se pueden editar
    -- =============================================
    IF v_fecha.estado != 'abierta' THEN
        v_error_hint := 'fecha_no_editable';
        RAISE EXCEPTION 'Solo se pueden editar fechas con estado "abierta". Estado actual: %', v_fecha.estado;
    END IF;

    -- =============================================
    -- Verificar permisos: admin o coadmin del grupo
    -- El creador de la fecha siempre puede editar,
    -- o cualquier admin/coadmin de un grupo activo
    -- =============================================
    IF v_fecha.created_by != v_usuario_id THEN
        IF NOT EXISTS (
            SELECT 1 FROM miembros_grupo
            WHERE usuario_id = v_usuario_id
            AND rol IN ('admin', 'coadmin')
            AND activo = TRUE
        ) THEN
            v_error_hint := 'sin_permisos';
            RAISE EXCEPTION 'Solo el creador o un administrador/co-administrador puede editar esta fecha';
        END IF;
    END IF;

    -- =============================================
    -- Validar duracion_horas
    -- =============================================
    IF p_duracion_horas NOT IN (1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0) THEN
        v_error_hint := 'duracion_invalida';
        RAISE EXCEPTION 'La duracion debe ser 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5 o 5.0 horas';
    END IF;

    -- =============================================
    -- Validar lugar (min 3 caracteres)
    -- =============================================
    v_lugar_limpio := TRIM(p_lugar);

    IF v_lugar_limpio IS NULL OR LENGTH(v_lugar_limpio) < 3 THEN
        v_error_hint := 'lugar_invalido';
        RAISE EXCEPTION 'El lugar debe tener al menos 3 caracteres';
    END IF;

    -- =============================================
    -- Validar num_equipos (2 a 4)
    -- =============================================
    IF p_num_equipos < 2 OR p_num_equipos > 4 THEN
        v_error_hint := 'num_equipos_invalido';
        RAISE EXCEPTION 'El numero de equipos debe ser entre 2 y 4';
    END IF;

    -- =============================================
    -- Validar num_equipos contra plan del usuario
    -- =============================================
    SELECT p.max_equipos_por_fecha, p.nombre
    INTO v_max_equipos, v_plan_nombre
    FROM usuarios u
    JOIN planes p ON p.id = u.plan_id
    WHERE u.id = v_usuario_id;

    IF v_max_equipos IS NULL THEN
        SELECT p.max_equipos_por_fecha, p.nombre
        INTO v_max_equipos, v_plan_nombre
        FROM planes p
        WHERE p.slug = 'gratis'
        LIMIT 1;
    END IF;

    IF p_num_equipos > v_max_equipos THEN
        v_error_hint := 'limite_plan_equipos';
        RAISE EXCEPTION 'Tu plan (%) permite maximo % equipos por fecha. Actualiza tu plan para usar mas equipos.',
            v_plan_nombre, v_max_equipos;
    END IF;

    -- =============================================
    -- Validar costo_por_jugador (0.00 a 100.00)
    -- =============================================
    IF p_costo_por_jugador < 0.00 OR p_costo_por_jugador > 100.00 THEN
        v_error_hint := 'costo_invalido';
        RAISE EXCEPTION 'El costo por jugador debe ser entre S/ 0.00 y S/ 100.00';
    END IF;

    -- =============================================
    -- Validar fecha futura
    -- =============================================
    IF p_fecha_hora_inicio <= NOW() THEN
        v_error_hint := 'fecha_pasada';
        RAISE EXCEPTION 'La fecha y hora de inicio debe ser futura';
    END IF;

    -- =============================================
    -- Detectar cambios
    -- =============================================
    -- Comparar dia (fecha sin hora)
    v_cambio_fecha := (p_fecha_hora_inicio AT TIME ZONE 'America/Lima')::date
                   != (v_fecha.fecha_hora_inicio AT TIME ZONE 'America/Lima')::date;

    -- Comparar hora (hora:minuto)
    v_cambio_hora := TO_CHAR(p_fecha_hora_inicio AT TIME ZONE 'America/Lima', 'HH24:MI')
                  != TO_CHAR(v_fecha.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'HH24:MI');

    v_cambio_duracion := p_duracion_horas != v_fecha.duracion_horas;
    v_cambio_lugar := v_lugar_limpio != v_fecha.lugar;
    v_cambio_costo := p_costo_por_jugador != v_fecha.costo_por_jugador;
    v_cambio_equipos := p_num_equipos != v_fecha.num_equipos;

    v_cambios_realizados := v_cambio_fecha OR v_cambio_hora OR v_cambio_duracion
                         OR v_cambio_lugar OR v_cambio_costo OR v_cambio_equipos;

    -- Guardar costo anterior si cambio
    IF v_cambio_costo THEN
        v_costo_anterior := v_fecha.costo_por_jugador;
    END IF;

    -- =============================================
    -- UPDATE en tabla fechas
    -- =============================================
    UPDATE fechas SET
        fecha_hora_inicio = p_fecha_hora_inicio,
        duracion_horas    = p_duracion_horas,
        lugar             = v_lugar_limpio,
        num_equipos       = p_num_equipos,
        costo_por_jugador = p_costo_por_jugador,
        updated_at        = NOW()
    WHERE id = p_fecha_id;

    -- =============================================
    -- Si cambio el costo, actualizar deudas pendientes en pagos
    -- Solo actualiza pagos con estado 'pendiente' de esta fecha
    -- =============================================
    IF v_cambio_costo THEN
        UPDATE pagos SET
            monto = p_costo_por_jugador,
            notas = COALESCE(notas, '') ||
                    CASE WHEN notas IS NOT NULL AND notas != '' THEN ' | ' ELSE '' END ||
                    'Costo actualizado de S/' || TO_CHAR(v_costo_anterior, 'FM990.00') ||
                    ' a S/' || TO_CHAR(p_costo_por_jugador, 'FM990.00') ||
                    ' el ' || TO_CHAR(NOW() AT TIME ZONE 'America/Lima', 'DD/MM/YYYY HH24:MI'),
            updated_at = NOW()
        WHERE fecha_id = p_fecha_id
        AND estado = 'pendiente';

        GET DIAGNOSTICS v_deudas_actualizadas = ROW_COUNT;
    END IF;

    -- =============================================
    -- Contar inscritos (para informar)
    -- =============================================
    SELECT COUNT(*) INTO v_inscritos_count
    FROM inscripciones
    WHERE fecha_id = p_fecha_id
    AND estado = 'inscrito';

    -- =============================================
    -- Construir resumen de cambios
    -- =============================================
    IF v_cambio_fecha THEN
        v_resumen_cambios := v_resumen_cambios || 'Fecha cambiada. ';
    END IF;
    IF v_cambio_hora THEN
        v_resumen_cambios := v_resumen_cambios || 'Hora cambiada. ';
    END IF;
    IF v_cambio_duracion THEN
        v_resumen_cambios := v_resumen_cambios || 'Duracion cambiada a ' || p_duracion_horas || 'h. ';
    END IF;
    IF v_cambio_lugar THEN
        v_resumen_cambios := v_resumen_cambios || 'Lugar cambiado. ';
    END IF;
    IF v_cambio_equipos THEN
        v_resumen_cambios := v_resumen_cambios || 'Equipos cambiados a ' || p_num_equipos || '. ';
    END IF;
    IF v_cambio_costo THEN
        v_resumen_cambios := v_resumen_cambios || 'Costo cambiado de S/' ||
            TO_CHAR(v_costo_anterior, 'FM990.00') || ' a S/' ||
            TO_CHAR(p_costo_por_jugador, 'FM990.00') || '. ';
        IF v_deudas_actualizadas > 0 THEN
            v_resumen_cambios := v_resumen_cambios || v_deudas_actualizadas || ' deuda(s) actualizada(s). ';
        END IF;
    END IF;

    IF NOT v_cambios_realizados THEN
        v_resumen_cambios := 'Sin cambios detectados.';
    END IF;

    -- =============================================
    -- Determinar formato de juego
    -- =============================================
    IF p_num_equipos = 2 THEN
        v_formato_juego := '2 equipos - Partido continuo';
    ELSE
        v_formato_juego := p_num_equipos || ' equipos - Rotacion';
    END IF;

    -- =============================================
    -- Retornar resultado exitoso
    -- Formato compatible con EditarFechaResponseModel.fromJson
    -- =============================================
    RETURN json_build_object(
        'success', TRUE,
        'message', CASE
            WHEN v_cambios_realizados THEN 'Fecha actualizada exitosamente'
            ELSE 'No se detectaron cambios'
        END,
        'data', json_build_object(
            'fecha_id', p_fecha_id,
            'cambios_realizados', v_cambios_realizados,
            'fecha_hora_inicio', p_fecha_hora_inicio,
            'fecha_hora_local', p_fecha_hora_inicio AT TIME ZONE 'America/Lima',
            'fecha_formato', TO_CHAR(p_fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY'),
            'hora_formato', TO_CHAR(p_fecha_hora_inicio AT TIME ZONE 'America/Lima', 'HH24:MI'),
            'duracion_horas', p_duracion_horas,
            'lugar', v_lugar_limpio,
            'num_equipos', p_num_equipos,
            'costo_por_jugador', p_costo_por_jugador,
            'costo_formato', 'S/ ' || TO_CHAR(p_costo_por_jugador, 'FM999,999,990.00'),
            'estado', v_fecha.estado,
            'formato_juego', v_formato_juego,
            'cambios', json_build_object(
                'fecha', v_cambio_fecha,
                'hora', v_cambio_hora,
                'duracion', v_cambio_duracion,
                'lugar', v_cambio_lugar,
                'costo', v_cambio_costo,
                'equipos', v_cambio_equipos
            ),
            'costo_anterior', v_costo_anterior,
            'deudas_actualizadas', v_deudas_actualizadas,
            'inscritos_notificados', v_inscritos_count,
            'resumen_cambios', TRIM(v_resumen_cambios)
        )
    );

EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', FALSE,
            'error', json_build_object(
                'message', SQLERRM,
                'code', SQLSTATE,
                'hint', COALESCE(v_error_hint, 'error_desconocido')
            )
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Permisos editar_fecha
GRANT EXECUTE ON FUNCTION editar_fecha(UUID, TIMESTAMPTZ, NUMERIC, TEXT, INTEGER, NUMERIC) TO authenticated;

COMMENT ON FUNCTION editar_fecha IS 'Edita una fecha/pichanga abierta. Admin define duracion, equipos y costo independientemente. Actualiza deudas pendientes si cambia el costo.';
