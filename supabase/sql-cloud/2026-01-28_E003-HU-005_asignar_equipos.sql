-- ============================================
-- E003-HU-005: Asignar Equipos
-- Fecha: 2026-01-28
-- Descripcion: Implementacion de tabla asignaciones_equipos, enum color_equipo
--              y funciones RPC para asignar jugadores a equipos por colores
-- ============================================

-- ============================================
-- PARTE 1: ENUM color_equipo
-- ============================================

-- Tipo ENUM para colores de equipos
-- RN-004: Colores predefinidos del catalogo
DO $$ BEGIN
    CREATE TYPE color_equipo AS ENUM (
        'naranja',      -- Color primario equipo 1
        'verde',        -- Color primario equipo 2
        'azul',         -- Color para tercer equipo (2 horas)
        'rojo',         -- Color adicional
        'amarillo',     -- Color adicional
        'blanco'        -- Color adicional
    );
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

COMMENT ON TYPE color_equipo IS 'E003-HU-005: Colores disponibles para equipos de pichanga';

-- ============================================
-- PARTE 2: TABLA asignaciones_equipos
-- ============================================

-- Tabla: asignaciones_equipos
-- Almacena las asignaciones de jugadores a equipos por fecha
CREATE TABLE IF NOT EXISTS asignaciones_equipos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    fecha_id UUID NOT NULL REFERENCES fechas(id) ON DELETE CASCADE,
    usuario_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    equipo color_equipo NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indice unico: un usuario solo puede tener una asignacion por fecha
CREATE UNIQUE INDEX IF NOT EXISTS idx_asignaciones_fecha_usuario_unico
ON asignaciones_equipos(fecha_id, usuario_id);

-- Indices para optimizar consultas
CREATE INDEX IF NOT EXISTS idx_asignaciones_fecha_id ON asignaciones_equipos(fecha_id);
CREATE INDEX IF NOT EXISTS idx_asignaciones_usuario_id ON asignaciones_equipos(usuario_id);
CREATE INDEX IF NOT EXISTS idx_asignaciones_equipo ON asignaciones_equipos(equipo);

-- Trigger para actualizar updated_at
DROP TRIGGER IF EXISTS trigger_asignaciones_equipos_updated_at ON asignaciones_equipos;
CREATE TRIGGER trigger_asignaciones_equipos_updated_at
    BEFORE UPDATE ON asignaciones_equipos
    FOR EACH ROW
    EXECUTE FUNCTION actualizar_updated_at();

-- ============================================
-- PARTE 3: ROW LEVEL SECURITY (RLS)
-- ============================================

-- Habilitar RLS en tabla asignaciones_equipos
ALTER TABLE asignaciones_equipos ENABLE ROW LEVEL SECURITY;

-- Eliminar politicas existentes si existen (para re-ejecucion segura)
DROP POLICY IF EXISTS "Usuarios autenticados pueden ver asignaciones" ON asignaciones_equipos;
DROP POLICY IF EXISTS "Admins pueden insertar asignaciones" ON asignaciones_equipos;
DROP POLICY IF EXISTS "Admins pueden actualizar asignaciones" ON asignaciones_equipos;
DROP POLICY IF EXISTS "Admins pueden eliminar asignaciones" ON asignaciones_equipos;

-- SELECT: Todos los usuarios autenticados pueden ver asignaciones (para ver su equipo y companeros)
CREATE POLICY "Usuarios autenticados pueden ver asignaciones"
ON asignaciones_equipos FOR SELECT
TO authenticated
USING (true);

-- INSERT: Solo admin aprobado puede insertar asignaciones
CREATE POLICY "Admins pueden insertar asignaciones"
ON asignaciones_equipos FOR INSERT
TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1 FROM usuarios u
        WHERE u.auth_user_id = auth.uid()
        AND u.rol = 'admin'
        AND u.estado = 'aprobado'
    )
);

-- UPDATE: Solo admin aprobado puede actualizar asignaciones
CREATE POLICY "Admins pueden actualizar asignaciones"
ON asignaciones_equipos FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM usuarios u
        WHERE u.auth_user_id = auth.uid()
        AND u.rol = 'admin'
        AND u.estado = 'aprobado'
    )
);

