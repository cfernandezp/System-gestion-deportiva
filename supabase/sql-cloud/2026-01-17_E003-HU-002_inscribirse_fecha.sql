-- ============================================
-- E003-HU-002: Inscribirse a Fecha
-- Fecha: 2026-01-17
-- Descripcion: Implementacion de tabla inscripciones, tabla pagos (deudas),
--              y funciones RPC para gestion de inscripciones a fechas de pichanga
-- ============================================

-- ============================================
-- PARTE 1: TIPOS ENUM
-- ============================================

-- Tipo ENUM para estados de inscripcion
DO $$ BEGIN
    CREATE TYPE estado_inscripcion AS ENUM (
        'inscrito',     -- Jugador inscrito activo
        'cancelado'     -- Inscripcion cancelada
    );
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

-- Tipo ENUM para estados de pago/deuda
DO $$ BEGIN
    CREATE TYPE estado_pago AS ENUM (
        'pendiente',    -- Deuda pendiente de pago
        'pagado',       -- Deuda pagada
        'anulado'       -- Deuda anulada (por cancelacion antes del cierre)
    );
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

-- ============================================
-- PARTE 2: TABLA INSCRIPCIONES
-- ============================================

-- Tabla: inscripciones
-- Almacena las inscripciones de jugadores a fechas
CREATE TABLE IF NOT EXISTS inscripciones (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    fecha_id UUID NOT NULL REFERENCES fechas(id) ON DELETE CASCADE,
    usuario_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    estado estado_inscripcion NOT NULL DEFAULT 'inscrito',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indice unico para evitar inscripciones duplicadas (RN-003)
-- Un usuario solo puede tener UNA inscripcion activa por fecha
CREATE UNIQUE INDEX IF NOT EXISTS idx_inscripciones_fecha_usuario_unico
ON inscripciones(fecha_id, usuario_id)
WHERE estado = 'inscrito';

-- Indices para optimizar consultas
CREATE INDEX IF NOT EXISTS idx_inscripciones_fecha_id ON inscripciones(fecha_id);
CREATE INDEX IF NOT EXISTS idx_inscripciones_usuario_id ON inscripciones(usuario_id);
CREATE INDEX IF NOT EXISTS idx_inscripciones_estado ON inscripciones(estado);

-- Trigger para actualizar updated_at
DROP TRIGGER IF EXISTS trigger_inscripciones_updated_at ON inscripciones;
CREATE TRIGGER trigger_inscripciones_updated_at
    BEFORE UPDATE ON inscripciones
    FOR EACH ROW
    EXECUTE FUNCTION actualizar_updated_at();

-- ============================================
-- PARTE 3: TABLA PAGOS (DEUDAS)
-- ============================================

-- Tabla: pagos
-- Almacena las deudas/pagos de los jugadores
CREATE TABLE IF NOT EXISTS pagos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    inscripcion_id UUID NOT NULL REFERENCES inscripciones(id) ON DELETE CASCADE,
    usuario_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    fecha_id UUID NOT NULL REFERENCES fechas(id) ON DELETE CASCADE,
    monto DECIMAL(10,2) NOT NULL CHECK (monto > 0),
    estado estado_pago NOT NULL DEFAULT 'pendiente',
    fecha_pago TIMESTAMPTZ,
    registrado_por UUID REFERENCES usuarios(id),
    notas TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indices para optimizar consultas
CREATE INDEX IF NOT EXISTS idx_pagos_inscripcion_id ON pagos(inscripcion_id);
CREATE INDEX IF NOT EXISTS idx_pagos_usuario_id ON pagos(usuario_id);
CREATE INDEX IF NOT EXISTS idx_pagos_fecha_id ON pagos(fecha_id);
CREATE INDEX IF NOT EXISTS idx_pagos_estado ON pagos(estado);

-- Trigger para actualizar updated_at
DROP TRIGGER IF EXISTS trigger_pagos_updated_at ON pagos;
CREATE TRIGGER trigger_pagos_updated_at
    BEFORE UPDATE ON pagos
    FOR EACH ROW
    EXECUTE FUNCTION actualizar_updated_at();

-- ============================================
-- PARTE 4: FUNCION RPC inscribirse_fecha
-- ============================================

-- ============================================
-- Funcion: inscribirse_fecha
-- Descripcion: Inscribe al usuario actual a una fecha de pichanga
-- Reglas: RN-001, RN-002, RN-003, RN-004, RN-005, RN-006
-- ============================================
CREATE OR REPLACE FUNCTION inscribirse_fecha(
    p_fecha_id UUID
) RETURNS JSON AS $$
DECLARE
    v_error_hint TEXT;
    v_current_user_id UUID;
    v_current_user RECORD;
    v_fecha RECORD;
    v_inscripcion_id UUID;
    v_pago_id UUID;
    v_total_inscritos INTEGER;
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
    -- Validacion RN-001: Solo usuarios aprobados pueden inscribirse
    -- ========================================
    SELECT id, rol, estado, nombre_completo, email
    INTO v_current_user
    FROM usuarios
    WHERE auth_user_id = v_current_user_id;

    IF NOT FOUND THEN
        v_error_hint := 'usuario_no_encontrado';
        RAISE EXCEPTION 'Usuario no encontrado en el sistema';
    END IF;

    IF v_current_user.estado != 'aprobado' THEN
        v_error_hint := 'usuario_no_aprobado';
        RAISE EXCEPTION 'Solo los jugadores aprobados pueden inscribirse a fechas de pichanga';
    END IF;

    -- ========================================
    -- Obtener datos de la fecha
    -- ========================================
    SELECT id, fecha_hora_inicio, duracion_horas, lugar, num_equipos,
           costo_por_jugador, estado, created_by
    INTO v_fecha
    FROM fechas
    WHERE id = p_fecha_id;

    IF NOT FOUND THEN
        v_error_hint := 'fecha_no_encontrada';
        RAISE EXCEPTION 'Fecha de pichanga no encontrada';
    END IF;

    -- ========================================
    -- Validacion RN-002: Solo fechas con estado 'abierta'
    -- ========================================
    IF v_fecha.estado != 'abierta' THEN
        v_error_hint := 'fecha_no_abierta';
        RAISE EXCEPTION 'Las inscripciones para esta fecha estan cerradas (estado: %)', v_fecha.estado;
    END IF;

    -- ========================================
    -- Validacion RN-003: No inscripcion duplicada
    -- ========================================
    IF EXISTS (
        SELECT 1 FROM inscripciones
        WHERE fecha_id = p_fecha_id
        AND usuario_id = v_current_user.id
        AND estado = 'inscrito'
    ) THEN
        v_error_hint := 'ya_inscrito';
        RAISE EXCEPTION 'Ya estas inscrito a esta fecha de pichanga';
    END IF;

    -- ========================================
    -- Validacion RN-005: Limite de inscripciones (opcional)
    -- Por ahora no hay limite definido en la tabla fechas
    -- Se puede agregar columna limite_jugadores en el futuro
    -- ========================================

    -- ========================================
    -- Insertar inscripcion
    -- ========================================
    INSERT INTO inscripciones (
        fecha_id,
        usuario_id,
        estado
    ) VALUES (
        p_fecha_id,
        v_current_user.id,
        'inscrito'
    )
    RETURNING id INTO v_inscripcion_id;

    -- ========================================
    -- RN-004: Generar deuda pendiente
    -- ========================================
    INSERT INTO pagos (
        inscripcion_id,
        usuario_id,
        fecha_id,
        monto,
        estado
    ) VALUES (
        v_inscripcion_id,
        v_current_user.id,
        p_fecha_id,
        v_fecha.costo_por_jugador,
        'pendiente'
    )
    RETURNING id INTO v_pago_id;

    -- ========================================
    -- RN-006: Notificar al admin
    -- ========================================
    FOR v_admin_record IN
        SELECT id, nombre_completo
        FROM usuarios
        WHERE rol = 'admin'
        AND estado = 'aprobado'
        AND id != v_current_user.id  -- No notificar si el admin se inscribe a si mismo
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
            'Nueva inscripcion a pichanga',
            v_current_user.nombre_completo || ' se ha inscrito a la pichanga del ' ||
                TO_CHAR(v_fecha.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY') ||
                ' a las ' ||
                TO_CHAR(v_fecha.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'HH24:MI'),
            jsonb_build_object(
                'fecha_id', p_fecha_id,
                'inscripcion_id', v_inscripcion_id,
                'usuario_id', v_current_user.id,
                'usuario_nombre', v_current_user.nombre_completo,
                'tipo_evento', 'inscripcion'
            )
        );
    END LOOP;

    -- ========================================
    -- Contar total de inscritos
    -- ========================================
    SELECT COUNT(*) INTO v_total_inscritos
    FROM inscripciones
    WHERE fecha_id = p_fecha_id
    AND estado = 'inscrito';

    -- ========================================
    -- Retorno exitoso
    -- ========================================
    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'inscripcion_id', v_inscripcion_id,
            'fecha_id', p_fecha_id,
            'fecha_formato', TO_CHAR(v_fecha.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY HH24:MI'),
            'lugar', v_fecha.lugar,
            'costo_por_jugador', v_fecha.costo_por_jugador,
            'costo_formato', 'S/ ' || TO_CHAR(v_fecha.costo_por_jugador, 'FM990.00'),
            'pago_id', v_pago_id,
            'estado_inscripcion', 'inscrito',
            'estado_pago', 'pendiente',
            'total_inscritos', v_total_inscritos
        ),
        'message', 'Te anotaste para la pichanga del ' ||
            TO_CHAR(v_fecha.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY') ||
            '. Recuerda que debes pagar S/ ' || TO_CHAR(v_fecha.costo_por_jugador, 'FM990.00')
    );

EXCEPTION
    WHEN unique_violation THEN
        RETURN json_build_object(
            'success', false,
            'error', json_build_object(
                'code', 'UNIQUE_VIOLATION',
                'message', 'Ya estas inscrito a esta fecha de pichanga',
                'hint', 'ya_inscrito'
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
-- PARTE 5: FUNCION RPC cancelar_inscripcion
-- ============================================

-- ============================================
-- Funcion: cancelar_inscripcion
-- Descripcion: Cancela la inscripcion del usuario a una fecha
-- Reglas: RN-004 (anular deuda si fecha abierta)
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
    -- ========================================
    SELECT id, estado
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
    -- Cancelar inscripcion
    -- ========================================
    UPDATE inscripciones
    SET estado = 'cancelado'
    WHERE id = v_inscripcion.id;

    -- ========================================
    -- RN-004: Gestionar deuda segun estado de fecha
    -- Si fecha abierta: anular deuda
    -- Si fecha cerrada o posterior: deuda permanece
    -- ========================================
    IF v_fecha.estado = 'abierta' THEN
        -- Anular deuda si la fecha sigue abierta
        UPDATE pagos
        SET estado = 'anulado',
            notas = 'Deuda anulada por cancelacion de inscripcion (fecha abierta)'
        WHERE inscripcion_id = v_inscripcion.id
        AND estado = 'pendiente';
    END IF;
    -- Si estado != 'abierta', la deuda permanece pendiente

    -- ========================================
    -- Notificar al admin
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
            v_current_user.nombre_completo || ' ha cancelado su inscripcion a la pichanga del ' ||
                TO_CHAR(v_fecha.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY') ||
                CASE
                    WHEN v_fecha.estado = 'abierta' THEN ' (deuda anulada)'
                    ELSE ' (deuda permanece pendiente)'
                END,
            jsonb_build_object(
                'fecha_id', p_fecha_id,
                'inscripcion_id', v_inscripcion.id,
                'usuario_id', v_current_user.id,
                'usuario_nombre', v_current_user.nombre_completo,
                'tipo_evento', 'cancelacion',
                'deuda_anulada', v_fecha.estado = 'abierta'
            )
        );
    END LOOP;

    -- ========================================
    -- Retorno exitoso
    -- ========================================
    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'inscripcion_id', v_inscripcion.id,
            'fecha_id', p_fecha_id,
            'fecha_formato', TO_CHAR(v_fecha.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY HH24:MI'),
            'estado_inscripcion', 'cancelado',
            'deuda_anulada', v_fecha.estado = 'abierta'
        ),
        'message', CASE
            WHEN v_fecha.estado = 'abierta'
            THEN 'Has cancelado tu inscripcion. La deuda ha sido anulada.'
            ELSE 'Has cancelado tu inscripcion. La deuda de S/ ' ||
                 TO_CHAR(v_fecha.costo_por_jugador, 'FM990.00') ||
                 ' permanece pendiente porque la fecha ya no esta abierta.'
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
-- PARTE 6: FUNCION RPC obtener_fecha_detalle
-- ============================================

-- ============================================
-- Funcion: obtener_fecha_detalle
-- Descripcion: Obtiene detalles de una fecha con lista de inscritos
-- CA-001, CA-002, CA-004, CA-005, CA-006
-- ============================================
CREATE OR REPLACE FUNCTION obtener_fecha_detalle(
    p_fecha_id UUID
) RETURNS JSON AS $$
DECLARE
    v_error_hint TEXT;
    v_current_user_id UUID;
    v_current_user RECORD;
    v_fecha RECORD;
    v_inscritos JSON;
    v_usuario_inscrito BOOLEAN;
    v_inscripcion_usuario RECORD;
    v_total_inscritos INTEGER;
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
    SELECT f.id, f.fecha_hora_inicio, f.duracion_horas, f.lugar,
           f.num_equipos, f.costo_por_jugador, f.estado, f.created_by,
           f.created_at, u.nombre_completo as creador_nombre
    INTO v_fecha
    FROM fechas f
    JOIN usuarios u ON u.id = f.created_by
    WHERE f.id = p_fecha_id;

    IF NOT FOUND THEN
        v_error_hint := 'fecha_no_encontrada';
        RAISE EXCEPTION 'Fecha de pichanga no encontrada';
    END IF;

    -- ========================================
    -- Verificar si usuario actual esta inscrito
    -- ========================================
    SELECT i.id, i.estado, i.created_at
    INTO v_inscripcion_usuario
    FROM inscripciones i
    WHERE i.fecha_id = p_fecha_id
    AND i.usuario_id = v_current_user.id
    AND i.estado = 'inscrito';

    v_usuario_inscrito := FOUND;

    -- ========================================
    -- Obtener lista de inscritos
    -- ========================================
    SELECT json_agg(
        json_build_object(
            'usuario_id', u.id,
            'nombre_completo', u.nombre_completo,
            'inscrito_at', i.created_at AT TIME ZONE 'America/Lima',
            'inscrito_formato', TO_CHAR(i.created_at AT TIME ZONE 'America/Lima', 'DD/MM/YYYY HH24:MI')
        ) ORDER BY i.created_at ASC
    )
    INTO v_inscritos
    FROM inscripciones i
    JOIN usuarios u ON u.id = i.usuario_id
    WHERE i.fecha_id = p_fecha_id
    AND i.estado = 'inscrito';

    -- Contar total
    SELECT COUNT(*) INTO v_total_inscritos
    FROM inscripciones
    WHERE fecha_id = p_fecha_id
    AND estado = 'inscrito';

    -- ========================================
    -- Retorno exitoso
    -- ========================================
    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'fecha', json_build_object(
                'id', v_fecha.id,
                'fecha_hora_inicio', v_fecha.fecha_hora_inicio,
                'fecha_hora_local', v_fecha.fecha_hora_inicio AT TIME ZONE 'America/Lima',
                'fecha_formato', TO_CHAR(v_fecha.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY'),
                'hora_formato', TO_CHAR(v_fecha.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'HH24:MI'),
                'duracion_horas', v_fecha.duracion_horas,
                'lugar', v_fecha.lugar,
                'num_equipos', v_fecha.num_equipos,
                'costo_por_jugador', v_fecha.costo_por_jugador,
                'costo_formato', 'S/ ' || TO_CHAR(v_fecha.costo_por_jugador, 'FM990.00'),
                'estado', v_fecha.estado,
                'formato_juego', CASE
                    WHEN v_fecha.num_equipos = 2 THEN '2 equipos - partido continuo'
                    WHEN v_fecha.num_equipos = 3 THEN '3 equipos con rotacion'
                    ELSE v_fecha.num_equipos || ' equipos'
                END,
                'creador', json_build_object(
                    'id', v_fecha.created_by,
                    'nombre', v_fecha.creador_nombre
                ),
                'created_at', v_fecha.created_at AT TIME ZONE 'America/Lima'
            ),
            'inscripciones', json_build_object(
                'total', v_total_inscritos,
                'lista', COALESCE(v_inscritos, '[]'::json)
            ),
            'usuario_actual', json_build_object(
                'esta_inscrito', v_usuario_inscrito,
                'inscripcion_id', v_inscripcion_usuario.id,
                'puede_inscribirse', v_fecha.estado = 'abierta' AND NOT v_usuario_inscrito AND v_current_user.estado = 'aprobado',
                'puede_cancelar', v_usuario_inscrito
            )
        ),
        'message', 'Detalle de fecha obtenido exitosamente'
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
-- PARTE 7: FUNCION RPC listar_fechas_disponibles
-- ============================================

-- ============================================
-- Funcion: listar_fechas_disponibles
-- Descripcion: Lista fechas con estado 'abierta' con contador de inscritos
-- CA-001, CA-006
-- ============================================
CREATE OR REPLACE FUNCTION listar_fechas_disponibles()
RETURNS JSON AS $$
DECLARE
    v_error_hint TEXT;
    v_current_user_id UUID;
    v_current_user RECORD;
    v_fechas JSON;
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
    -- Obtener fechas abiertas con contador de inscritos
    -- ========================================
    SELECT json_agg(fecha_data ORDER BY fecha_hora_inicio ASC)
    INTO v_fechas
    FROM (
        SELECT
            json_build_object(
                'id', f.id,
                'fecha_hora_inicio', f.fecha_hora_inicio,
                'fecha_hora_local', f.fecha_hora_inicio AT TIME ZONE 'America/Lima',
                'fecha_formato', TO_CHAR(f.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY'),
                'hora_formato', TO_CHAR(f.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'HH24:MI'),
                'duracion_horas', f.duracion_horas,
                'lugar', f.lugar,
                'num_equipos', f.num_equipos,
                'costo_por_jugador', f.costo_por_jugador,
                'costo_formato', 'S/ ' || TO_CHAR(f.costo_por_jugador, 'FM990.00'),
                'estado', f.estado,
                'formato_juego', CASE
                    WHEN f.num_equipos = 2 THEN '2 equipos - partido continuo'
                    WHEN f.num_equipos = 3 THEN '3 equipos con rotacion'
                    ELSE f.num_equipos || ' equipos'
                END,
                'total_inscritos', (
                    SELECT COUNT(*)
                    FROM inscripciones i
                    WHERE i.fecha_id = f.id
                    AND i.estado = 'inscrito'
                ),
                'usuario_inscrito', EXISTS (
                    SELECT 1
                    FROM inscripciones i
                    WHERE i.fecha_id = f.id
                    AND i.usuario_id = v_current_user.id
                    AND i.estado = 'inscrito'
                ),
                'created_at', f.created_at AT TIME ZONE 'America/Lima'
            ) as fecha_data,
            f.fecha_hora_inicio
        FROM fechas f
        WHERE f.estado = 'abierta'
        AND f.fecha_hora_inicio > NOW()  -- Solo fechas futuras
    ) subquery;

    -- ========================================
    -- Retorno exitoso
    -- ========================================
    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'fechas', COALESCE(v_fechas, '[]'::json),
            'total', (
                SELECT COUNT(*)
                FROM fechas
                WHERE estado = 'abierta'
                AND fecha_hora_inicio > NOW()
            )
        ),
        'message', 'Lista de fechas disponibles obtenida exitosamente'
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
-- PARTE 8: PERMISOS
-- ============================================

GRANT EXECUTE ON FUNCTION inscribirse_fecha TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION cancelar_inscripcion TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION obtener_fecha_detalle TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION listar_fechas_disponibles TO authenticated, service_role;

-- ============================================
-- PARTE 9: ROW LEVEL SECURITY (RLS)
-- ============================================

-- Habilitar RLS en tablas
ALTER TABLE inscripciones ENABLE ROW LEVEL SECURITY;
ALTER TABLE pagos ENABLE ROW LEVEL SECURITY;

-- Eliminar politicas existentes si existen (para re-ejecucion segura)
DROP POLICY IF EXISTS "Usuarios pueden ver sus propias inscripciones" ON inscripciones;
DROP POLICY IF EXISTS "Admins pueden ver todas las inscripciones" ON inscripciones;
DROP POLICY IF EXISTS "Usuarios pueden ver inscripciones de fechas" ON inscripciones;
DROP POLICY IF EXISTS "Usuarios pueden ver sus propios pagos" ON pagos;
DROP POLICY IF EXISTS "Admins pueden ver todos los pagos" ON pagos;
DROP POLICY IF EXISTS "Admins pueden actualizar pagos" ON pagos;

-- Politicas para inscripciones
-- SELECT: Usuario puede ver sus propias inscripciones
CREATE POLICY "Usuarios pueden ver sus propias inscripciones"
ON inscripciones FOR SELECT
TO authenticated
USING (
    usuario_id IN (
        SELECT id FROM usuarios
        WHERE auth_user_id = auth.uid()
    )
);

-- SELECT: Admin puede ver todas las inscripciones
CREATE POLICY "Admins pueden ver todas las inscripciones"
ON inscripciones FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM usuarios u
        WHERE u.auth_user_id = auth.uid()
        AND u.rol = 'admin'
        AND u.estado = 'aprobado'
    )
);

-- SELECT: Usuarios aprobados pueden ver inscripciones de las fechas (para ver lista de inscritos)
CREATE POLICY "Usuarios pueden ver inscripciones de fechas"
ON inscripciones FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM usuarios u
        WHERE u.auth_user_id = auth.uid()
        AND u.estado = 'aprobado'
    )
);

