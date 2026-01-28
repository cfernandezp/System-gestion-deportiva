-- ============================================
-- E003-HU-006: Ver Mi Equipo
-- Fecha: 2026-01-28
-- Descripcion: Implementacion de tabla asignaciones_equipos y funciones RPC
--              para permitir a jugadores ver su equipo asignado y companeros
-- ============================================

-- ============================================
-- PARTE 1: TIPO ENUM PARA COLORES DE EQUIPO
-- ============================================

-- Tipo ENUM para colores de equipo (RN-005)
-- Colores predefinidos del design system
DO $$ BEGIN
    CREATE TYPE color_equipo AS ENUM (
        'naranja',   -- #FF9800
        'verde',     -- #4CAF50
        'azul',      -- #2196F3
        'rojo',      -- #F44336
        'amarillo',  -- #FFEB3B
        'blanco'     -- #FFFFFF (con borde gris)
    );
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

-- ============================================
-- PARTE 2: TABLA ASIGNACIONES_EQUIPOS
-- ============================================

-- Tabla: asignaciones_equipos
-- Almacena la asignacion de jugadores a equipos para cada fecha
CREATE TABLE IF NOT EXISTS asignaciones_equipos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    fecha_id UUID NOT NULL REFERENCES fechas(id) ON DELETE CASCADE,
    usuario_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    color_equipo color_equipo NOT NULL,
    numero_equipo INTEGER NOT NULL CHECK (numero_equipo BETWEEN 1 AND 3),
    asignado_por UUID REFERENCES usuarios(id) ON DELETE SET NULL,
    asignado_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indice unico: un usuario solo puede estar en un equipo por fecha
CREATE UNIQUE INDEX IF NOT EXISTS idx_asignaciones_usuario_fecha_unico
ON asignaciones_equipos(fecha_id, usuario_id);

-- Indices para optimizar consultas
CREATE INDEX IF NOT EXISTS idx_asignaciones_fecha_id ON asignaciones_equipos(fecha_id);
CREATE INDEX IF NOT EXISTS idx_asignaciones_usuario_id ON asignaciones_equipos(usuario_id);
CREATE INDEX IF NOT EXISTS idx_asignaciones_color_equipo ON asignaciones_equipos(color_equipo);
CREATE INDEX IF NOT EXISTS idx_asignaciones_numero_equipo ON asignaciones_equipos(fecha_id, numero_equipo);

-- Trigger para actualizar updated_at
DROP TRIGGER IF EXISTS trigger_asignaciones_equipos_updated_at ON asignaciones_equipos;
CREATE TRIGGER trigger_asignaciones_equipos_updated_at
    BEFORE UPDATE ON asignaciones_equipos
    FOR EACH ROW
    EXECUTE FUNCTION actualizar_updated_at();

-- ============================================
-- PARTE 3: HABILITAR REALTIME (RN-004)
-- ============================================

-- Habilitar Supabase Realtime para actualizaciones en tiempo real
-- Latencia maxima aceptable: 5 segundos
ALTER PUBLICATION supabase_realtime ADD TABLE asignaciones_equipos;

-- ============================================
-- PARTE 4: FUNCION RPC obtener_mi_equipo
-- ============================================

