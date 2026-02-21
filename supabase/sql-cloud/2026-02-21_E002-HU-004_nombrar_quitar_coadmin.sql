-- ============================================================
-- E002-HU-004: Nombrar y Quitar Co-Administradores
-- CA-001: Promover jugador a co-admin
-- CA-002: Degradar co-admin a jugador
-- CA-003: Solo admin creador puede gestionar co-admins (RN-001)
-- CA-004: Limite de co-admins segun plan (RN-002)
-- CA-005: Permisos del co-admin (RN-004)
-- RN-003: Solo jugadores activos pueden ser promovidos
-- RN-005: Degradacion conserva membresia
-- RN-006: Confirmacion obligatoria (se maneja en frontend)
-- ============================================================

-- ============================================================
-- FUNCION 1: promover_a_coadmin
-- Promueve un jugador activo a co-admin
-- Solo el admin creador del grupo puede ejecutar
-- Valida limite de co-admins segun plan
-- ============================================================
CREATE OR REPLACE FUNCTION public.promover_a_coadmin(
  p_grupo_id UUID,
  p_miembro_id UUID
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_auth_uid UUID := auth.uid();
  v_usuario_id UUID;
  v_admin_creador_id UUID;
  v_miembro RECORD;
  v_max_coadmins INT;
  v_coadmins_actuales INT;
  v_plan_nombre TEXT;
BEGIN
  -- 1. Obtener usuario_id del solicitante
  SELECT id INTO v_usuario_id
  FROM public.usuarios
  WHERE auth_user_id = v_auth_uid;

  IF v_usuario_id IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'USER_NOT_FOUND',
        'message', 'Usuario no encontrado',
        'hint', 'El usuario actual no existe en la base de datos'
      )
    );
  END IF;

  -- 2. RN-001: Verificar que el solicitante es el admin creador del grupo
  SELECT admin_creador_id INTO v_admin_creador_id
  FROM public.grupos
  WHERE id = p_grupo_id AND activo = true;

  IF v_admin_creador_id IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'GROUP_NOT_FOUND',
        'message', 'Grupo no encontrado o inactivo',
        'hint', 'El grupo no existe o esta desactivado'
      )
    );
  END IF;

  IF v_usuario_id != v_admin_creador_id THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'NOT_ADMIN_CREATOR',
        'message', 'Solo el administrador creador puede gestionar co-administradores',
        'hint', 'Esta accion es exclusiva del admin creador del grupo'
      )
    );
  END IF;

  -- 3. Obtener datos del miembro a promover
  SELECT mg.id, mg.usuario_id, mg.rol, mg.activo, u.estado, u.nombre_completo
  INTO v_miembro
  FROM public.miembros_grupo mg
  JOIN public.usuarios u ON u.id = mg.usuario_id
  WHERE mg.id = p_miembro_id AND mg.grupo_id = p_grupo_id;

  IF v_miembro IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'MEMBER_NOT_FOUND',
        'message', 'Miembro no encontrado en este grupo',
        'hint', 'El miembro especificado no pertenece a este grupo'
      )
    );
  END IF;

  -- RN-003: Solo jugadores activos pueden ser promovidos
  IF v_miembro.rol != 'jugador' THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'INVALID_ROLE',
        'message', 'Solo se puede promover a jugadores',
        'hint', 'El miembro tiene rol: ' || v_miembro.rol
      )
    );
  END IF;

  IF v_miembro.activo = false THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'MEMBER_INACTIVE',
        'message', 'El miembro esta inactivo en el grupo',
        'hint', 'Solo se pueden promover miembros activos'
      )
    );
  END IF;

  -- 4. RN-002 / CA-004: Verificar limite de co-admins segun plan
  SELECT p.max_coadmins_por_grupo, p.nombre
  INTO v_max_coadmins, v_plan_nombre
  FROM public.grupos g
  JOIN public.planes p ON p.id = g.plan_id
  WHERE g.id = p_grupo_id;

  SELECT COUNT(*) INTO v_coadmins_actuales
  FROM public.miembros_grupo
  WHERE grupo_id = p_grupo_id
    AND rol = 'coadmin'
    AND activo = true;

  IF v_coadmins_actuales >= v_max_coadmins THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'COADMIN_LIMIT_REACHED',
        'message', 'Se alcanzo el limite de co-administradores para este grupo (' || v_max_coadmins || ' max en plan ' || v_plan_nombre || ')',
        'hint', 'Limite: ' || v_max_coadmins || ' co-admins en plan ' || v_plan_nombre
      )
    );
  END IF;

  -- 5. CA-001: Promover a co-admin
  UPDATE public.miembros_grupo
  SET rol = 'coadmin',
      updated_at = now()
  WHERE id = p_miembro_id AND grupo_id = p_grupo_id;

  RETURN jsonb_build_object(
    'success', true,
    'data', jsonb_build_object(
      'miembro_id', p_miembro_id,
      'nombre', v_miembro.nombre_completo,
      'nuevo_rol', 'coadmin',
      'coadmins_actuales', v_coadmins_actuales + 1,
      'max_coadmins', v_max_coadmins
    ),
    'message', 'Jugador promovido a co-administrador exitosamente'
  );
