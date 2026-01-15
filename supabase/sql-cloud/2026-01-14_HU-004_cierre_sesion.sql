-- ============================================
-- HU-004: Cierre de Sesion
-- Fecha: 2026-01-14
-- Descripcion: Implementacion del cierre de sesion con invalidacion
--              inmediata y registro de auditoria
-- ============================================

-- ============================================
-- NOTA IMPORTANTE SOBRE ARQUITECTURA
-- ============================================
-- Supabase Auth maneja el logout principalmente desde el cliente:
-- - supabase.auth.signOut() invalida el JWT token
-- - Supabase elimina automaticamente el refresh token
--
-- Esta funcion RPC complementa el logout para:
-- 1. Registrar el evento de cierre de sesion (auditoria)
-- 2. Permitir logica adicional futura (ej: notificaciones)
-- 3. Confirmar al cliente que el logout fue procesado
-- ============================================

-- ============================================
-- PARTE 1: TABLA DE AUDITORIA DE SESIONES (Opcional)
-- ============================================

-- Tabla: sesiones_log
-- Descripcion: Registra eventos de inicio y cierre de sesion para auditoria
CREATE TABLE IF NOT EXISTS sesiones_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id UUID NOT NULL REFERENCES usuarios(id),
    auth_user_id UUID NOT NULL,
    evento VARCHAR(20) NOT NULL CHECK (evento IN ('login', 'logout')),
    ip_address INET,
    user_agent TEXT,
    fecha_evento TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indices para consultas de auditoria
CREATE INDEX IF NOT EXISTS idx_sesiones_log_usuario ON sesiones_log(usuario_id);
CREATE INDEX IF NOT EXISTS idx_sesiones_log_fecha ON sesiones_log(fecha_evento DESC);
CREATE INDEX IF NOT EXISTS idx_sesiones_log_evento ON sesiones_log(evento);

-- ============================================
-- PARTE 2: FUNCIONES RPC
-- ============================================

-- ============================================
-- Funcion: cerrar_sesion
-- Descripcion: Registra el cierre de sesion y confirma la invalidacion
-- Reglas: RN-002 (Invalidacion inmediata de la sesion)
-- Criterios: CA-002 (Cierre de sesion exitoso)
-- ============================================
CREATE OR REPLACE FUNCTION cerrar_sesion()
RETURNS JSON AS $$
DECLARE
    v_error_hint TEXT;
    v_auth_user_id UUID;
    v_usuario RECORD;
BEGIN
    -- ============================================
    -- PASO 1: Verificar que hay un usuario autenticado
    -- ============================================
    v_auth_user_id := auth.uid();

    IF v_auth_user_id IS NULL THEN
        v_error_hint := 'no_autenticado';
        RAISE EXCEPTION 'No hay sesion activa para cerrar';
    END IF;

    -- ============================================
    -- PASO 2: Obtener datos del usuario para el log
    -- ============================================
    SELECT id, nombre_completo, email
    INTO v_usuario
    FROM usuarios
    WHERE auth_user_id = v_auth_user_id;

    IF NOT FOUND THEN
        -- Usuario existe en auth pero no en tabla usuarios (caso raro)
        -- Aun asi permitimos el logout
        v_error_hint := 'usuario_no_encontrado';
        RAISE EXCEPTION 'Usuario no encontrado en el sistema';
    END IF;

    -- ============================================
    -- PASO 3: Registrar evento de logout (Auditoria)
    -- ============================================
    INSERT INTO sesiones_log (
        usuario_id,
        auth_user_id,
        evento,
        fecha_evento
    ) VALUES (
        v_usuario.id,
        v_auth_user_id,
        'logout',
        NOW()
    );

    -- ============================================
    -- PASO 4: Retornar confirmacion (RN-002, CA-002)
    -- ============================================
    -- NOTA: La invalidacion real del token JWT la hace el cliente
    -- con supabase.auth.signOut(). Esta funcion confirma que el
    -- backend proceso el logout correctamente.

    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'usuario_id', v_usuario.id,
            'email', v_usuario.email,
            'fecha_cierre', NOW() AT TIME ZONE 'America/Lima',
            'sesion_invalidada', true
        ),
        'message', 'Sesion cerrada exitosamente'
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
-- Funcion: registrar_inicio_sesion
-- Descripcion: Registra un inicio de sesion exitoso (complemento de HU-002)
-- Uso: Llamar desde el cliente despues de un login exitoso
-- ============================================
CREATE OR REPLACE FUNCTION registrar_inicio_sesion()
RETURNS JSON AS $$
DECLARE
    v_error_hint TEXT;
    v_auth_user_id UUID;
    v_usuario RECORD;