-- ============================================
-- Funcion: obtener_mi_equipo
-- Descripcion: Obtiene el equipo del usuario actual para una fecha
-- CA-001, CA-002, CA-003, CA-005, CA-006, RN-001, RN-003
-- ============================================
CREATE OR REPLACE FUNCTION obtener_mi_equipo(
    p_fecha_id UUID
) RETURNS JSON AS $$
DECLARE
    v_error_hint TEXT;
    v_current_user_id UUID;
    v_current_user RECORD;
    v_fecha RECORD;
    v_inscripcion RECORD;
    v_asignacion RECORD;
    v_companeros JSON;
    v_total_equipos INTEGER;
    v_equipos_asignados BOOLEAN;
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
    -- Verificar que la fecha existe
    -- ========================================
    SELECT id, fecha_hora_inicio, lugar, num_equipos, estado
    INTO v_fecha
    FROM fechas
    WHERE id = p_fecha_id;

    IF NOT FOUND THEN
        v_error_hint := 'fecha_no_encontrada';
        RAISE EXCEPTION 'Fecha de pichanga no encontrada';
    END IF;

    -- ========================================
    -- CA-006: Verificar si usuario esta inscrito
    -- ========================================
    SELECT id, estado, created_at
    INTO v_inscripcion
    FROM inscripciones
    WHERE fecha_id = p_fecha_id
    AND usuario_id = v_current_user.id
    AND estado = 'inscrito';

    -- Si no esta inscrito, retornar estado especial
    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', true,
            'data', json_build_object(
                'esta_inscrito', false,
                'tiene_equipo', false,
                'equipos_asignados', EXISTS (
                    SELECT 1 FROM asignaciones_equipos
                    WHERE fecha_id = p_fecha_id
                ),
                'mensaje', 'No estas inscrito a esta fecha'
            ),
            'message', 'Consulta realizada exitosamente'
        );
    END IF;

    -- ========================================
    -- Verificar si hay equipos asignados para esta fecha
    -- ========================================
    v_equipos_asignados := EXISTS (
        SELECT 1 FROM asignaciones_equipos
        WHERE fecha_id = p_fecha_id
    );

    -- ========================================
    -- CA-005: Si no hay equipos asignados, retornar estado pendiente
    -- ========================================
    IF NOT v_equipos_asignados THEN
        RETURN json_build_object(
            'success', true,
            'data', json_build_object(
                'esta_inscrito', true,
                'tiene_equipo', false,
                'equipos_asignados', false,
                'mensaje', 'Esperando asignacion de equipos'
            ),
            'message', 'Aun no se han asignado equipos para esta fecha'
        );
    END IF;

    -- ========================================
    -- RN-001: Obtener asignacion del usuario
    -- ========================================
    SELECT ae.id, ae.color_equipo::text, ae.numero_equipo, ae.asignado_at,
           u.nombre_completo as asignado_por_nombre
    INTO v_asignacion
    FROM asignaciones_equipos ae
    LEFT JOIN usuarios u ON u.id = ae.asignado_por
    WHERE ae.fecha_id = p_fecha_id
    AND ae.usuario_id = v_current_user.id;

    -- Si el usuario esta inscrito pero no tiene equipo asignado
    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', true,
            'data', json_build_object(
                'esta_inscrito', true,
                'tiene_equipo', false,
                'equipos_asignados', true,
                'mensaje', 'Estas inscrito pero aun no tienes equipo asignado'
            ),
            'message', 'Consulta realizada exitosamente'
        );
    END IF;

    -- ========================================
    -- CA-003, RN-003: Obtener lista de companeros
    -- Solo informacion publica: foto, apodo/nombre
    -- ========================================
    SELECT json_agg(
        json_build_object(
            'usuario_id', u.id,
            'nombre', COALESCE(u.apodo, SPLIT_PART(u.nombre_completo, ' ', 1)),
            'nombre_completo', u.nombre_completo,
            'foto_url', u.foto_url,
            'es_tu', u.id = v_current_user.id
        ) ORDER BY
            CASE WHEN u.id = v_current_user.id THEN 0 ELSE 1 END,
            u.nombre_completo
    )
    INTO v_companeros
    FROM asignaciones_equipos ae
    JOIN usuarios u ON u.id = ae.usuario_id
    WHERE ae.fecha_id = p_fecha_id
    AND ae.numero_equipo = v_asignacion.numero_equipo
    AND ae.color_equipo::text = v_asignacion.color_equipo;

    -- ========================================
    -- CA-001, CA-002: Retornar datos del equipo
    -- ========================================
    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'esta_inscrito', true,
            'tiene_equipo', true,
            'equipos_asignados', true,
            'mi_equipo', json_build_object(
                'color_equipo', v_asignacion.color_equipo,
                'numero_equipo', v_asignacion.numero_equipo,
                'nombre_equipo', 'Equipo ' || INITCAP(v_asignacion.color_equipo),
                'color_hex', CASE v_asignacion.color_equipo
                    WHEN 'naranja' THEN '#FF9800'
                    WHEN 'verde' THEN '#4CAF50'
                    WHEN 'azul' THEN '#2196F3'
                    WHEN 'rojo' THEN '#F44336'
                    WHEN 'amarillo' THEN '#FFEB3B'
                    WHEN 'blanco' THEN '#FFFFFF'
                    ELSE '#9E9E9E'
                END,
                'asignado_at', v_asignacion.asignado_at AT TIME ZONE 'America/Lima',
                'asignado_at_formato', TO_CHAR(v_asignacion.asignado_at AT TIME ZONE 'America/Lima', 'DD/MM/YYYY HH24:MI'),
                'asignado_por', v_asignacion.asignado_por_nombre
            ),
            'companeros', COALESCE(v_companeros, '[]'::json),
            'total_companeros', COALESCE(json_array_length(v_companeros), 0)
        ),
        'message', 'Tu equipo es ' || INITCAP(v_asignacion.color_equipo)
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
-- PARTE 5: FUNCION RPC obtener_equipos_fecha
-- ============================================

