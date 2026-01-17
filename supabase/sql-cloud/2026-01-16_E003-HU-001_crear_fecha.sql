-- ============================================
-- E003-HU-001: Crear Fecha
-- Fecha: 2026-01-16
-- Descripcion: Implementacion de tabla fechas, enum estado_fecha
--              y funcion RPC crear_fecha para gestion de jornadas de pichanga
-- ============================================

-- ============================================
-- PARTE 1: TIPO ENUM
-- ============================================

-- Tipo ENUM para estados de fecha/jornada
-- RN-006: Estados del ciclo de vida de una fecha
DO $$ BEGIN
    CREATE TYPE estado_fecha AS ENUM (
        'abierta',      -- Inscripciones abiertas
        'cerrada',      -- Inscripciones cerradas, esperando inicio
        'en_juego',     -- Jornada en progreso
        'finalizada',   -- Jornada completada
        'cancelada'     -- Jornada cancelada
    );
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

-- ============================================
-- PARTE 2: TABLA FECHAS
-- ============================================

-- Tabla: fechas
-- Almacena las jornadas/fechas de pichanga
CREATE TABLE IF NOT EXISTS fechas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    fecha_hora_inicio TIMESTAMPTZ NOT NULL,
    duracion_horas INTEGER NOT NULL CHECK (duracion_horas IN (1, 2)),
    lugar TEXT NOT NULL CHECK (LENGTH(TRIM(lugar)) >= 3),
    num_equipos INTEGER NOT NULL CHECK (num_equipos IN (2, 3)),
    costo_por_jugador DECIMAL(10,2) NOT NULL CHECK (costo_por_jugador > 0),
    estado estado_fecha NOT NULL DEFAULT 'abierta',
    created_by UUID NOT NULL REFERENCES usuarios(id) ON DELETE RESTRICT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indices para optimizar consultas
CREATE INDEX IF NOT EXISTS idx_fechas_fecha_hora_inicio ON fechas(fecha_hora_inicio);
CREATE INDEX IF NOT EXISTS idx_fechas_estado ON fechas(estado);
CREATE INDEX IF NOT EXISTS idx_fechas_created_by ON fechas(created_by);

-- Indice unico para evitar fechas duplicadas (RN-005)
-- Solo considera fechas que no estan canceladas
CREATE UNIQUE INDEX IF NOT EXISTS idx_fechas_unico_activo
ON fechas(fecha_hora_inicio)
WHERE estado != 'cancelada';

-- Trigger para actualizar updated_at
DROP TRIGGER IF EXISTS trigger_fechas_updated_at ON fechas;
CREATE TRIGGER trigger_fechas_updated_at
    BEFORE UPDATE ON fechas
    FOR EACH ROW
    EXECUTE FUNCTION actualizar_updated_at();

-- ============================================
-- PARTE 3: FUNCION RPC crear_fecha
-- ============================================

