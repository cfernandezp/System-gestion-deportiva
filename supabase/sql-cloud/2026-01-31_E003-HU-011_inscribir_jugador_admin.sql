-- ============================================
-- E003-HU-011: Inscribir Jugador como Admin
-- Fecha: 2026-01-31
-- Descripcion: Permite al admin/organizador inscribir manualmente
--              a cualquier jugador aprobado a una fecha de pichanga
-- ============================================

-- ============================================
-- PARTE 1: AGREGAR COLUMNA inscrito_por (RN-007)
-- ============================================

-- Agregar columna para auditoria de quien inscribio
ALTER TABLE inscripciones
ADD COLUMN IF NOT EXISTS inscrito_por UUID REFERENCES usuarios(id);

-- Comentario de documentacion
COMMENT ON COLUMN inscripciones.inscrito_por IS 'E003-HU-011 RN-007: ID del admin que realizo la inscripcion administrativa. NULL si es auto-inscripcion.';

-- Indice para optimizar consultas
CREATE INDEX IF NOT EXISTS idx_inscripciones_inscrito_por ON inscripciones(inscrito_por);

-- ============================================
-- PARTE 2: FUNCION AUXILIAR listar_jugadores_disponibles_inscripcion
-- Descripcion: Lista jugadores aprobados que NO estan inscritos a una fecha
-- CA-002: Lista de jugadores aprobados, excluyendo ya inscritos
-- ============================================

CREATE OR REPLACE FUNCTION listar_jugadores_disponibles_inscripcion(
    p_fecha_id UUID
) RETURNS JSON AS $$
DECLARE
    v_error_hint TEXT;
    v_current_user_id UUID;
    v_current_user RECORD;
    v_fecha RECORD;
    v_jugadores JSON;
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
    -- Validacion RN-001: Solo admin u organizador
    -- ========================================
    SELECT id, rol, estado, nombre_completo
    INTO v_current_user
    FROM usuarios
    WHERE auth_user_id = v_current_user_id;

    IF NOT FOUND THEN
        v_error_hint := 'usuario_no_encontrado';
        RAISE EXCEPTION 'Usuario no encontrado en el sistema';
    END IF;

    -- Verificar fecha existe
    SELECT id, created_by
    INTO v_fecha
    FROM fechas
    WHERE id = p_fecha_id;

    IF NOT FOUND THEN
        v_error_hint := 'fecha_no_encontrada';
        RAISE EXCEPTION 'Fecha de pichanga no encontrada';
    END IF;

    -- RN-001: Validar permisos (admin global O organizador de la fecha)
    IF v_current_user.rol != 'admin' AND v_current_user.id != v_fecha.created_by THEN
        v_error_hint := 'sin_permisos';
        RAISE EXCEPTION 'Solo administradores u organizadores pueden ver jugadores disponibles';
    END IF;

    -- ========================================
    -- Obtener jugadores disponibles (CA-002)
    -- - Aprobados (RN-002)
    -- - NO inscritos a esta fecha (CA-002)
    -- ========================================
    SELECT json_agg(
        json_build_object(
            'id', u.id,
            'nombre_completo', u.nombre_completo,
            'apodo', u.apodo,
            'nombre_display', COALESCE(u.apodo, u.nombre_completo),
            'posicion_preferida', u.posicion_preferida,
            'foto_url', u.foto_url
        ) ORDER BY COALESCE(u.apodo, u.nombre_completo) ASC
    )
    INTO v_jugadores
    FROM usuarios u
    WHERE u.estado = 'aprobado'
    AND NOT EXISTS (
        SELECT 1 FROM inscripciones i
        WHERE i.fecha_id = p_fecha_id
        AND i.usuario_id = u.id
        AND i.estado = 'inscrito'
    );

    -- ========================================
    -- Retorno exitoso
    -- ========================================
    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'jugadores', COALESCE(v_jugadores, '[]'::json),
            'total', COALESCE(json_array_length(v_jugadores), 0)
        ),
        'message', 'Lista de jugadores disponibles obtenida exitosamente'
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
-- PARTE 3: FUNCION RPC inscribir_jugador_admin
-- ============================================

