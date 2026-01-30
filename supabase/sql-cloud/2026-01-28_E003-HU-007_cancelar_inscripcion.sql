-- ============================================
-- E003-HU-007: Cancelar Inscripcion
-- Fecha: 2026-01-28
-- Descripcion: Implementacion de funciones RPC para cancelar inscripciones
--              de jugadores a fechas de pichanga con auditoria y notificaciones
-- ============================================

-- ============================================
-- PARTE 1: ALTER TABLE - Agregar columnas de auditoria a inscripciones
-- ============================================

-- Agregar columnas para auditoria de cancelacion (si no existen)
DO $$
BEGIN
    -- Columna cancelado_at: Timestamp de cuando se cancelo
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'inscripciones'
        AND column_name = 'cancelado_at'
    ) THEN
        ALTER TABLE inscripciones ADD COLUMN cancelado_at TIMESTAMPTZ;
        COMMENT ON COLUMN inscripciones.cancelado_at IS 'Timestamp de cancelacion de la inscripcion (UTC)';
    END IF;

    -- Columna cancelado_por: Quien realizo la cancelacion
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'inscripciones'
        AND column_name = 'cancelado_por'
    ) THEN
        ALTER TABLE inscripciones ADD COLUMN cancelado_por UUID REFERENCES usuarios(id);
        COMMENT ON COLUMN inscripciones.cancelado_por IS 'ID del usuario que cancelo la inscripcion (puede ser el mismo usuario o un admin)';
    END IF;
END $$;

-- Indice para consultas de cancelaciones
CREATE INDEX IF NOT EXISTS idx_inscripciones_cancelado_at ON inscripciones(cancelado_at)
WHERE cancelado_at IS NOT NULL;

-- ============================================
-- PARTE 2: FUNCION RPC cancelar_inscripcion (mejorada)
-- ============================================

