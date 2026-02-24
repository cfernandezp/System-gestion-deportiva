-- ============================================
-- E002-HU-001: Crear Grupo Deportivo
-- Fecha: 2026-02-20
-- Crea tablas grupos, miembros_grupo y RPC crear_grupo
-- Dependencia: tabla planes (E000-HU-002) debe existir
-- ============================================

-- ============================================
-- PASO 1: Enum rol_en_grupo
-- ============================================
DO $$ BEGIN
    CREATE TYPE rol_en_grupo AS ENUM ('admin', 'coadmin', 'jugador', 'invitado');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

-- ============================================
-- PASO 2: Tabla grupos
-- ============================================
CREATE TABLE IF NOT EXISTS grupos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre VARCHAR(100) NOT NULL,
    logo_url TEXT,
    lema VARCHAR(100),
    reglas TEXT,
    tipo_deporte VARCHAR(50) NOT NULL DEFAULT 'Futbol',
    admin_creador_id UUID NOT NULL REFERENCES usuarios(id),
    plan_id UUID NOT NULL REFERENCES planes(id),
    limite_jugadores INTEGER NOT NULL DEFAULT 25,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    -- RN-002: Nombre unico por administrador creador
    UNIQUE(admin_creador_id, nombre)
);

-- Indices para consultas frecuentes
CREATE INDEX IF NOT EXISTS idx_grupos_admin_creador ON grupos(admin_creador_id);
CREATE INDEX IF NOT EXISTS idx_grupos_activo ON grupos(activo) WHERE activo = TRUE;

-- ============================================
-- PASO 3: Tabla miembros_grupo
-- ============================================
CREATE TABLE IF NOT EXISTS miembros_grupo (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    grupo_id UUID NOT NULL REFERENCES grupos(id) ON DELETE CASCADE,
    usuario_id UUID NOT NULL REFERENCES usuarios(id),
    rol rol_en_grupo NOT NULL DEFAULT 'jugador',
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    -- Un usuario solo puede ser miembro una vez por grupo
    UNIQUE(grupo_id, usuario_id)
);

-- Indices
CREATE INDEX IF NOT EXISTS idx_miembros_grupo_grupo ON miembros_grupo(grupo_id);
CREATE INDEX IF NOT EXISTS idx_miembros_grupo_usuario ON miembros_grupo(usuario_id);

-- ============================================
-- PASO 4: RLS para grupos
-- ============================================
ALTER TABLE grupos ENABLE ROW LEVEL SECURITY;

-- Admin creador puede ver sus grupos
DROP POLICY IF EXISTS "grupos_select_admin" ON grupos;
CREATE POLICY "grupos_select_admin" ON grupos
    FOR SELECT TO authenticated
    USING (
        admin_creador_id IN (
            SELECT id FROM usuarios WHERE auth_user_id = auth.uid()
        )
    );

-- Miembros pueden ver grupos donde participan
DROP POLICY IF EXISTS "grupos_select_miembro" ON grupos;
CREATE POLICY "grupos_select_miembro" ON grupos
    FOR SELECT TO authenticated
    USING (
        id IN (
            SELECT grupo_id FROM miembros_grupo
            WHERE usuario_id IN (
                SELECT id FROM usuarios WHERE auth_user_id = auth.uid()
            )
            AND activo = TRUE
        )
    );

-- Solo admin creador puede actualizar
DROP POLICY IF EXISTS "grupos_update_admin" ON grupos;
CREATE POLICY "grupos_update_admin" ON grupos
    FOR UPDATE TO authenticated
    USING (
        admin_creador_id IN (
            SELECT id FROM usuarios WHERE auth_user_id = auth.uid()
        )
    );

-- Solo autenticados pueden insertar (via RPC)
DROP POLICY IF EXISTS "grupos_insert_auth" ON grupos;
CREATE POLICY "grupos_insert_auth" ON grupos
    FOR INSERT TO authenticated
    WITH CHECK (TRUE);

-- ============================================
-- PASO 5: RLS para miembros_grupo
-- ============================================
ALTER TABLE miembros_grupo ENABLE ROW LEVEL SECURITY;

-- Miembros del grupo pueden ver otros miembros
DROP POLICY IF EXISTS "miembros_select" ON miembros_grupo;
CREATE POLICY "miembros_select" ON miembros_grupo
    FOR SELECT TO authenticated
    USING (
        grupo_id IN (
            SELECT grupo_id FROM miembros_grupo mg
            WHERE mg.usuario_id IN (
                SELECT id FROM usuarios WHERE auth_user_id = auth.uid()
            )
        )
    );

-- Insert via RPC
DROP POLICY IF EXISTS "miembros_insert_auth" ON miembros_grupo;
CREATE POLICY "miembros_insert_auth" ON miembros_grupo
    FOR INSERT TO authenticated
    WITH CHECK (TRUE);

-- ============================================
-- PASO 6: RPC crear_grupo
-- CA-001 a CA-007, RN-001 a RN-008
-- ============================================
CREATE OR REPLACE FUNCTION crear_grupo(
    p_nombre TEXT,
    p_lema TEXT DEFAULT NULL,
    p_reglas TEXT DEFAULT NULL,
    p_logo_url TEXT DEFAULT NULL
) RETURNS JSON AS $$
DECLARE
    v_usuario_id UUID;
    v_auth_uid UUID;
    v_plan_id UUID;
    v_limite_grupos INTEGER;
    v_limite_jugadores INTEGER;
    v_grupos_actuales INTEGER;
    v_grupo_id UUID;
    v_nombre_limpio TEXT;
    v_error_hint TEXT;
