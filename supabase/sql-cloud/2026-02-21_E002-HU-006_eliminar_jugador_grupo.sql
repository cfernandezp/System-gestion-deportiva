-- ============================================
-- E002-HU-006: Eliminar Jugador del Grupo
-- Fecha: 2026-02-21
-- Descripcion: RPC para que un admin o coadmin elimine (desactive)
--   a un miembro de su grupo deportivo.
--
-- Reglas de Negocio:
--   RN-001: Solo admin y coadmin pueden eliminar.
--           Admin puede eliminar jugadores Y coadmins.
--           Coadmin SOLO puede eliminar jugadores e invitados.
--   RN-002: El admin creador del grupo NO puede ser eliminado.
--   RN-003: Un coadmin NO puede eliminar a otro coadmin ni al admin.
--   RN-004: El admin puede eliminar a cualquier miembro excepto a si mismo.
--   RN-005: La eliminacion es soft delete (activo = FALSE).
--           La cuenta del usuario NO se toca.
--   RN-007: No hay notificacion automatica.
-- ============================================

CREATE OR REPLACE FUNCTION eliminar_jugador_grupo(
    p_grupo_id UUID,
    p_miembro_id UUID  -- ID del registro en miembros_grupo a desactivar
) RETURNS JSON AS $$
DECLARE
    v_auth_uid UUID;
    v_caller_usuario_id UUID;
    v_caller_rol rol_en_grupo;
    v_target_usuario_id UUID;
    v_target_rol rol_en_grupo;
    v_target_nombre TEXT;
    v_admin_creador_id UUID;
    v_grupo_nombre TEXT;
    v_error_hint TEXT;
BEGIN
    -- =============================================
    -- Paso 1: Verificar autenticacion
    -- =============================================
    v_auth_uid := auth.uid();
    IF v_auth_uid IS NULL THEN
        v_error_hint := 'no_autenticado';
        RAISE EXCEPTION 'Debes iniciar sesion para realizar esta accion';
    END IF;

    -- =============================================
    -- Paso 2: Obtener usuario_id del caller
    -- =============================================
    SELECT id INTO v_caller_usuario_id
    FROM usuarios
    WHERE auth_user_id = v_auth_uid;

    IF v_caller_usuario_id IS NULL THEN
        v_error_hint := 'usuario_no_encontrado';
        RAISE EXCEPTION 'No se encontro el perfil de usuario';
    END IF;

    -- =============================================
    -- Paso 3: Verificar que el grupo existe y obtener admin_creador_id
    -- =============================================
    SELECT g.admin_creador_id, g.nombre
    INTO v_admin_creador_id, v_grupo_nombre
    FROM grupos g
    WHERE g.id = p_grupo_id
    AND g.activo = TRUE;

    IF v_admin_creador_id IS NULL THEN
        v_error_hint := 'grupo_no_encontrado';
        RAISE EXCEPTION 'El grupo no existe o no esta activo';
    END IF;

    -- =============================================
    -- Paso 4: Obtener rol del caller en el grupo (RN-001)
    -- =============================================
    SELECT mg.rol INTO v_caller_rol
    FROM miembros_grupo mg
    WHERE mg.grupo_id = p_grupo_id
    AND mg.usuario_id = v_caller_usuario_id
    AND mg.activo = TRUE;

    IF v_caller_rol IS NULL THEN
        v_error_hint := 'no_es_miembro';
        RAISE EXCEPTION 'No eres miembro activo de este grupo';
    END IF;

    IF v_caller_rol NOT IN ('admin', 'coadmin') THEN
        v_error_hint := 'sin_permisos';
        RAISE EXCEPTION 'Solo el admin o coadmin pueden eliminar miembros del grupo';
    END IF;

    -- =============================================
    -- Paso 5: Obtener datos del miembro target
    -- =============================================
    SELECT mg.usuario_id, mg.rol
    INTO v_target_usuario_id, v_target_rol
    FROM miembros_grupo mg
    WHERE mg.id = p_miembro_id
    AND mg.grupo_id = p_grupo_id
    AND mg.activo = TRUE;

    IF v_target_usuario_id IS NULL THEN
        v_error_hint := 'miembro_no_encontrado';
        RAISE EXCEPTION 'El miembro no existe, no pertenece a este grupo o ya fue eliminado';
    END IF;

    -- Obtener nombre del target para el mensaje de respuesta
    SELECT COALESCE(u.apodo, u.nombre_completo)
    INTO v_target_nombre
    FROM usuarios u
    WHERE u.id = v_target_usuario_id;

    -- =============================================
    -- Paso 6: Validar que no se elimine a si mismo (RN-004)
    -- =============================================
    IF v_target_usuario_id = v_caller_usuario_id THEN
        v_error_hint := 'auto_eliminacion';
        RAISE EXCEPTION 'No puedes eliminarte a ti mismo del grupo';
    END IF;

    -- =============================================
    -- Paso 7: RN-002 - El admin creador NO puede ser eliminado
    -- =============================================
    IF v_target_usuario_id = v_admin_creador_id THEN
        v_error_hint := 'admin_creador_protegido';
        RAISE EXCEPTION 'El administrador creador del grupo no puede ser eliminado';
    END IF;

    -- =============================================
    -- Paso 8: RN-003 - Coadmin solo puede eliminar jugadores e invitados
    -- =============================================
    IF v_caller_rol = 'coadmin' AND v_target_rol NOT IN ('jugador', 'invitado') THEN
        v_error_hint := 'coadmin_sin_permiso';
        RAISE EXCEPTION 'Un co-administrador solo puede eliminar jugadores e invitados';
    END IF;

    -- =============================================
    -- Paso 9: RN-005 - Soft delete: desactivar miembro
    -- =============================================
    UPDATE miembros_grupo
    SET activo = FALSE,
        updated_at = NOW()
    WHERE id = p_miembro_id;

    -- =============================================
    -- Retornar resultado exitoso
    -- =============================================
    RETURN json_build_object(
        'success', TRUE,
        'message', 'Miembro eliminado del grupo exitosamente',
        'data', json_build_object(
            'miembro_id', p_miembro_id,
            'grupo_id', p_grupo_id,
            'grupo_nombre', v_grupo_nombre,
            'usuario_id', v_target_usuario_id,
            'nombre', v_target_nombre,
            'rol_eliminado', v_target_rol,
            'eliminado_por', v_caller_usuario_id,
            'eliminado_por_rol', v_caller_rol
        )
    );

EXCEPTION
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
GRANT EXECUTE ON FUNCTION eliminar_jugador_grupo TO authenticated;

-- Comentario
COMMENT ON FUNCTION eliminar_jugador_grupo IS 'E002-HU-006: Elimina (desactiva) un miembro de un grupo deportivo. Solo admin y coadmin pueden ejecutar.';