-- ============================================
-- Funcion: inscribir_jugador_admin
-- Descripcion: Inscribe un jugador a una fecha como admin/organizador
-- Reglas: RN-001 a RN-008
-- Criterios: CA-001 a CA-008
-- ============================================
CREATE OR REPLACE FUNCTION inscribir_jugador_admin(
    p_fecha_id UUID,
    p_jugador_id UUID
) RETURNS JSON AS $$
DECLARE
    v_error_hint TEXT;
    v_current_user_id UUID;
    v_current_user RECORD;
    v_jugador RECORD;
    v_fecha RECORD;
    v_inscripcion_id UUID;
    v_pago_id UUID;
    v_total_inscritos INTEGER;
    v_limite_jugadores INTEGER;
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

    IF p_jugador_id IS NULL THEN
        v_error_hint := 'jugador_id_requerido';
        RAISE EXCEPTION 'El ID del jugador es obligatorio';
    END IF;

    -- ========================================
    -- Obtener usuario actual (admin/organizador)
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
    SELECT id, fecha_hora_inicio, duracion_horas, lugar, num_equipos,
           costo_por_jugador, estado, created_by, limite_jugadores
    INTO v_fecha
    FROM fechas
    WHERE id = p_fecha_id;

    IF NOT FOUND THEN
        v_error_hint := 'fecha_no_encontrada';
        RAISE EXCEPTION 'Fecha de pichanga no encontrada';
    END IF;

    -- ========================================
    -- Validacion RN-001: Solo admin u organizador
    -- ========================================
    IF v_current_user.rol != 'admin' AND v_current_user.id != v_fecha.created_by THEN
        v_error_hint := 'sin_permisos';
        RAISE EXCEPTION 'Solo administradores u organizadores pueden inscribir jugadores';
    END IF;

    IF v_current_user.estado != 'aprobado' THEN
        v_error_hint := 'admin_no_aprobado';
        RAISE EXCEPTION 'Tu cuenta no esta aprobada para realizar esta accion';
    END IF;

    -- ========================================
    -- Validacion RN-004: Solo fechas con estado 'abierta' (CA-008)
    -- ========================================
    IF v_fecha.estado != 'abierta' THEN
        v_error_hint := 'fecha_no_abierta';
        RAISE EXCEPTION 'Solo se puede inscribir jugadores a fechas con inscripciones abiertas (estado actual: %)', v_fecha.estado;
    END IF;

    -- ========================================
    -- Obtener datos del jugador a inscribir
    -- ========================================
    SELECT id, rol, estado, nombre_completo, apodo
    INTO v_jugador
    FROM usuarios
    WHERE id = p_jugador_id;

    IF NOT FOUND THEN
        v_error_hint := 'jugador_no_encontrado';
        RAISE EXCEPTION 'Jugador no encontrado en el sistema';
    END IF;

    -- ========================================
    -- Validacion RN-002: Solo jugadores aprobados
    -- ========================================
    IF v_jugador.estado != 'aprobado' THEN
        v_error_hint := 'jugador_no_aprobado';
        RAISE EXCEPTION 'Solo se puede inscribir a jugadores con estado aprobado';
    END IF;

    -- ========================================
    -- Validacion RN-002 (caso especial): Admin no puede inscribirse a si mismo
    -- ========================================
    IF v_jugador.id = v_current_user.id THEN
        v_error_hint := 'no_auto_inscripcion';
        RAISE EXCEPTION 'No puedes inscribirte a ti mismo usando esta funcion. Usa la inscripcion normal.';
    END IF;

    -- ========================================
    -- Validacion RN-003: Jugador no inscrito previamente (CA-003)
    -- ========================================
    IF EXISTS (
        SELECT 1 FROM inscripciones
        WHERE fecha_id = p_fecha_id
        AND usuario_id = p_jugador_id
        AND estado = 'inscrito'
    ) THEN
        v_error_hint := 'ya_inscrito';
        RAISE EXCEPTION 'Este jugador ya esta anotado a esta fecha';
    END IF;

    -- ========================================
    -- Validacion RN-006: Limite de cupos (CA-007)
    -- ========================================
    -- Contar inscritos actuales
    SELECT COUNT(*) INTO v_total_inscritos
    FROM inscripciones
    WHERE fecha_id = p_fecha_id
    AND estado = 'inscrito';

    -- Obtener limite (puede ser NULL = sin limite)
    v_limite_jugadores := v_fecha.limite_jugadores;

    IF v_limite_jugadores IS NOT NULL AND v_total_inscritos >= v_limite_jugadores THEN
        v_error_hint := 'limite_cupos';
        RAISE EXCEPTION 'Se alcanzo el limite de cupos (% jugadores)', v_limite_jugadores;
    END IF;

    -- ========================================
    -- Insertar inscripcion (RN-007: registrar quien inscribio)
    -- ========================================
    INSERT INTO inscripciones (
        fecha_id,
        usuario_id,
        estado,
        inscrito_por  -- RN-007: Auditoria
    ) VALUES (
        p_fecha_id,
        p_jugador_id,
        'inscrito',
        v_current_user.id
    )
    RETURNING id INTO v_inscripcion_id;

    -- ========================================
    -- RN-005: Generar deuda pendiente (CA-005)
    -- ========================================
    INSERT INTO pagos (
        inscripcion_id,
        usuario_id,
        fecha_id,
        monto,
        estado,
        notas
    ) VALUES (
        v_inscripcion_id,
        p_jugador_id,
        p_fecha_id,
        v_fecha.costo_por_jugador,
        'pendiente',
        'Inscrito por admin: ' || v_current_user.nombre_completo
    )
    RETURNING id INTO v_pago_id;

    -- ========================================
    -- RN-008: Notificar al jugador inscrito (CA-006)
    -- ========================================
    INSERT INTO notificaciones (
        usuario_id,
        tipo,
        titulo,
        mensaje,
        metadata
    ) VALUES (
        p_jugador_id,
        'general',
        'Te han inscrito a una pichanga',
        v_current_user.nombre_completo || ' te ha inscrito a la pichanga del ' ||
            TO_CHAR(v_fecha.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY') ||
            ' a las ' ||
            TO_CHAR(v_fecha.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'HH24:MI') ||
            ' en ' || v_fecha.lugar ||
            '. Debes pagar S/ ' || TO_CHAR(v_fecha.costo_por_jugador, 'FM990.00'),
        jsonb_build_object(
            'fecha_id', p_fecha_id,
            'inscripcion_id', v_inscripcion_id,
            'inscrito_por_id', v_current_user.id,
            'inscrito_por_nombre', v_current_user.nombre_completo,
            'tipo_evento', 'inscripcion_admin',
            'costo', v_fecha.costo_por_jugador,
            'lugar', v_fecha.lugar
        )
    );

    -- ========================================
    -- Contar total de inscritos actualizado
    -- ========================================
    SELECT COUNT(*) INTO v_total_inscritos
    FROM inscripciones
    WHERE fecha_id = p_fecha_id
    AND estado = 'inscrito';

    -- ========================================
    -- Retorno exitoso (CA-004)
    -- ========================================
    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'inscripcion_id', v_inscripcion_id,
            'fecha_id', p_fecha_id,
            'jugador_id', p_jugador_id,
            'jugador_nombre', COALESCE(v_jugador.apodo, v_jugador.nombre_completo),
            'fecha_formato', TO_CHAR(v_fecha.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY HH24:MI'),
            'lugar', v_fecha.lugar,
            'costo_por_jugador', v_fecha.costo_por_jugador,
            'costo_formato', 'S/ ' || TO_CHAR(v_fecha.costo_por_jugador, 'FM990.00'),
            'pago_id', v_pago_id,
            'estado_inscripcion', 'inscrito',
            'estado_pago', 'pendiente',
            'total_inscritos', v_total_inscritos,
            'inscrito_por_id', v_current_user.id,
            'inscrito_por_nombre', v_current_user.nombre_completo
        ),
        'message', 'Jugador ' || COALESCE(v_jugador.apodo, v_jugador.nombre_completo) || ' inscrito exitosamente'
    );

EXCEPTION
    WHEN unique_violation THEN
        RETURN json_build_object(
            'success', false,
            'error', json_build_object(
                'code', 'UNIQUE_VIOLATION',
                'message', 'Este jugador ya esta anotado a esta fecha',
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
-- PARTE 4: PERMISOS
-- ============================================

GRANT EXECUTE ON FUNCTION listar_jugadores_disponibles_inscripcion TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION inscribir_jugador_admin TO authenticated, service_role;

-- ============================================
-- PARTE 5: COMENTARIOS DE DOCUMENTACION
-- ============================================

COMMENT ON FUNCTION listar_jugadores_disponibles_inscripcion IS 'E003-HU-011 CA-002: Lista jugadores aprobados que no estan inscritos a una fecha';
COMMENT ON FUNCTION inscribir_jugador_admin IS 'E003-HU-011: Permite a admin/organizador inscribir manualmente a un jugador a una fecha (RN-001 a RN-008, CA-001 a CA-008)';

-- ============================================
-- FIN DEL SCRIPT
-- ============================================