BEGIN
    -- =============================================
    -- RN-001: Verificar autenticacion
    -- =============================================
    v_auth_uid := auth.uid();
    IF v_auth_uid IS NULL THEN
        v_error_hint := 'no_autenticado';
        RAISE EXCEPTION 'Debes iniciar sesion para crear un grupo';
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
    -- CA-001 / CA-002: Validar nombre
    -- =============================================
    v_nombre_limpio := TRIM(p_nombre);

    IF v_nombre_limpio IS NULL OR LENGTH(v_nombre_limpio) < 1 THEN
        v_error_hint := 'nombre_requerido';
        RAISE EXCEPTION 'El nombre del grupo es obligatorio';
    END IF;

    IF LENGTH(v_nombre_limpio) > 100 THEN
        v_error_hint := 'nombre_muy_largo';
        RAISE EXCEPTION 'El nombre del grupo no puede exceder 100 caracteres';
    END IF;

    -- RN-002: Verificar nombre unico por admin
    IF EXISTS (
        SELECT 1 FROM grupos
        WHERE admin_creador_id = v_usuario_id
        AND LOWER(nombre) = LOWER(v_nombre_limpio)
        AND activo = TRUE
    ) THEN
        v_error_hint := 'nombre_duplicado';
        RAISE EXCEPTION 'Ya tienes un grupo con ese nombre';
    END IF;

    -- =============================================
    -- RN-004: Validar lema (max 100 caracteres)
    -- =============================================
    IF p_lema IS NOT NULL AND LENGTH(TRIM(p_lema)) > 100 THEN
        v_error_hint := 'lema_muy_largo';
        RAISE EXCEPTION 'El lema no puede exceder 100 caracteres';
    END IF;

    -- =============================================
    -- CA-006 / RN-007: Verificar limite de grupos por plan
    -- =============================================
    SELECT u.plan_id, p.max_grupos_por_admin, p.max_jugadores_por_grupo
    INTO v_plan_id, v_limite_grupos, v_limite_jugadores
    FROM usuarios u
    JOIN planes p ON u.plan_id = p.id
    WHERE u.id = v_usuario_id;

    IF v_plan_id IS NULL THEN
        -- Si no tiene plan, usar plan Gratis por defecto
        SELECT id, max_grupos_por_admin, max_jugadores_por_grupo
        INTO v_plan_id, v_limite_grupos, v_limite_jugadores
        FROM planes WHERE slug = 'gratis' LIMIT 1;
    END IF;

    -- Contar grupos activos donde es admin creador
    SELECT COUNT(*) INTO v_grupos_actuales
    FROM grupos
    WHERE admin_creador_id = v_usuario_id
    AND activo = TRUE;

    IF v_grupos_actuales >= v_limite_grupos THEN
        v_error_hint := 'limite_grupos_alcanzado';
        RAISE EXCEPTION 'Has alcanzado el limite de % grupos de tu plan. Actualiza tu plan para crear mas grupos.', v_limite_grupos;
    END IF;

    -- =============================================
    -- Crear grupo
    -- CA-005 / RN-006: Tipo deporte fijo 'Futbol'
    -- CA-007: Limites por defecto del plan
    -- =============================================
    INSERT INTO grupos (
        nombre,
        logo_url,
        lema,
        reglas,
        tipo_deporte,
        admin_creador_id,
        plan_id,
        limite_jugadores,
        activo,
        created_at,
        updated_at
    ) VALUES (
        v_nombre_limpio,
        CASE
            WHEN p_logo_url IS NOT NULL AND TRIM(p_logo_url) != ''
            THEN TRIM(p_logo_url)
            ELSE NULL
        END,
        CASE
            WHEN p_lema IS NOT NULL AND TRIM(p_lema) != ''
            THEN TRIM(p_lema)
            ELSE NULL
        END,
        CASE
            WHEN p_reglas IS NOT NULL AND TRIM(p_reglas) != ''
            THEN TRIM(p_reglas)
            ELSE NULL
        END,
        'Futbol',
        v_usuario_id,
        v_plan_id,
        v_limite_jugadores,
        TRUE,
        NOW(),
        NOW()
    )
    RETURNING id INTO v_grupo_id;

    -- =============================================
    -- RN-008: Asignar creador como admin del grupo
    -- =============================================
    INSERT INTO miembros_grupo (
        grupo_id,
        usuario_id,
        rol,
        activo,
        created_at,
        updated_at
    ) VALUES (
        v_grupo_id,
        v_usuario_id,
        'admin',
        TRUE,
        NOW(),
        NOW()
    );

    -- =============================================
    -- Retornar resultado exitoso
    -- =============================================
    RETURN json_build_object(
        'success', TRUE,
        'message', 'Grupo creado exitosamente',
        'data', json_build_object(
            'grupo_id', v_grupo_id,
            'nombre', v_nombre_limpio,
            'logo_url', p_logo_url,
            'lema', p_lema,
            'reglas', p_reglas,
            'tipo_deporte', 'Futbol',
            'admin_creador_id', v_usuario_id,
            'plan_id', v_plan_id,
            'limite_jugadores', v_limite_jugadores,
            'activo', TRUE
        )
    );

EXCEPTION
    WHEN unique_violation THEN
        RETURN json_build_object(
            'success', FALSE,
            'error', json_build_object(
                'message', 'Ya tienes un grupo con ese nombre',
                'code', SQLSTATE,
                'hint', 'nombre_duplicado'
            )
        );
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

-- Permisos
GRANT EXECUTE ON FUNCTION crear_grupo TO authenticated;

-- ============================================
-- NOTA: Crear bucket 'grupo-logos' manualmente en Supabase Dashboard
-- Storage > New bucket > nombre: grupo-logos
-- Public bucket: YES (para que los logos sean accesibles)
-- File size limit: 2MB
-- Allowed MIME types: image/jpeg, image/png
-- ============================================