-- ============================================
-- Funcion: obtener_equipos_fecha
-- Descripcion: Obtiene todos los equipos de una fecha con sus jugadores
-- CA-004, RN-002
-- ============================================
CREATE OR REPLACE FUNCTION obtener_equipos_fecha(
    p_fecha_id UUID
) RETURNS JSON AS $$
DECLARE
    v_error_hint TEXT;
    v_current_user_id UUID;
    v_current_user RECORD;
    v_fecha RECORD;
    v_inscripcion RECORD;
    v_mi_equipo_numero INTEGER;
    v_mi_color_equipo TEXT;
    v_equipos JSON;
    v_equipos_asignados BOOLEAN;
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
    -- Verificar que la fecha existe
    -- ========================================
    SELECT id, fecha_hora_inicio, lugar, num_equipos, estado
    INTO v_fecha
    FROM fechas
    WHERE id = p_fecha_id;

    IF NOT FOUND THEN
        v_error_hint := 'fecha_no_encontrada';
        RAISE EXCEPTION 'Fecha de pichanga no encontrada';
    END IF;

    -- ========================================
    -- Verificar si hay equipos asignados
    -- ========================================
    v_equipos_asignados := EXISTS (
        SELECT 1 FROM asignaciones_equipos
        WHERE fecha_id = p_fecha_id
    );

    IF NOT v_equipos_asignados THEN
        RETURN json_build_object(
            'success', true,
            'data', json_build_object(
                'equipos_asignados', false,
                'equipos', '[]'::json,
                'total_equipos', 0,
                'mensaje', 'Aun no se han asignado equipos para esta fecha'
            ),
            'message', 'No hay equipos asignados'
        );
    END IF;

    -- ========================================
    -- Verificar inscripcion del usuario y obtener su equipo
    -- ========================================
    SELECT ae.numero_equipo, ae.color_equipo::text
    INTO v_mi_equipo_numero, v_mi_color_equipo
    FROM inscripciones i
    LEFT JOIN asignaciones_equipos ae ON ae.fecha_id = i.fecha_id AND ae.usuario_id = i.usuario_id
    WHERE i.fecha_id = p_fecha_id
    AND i.usuario_id = v_current_user.id
    AND i.estado = 'inscrito';

    -- ========================================
    -- CA-004, RN-002: Obtener todos los equipos
    -- Mi equipo aparece primero (destacado)
    -- ========================================
    SELECT json_agg(equipo_data ORDER BY es_mi_equipo DESC, numero_equipo ASC)
    INTO v_equipos
    FROM (
        SELECT
            json_build_object(
                'numero_equipo', ae.numero_equipo,
                'color_equipo', ae.color_equipo::text,
                'nombre_equipo', 'Equipo ' || INITCAP(ae.color_equipo::text),
                'color_hex', CASE ae.color_equipo::text
                    WHEN 'naranja' THEN '#FF9800'
                    WHEN 'verde' THEN '#4CAF50'
                    WHEN 'azul' THEN '#2196F3'
                    WHEN 'rojo' THEN '#F44336'
                    WHEN 'amarillo' THEN '#FFEB3B'
                    WHEN 'blanco' THEN '#FFFFFF'
                    ELSE '#9E9E9E'
                END,
                'es_mi_equipo', (ae.numero_equipo = v_mi_equipo_numero AND ae.color_equipo::text = v_mi_color_equipo),
                'jugadores', (
                    SELECT json_agg(
                        json_build_object(
                            'usuario_id', u.id,
                            'nombre', COALESCE(u.apodo, SPLIT_PART(u.nombre_completo, ' ', 1)),
                            'nombre_completo', u.nombre_completo,
                            'foto_url', u.foto_url,
                            'es_tu', u.id = v_current_user.id
                        ) ORDER BY
                            CASE WHEN u.id = v_current_user.id THEN 0 ELSE 1 END,
                            u.nombre_completo
                    )
                    FROM asignaciones_equipos ae2
                    JOIN usuarios u ON u.id = ae2.usuario_id
                    WHERE ae2.fecha_id = p_fecha_id
                    AND ae2.numero_equipo = ae.numero_equipo
                    AND ae2.color_equipo = ae.color_equipo
                ),
                'total_jugadores', (
                    SELECT COUNT(*)
                    FROM asignaciones_equipos ae2
                    WHERE ae2.fecha_id = p_fecha_id
                    AND ae2.numero_equipo = ae.numero_equipo
                    AND ae2.color_equipo = ae.color_equipo
                )
            ) as equipo_data,
            ae.numero_equipo,
            (ae.numero_equipo = v_mi_equipo_numero AND ae.color_equipo::text = v_mi_color_equipo) as es_mi_equipo
        FROM asignaciones_equipos ae
        WHERE ae.fecha_id = p_fecha_id
        GROUP BY ae.numero_equipo, ae.color_equipo
    ) subquery;

    -- ========================================
    -- Retorno exitoso
    -- ========================================
    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'equipos_asignados', true,
            'equipos', COALESCE(v_equipos, '[]'::json),
            'total_equipos', COALESCE(json_array_length(v_equipos), 0),
            'mi_equipo_numero', v_mi_equipo_numero,
            'mi_color_equipo', v_mi_color_equipo,
            'esta_inscrito', v_mi_equipo_numero IS NOT NULL OR EXISTS (
                SELECT 1 FROM inscripciones
                WHERE fecha_id = p_fecha_id
                AND usuario_id = v_current_user.id
                AND estado = 'inscrito'
            ),
            'fecha', json_build_object(
                'id', v_fecha.id,
                'fecha_hora_inicio', v_fecha.fecha_hora_inicio AT TIME ZONE 'America/Lima',
                'fecha_formato', TO_CHAR(v_fecha.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY'),
                'hora_formato', TO_CHAR(v_fecha.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'HH24:MI'),
                'lugar', v_fecha.lugar,
                'num_equipos', v_fecha.num_equipos,
                'estado', v_fecha.estado::text
            )
        ),
        'message', 'Equipos obtenidos exitosamente'
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
-- PARTE 6: PERMISOS
-- ============================================

