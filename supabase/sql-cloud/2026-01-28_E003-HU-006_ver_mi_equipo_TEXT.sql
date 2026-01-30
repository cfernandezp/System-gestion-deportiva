-- ============================================
-- E003-HU-006: Ver Mi Equipo - VERSION CON TEXT
-- Fecha: 2026-01-28
-- SOLUCION: Usar TEXT + CHECK constraint en lugar de ENUM
-- ============================================
--
-- INSTRUCCIONES:
-- 1. Ejecutar este script COMPLETO en SQL Editor de Supabase Cloud
-- 2. Este script usa TEXT en lugar de ENUM para evitar problemas
--
-- ============================================

-- ============================================
-- PARTE 1: TABLA ASIGNACIONES_EQUIPOS
-- ============================================
-- Usar TEXT con CHECK constraint en lugar de ENUM

CREATE TABLE IF NOT EXISTS asignaciones_equipos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    fecha_id UUID NOT NULL REFERENCES fechas(id) ON DELETE CASCADE,
    usuario_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    equipo_color TEXT NOT NULL CHECK (equipo_color IN ('naranja', 'verde', 'azul', 'rojo', 'amarillo', 'blanco')),
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
CREATE INDEX IF NOT EXISTS idx_asignaciones_equipo_color ON asignaciones_equipos(equipo_color);
CREATE INDEX IF NOT EXISTS idx_asignaciones_numero_equipo ON asignaciones_equipos(fecha_id, numero_equipo);

-- Trigger para actualizar updated_at
DROP TRIGGER IF EXISTS trigger_asignaciones_equipos_updated_at ON asignaciones_equipos;
CREATE TRIGGER trigger_asignaciones_equipos_updated_at
    BEFORE UPDATE ON asignaciones_equipos
    FOR EACH ROW
    EXECUTE FUNCTION actualizar_updated_at();

-- ============================================
-- PARTE 2: HABILITAR REALTIME (RN-004)
-- ============================================

DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE asignaciones_equipos;
EXCEPTION
    WHEN duplicate_object THEN
        RAISE NOTICE 'Tabla ya esta en supabase_realtime';
END $$;

-- ============================================
-- PARTE 3: FUNCION RPC obtener_mi_equipo
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
    v_equipos_asignados BOOLEAN;