-- DELETE: Solo admin aprobado puede eliminar asignaciones
CREATE POLICY "Admins pueden eliminar asignaciones"
ON asignaciones_equipos FOR DELETE
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

-- Habilitar realtime para la tabla asignaciones_equipos
-- Esto permite que los jugadores vean en tiempo real cuando se les asigna equipo
ALTER PUBLICATION supabase_realtime ADD TABLE asignaciones_equipos;

-- ============================================
-- PARTE 5: FUNCION RPC asignar_equipo
-- ============================================

-- ============================================
-- Funcion: asignar_equipo
-- Descripcion: Asigna un jugador a un equipo (INSERT o UPDATE - upsert)
-- Reglas: RN-001, RN-002, RN-008
-- CA: CA-004, CA-005, CA-008
-- ============================================
CREATE OR REPLACE FUNCTION asignar_equipo(
    p_fecha_id UUID,
    p_usuario_id UUID,
    p_equipo TEXT
) RETURNS JSON AS $$
DECLARE
    v_error_hint TEXT;
    v_current_user_id UUID;
    v_current_user RECORD;
    v_fecha RECORD;
    v_usuario_destino RECORD;
    v_inscripcion RECORD;
    v_equipo_enum color_equipo;
    v_asignacion_id UUID;
    v_es_actualizacion BOOLEAN;
    v_equipo_anterior color_equipo;
    v_colores_validos TEXT[];
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

    IF p_usuario_id IS NULL THEN
        v_error_hint := 'usuario_id_requerido';
        RAISE EXCEPTION 'El ID del usuario es obligatorio';
    END IF;

    IF p_equipo IS NULL OR TRIM(p_equipo) = '' THEN
        v_error_hint := 'equipo_requerido';
        RAISE EXCEPTION 'El equipo es obligatorio';
    END IF;

    -- ========================================
    -- RN-001: Solo admin aprobado puede asignar equipos
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
        RAISE EXCEPTION 'Solo los administradores aprobados pueden asignar equipos';
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
    -- RN-002 y RN-008: Solo se puede asignar si fecha.estado = 'cerrada'
    -- ========================================
    IF v_fecha.estado != 'cerrada' THEN
        v_error_hint := 'estado_invalido';
        RAISE EXCEPTION 'Solo se pueden asignar equipos cuando las inscripciones estan cerradas. Estado actual: %', v_fecha.estado;
    END IF;

    -- ========================================
    -- Verificar que el usuario destino existe
    -- ========================================
    SELECT id, nombre_completo, estado
    INTO v_usuario_destino
    FROM usuarios
    WHERE id = p_usuario_id;

    IF NOT FOUND THEN
        v_error_hint := 'usuario_destino_no_encontrado';
        RAISE EXCEPTION 'Usuario a asignar no encontrado';
    END IF;

    -- ========================================
    -- Verificar que el usuario esta inscrito a la fecha
    -- ========================================
    SELECT id, estado
    INTO v_inscripcion
    FROM inscripciones
    WHERE fecha_id = p_fecha_id
    AND usuario_id = p_usuario_id
    AND estado = 'inscrito';

    IF NOT FOUND THEN
        v_error_hint := 'usuario_no_inscrito';
        RAISE EXCEPTION 'El usuario % no esta inscrito a esta fecha', v_usuario_destino.nombre_completo;
    END IF;

    -- ========================================
    -- RN-004: Validar color del equipo
    -- ========================================
    BEGIN
        v_equipo_enum := p_equipo::color_equipo;
    EXCEPTION
        WHEN invalid_text_representation THEN
            v_error_hint := 'color_invalido';
            RAISE EXCEPTION 'Color de equipo invalido: %. Colores validos: naranja, verde, azul, rojo, amarillo, blanco', p_equipo;
    END;

    -- ========================================
    -- RN-003/RN-004: Validar que el color es apropiado segun num_equipos
    -- 2 equipos: naranja, verde
    -- 3 equipos: naranja, verde, azul
    -- ========================================
    IF v_fecha.num_equipos = 2 THEN
        v_colores_validos := ARRAY['naranja', 'verde'];
    ELSE -- 3 equipos
        v_colores_validos := ARRAY['naranja', 'verde', 'azul'];
    END IF;

    IF NOT (p_equipo = ANY(v_colores_validos)) THEN
        v_error_hint := 'color_no_permitido';
        RAISE EXCEPTION 'Para esta fecha de % equipo(s) solo se permiten los colores: %',
            v_fecha.num_equipos,
            array_to_string(v_colores_validos, ', ');
    END IF;

    -- ========================================
    -- Verificar si ya existe asignacion (para upsert)
    -- ========================================
    SELECT id, equipo
    INTO v_asignacion_id, v_equipo_anterior
    FROM asignaciones_equipos
    WHERE fecha_id = p_fecha_id
    AND usuario_id = p_usuario_id;

    v_es_actualizacion := FOUND;

    -- ========================================
    -- INSERT o UPDATE (upsert)
    -- ========================================
    IF v_es_actualizacion THEN
        -- Actualizar asignacion existente
        UPDATE asignaciones_equipos
        SET equipo = v_equipo_enum
        WHERE id = v_asignacion_id;
    ELSE
        -- Insertar nueva asignacion
        INSERT INTO asignaciones_equipos (
            fecha_id,
            usuario_id,
            equipo
        ) VALUES (
            p_fecha_id,
            p_usuario_id,
            v_equipo_enum
        )
        RETURNING id INTO v_asignacion_id;
    END IF;

    -- ========================================
    -- Retorno exitoso
    -- ========================================
    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'asignacion_id', v_asignacion_id,
            'fecha_id', p_fecha_id,
            'usuario_id', p_usuario_id,
            'usuario_nombre', v_usuario_destino.nombre_completo,
            'equipo', v_equipo_enum,
            'equipo_anterior', CASE WHEN v_es_actualizacion THEN v_equipo_anterior::TEXT ELSE NULL END,
            'es_actualizacion', v_es_actualizacion,
            'fecha_formato', TO_CHAR(v_fecha.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY HH24:MI'),
            'lugar', v_fecha.lugar
        ),
        'message', CASE
            WHEN v_es_actualizacion THEN
                v_usuario_destino.nombre_completo || ' cambiado de equipo ' ||
                v_equipo_anterior::TEXT || ' a ' || v_equipo_enum::TEXT
            ELSE
                v_usuario_destino.nombre_completo || ' asignado al equipo ' || v_equipo_enum::TEXT
        END
    );