-- ============================================
-- Funcion: cancelar_inscripcion
-- Descripcion: Permite a un jugador cancelar su propia inscripcion a una fecha
-- Reglas: RN-001, RN-002, RN-003, RN-004, RN-005, RN-006
-- CA: CA-001, CA-002, CA-003, CA-004, CA-005, CA-007
-- ============================================
CREATE OR REPLACE FUNCTION cancelar_inscripcion(
    p_fecha_id UUID
) RETURNS JSON AS $$
DECLARE
    v_error_hint TEXT;
    v_current_user_id UUID;
    v_current_user RECORD;
    v_fecha RECORD;
    v_inscripcion RECORD;
    v_pago_anulado BOOLEAN;
    v_asignacion_eliminada BOOLEAN;
    v_admin_record RECORD;
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
    SELECT id, fecha_hora_inicio, lugar, estado, costo_por_jugador
    INTO v_fecha
    FROM fechas
    WHERE id = p_fecha_id;

    IF NOT FOUND THEN
        v_error_hint := 'fecha_no_encontrada';
        RAISE EXCEPTION 'Fecha de pichanga no encontrada';
    END IF;

    -- ========================================
    -- Verificar que el usuario esta inscrito
    -- CA-001: Solo si esta inscrito puede ver opcion cancelar
    -- ========================================
    SELECT id, estado, usuario_id
    INTO v_inscripcion
    FROM inscripciones
    WHERE fecha_id = p_fecha_id
    AND usuario_id = v_current_user.id
    AND estado = 'inscrito';

    IF NOT FOUND THEN
        v_error_hint := 'no_inscrito';
        RAISE EXCEPTION 'No estas inscrito a esta fecha de pichanga';
    END IF;

    -- ========================================
    -- RN-001: Cancelacion libre si fecha.estado = 'abierta'
    -- RN-002: Bloqueo si fecha.estado != 'abierta' (jugador no puede cancelar solo)
    -- CA-005: Mensaje "Contacta al administrador" si cerrada
    -- ========================================
    IF v_fecha.estado != 'abierta' THEN
        v_error_hint := 'fecha_cerrada';
        RAISE EXCEPTION 'Las inscripciones estan cerradas. Contacta al administrador para cancelar tu inscripcion';
    END IF;

    -- ========================================
    -- RN-006: Soft delete - Cambiar estado a 'cancelado' con auditoria
    -- CA-003: Cancelacion exitosa
    -- ========================================
    UPDATE inscripciones
    SET estado = 'cancelado',
        cancelado_at = NOW(),
        cancelado_por = v_current_user.id
    WHERE id = v_inscripcion.id;

    -- ========================================
    -- RN-003: Si fecha abierta, anular deuda
    -- CA-003: "mi deuda asociada se anula"
    -- ========================================
    v_pago_anulado := FALSE;

    UPDATE pagos
    SET estado = 'anulado',
        notas = COALESCE(notas || ' | ', '') ||
                'Deuda anulada por cancelacion de inscripcion (fecha abierta) - ' ||
                TO_CHAR(NOW() AT TIME ZONE 'America/Lima', 'DD/MM/YYYY HH24:MI')
    WHERE inscripcion_id = v_inscripcion.id
    AND estado = 'pendiente';

    IF FOUND THEN
        v_pago_anulado := TRUE;
    END IF;

    -- ========================================
    -- RN-004: Eliminar asignacion de equipo si existe
    -- La tabla asignaciones_equipos puede no existir aun
    -- ========================================
    v_asignacion_eliminada := FALSE;

    IF EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public'
        AND table_name = 'asignaciones_equipos'
    ) THEN
        DELETE FROM asignaciones_equipos
        WHERE fecha_id = p_fecha_id
        AND usuario_id = v_current_user.id;

        IF FOUND THEN
            v_asignacion_eliminada := TRUE;
        END IF;
    END IF;

    -- ========================================
    -- RN-005: Notificar a admin(s)
    -- CA-007: Admin recibe notificacion de la baja
    -- Mensaje: "[Jugador] cancelo su inscripcion para [fecha]"
    -- ========================================
    FOR v_admin_record IN
        SELECT id, nombre_completo
        FROM usuarios
        WHERE rol = 'admin'
        AND estado = 'aprobado'
        AND id != v_current_user.id
    LOOP
        INSERT INTO notificaciones (
            usuario_id,
            tipo,
            titulo,
            mensaje,
            metadata
        ) VALUES (
            v_admin_record.id,
            'general',
            'Cancelacion de inscripcion',
            v_current_user.nombre_completo || ' cancelo su inscripcion para la pichanga del ' ||
                TO_CHAR(v_fecha.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY') ||
                ' a las ' ||
                TO_CHAR(v_fecha.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'HH24:MI') ||
                ' (deuda anulada)',
            jsonb_build_object(
                'fecha_id', p_fecha_id,
                'inscripcion_id', v_inscripcion.id,
                'usuario_id', v_current_user.id,
                'usuario_nombre', v_current_user.nombre_completo,
                'tipo_evento', 'cancelacion_propia',
                'deuda_anulada', v_pago_anulado,
                'asignacion_eliminada', v_asignacion_eliminada
            )
        );
    END LOOP;

    -- ========================================
    -- Retorno exitoso
    -- CA-003: Mensaje "Inscripcion cancelada"
    -- CA-004: Puede volver a inscribirse (fecha sigue abierta)
    -- ========================================
    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'inscripcion_id', v_inscripcion.id,
            'fecha_id', p_fecha_id,
            'fecha_formato', TO_CHAR(v_fecha.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY HH24:MI'),
            'lugar', v_fecha.lugar,
            'estado_inscripcion', 'cancelado',
            'deuda_anulada', v_pago_anulado,
            'asignacion_eliminada', v_asignacion_eliminada,
            'puede_reinscribirse', TRUE,
            'cancelado_at', NOW() AT TIME ZONE 'America/Lima',
            'cancelado_at_formato', TO_CHAR(NOW() AT TIME ZONE 'America/Lima', 'DD/MM/YYYY HH24:MI')
        ),
        'message', 'Inscripcion cancelada. Tu deuda ha sido anulada. Puedes volver a inscribirte si cambias de opinion.'
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
-- PARTE 3: FUNCION RPC cancelar_inscripcion_admin
-- ============================================

-- ============================================
-- Funcion: cancelar_inscripcion_admin
-- Descripcion: Permite a un admin cancelar la inscripcion de cualquier jugador
--              en cualquier estado de la fecha (excepto finalizada)
-- Reglas: RN-002 (caso especial admin), RN-003, RN-004, RN-005, RN-006
-- CA: CA-006
-- ============================================
CREATE OR REPLACE FUNCTION cancelar_inscripcion_admin(
    p_inscripcion_id UUID,
    p_anular_deuda BOOLEAN DEFAULT FALSE
) RETURNS JSON AS $$
DECLARE
    v_error_hint TEXT;
    v_current_user_id UUID;
    v_current_user RECORD;
    v_inscripcion RECORD;
    v_fecha RECORD;
    v_jugador RECORD;
    v_pago_anulado BOOLEAN;
    v_asignacion_eliminada BOOLEAN;
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
    IF p_inscripcion_id IS NULL THEN
        v_error_hint := 'inscripcion_id_requerido';
        RAISE EXCEPTION 'El ID de la inscripcion es obligatorio';
    END IF;

    -- ========================================
    -- RN-002 (caso especial): Solo admin aprobado puede cancelar
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
        RAISE EXCEPTION 'Solo los administradores aprobados pueden cancelar inscripciones de otros jugadores';
    END IF;

    -- ========================================
    -- Obtener datos de la inscripcion
    -- ========================================
    SELECT i.id, i.fecha_id, i.usuario_id, i.estado
    INTO v_inscripcion
    FROM inscripciones i
    WHERE i.id = p_inscripcion_id;

    IF NOT FOUND THEN
        v_error_hint := 'inscripcion_no_encontrada';
        RAISE EXCEPTION 'Inscripcion no encontrada';
    END IF;

    -- Verificar que la inscripcion esta activa
    IF v_inscripcion.estado != 'inscrito' THEN
        v_error_hint := 'inscripcion_no_activa';
        RAISE EXCEPTION 'La inscripcion ya esta cancelada o no esta activa';
    END IF;

    -- ========================================
    -- Obtener datos del jugador afectado
    -- ========================================
    SELECT id, nombre_completo, email
    INTO v_jugador
    FROM usuarios
    WHERE id = v_inscripcion.usuario_id;

    IF NOT FOUND THEN
        v_error_hint := 'jugador_no_encontrado';
        RAISE EXCEPTION 'Jugador no encontrado';
    END IF;

    -- ========================================
    -- Obtener datos de la fecha
    -- ========================================
    SELECT id, fecha_hora_inicio, lugar, estado, costo_por_jugador
    INTO v_fecha
    FROM fechas
    WHERE id = v_inscripcion.fecha_id;

    IF NOT FOUND THEN
        v_error_hint := 'fecha_no_encontrada';
        RAISE EXCEPTION 'Fecha de pichanga no encontrada';
    END IF;

    -- ========================================
    -- Validar que la fecha no este finalizada
    -- Admin puede cancelar en: abierta, cerrada, en_juego
    -- ========================================
    IF v_fecha.estado = 'finalizada' THEN
        v_error_hint := 'fecha_finalizada';
        RAISE EXCEPTION 'No se pueden modificar inscripciones de una fecha finalizada';
    END IF;

    -- ========================================
    -- RN-006: Soft delete con auditoria
    -- cancelado_por = admin_id (diferente al usuario_id del jugador)
    -- ========================================
    UPDATE inscripciones
    SET estado = 'cancelado',
        cancelado_at = NOW(),
        cancelado_por = v_current_user.id
    WHERE id = p_inscripcion_id;

    -- ========================================
    -- RN-003: Gestionar deuda segun p_anular_deuda
    -- Si fecha abierta: siempre se anula
    -- Si fecha cerrada: segun parametro p_anular_deuda (criterio admin)
    -- ========================================
    v_pago_anulado := FALSE;

    IF v_fecha.estado = 'abierta' OR p_anular_deuda = TRUE THEN
        UPDATE pagos
        SET estado = 'anulado',
            notas = COALESCE(notas || ' | ', '') ||
                    'Deuda anulada por admin (' || v_current_user.nombre_completo || ') - ' ||
                    TO_CHAR(NOW() AT TIME ZONE 'America/Lima', 'DD/MM/YYYY HH24:MI')
        WHERE inscripcion_id = p_inscripcion_id
        AND estado = 'pendiente';

        IF FOUND THEN
            v_pago_anulado := TRUE;
        END IF;
    END IF;

    -- ========================================
    -- RN-004: Eliminar asignacion de equipo si existe
    -- ========================================
    v_asignacion_eliminada := FALSE;

    IF EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public'
        AND table_name = 'asignaciones_equipos'
    ) THEN
        DELETE FROM asignaciones_equipos
        WHERE fecha_id = v_inscripcion.fecha_id
        AND usuario_id = v_inscripcion.usuario_id;

        IF FOUND THEN
            v_asignacion_eliminada := TRUE;
        END IF;
    END IF;

    -- ========================================
    -- RN-005: Notificar al jugador afectado
    -- CA-006: "el jugador recibe notificacion de la cancelacion"
    -- ========================================
    INSERT INTO notificaciones (
        usuario_id,
        tipo,
        titulo,
        mensaje,
        metadata
    ) VALUES (
        v_jugador.id,
        'general',
        'Tu inscripcion fue cancelada',
        'El administrador ' || v_current_user.nombre_completo ||
            ' ha cancelado tu inscripcion a la pichanga del ' ||
            TO_CHAR(v_fecha.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY') ||
            ' a las ' ||
            TO_CHAR(v_fecha.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'HH24:MI') ||
            CASE
                WHEN v_pago_anulado THEN '. La deuda asociada ha sido anulada.'
                ELSE '. La deuda de S/ ' || TO_CHAR(v_fecha.costo_por_jugador, 'FM990.00') || ' permanece pendiente.'
            END,
        jsonb_build_object(
            'fecha_id', v_inscripcion.fecha_id,
            'inscripcion_id', p_inscripcion_id,
            'cancelado_por_id', v_current_user.id,
            'cancelado_por_nombre', v_current_user.nombre_completo,
            'tipo_evento', 'cancelacion_por_admin',
            'deuda_anulada', v_pago_anulado,
            'asignacion_eliminada', v_asignacion_eliminada
        )
    );

    -- ========================================
    -- Retorno exitoso
    -- ========================================
    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'inscripcion_id', p_inscripcion_id,
            'fecha_id', v_inscripcion.fecha_id,
            'fecha_formato', TO_CHAR(v_fecha.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY HH24:MI'),
            'lugar', v_fecha.lugar,
            'jugador', json_build_object(
                'id', v_jugador.id,
                'nombre', v_jugador.nombre_completo
            ),
            'estado_inscripcion', 'cancelado',
            'deuda_anulada', v_pago_anulado,
            'asignacion_eliminada', v_asignacion_eliminada,
            'cancelado_por', json_build_object(
                'id', v_current_user.id,
                'nombre', v_current_user.nombre_completo
            ),
            'cancelado_at', NOW() AT TIME ZONE 'America/Lima',
            'cancelado_at_formato', TO_CHAR(NOW() AT TIME ZONE 'America/Lima', 'DD/MM/YYYY HH24:MI')
        ),
        'message', 'Inscripcion de ' || v_jugador.nombre_completo || ' cancelada exitosamente.' ||
            CASE
                WHEN v_pago_anulado THEN ' La deuda fue anulada.'
                ELSE ' La deuda permanece pendiente.'
            END ||
            ' Se ha notificado al jugador.'
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
-- PARTE 4: FUNCION AUXILIAR verificar_puede_cancelar
-- ============================================

-- ============================================
-- Funcion: verificar_puede_cancelar
-- Descripcion: Verifica si el usuario puede cancelar su inscripcion
--              Util para el frontend para mostrar/ocultar el boton cancelar
-- CA: CA-001, CA-005
-- ============================================
CREATE OR REPLACE FUNCTION verificar_puede_cancelar(
    p_fecha_id UUID
) RETURNS JSON AS $$
DECLARE
    v_error_hint TEXT;
    v_current_user_id UUID;
    v_current_user RECORD;
    v_fecha RECORD;
    v_inscripcion RECORD;
BEGIN
    -- Validacion basica
    v_current_user_id := auth.uid();

    IF v_current_user_id IS NULL THEN
        RETURN json_build_object(
            'success', true,
            'data', json_build_object(
                'puede_cancelar', FALSE,
                'motivo', 'no_autenticado'
            )
        );
    END IF;

    -- Obtener usuario
    SELECT id, rol, estado
    INTO v_current_user
    FROM usuarios
    WHERE auth_user_id = v_current_user_id;

    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', true,
            'data', json_build_object(
                'puede_cancelar', FALSE,
                'motivo', 'usuario_no_encontrado'
            )
        );
    END IF;

    -- Obtener fecha
    SELECT id, estado
    INTO v_fecha
    FROM fechas
    WHERE id = p_fecha_id;

    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', true,
            'data', json_build_object(
                'puede_cancelar', FALSE,
                'motivo', 'fecha_no_encontrada'
            )
        );
    END IF;

    -- Verificar inscripcion activa
    SELECT id, estado
    INTO v_inscripcion
    FROM inscripciones
    WHERE fecha_id = p_fecha_id
    AND usuario_id = v_current_user.id
    AND estado = 'inscrito';

    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', true,
            'data', json_build_object(
                'puede_cancelar', FALSE,
                'motivo', 'no_inscrito'
            )
        );
    END IF;

    -- CA-001/CA-005: Evaluar si puede cancelar
    IF v_fecha.estado = 'abierta' THEN
        -- RN-001: Puede cancelar libremente
        RETURN json_build_object(
            'success', true,
            'data', json_build_object(
                'puede_cancelar', TRUE,
                'inscripcion_id', v_inscripcion.id,
                'fecha_estado', v_fecha.estado,
                'cancelacion_libre', TRUE,
                'deuda_sera_anulada', TRUE,
                'mensaje_confirmacion', 'Estas seguro de cancelar tu inscripcion?'
            )
        );
    ELSE
        -- RN-002: No puede cancelar directamente
        RETURN json_build_object(
            'success', true,
            'data', json_build_object(
                'puede_cancelar', FALSE,
                'inscripcion_id', v_inscripcion.id,
                'fecha_estado', v_fecha.estado,
                'cancelacion_libre', FALSE,
                'motivo', 'fecha_cerrada',
                'mensaje', 'Las inscripciones estan cerradas. Contacta al administrador'
            )
        );
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', json_build_object(
                'code', SQLSTATE,
                'message', SQLERRM,
                'hint', 'error_verificacion'
            )
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- PARTE 5: PERMISOS
-- ============================================

GRANT EXECUTE ON FUNCTION cancelar_inscripcion TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION cancelar_inscripcion_admin TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION verificar_puede_cancelar TO authenticated, service_role;

-- ============================================
-- PARTE 6: COMENTARIOS DE DOCUMENTACION
-- ============================================

COMMENT ON FUNCTION cancelar_inscripcion IS 'E003-HU-007: Cancela inscripcion propia del jugador (RN-001 a RN-006, CA-001 a CA-005, CA-007)';
COMMENT ON FUNCTION cancelar_inscripcion_admin IS 'E003-HU-007: Admin cancela inscripcion de cualquier jugador (RN-002 caso especial, RN-003 a RN-006, CA-006)';
COMMENT ON FUNCTION verificar_puede_cancelar IS 'E003-HU-007: Verifica si usuario puede cancelar su inscripcion (CA-001, CA-005)';

-- ============================================
-- FIN DEL SCRIPT
-- ============================================