-- Politicas para pagos
-- SELECT: Usuario puede ver sus propios pagos
CREATE POLICY "Usuarios pueden ver sus propios pagos"
ON pagos FOR SELECT
TO authenticated
USING (
    usuario_id IN (
        SELECT id FROM usuarios
        WHERE auth_user_id = auth.uid()
    )
);

-- SELECT: Admin puede ver todos los pagos
CREATE POLICY "Admins pueden ver todos los pagos"
ON pagos FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM usuarios u
        WHERE u.auth_user_id = auth.uid()
        AND u.rol = 'admin'
        AND u.estado = 'aprobado'
    )
);

-- UPDATE: Admin puede actualizar pagos (para registrar pagos)
CREATE POLICY "Admins pueden actualizar pagos"
ON pagos FOR UPDATE
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
-- PARTE 10: COMENTARIOS DE DOCUMENTACION
-- ============================================

COMMENT ON TABLE inscripciones IS 'E003-HU-002: Tabla de inscripciones de jugadores a fechas de pichanga';
COMMENT ON COLUMN inscripciones.id IS 'Identificador unico de la inscripcion';
COMMENT ON COLUMN inscripciones.fecha_id IS 'ID de la fecha a la que se inscribe';
COMMENT ON COLUMN inscripciones.usuario_id IS 'ID del usuario que se inscribe';
COMMENT ON COLUMN inscripciones.estado IS 'Estado de la inscripcion: inscrito, cancelado';
COMMENT ON COLUMN inscripciones.created_at IS 'Timestamp de creacion (UTC)';
COMMENT ON COLUMN inscripciones.updated_at IS 'Timestamp de ultima actualizacion (UTC)';