-- ============================================
-- Funcion: crear_fecha
-- Descripcion: Crea una nueva fecha/jornada de pichanga
-- Reglas: RN-001, RN-002, RN-003, RN-004, RN-005, RN-006, RN-007
-- ============================================
CREATE OR REPLACE FUNCTION crear_fecha(
    p_fecha_hora_inicio TIMESTAMPTZ,
    p_duracion_horas INTEGER,
    p_lugar TEXT
) RETURNS JSON AS $$
DECLARE
    v_error_hint TEXT;
    v_current_user_id UUID;
    v_current_user RECORD;
    v_fecha_id UUID;
    v_num_equipos INTEGER;
    v_costo_por_jugador DECIMAL(10,2);
    v_fecha_local TIMESTAMPTZ;
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

    -- ========================================
    -- Validacion RN-002/RN-007: Duracion valida (1 o 2 horas)
    -- ========================================
    IF p_duracion_horas NOT IN (1, 2) THEN
        v_error_hint := 'duracion_invalida';
        RAISE EXCEPTION 'La duracion debe ser 1 o 2 horas';
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
    -- Calculos automaticos RN-002, RN-003, RN-007
    -- 1 hora = 2 equipos, S/8.00
    -- 2 horas = 3 equipos, S/10.00
    -- ========================================
    IF p_duracion_horas = 1 THEN
        v_num_equipos := 2;
        v_costo_por_jugador := 8.00;
    ELSE -- p_duracion_horas = 2
        v_num_equipos := 3;
        v_costo_por_jugador := 10.00;
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
        v_num_equipos,
        v_costo_por_jugador,
        'abierta',
        v_current_user.id
    )
    RETURNING id INTO v_fecha_id;

    -- ========================================
    -- Notificar a jugadores aprobados (CA-007)
    -- Usar tipo_notificacion 'general' ya que no existe 'nueva_fecha'
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
                '. Costo: S/ ' || TO_CHAR(v_costo_por_jugador, 'FM990.00'),
            jsonb_build_object(
                'fecha_id', v_fecha_id,
                'fecha_hora_inicio', p_fecha_hora_inicio,
                'lugar', TRIM(p_lugar),
                'costo', v_costo_por_jugador,
                'duracion_horas', p_duracion_horas,
                'num_equipos', v_num_equipos
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
            'num_equipos', v_num_equipos,
            'costo_por_jugador', v_costo_por_jugador,
            'costo_formato', 'S/ ' || TO_CHAR(v_costo_por_jugador, 'FM990.00'),
            'estado', 'abierta',
            'formato_juego', CASE
                WHEN p_duracion_horas = 1 THEN '2 equipos - partido continuo'
                ELSE '3 equipos con rotacion'
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
-- PARTE 4: PERMISOS
-- ============================================

GRANT EXECUTE ON FUNCTION crear_fecha TO authenticated, service_role;

-- ============================================
-- PARTE 5: ROW LEVEL SECURITY (RLS)
-- ============================================

-- Habilitar RLS en tabla fechas
ALTER TABLE fechas ENABLE ROW LEVEL SECURITY;

-- Eliminar politicas existentes si existen (para re-ejecucion segura)
DROP POLICY IF EXISTS "Usuarios autenticados pueden ver fechas" ON fechas;
DROP POLICY IF EXISTS "Admins pueden insertar fechas" ON fechas;
DROP POLICY IF EXISTS "Admins pueden actualizar fechas" ON fechas;
DROP POLICY IF EXISTS "Admins pueden eliminar fechas" ON fechas;

-- SELECT: Todos los usuarios autenticados pueden ver fechas
CREATE POLICY "Usuarios autenticados pueden ver fechas"
ON fechas FOR SELECT
TO authenticated
USING (true);

-- INSERT: Solo admin aprobado puede insertar
CREATE POLICY "Admins pueden insertar fechas"
ON fechas FOR INSERT
TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1 FROM usuarios u
        WHERE u.auth_user_id = auth.uid()
        AND u.rol = 'admin'
        AND u.estado = 'aprobado'
    )
);

-- UPDATE: Solo admin aprobado puede actualizar
CREATE POLICY "Admins pueden actualizar fechas"
ON fechas FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM usuarios u
        WHERE u.auth_user_id = auth.uid()
        AND u.rol = 'admin'
        AND u.estado = 'aprobado'
    )
);

-- DELETE: Solo admin aprobado puede eliminar
CREATE POLICY "Admins pueden eliminar fechas"
ON fechas FOR DELETE
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
-- PARTE 6: COMENTARIOS DE DOCUMENTACION
-- ============================================

COMMENT ON TABLE fechas IS 'E003-HU-001: Tabla de fechas/jornadas de pichanga';
COMMENT ON COLUMN fechas.id IS 'Identificador unico de la fecha';
COMMENT ON COLUMN fechas.fecha_hora_inicio IS 'Fecha y hora de inicio de la pichanga (UTC)';
COMMENT ON COLUMN fechas.duracion_horas IS 'Duracion en horas: 1 o 2';
COMMENT ON COLUMN fechas.lugar IS 'Nombre de la cancha o direccion';
COMMENT ON COLUMN fechas.num_equipos IS 'Numero de equipos: 2 (1h) o 3 (2h) - calculado automaticamente';
COMMENT ON COLUMN fechas.costo_por_jugador IS 'Costo por jugador en soles: S/8 (1h) o S/10 (2h) - calculado automaticamente';
COMMENT ON COLUMN fechas.estado IS 'Estado del ciclo de vida: abierta, cerrada, en_juego, finalizada, cancelada';
COMMENT ON COLUMN fechas.created_by IS 'ID del admin que creo la fecha';
COMMENT ON COLUMN fechas.created_at IS 'Timestamp de creacion (UTC)';
COMMENT ON COLUMN fechas.updated_at IS 'Timestamp de ultima actualizacion (UTC)';

COMMENT ON FUNCTION crear_fecha IS 'E003-HU-001: Crea nueva fecha de pichanga con validaciones (RN-001 a RN-007)';

-- ============================================
-- FIN DEL SCRIPT
-- ============================================