BEGIN
    v_current_user_id := auth.uid();

    IF v_current_user_id IS NULL THEN
        v_error_hint := 'no_autenticado';
        RAISE EXCEPTION 'Debes iniciar sesion para realizar esta accion';
    END IF;

    IF p_fecha_id IS NULL THEN
        v_error_hint := 'fecha_id_requerido';
        RAISE EXCEPTION 'El ID de la fecha es obligatorio';
    END IF;

    SELECT id, rol, estado, nombre_completo
    INTO v_current_user
    FROM usuarios
    WHERE auth_user_id = v_current_user_id;

    IF NOT FOUND THEN
        v_error_hint := 'usuario_no_encontrado';
        RAISE EXCEPTION 'Usuario no encontrado en el sistema';
    END IF;

    SELECT id, fecha_hora_inicio, lugar, num_equipos, estado
    INTO v_fecha
    FROM fechas
    WHERE id = p_fecha_id;

    IF NOT FOUND THEN
        v_error_hint := 'fecha_no_encontrada';
        RAISE EXCEPTION 'Fecha de pichanga no encontrada';
    END IF;

    SELECT id, estado, created_at
    INTO v_inscripcion
    FROM inscripciones
    WHERE fecha_id = p_fecha_id
    AND usuario_id = v_current_user.id
    AND estado = 'inscrito';

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

    v_equipos_asignados := EXISTS (
        SELECT 1 FROM asignaciones_equipos
        WHERE fecha_id = p_fecha_id
    );

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

    SELECT ae.id, ae.equipo_color, ae.numero_equipo, ae.asignado_at,
           u.nombre_completo as asignado_por_nombre
    INTO v_asignacion
    FROM asignaciones_equipos ae
    LEFT JOIN usuarios u ON u.id = ae.asignado_por
    WHERE ae.fecha_id = p_fecha_id
    AND ae.usuario_id = v_current_user.id;

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
    AND ae.equipo_color = v_asignacion.equipo_color;

    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'esta_inscrito', true,
            'tiene_equipo', true,
            'equipos_asignados', true,
            'mi_equipo', json_build_object(
                'color_equipo', v_asignacion.equipo_color,
                'numero_equipo', v_asignacion.numero_equipo,
                'nombre_equipo', 'Equipo ' || INITCAP(v_asignacion.equipo_color),
                'color_hex', CASE v_asignacion.equipo_color
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
        'message', 'Tu equipo es ' || INITCAP(v_asignacion.equipo_color)
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
-- PARTE 4: FUNCION RPC obtener_equipos_fecha
-- ============================================

CREATE OR REPLACE FUNCTION obtener_equipos_fecha(
    p_fecha_id UUID
) RETURNS JSON AS $$
DECLARE
    v_error_hint TEXT;
    v_current_user_id UUID;
    v_current_user RECORD;
    v_fecha RECORD;
    v_mi_equipo_numero INTEGER;
    v_mi_equipo_color TEXT;
    v_equipos JSON;
    v_equipos_asignados BOOLEAN;
BEGIN
    v_current_user_id := auth.uid();

    IF v_current_user_id IS NULL THEN
        v_error_hint := 'no_autenticado';
        RAISE EXCEPTION 'Debes iniciar sesion para realizar esta accion';
    END IF;

    IF p_fecha_id IS NULL THEN
        v_error_hint := 'fecha_id_requerido';
        RAISE EXCEPTION 'El ID de la fecha es obligatorio';
    END IF;

    SELECT id, rol, estado, nombre_completo
    INTO v_current_user
    FROM usuarios
    WHERE auth_user_id = v_current_user_id;

    IF NOT FOUND THEN
        v_error_hint := 'usuario_no_encontrado';
        RAISE EXCEPTION 'Usuario no encontrado en el sistema';
    END IF;

    SELECT id, fecha_hora_inicio, lugar, num_equipos, estado
    INTO v_fecha
    FROM fechas
    WHERE id = p_fecha_id;

    IF NOT FOUND THEN
        v_error_hint := 'fecha_no_encontrada';
        RAISE EXCEPTION 'Fecha de pichanga no encontrada';
    END IF;

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

    SELECT ae.numero_equipo, ae.equipo_color
    INTO v_mi_equipo_numero, v_mi_equipo_color
    FROM inscripciones i
    LEFT JOIN asignaciones_equipos ae ON ae.fecha_id = i.fecha_id AND ae.usuario_id = i.usuario_id
    WHERE i.fecha_id = p_fecha_id
    AND i.usuario_id = v_current_user.id
    AND i.estado = 'inscrito';

    SELECT json_agg(equipo_data ORDER BY es_mi_equipo DESC, numero_equipo ASC)
    INTO v_equipos
    FROM (
        SELECT
            json_build_object(
                'numero_equipo', ae.numero_equipo,
                'color_equipo', ae.equipo_color,
                'nombre_equipo', 'Equipo ' || INITCAP(ae.equipo_color),
                'color_hex', CASE ae.equipo_color
                    WHEN 'naranja' THEN '#FF9800'
                    WHEN 'verde' THEN '#4CAF50'
                    WHEN 'azul' THEN '#2196F3'
                    WHEN 'rojo' THEN '#F44336'
                    WHEN 'amarillo' THEN '#FFEB3B'
                    WHEN 'blanco' THEN '#FFFFFF'
                    ELSE '#9E9E9E'
                END,
                'es_mi_equipo', (ae.numero_equipo = v_mi_equipo_numero AND ae.equipo_color = v_mi_equipo_color),
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
                    AND ae2.equipo_color = ae.equipo_color
                ),
                'total_jugadores', (
                    SELECT COUNT(*)
                    FROM asignaciones_equipos ae2
                    WHERE ae2.fecha_id = p_fecha_id
                    AND ae2.numero_equipo = ae.numero_equipo
                    AND ae2.equipo_color = ae.equipo_color
                )
            ) as equipo_data,
            ae.numero_equipo,
            (ae.numero_equipo = v_mi_equipo_numero AND ae.equipo_color = v_mi_equipo_color) as es_mi_equipo
        FROM asignaciones_equipos ae
        WHERE ae.fecha_id = p_fecha_id
        GROUP BY ae.numero_equipo, ae.equipo_color
    ) subquery;

    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'equipos_asignados', true,
            'equipos', COALESCE(v_equipos, '[]'::json),
            'total_equipos', COALESCE(json_array_length(v_equipos), 0),
            'mi_equipo_numero', v_mi_equipo_numero,
            'mi_color_equipo', v_mi_equipo_color,
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
-- PARTE 5: PERMISOS
-- ============================================