GRANT EXECUTE ON FUNCTION obtener_mi_equipo TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION obtener_equipos_fecha TO authenticated, service_role;

-- ============================================
-- PARTE 7: ROW LEVEL SECURITY (RLS)
-- ============================================

-- Habilitar RLS en tabla asignaciones_equipos
ALTER TABLE asignaciones_equipos ENABLE ROW LEVEL SECURITY;

-- Eliminar politicas existentes si existen (para re-ejecucion segura)
DROP POLICY IF EXISTS "Usuarios pueden ver asignaciones de fechas donde estan inscritos" ON asignaciones_equipos;
DROP POLICY IF EXISTS "Usuarios pueden ver sus propias asignaciones" ON asignaciones_equipos;
DROP POLICY IF EXISTS "Admins pueden ver todas las asignaciones" ON asignaciones_equipos;
DROP POLICY IF EXISTS "Admins pueden insertar asignaciones" ON asignaciones_equipos;
DROP POLICY IF EXISTS "Admins pueden actualizar asignaciones" ON asignaciones_equipos;
DROP POLICY IF EXISTS "Admins pueden eliminar asignaciones" ON asignaciones_equipos;

-- SELECT: Usuarios pueden ver sus propias asignaciones
CREATE POLICY "Usuarios pueden ver sus propias asignaciones"
ON asignaciones_equipos FOR SELECT
TO authenticated
USING (
    usuario_id IN (
        SELECT id FROM usuarios
        WHERE auth_user_id = auth.uid()
    )
);