EXCEPTION
    WHEN unique_violation THEN
        RETURN json_build_object(
            'success', false,
            'error', json_build_object(
                'code', 'UNIQUE_VIOLATION',
                'message', 'El usuario ya tiene una asignacion para esta fecha',
                'hint', 'asignacion_duplicada'
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
-- PARTE 6: FUNCION RPC confirmar_equipos
-- ============================================

-- ============================================
-- Funcion: confirmar_equipos
-- Descripcion: Confirma las asignaciones de equipo y notifica a todos los jugadores
-- Reglas: RN-001, RN-002, RN-005, RN-006, RN-007
-- CA: CA-006, CA-007
-- ============================================
CREATE OR REPLACE FUNCTION confirmar_equipos(
    p_fecha_id UUID
) RETURNS JSON AS $$
DECLARE
    v_error_hint TEXT;
    v_current_user_id UUID;
    v_current_user RECORD;
    v_fecha RECORD;
    v_total_inscritos INTEGER;
    v_total_asignados INTEGER;
    v_sin_asignar INTEGER;
    v_equipo_counts JSON;
    v_max_count INTEGER;
    v_min_count INTEGER;
    v_desbalanceado BOOLEAN;
    v_diferencia_max INTEGER;
    v_jugador RECORD;
    v_companeros TEXT;
    v_mensaje_equipo TEXT;
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
    -- RN-001: Solo admin aprobado puede confirmar equipos
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
        RAISE EXCEPTION 'Solo los administradores aprobados pueden confirmar equipos';
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
    -- RN-002: Solo se puede confirmar si fecha.estado = 'cerrada'
    -- ========================================
    IF v_fecha.estado != 'cerrada' THEN
        v_error_hint := 'estado_invalido';
        RAISE EXCEPTION 'Solo se pueden confirmar equipos cuando las inscripciones estan cerradas. Estado actual: %', v_fecha.estado;
    END IF;

    -- ========================================
    -- Contar inscritos y asignados
    -- ========================================
    SELECT COUNT(*) INTO v_total_inscritos
    FROM inscripciones
    WHERE fecha_id = p_fecha_id
    AND estado = 'inscrito';

    SELECT COUNT(*) INTO v_total_asignados
    FROM asignaciones_equipos
    WHERE fecha_id = p_fecha_id;

    v_sin_asignar := v_total_inscritos - v_total_asignados;

    -- ========================================
    -- RN-005: Todos los inscritos deben tener equipo asignado
    -- ========================================
    IF v_sin_asignar > 0 THEN
        v_error_hint := 'asignacion_incompleta';
        RAISE EXCEPTION 'No se puede confirmar: Hay % jugador(es) sin equipo asignado', v_sin_asignar;
    END IF;

    -- ========================================
    -- RN-006: Calcular balance de equipos y advertencia
    -- ========================================
    SELECT json_agg(
        json_build_object(
            'equipo', equipo,
            'cantidad', cantidad
        )
    )
    INTO v_equipo_counts
    FROM (
        SELECT equipo, COUNT(*) as cantidad
        FROM asignaciones_equipos
        WHERE fecha_id = p_fecha_id
        GROUP BY equipo
        ORDER BY equipo
    ) counts;

    -- Obtener max y min para calcular diferencia
    SELECT MAX(cnt), MIN(cnt)
    INTO v_max_count, v_min_count
    FROM (
        SELECT COUNT(*) as cnt
        FROM asignaciones_equipos
        WHERE fecha_id = p_fecha_id
        GROUP BY equipo
    ) eq_counts;

    v_diferencia_max := COALESCE(v_max_count - v_min_count, 0);
    v_desbalanceado := v_diferencia_max > 1;

    -- ========================================
    -- RN-007: Crear notificaciones para cada jugador con equipo y companeros
    -- ========================================
    FOR v_jugador IN
        SELECT
            ae.usuario_id,
            ae.equipo,
            u.nombre_completo
        FROM asignaciones_equipos ae
        JOIN usuarios u ON u.id = ae.usuario_id
        WHERE ae.fecha_id = p_fecha_id
    LOOP
        -- Obtener lista de companeros (mismo equipo, excluyendo al jugador)
        SELECT string_agg(u.nombre_completo, ', ' ORDER BY u.nombre_completo)
        INTO v_companeros
        FROM asignaciones_equipos ae
        JOIN usuarios u ON u.id = ae.usuario_id
        WHERE ae.fecha_id = p_fecha_id
        AND ae.equipo = v_jugador.equipo
        AND ae.usuario_id != v_jugador.usuario_id;

        -- Construir mensaje
        v_mensaje_equipo := 'Has sido asignado al equipo ' || UPPER(v_jugador.equipo::TEXT) ||
            ' para la pichanga del ' ||
            TO_CHAR(v_fecha.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY') ||
            ' a las ' ||
            TO_CHAR(v_fecha.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'HH24:MI') ||
            ' en ' || v_fecha.lugar || '.';

        IF v_companeros IS NOT NULL AND v_companeros != '' THEN
            v_mensaje_equipo := v_mensaje_equipo || ' Tus companeros: ' || v_companeros || '.';
        END IF;

        -- Insertar notificacion
        INSERT INTO notificaciones (
            usuario_id,
            tipo,
            titulo,
            mensaje,
            metadata
        ) VALUES (
            v_jugador.usuario_id,
            'general',
            'Equipo asignado: ' || UPPER(v_jugador.equipo::TEXT),
            v_mensaje_equipo,
            jsonb_build_object(
                'fecha_id', p_fecha_id,
                'tipo_evento', 'asignacion_equipo',
                'equipo', v_jugador.equipo,
                'companeros', v_companeros,
                'confirmado_por', v_current_user.id,
                'confirmado_por_nombre', v_current_user.nombre_completo
            )
        );
    END LOOP;

    -- ========================================
    -- Retorno exitoso con resumen
    -- ========================================
    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'fecha_id', p_fecha_id,
            'fecha_formato', TO_CHAR(v_fecha.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY HH24:MI'),
            'lugar', v_fecha.lugar,
            'num_equipos', v_fecha.num_equipos,
            'total_jugadores', v_total_asignados,
            'equipos', v_equipo_counts,
            'balance', json_build_object(
                'desbalanceado', v_desbalanceado,
                'diferencia_maxima', v_diferencia_max,
                'advertencia', CASE
                    WHEN v_desbalanceado THEN
                        'Equipos desbalanceados: diferencia de ' || v_diferencia_max || ' jugadores'
                    ELSE NULL
                END
            ),
            'notificaciones_enviadas', v_total_asignados,
            'confirmado_por', v_current_user.id,
            'confirmado_por_nombre', v_current_user.nombre_completo,
            'confirmado_at', NOW() AT TIME ZONE 'America/Lima',
            'confirmado_at_formato', TO_CHAR(NOW() AT TIME ZONE 'America/Lima', 'DD/MM/YYYY HH24:MI')
        ),
        'message', CASE
            WHEN v_desbalanceado THEN
                'Equipos confirmados con advertencia: Los equipos estan desbalanceados (diferencia de ' ||
                v_diferencia_max || ' jugadores). Se ha notificado a ' || v_total_asignados || ' jugadores.'
            ELSE
                'Equipos confirmados exitosamente. Se ha notificado a ' || v_total_asignados || ' jugadores.'
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
-- PARTE 7: FUNCION RPC obtener_asignaciones
-- ============================================

-- ============================================
-- Funcion: obtener_asignaciones
-- Descripcion: Obtiene la lista de jugadores inscritos con su asignacion de equipo
-- Retorna inscritos asignados y sin asignar, mas info de equipos disponibles
-- Reglas: RN-003, RN-004
-- CA: CA-001, CA-002, CA-003
-- ============================================
CREATE OR REPLACE FUNCTION obtener_asignaciones(
    p_fecha_id UUID
) RETURNS JSON AS $$
DECLARE
    v_error_hint TEXT;
    v_current_user_id UUID;
    v_current_user RECORD;
    v_fecha RECORD;
    v_jugadores JSON;
    v_equipos_resumen JSON;
    v_total_inscritos INTEGER;
    v_total_asignados INTEGER;
    v_colores_disponibles TEXT[];
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
    -- RN-003/RN-004: Determinar colores disponibles segun num_equipos
    -- ========================================
    IF v_fecha.num_equipos = 2 THEN
        v_colores_disponibles := ARRAY['naranja', 'verde'];
    ELSE -- 3 equipos
        v_colores_disponibles := ARRAY['naranja', 'verde', 'azul'];
    END IF;

    -- ========================================
    -- Obtener lista de jugadores inscritos con su asignacion
    -- ========================================
    SELECT json_agg(jugador_data ORDER BY equipo_orden, nombre_completo)
    INTO v_jugadores
    FROM (
        SELECT
            json_build_object(
                'usuario_id', i.usuario_id,
                'nombre_completo', u.nombre_completo,
                'inscrito_at', i.created_at AT TIME ZONE 'America/Lima',
                'inscrito_formato', TO_CHAR(i.created_at AT TIME ZONE 'America/Lima', 'DD/MM/YYYY HH24:MI'),
                'equipo', ae.equipo,
                'asignacion_id', ae.id,
                'asignado', ae.id IS NOT NULL
            ) as jugador_data,
            -- Para ordenar: primero sin asignar (NULL), luego por equipo
            CASE
                WHEN ae.equipo IS NULL THEN 0
                WHEN ae.equipo = 'naranja' THEN 1
                WHEN ae.equipo = 'verde' THEN 2
                WHEN ae.equipo = 'azul' THEN 3
                ELSE 4
            END as equipo_orden,
            u.nombre_completo
        FROM inscripciones i
        JOIN usuarios u ON u.id = i.usuario_id
        LEFT JOIN asignaciones_equipos ae ON ae.fecha_id = i.fecha_id AND ae.usuario_id = i.usuario_id
        WHERE i.fecha_id = p_fecha_id
        AND i.estado = 'inscrito'
    ) subquery;

    -- ========================================
    -- Resumen de equipos (conteo por equipo)
    -- ========================================
    SELECT json_agg(
        json_build_object(
            'equipo', equipo,
            'cantidad', cantidad,
            'jugadores', jugadores
        ) ORDER BY
            CASE equipo
                WHEN 'naranja' THEN 1
                WHEN 'verde' THEN 2
                WHEN 'azul' THEN 3
                ELSE 4
            END
    )
    INTO v_equipos_resumen
    FROM (
        SELECT
            ae.equipo,
            COUNT(*) as cantidad,
            json_agg(
                json_build_object(
                    'usuario_id', u.id,
                    'nombre_completo', u.nombre_completo
                ) ORDER BY u.nombre_completo
            ) as jugadores
        FROM asignaciones_equipos ae
        JOIN usuarios u ON u.id = ae.usuario_id
        WHERE ae.fecha_id = p_fecha_id
        GROUP BY ae.equipo
    ) eq_summary;

    -- ========================================
    -- Contar totales
    -- ========================================
    SELECT COUNT(*) INTO v_total_inscritos
    FROM inscripciones
    WHERE fecha_id = p_fecha_id
    AND estado = 'inscrito';

    SELECT COUNT(*) INTO v_total_asignados
    FROM asignaciones_equipos
    WHERE fecha_id = p_fecha_id;

    -- ========================================
    -- Retorno exitoso
    -- ========================================
    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'fecha', json_build_object(
                'id', v_fecha.id,
                'fecha_hora_inicio', v_fecha.fecha_hora_inicio,
                'fecha_formato', TO_CHAR(v_fecha.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY'),
                'hora_formato', TO_CHAR(v_fecha.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'HH24:MI'),
                'lugar', v_fecha.lugar,
                'duracion_horas', v_fecha.duracion_horas,
                'num_equipos', v_fecha.num_equipos,
                'estado', v_fecha.estado,
                'puede_asignar', v_fecha.estado = 'cerrada' AND v_current_user.rol = 'admin' AND v_current_user.estado = 'aprobado'
            ),
            'colores_disponibles', v_colores_disponibles,
            'jugadores', COALESCE(v_jugadores, '[]'::json),
            'equipos', COALESCE(v_equipos_resumen, '[]'::json),
            'resumen', json_build_object(
                'total_inscritos', v_total_inscritos,
                'total_asignados', v_total_asignados,
                'sin_asignar', v_total_inscritos - v_total_asignados,
                'asignacion_completa', v_total_inscritos = v_total_asignados AND v_total_inscritos > 0
            ),
            'usuario_actual', json_build_object(
                'es_admin', v_current_user.rol = 'admin' AND v_current_user.estado = 'aprobado'
            )
        ),
        'message', 'Asignaciones obtenidas exitosamente'
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

GRANT EXECUTE ON FUNCTION asignar_equipo TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION confirmar_equipos TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION obtener_asignaciones TO authenticated, service_role;

-- ============================================
-- PARTE 9: COMENTARIOS DE DOCUMENTACION
-- ============================================

COMMENT ON TABLE asignaciones_equipos IS 'E003-HU-005: Tabla de asignaciones de jugadores a equipos por fecha';
COMMENT ON COLUMN asignaciones_equipos.id IS 'Identificador unico de la asignacion';
COMMENT ON COLUMN asignaciones_equipos.fecha_id IS 'ID de la fecha de pichanga';
COMMENT ON COLUMN asignaciones_equipos.usuario_id IS 'ID del usuario asignado';
COMMENT ON COLUMN asignaciones_equipos.equipo IS 'Color del equipo asignado';
COMMENT ON COLUMN asignaciones_equipos.created_at IS 'Timestamp de creacion (UTC)';
COMMENT ON COLUMN asignaciones_equipos.updated_at IS 'Timestamp de ultima actualizacion (UTC)';

COMMENT ON FUNCTION asignar_equipo IS 'E003-HU-005: Asigna un jugador a un equipo (RN-001, RN-002, RN-008)';
COMMENT ON FUNCTION confirmar_equipos IS 'E003-HU-005: Confirma asignaciones y notifica jugadores (RN-001, RN-002, RN-005, RN-006, RN-007)';
COMMENT ON FUNCTION obtener_asignaciones IS 'E003-HU-005: Obtiene lista de asignaciones de una fecha (RN-003, RN-004)';

-- ============================================
-- FIN DEL SCRIPT
-- ============================================