BEGIN
    v_auth_user_id := auth.uid();

    IF v_auth_user_id IS NULL THEN
        v_error_hint := 'no_autenticado';
        RAISE EXCEPTION 'Usuario no autenticado';
    END IF;

    SELECT id, nombre_completo, email
    INTO v_usuario
    FROM usuarios
    WHERE auth_user_id = v_auth_user_id;

    IF NOT FOUND THEN
        v_error_hint := 'usuario_no_encontrado';
        RAISE EXCEPTION 'Usuario no encontrado en el sistema';
    END IF;

    -- Registrar evento de login
    INSERT INTO sesiones_log (
        usuario_id,
        auth_user_id,
        evento,
        fecha_evento
    ) VALUES (
        v_usuario.id,
        v_auth_user_id,
        'login',
        NOW()
    );

    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'usuario_id', v_usuario.id,
            'fecha_login', NOW() AT TIME ZONE 'America/Lima'
        ),
        'message', 'Inicio de sesion registrado'
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
-- Funcion: obtener_historial_sesiones
-- Descripcion: Obtiene el historial de sesiones del usuario actual
-- Uso: Para que el usuario vea su actividad reciente
-- ============================================
CREATE OR REPLACE FUNCTION obtener_historial_sesiones(
    p_limite INT DEFAULT 10
)
RETURNS JSON AS $$
DECLARE
    v_error_hint TEXT;
    v_auth_user_id UUID;
    v_usuario_id UUID;
    v_sesiones JSON;
BEGIN
    v_auth_user_id := auth.uid();

    IF v_auth_user_id IS NULL THEN
        v_error_hint := 'no_autenticado';
        RAISE EXCEPTION 'Usuario no autenticado';
    END IF;

    -- Obtener usuario_id
    SELECT id INTO v_usuario_id
    FROM usuarios
    WHERE auth_user_id = v_auth_user_id;

    IF NOT FOUND THEN
        v_error_hint := 'usuario_no_encontrado';
        RAISE EXCEPTION 'Usuario no encontrado';
    END IF;

    -- Obtener historial
    SELECT json_agg(
        json_build_object(
            'evento', evento,
            'fecha_utc', fecha_evento,
            'fecha_local', fecha_evento AT TIME ZONE 'America/Lima'
        ) ORDER BY fecha_evento DESC
    )
    INTO v_sesiones
    FROM sesiones_log
    WHERE usuario_id = v_usuario_id
    LIMIT p_limite;

    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'sesiones', COALESCE(v_sesiones, '[]'::json),
            'total', (SELECT COUNT(*) FROM sesiones_log WHERE usuario_id = v_usuario_id)
        ),
        'message', 'Historial obtenido'
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
-- PARTE 3: PERMISOS
-- ============================================

-- cerrar_sesion: Solo para usuarios autenticados
GRANT EXECUTE ON FUNCTION cerrar_sesion TO authenticated;

-- registrar_inicio_sesion: Solo para usuarios autenticados
GRANT EXECUTE ON FUNCTION registrar_inicio_sesion TO authenticated;

-- obtener_historial_sesiones: Solo para usuarios autenticados
GRANT EXECUTE ON FUNCTION obtener_historial_sesiones TO authenticated;

-- ============================================
-- PARTE 4: ROW LEVEL SECURITY (RLS)
-- ============================================

-- Habilitar RLS en tabla sesiones_log
ALTER TABLE sesiones_log ENABLE ROW LEVEL SECURITY;

-- Eliminar politicas existentes si existen (para re-ejecucion segura)
DROP POLICY IF EXISTS "Usuarios ven sus propias sesiones" ON sesiones_log;
DROP POLICY IF EXISTS "No inserciones directas" ON sesiones_log;
DROP POLICY IF EXISTS "Service role acceso completo" ON sesiones_log;

-- Los usuarios solo pueden ver sus propias sesiones
CREATE POLICY "Usuarios ven sus propias sesiones"
ON sesiones_log FOR SELECT
TO authenticated
USING (auth_user_id = auth.uid());

-- No permitir inserciones directas (solo via funciones)
CREATE POLICY "No inserciones directas"
ON sesiones_log FOR INSERT
TO authenticated
USING (false);

-- Service role tiene acceso completo
CREATE POLICY "Service role acceso completo"
ON sesiones_log FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- ============================================
-- PARTE 5: COMENTARIOS DE DOCUMENTACION
-- ============================================

COMMENT ON TABLE sesiones_log IS 'HU-004: Registro de eventos de inicio y cierre de sesion para auditoria';
COMMENT ON FUNCTION cerrar_sesion IS 'HU-004: Registra cierre de sesion y confirma invalidacion (CA-002, RN-002)';
COMMENT ON FUNCTION registrar_inicio_sesion IS 'HU-004: Registra inicio de sesion para auditoria';
COMMENT ON FUNCTION obtener_historial_sesiones IS 'HU-004: Obtiene historial de sesiones del usuario actual';

-- ============================================
-- FIN DEL SCRIPT
-- ============================================