-- SELECT: Usuarios inscritos pueden ver asignaciones de la misma fecha
CREATE POLICY "Usuarios pueden ver asignaciones de fechas donde estan inscritos"
ON asignaciones_equipos FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM inscripciones i
        JOIN usuarios u ON u.id = i.usuario_id
        WHERE u.auth_user_id = auth.uid()
        AND i.fecha_id = asignaciones_equipos.fecha_id
        AND i.estado = 'inscrito'
    )
);

-- SELECT: Admin puede ver todas las asignaciones
CREATE POLICY "Admins pueden ver todas las asignaciones"
ON asignaciones_equipos FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM usuarios u
        WHERE u.auth_user_id = auth.uid()
        AND u.rol = 'admin'
        AND u.estado = 'aprobado'
    )
);

-- INSERT: Solo admin puede insertar asignaciones
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

-- UPDATE: Solo admin puede actualizar asignaciones (CA-007: cambio de equipo)
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

-- DELETE: Solo admin puede eliminar asignaciones
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
-- PARTE 8: COMENTARIOS DE DOCUMENTACION
-- ============================================

COMMENT ON TABLE asignaciones_equipos IS 'E003-HU-006: Tabla de asignaciones de jugadores a equipos por fecha';
COMMENT ON COLUMN asignaciones_equipos.id IS 'Identificador unico de la asignacion';
COMMENT ON COLUMN asignaciones_equipos.fecha_id IS 'ID de la fecha de pichanga';
COMMENT ON COLUMN asignaciones_equipos.usuario_id IS 'ID del jugador asignado';
COMMENT ON COLUMN asignaciones_equipos.color_equipo IS 'Color del equipo (naranja, verde, azul, rojo, amarillo, blanco)';
COMMENT ON COLUMN asignaciones_equipos.numero_equipo IS 'Numero del equipo (1, 2 o 3)';
COMMENT ON COLUMN asignaciones_equipos.asignado_por IS 'ID del admin que realizo la asignacion';
COMMENT ON COLUMN asignaciones_equipos.asignado_at IS 'Timestamp de cuando se realizo la asignacion';
COMMENT ON COLUMN asignaciones_equipos.created_at IS 'Timestamp de creacion (UTC)';
COMMENT ON COLUMN asignaciones_equipos.updated_at IS 'Timestamp de ultima actualizacion (UTC)';

COMMENT ON FUNCTION obtener_mi_equipo IS 'E003-HU-006: Obtiene el equipo del usuario actual para una fecha (CA-001 a CA-006, RN-001, RN-003)';
COMMENT ON FUNCTION obtener_equipos_fecha IS 'E003-HU-006: Obtiene todos los equipos de una fecha con sus jugadores (CA-004, RN-002)';

-- ============================================
-- FIN DEL SCRIPT
-- ============================================