COMMENT ON TABLE pagos IS 'E003-HU-002: Tabla de pagos/deudas de jugadores por inscripciones';
COMMENT ON COLUMN pagos.id IS 'Identificador unico del pago';
COMMENT ON COLUMN pagos.inscripcion_id IS 'ID de la inscripcion asociada';
COMMENT ON COLUMN pagos.usuario_id IS 'ID del usuario deudor';
COMMENT ON COLUMN pagos.fecha_id IS 'ID de la fecha asociada';
COMMENT ON COLUMN pagos.monto IS 'Monto de la deuda en soles';
COMMENT ON COLUMN pagos.estado IS 'Estado del pago: pendiente, pagado, anulado';
COMMENT ON COLUMN pagos.fecha_pago IS 'Timestamp cuando se realizo el pago';
COMMENT ON COLUMN pagos.registrado_por IS 'ID del admin que registro el pago';
COMMENT ON COLUMN pagos.notas IS 'Notas adicionales sobre el pago';

COMMENT ON FUNCTION inscribirse_fecha IS 'E003-HU-002: Inscribe usuario a una fecha de pichanga (RN-001 a RN-006)';
COMMENT ON FUNCTION cancelar_inscripcion IS 'E003-HU-002: Cancela inscripcion de usuario (RN-004)';
COMMENT ON FUNCTION obtener_fecha_detalle IS 'E003-HU-002: Obtiene detalle de fecha con lista de inscritos (CA-001 a CA-006)';
COMMENT ON FUNCTION listar_fechas_disponibles IS 'E003-HU-002: Lista fechas abiertas con contador de inscritos';

-- ============================================
-- FIN DEL SCRIPT
-- ============================================