GRANT EXECUTE ON FUNCTION obtener_mi_equipo TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION obtener_equipos_fecha TO authenticated, service_role;

-- ============================================
-- PARTE 6: ROW LEVEL SECURITY (RLS)
-- ============================================

ALTER TABLE asignaciones_equipos ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Usuarios pueden ver asignaciones de fechas donde estan inscritos" ON asignaciones_equipos;
DROP POLICY IF EXISTS "Usuarios pueden ver sus propias asignaciones" ON asignaciones_equipos;
DROP POLICY IF EXISTS "Admins pueden ver todas las asignaciones" ON asignaciones_equipos;
DROP POLICY IF EXISTS "Admins pueden insertar asignaciones" ON asignaciones_equipos;
DROP POLICY IF EXISTS "Admins pueden actualizar asignaciones" ON asignaciones_equipos;
DROP POLICY IF EXISTS "Admins pueden eliminar asignaciones" ON asignaciones_equipos;

CREATE POLICY "Usuarios pueden ver sus propias asignaciones"
ON asignaciones_equipos FOR SELECT TO authenticated
USING (usuario_id IN (SELECT id FROM usuarios WHERE auth_user_id = auth.uid()));

CREATE POLICY "Usuarios pueden ver asignaciones de fechas donde estan inscritos"
ON asignaciones_equipos FOR SELECT TO authenticated
USING (EXISTS (
    SELECT 1 FROM inscripciones i
    JOIN usuarios u ON u.id = i.usuario_id
    WHERE u.auth_user_id = auth.uid()
    AND i.fecha_id = asignaciones_equipos.fecha_id
    AND i.estado = 'inscrito'
));

CREATE POLICY "Admins pueden ver todas las asignaciones"
ON asignaciones_equipos FOR SELECT TO authenticated
USING (EXISTS (
    SELECT 1 FROM usuarios u
    WHERE u.auth_user_id = auth.uid()
    AND u.rol = 'admin' AND u.estado = 'aprobado'
));

CREATE POLICY "Admins pueden insertar asignaciones"
ON asignaciones_equipos FOR INSERT TO authenticated
WITH CHECK (EXISTS (
    SELECT 1 FROM usuarios u
    WHERE u.auth_user_id = auth.uid()
    AND u.rol = 'admin' AND u.estado = 'aprobado'
));

CREATE POLICY "Admins pueden actualizar asignaciones"
ON asignaciones_equipos FOR UPDATE TO authenticated
USING (EXISTS (
    SELECT 1 FROM usuarios u
    WHERE u.auth_user_id = auth.uid()
    AND u.rol = 'admin' AND u.estado = 'aprobado'
));

CREATE POLICY "Admins pueden eliminar asignaciones"
ON asignaciones_equipos FOR DELETE TO authenticated
USING (EXISTS (
    SELECT 1 FROM usuarios u
    WHERE u.auth_user_id = auth.uid()
    AND u.rol = 'admin' AND u.estado = 'aprobado'
));

-- ============================================
-- PARTE 7: COMENTARIOS
-- ============================================

COMMENT ON TABLE asignaciones_equipos IS 'E003-HU-006: Asignaciones de jugadores a equipos por fecha';
COMMENT ON COLUMN asignaciones_equipos.equipo_color IS 'Color del equipo (naranja, verde, azul, rojo, amarillo, blanco)';

-- ============================================
-- FIN DEL SCRIPT
-- ============================================
