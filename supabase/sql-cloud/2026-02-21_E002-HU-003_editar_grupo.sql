-- ============================================
-- E002-HU-003: Editar Grupo Deportivo
-- Fecha: 2026-02-21
-- Descripcion: RPC para que admin o co-admin editen
--   nombre, logo, lema y reglas de un grupo
-- Dependencia: E002-HU-001 (tablas grupos, miembros_grupo)
-- ============================================

-- ============================================
-- RPC editar_grupo
-- CA-001 a CA-005, RN-001 a RN-004
-- ============================================
CREATE OR REPLACE FUNCTION editar_grupo(
    p_grupo_id UUID,
    p_nombre TEXT,
    p_lema TEXT DEFAULT NULL,
    p_reglas TEXT DEFAULT NULL,
    p_logo_url TEXT DEFAULT NULL
) RETURNS JSON AS $$
DECLARE
    v_auth_uid UUID;
    v_usuario_id UUID;
    v_admin_creador_id UUID;
    v_rol_caller rol_en_grupo;
    v_nombre_limpio TEXT;
    v_error_hint TEXT;
    v_grupo_actualizado RECORD;
BEGIN
    -- =============================================
    -- Verificar autenticacion
    -- =============================================
    v_auth_uid := auth.uid();
    IF v_auth_uid IS NULL THEN
        v_error_hint := 'no_autenticado';
        RAISE EXCEPTION 'Debes iniciar sesion para editar un grupo';
    END IF;

    -- Obtener usuario_id del caller
    SELECT id INTO v_usuario_id
    FROM usuarios
    WHERE auth_user_id = v_auth_uid;

    IF v_usuario_id IS NULL THEN
        v_error_hint := 'usuario_no_encontrado';
        RAISE EXCEPTION 'No se encontro el perfil de usuario';
    END IF;

    -- =============================================
    -- Verificar que el grupo existe y esta activo
    -- =============================================
    SELECT admin_creador_id INTO v_admin_creador_id
    FROM grupos
    WHERE id = p_grupo_id
    AND activo = TRUE;

    IF v_admin_creador_id IS NULL THEN
        v_error_hint := 'grupo_no_encontrado';
        RAISE EXCEPTION 'El grupo no existe o no esta activo';
    END IF;

    -- =============================================
    -- RN-001 / CA-004: Verificar permisos (admin o coadmin)
    -- =============================================
    SELECT rol INTO v_rol_caller
    FROM miembros_grupo
    WHERE grupo_id = p_grupo_id
    AND usuario_id = v_usuario_id
    AND activo = TRUE;

    IF v_rol_caller IS NULL OR v_rol_caller NOT IN ('admin', 'coadmin') THEN
        v_error_hint := 'sin_permisos';
        RAISE EXCEPTION 'Solo el administrador o co-administrador pueden editar el grupo';
    END IF;

    -- =============================================
    -- CA-002 / RN-003: Validar nombre (obligatorio, max 100)
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

    -- =============================================
    -- CA-005 / RN-003: Unicidad de nombre por admin CREADOR
    -- Excluir el grupo actual de la validacion
    -- Comparacion case-insensitive con LOWER()
    -- =============================================
    IF EXISTS (
        SELECT 1 FROM grupos
        WHERE admin_creador_id = v_admin_creador_id
        AND LOWER(nombre) = LOWER(v_nombre_limpio)
        AND id != p_grupo_id
        AND activo = TRUE
    ) THEN
        v_error_hint := 'nombre_duplicado';
        RAISE EXCEPTION 'El administrador creador ya tiene otro grupo con ese nombre';
    END IF;

    -- =============================================
    -- RN-003: Validar lema (max 100 caracteres)
    -- =============================================
    IF p_lema IS NOT NULL AND LENGTH(TRIM(p_lema)) > 100 THEN
        v_error_hint := 'lema_muy_largo';
        RAISE EXCEPTION 'El lema no puede exceder 100 caracteres';
    END IF;

    -- =============================================
    -- Actualizar grupo
    -- =============================================
    UPDATE grupos
    SET
        nombre = v_nombre_limpio,
        logo_url = CASE
            WHEN p_logo_url IS NOT NULL AND TRIM(p_logo_url) != ''
            THEN TRIM(p_logo_url)
            ELSE logo_url
        END,
        lema = CASE
            WHEN p_lema IS NOT NULL AND TRIM(p_lema) != ''
            THEN TRIM(p_lema)
            WHEN p_lema IS NOT NULL AND TRIM(p_lema) = ''
            THEN NULL
            ELSE lema
        END,
        reglas = CASE
            WHEN p_reglas IS NOT NULL AND TRIM(p_reglas) != ''
            THEN TRIM(p_reglas)
            WHEN p_reglas IS NOT NULL AND TRIM(p_reglas) = ''
            THEN NULL
            ELSE reglas
        END,
        updated_at = NOW()
    WHERE id = p_grupo_id
    RETURNING id, nombre, logo_url, lema, reglas
    INTO v_grupo_actualizado;

    -- =============================================
    -- Retornar resultado exitoso
    -- =============================================
    RETURN json_build_object(
        'success', TRUE,
        'message', 'Grupo actualizado exitosamente',
        'data', json_build_object(
            'grupo_id', v_grupo_actualizado.id,
            'nombre', v_grupo_actualizado.nombre,
            'logo_url', v_grupo_actualizado.logo_url,
            'lema', v_grupo_actualizado.lema,
            'reglas', v_grupo_actualizado.reglas
        )
    );

EXCEPTION
    WHEN unique_violation THEN
        RETURN json_build_object(
            'success', FALSE,
            'error', json_build_object(
                'message', 'El administrador creador ya tiene otro grupo con ese nombre',
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

-- Permisos: solo usuarios autenticados
GRANT EXECUTE ON FUNCTION editar_grupo TO authenticated;
REVOKE EXECUTE ON FUNCTION editar_grupo FROM anon, public;

-- Comentario
COMMENT ON FUNCTION editar_grupo IS 'E002-HU-003: Permite a admin o co-admin editar nombre, logo, lema y reglas de un grupo';

-- ============================================
-- VERIFICACION: Ejecutar despues del script principal
-- para confirmar que la funcion se creo correctamente
-- ============================================
SELECT
    p.proname AS funcion,
    pg_get_function_arguments(p.oid) AS parametros,
    pg_get_function_result(p.oid) AS retorno
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
AND p.proname = 'editar_grupo';