END;
$$;

-- ============================================================
-- FUNCION 2: degradar_coadmin
-- Degrada un co-admin a jugador regular
-- Solo el admin creador del grupo puede ejecutar
-- RN-005: Conserva membresia y historial
-- ============================================================
CREATE OR REPLACE FUNCTION public.degradar_coadmin(
  p_grupo_id UUID,
  p_miembro_id UUID
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_auth_uid UUID := auth.uid();
  v_usuario_id UUID;
  v_admin_creador_id UUID;
  v_miembro RECORD;
BEGIN
  -- 1. Obtener usuario_id del solicitante
  SELECT id INTO v_usuario_id
  FROM public.usuarios
  WHERE auth_user_id = v_auth_uid;

  IF v_usuario_id IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'USER_NOT_FOUND',
        'message', 'Usuario no encontrado',
        'hint', 'El usuario actual no existe en la base de datos'
      )
    );
  END IF;

  -- 2. RN-001: Verificar que el solicitante es el admin creador del grupo
  SELECT admin_creador_id INTO v_admin_creador_id
  FROM public.grupos
  WHERE id = p_grupo_id AND activo = true;

  IF v_admin_creador_id IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'GROUP_NOT_FOUND',
        'message', 'Grupo no encontrado o inactivo',
        'hint', 'El grupo no existe o esta desactivado'
      )
    );
  END IF;

  IF v_usuario_id != v_admin_creador_id THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'NOT_ADMIN_CREATOR',
        'message', 'Solo el administrador creador puede gestionar co-administradores',
        'hint', 'Esta accion es exclusiva del admin creador del grupo'
      )
    );
  END IF;

  -- 3. Obtener datos del miembro a degradar
  SELECT mg.id, mg.usuario_id, mg.rol, mg.activo, u.nombre_completo
  INTO v_miembro
  FROM public.miembros_grupo mg
  JOIN public.usuarios u ON u.id = mg.usuario_id
  WHERE mg.id = p_miembro_id AND mg.grupo_id = p_grupo_id;

  IF v_miembro IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'MEMBER_NOT_FOUND',
        'message', 'Miembro no encontrado en este grupo',
        'hint', 'El miembro especificado no pertenece a este grupo'
      )
    );
  END IF;

  -- Verificar que es co-admin
  IF v_miembro.rol != 'coadmin' THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'INVALID_ROLE',
        'message', 'Solo se puede degradar a co-administradores',
        'hint', 'El miembro tiene rol: ' || v_miembro.rol
      )
    );
  END IF;

  -- 4. CA-002 / RN-005: Degradar a jugador (conserva membresia)
  UPDATE public.miembros_grupo
  SET rol = 'jugador',
      updated_at = now()
  WHERE id = p_miembro_id AND grupo_id = p_grupo_id;

  RETURN jsonb_build_object(
    'success', true,
    'data', jsonb_build_object(
      'miembro_id', p_miembro_id,
      'nombre', v_miembro.nombre_completo,
      'nuevo_rol', 'jugador'
    ),
    'message', 'Co-administrador degradado a jugador exitosamente'
  );
END;
$$;

-- Permisos para usuarios autenticados
GRANT EXECUTE ON FUNCTION public.promover_a_coadmin(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.degradar_coadmin(UUID, UUID) TO authenticated;
