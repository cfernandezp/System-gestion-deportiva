-- ============================================================
-- E002-HU-008: Registrar Invitado en el Grupo
-- Fecha: 2026-02-21
-- Descripcion: RPCs para registrar y eliminar invitados de un
--   grupo deportivo. Un invitado es un registro ligero (solo
--   nombre) sin cuenta de usuario real, que puede participar
--   en pichangas, goles y pagos.
--
-- Reglas de Negocio implementadas:
--   RN-001: Registro ligero sin cuenta (solo nombre)
--   RN-002: Limite de invitados segun plan del grupo
--   RN-003: Invitado pertenece a un solo grupo (registro local)
--   RN-006: Conservacion de historial (soft delete)
--   RN-007: Solo admin y coadmin gestionan invitados
--
-- Criterios de Aceptacion cubiertos:
--   CA-001: Registrar invitado con nombre
--   CA-002: Limite de invitados por grupo
--   CA-003: Nombre obligatorio
--   CA-010: Eliminar invitado del grupo (soft delete)
-- ============================================================

-- ============================================================
-- FUNCION 1: registrar_invitado
-- Registra un invitado ligero en el grupo.
-- Crea un registro minimo en usuarios (sin auth) y lo inserta
-- en miembros_grupo con rol='invitado'.
-- Solo admin o coadmin pueden ejecutar (RN-007).
-- Valida limite de invitados segun plan (RN-002).
-- ============================================================
CREATE OR REPLACE FUNCTION public.registrar_invitado(
  p_grupo_id UUID,
  p_nombre TEXT
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_auth_uid UUID := auth.uid();
  v_caller_usuario_id UUID;
  v_caller_rol rol_en_grupo;
  v_grupo_activo BOOLEAN;
  v_plan_nombre TEXT;
  v_max_invitados INT;
  v_invitados_actuales INT;
  v_nombre_limpio TEXT;
  v_nombre_existe BOOLEAN;
  v_nuevo_usuario_id UUID;
  v_nuevo_miembro_id UUID;
  v_email_ficticio TEXT;
BEGIN
  -- ==========================================================
  -- Paso 1: Verificar autenticacion
  -- ==========================================================
  IF v_auth_uid IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'NO_AUTH',
        'message', 'Debes iniciar sesion para realizar esta accion',
        'hint', 'Usuario no autenticado'
      )
    );
  END IF;

  -- ==========================================================
  -- Paso 2: Obtener usuario_id del caller
  -- ==========================================================
  SELECT id INTO v_caller_usuario_id
  FROM public.usuarios
  WHERE auth_user_id = v_auth_uid;

  IF v_caller_usuario_id IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'USER_NOT_FOUND',
        'message', 'No se encontro el perfil de usuario',
        'hint', 'El usuario actual no existe en la base de datos'
      )
    );
  END IF;

  -- ==========================================================
  -- Paso 3: Verificar que el grupo existe y esta activo
  -- ==========================================================
  SELECT g.activo INTO v_grupo_activo
  FROM public.grupos g
  WHERE g.id = p_grupo_id;

  IF v_grupo_activo IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'GROUP_NOT_FOUND',
        'message', 'El grupo no existe',
        'hint', 'No se encontro el grupo especificado'
      )
    );
  END IF;

  IF v_grupo_activo = false THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'GROUP_NOT_FOUND',
        'message', 'El grupo no esta activo',
        'hint', 'El grupo esta desactivado'
      )
    );
  END IF;

  -- ==========================================================
  -- Paso 4: Verificar que el caller es admin o coadmin (RN-007)
  -- ==========================================================
  SELECT mg.rol INTO v_caller_rol
  FROM public.miembros_grupo mg
  WHERE mg.grupo_id = p_grupo_id
    AND mg.usuario_id = v_caller_usuario_id
    AND mg.activo = true;

  IF v_caller_rol IS NULL OR v_caller_rol NOT IN ('admin', 'coadmin') THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'NOT_ADMIN_OR_COADMIN',
        'message', 'Solo el admin o co-admin pueden registrar invitados',
        'hint', 'No tienes permisos para gestionar invitados en este grupo'
      )
    );
  END IF;

  -- ==========================================================
  -- Paso 5: Validar nombre no vacio (CA-003)
  -- ==========================================================
  v_nombre_limpio := BTRIM(COALESCE(p_nombre, ''));

  IF v_nombre_limpio = '' THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'NOMBRE_REQUERIDO',
        'message', 'El nombre del invitado es obligatorio',
        'hint', 'Debes ingresar un nombre para el invitado'
      )
    );
  END IF;

  -- ==========================================================
  -- Paso 6: Verificar nombre unico entre invitados activos
  -- del mismo grupo (RN-001: caso especial)
  -- ==========================================================
  SELECT EXISTS(
    SELECT 1
    FROM public.miembros_grupo mg
    JOIN public.usuarios u ON u.id = mg.usuario_id
    WHERE mg.grupo_id = p_grupo_id
      AND mg.rol = 'invitado'
      AND mg.activo = true
      AND LOWER(BTRIM(u.nombre_completo)) = LOWER(v_nombre_limpio)
  ) INTO v_nombre_existe;

  IF v_nombre_existe THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'NOMBRE_DUPLICADO',
        'message', 'Ya existe un invitado activo con el nombre "' || v_nombre_limpio || '" en este grupo',
        'hint', 'Usa un nombre diferente o un apodo para distinguirlo'
      )
    );
  END IF;

  -- ==========================================================
  -- Paso 7: Verificar limite de invitados segun plan (CA-002/RN-002)
  -- ==========================================================
  SELECT p.max_invitados_por_grupo, p.nombre
  INTO v_max_invitados, v_plan_nombre
  FROM public.grupos g
  JOIN public.planes p ON p.id = g.plan_id
  WHERE g.id = p_grupo_id;

  SELECT COUNT(*) INTO v_invitados_actuales
  FROM public.miembros_grupo
  WHERE grupo_id = p_grupo_id
    AND rol = 'invitado'
    AND activo = true;

  IF v_invitados_actuales >= v_max_invitados THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'INVITADO_LIMIT_REACHED',
        'message', 'Se alcanzo el limite de invitados para este grupo ('
          || v_max_invitados || ' max en plan ' || v_plan_nombre || ')',
        'hint', 'Limite: ' || v_max_invitados || ' invitados en plan '
          || v_plan_nombre || '. Puedes promover un invitado a jugador o eliminar uno para liberar cupo.'
      )
    );
  END IF;

  -- ==========================================================
  -- Paso 8: Crear registro ligero en usuarios (RN-001)
  -- El invitado NO tiene auth, celular ni credenciales.
  -- Se genera un email ficticio para satisfacer el NOT NULL.
  -- ==========================================================
  v_nuevo_usuario_id := gen_random_uuid();
  v_email_ficticio := 'invitado_' || v_nuevo_usuario_id || '@invitado.local';

  INSERT INTO public.usuarios (
    id,
    auth_user_id,
    nombre_completo,
    email,
    estado,
    rol,
    celular
  ) VALUES (
    v_nuevo_usuario_id,
    NULL,               -- sin auth (no tiene cuenta)
    v_nombre_limpio,
    v_email_ficticio,   -- email ficticio para NOT NULL
    'aprobado',         -- puede participar inmediatamente
    'jugador',          -- rol general en el sistema
    NULL                -- sin celular
  );

  -- ==========================================================
  -- Paso 9: Insertar en miembros_grupo con rol='invitado'
  -- ==========================================================
  INSERT INTO public.miembros_grupo (
    grupo_id,
    usuario_id,
    rol,
    activo
  ) VALUES (
    p_grupo_id,
    v_nuevo_usuario_id,
    'invitado',
    true
  )
  RETURNING id INTO v_nuevo_miembro_id;

  -- ==========================================================
  -- Retorno exitoso
  -- ==========================================================
  RETURN jsonb_build_object(
    'success', true,
    'data', jsonb_build_object(
      'miembro_id', v_nuevo_miembro_id,
      'usuario_id', v_nuevo_usuario_id,
      'nombre', v_nombre_limpio,
      'rol', 'invitado',
      'invitados_actuales', v_invitados_actuales + 1,
      'max_invitados', v_max_invitados
    ),
    'message', 'Invitado registrado exitosamente'
  );
END;
$$;

-- ============================================================
-- FUNCION 2: eliminar_invitado
-- Elimina (soft delete) un invitado del grupo.
-- Solo admin o coadmin pueden ejecutar (RN-007).
-- RN-006: Conserva historial (soft delete: activo=false).
-- ============================================================
CREATE OR REPLACE FUNCTION public.eliminar_invitado(
  p_grupo_id UUID,
  p_miembro_id UUID
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_auth_uid UUID := auth.uid();
  v_caller_usuario_id UUID;
  v_caller_rol rol_en_grupo;
  v_grupo_activo BOOLEAN;
  v_miembro RECORD;
BEGIN
  -- ==========================================================
  -- Paso 1: Verificar autenticacion
  -- ==========================================================
  IF v_auth_uid IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'NO_AUTH',
        'message', 'Debes iniciar sesion para realizar esta accion',
        'hint', 'Usuario no autenticado'
      )
    );
  END IF;

  -- ==========================================================
  -- Paso 2: Obtener usuario_id del caller
  -- ==========================================================
  SELECT id INTO v_caller_usuario_id
  FROM public.usuarios
  WHERE auth_user_id = v_auth_uid;

  IF v_caller_usuario_id IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'USER_NOT_FOUND',
        'message', 'No se encontro el perfil de usuario',
        'hint', 'El usuario actual no existe en la base de datos'
      )
    );
  END IF;

  -- ==========================================================
  -- Paso 3: Verificar que el grupo existe y esta activo
  -- ==========================================================
  SELECT g.activo INTO v_grupo_activo
  FROM public.grupos g
  WHERE g.id = p_grupo_id;

  IF v_grupo_activo IS NULL OR v_grupo_activo = false THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'GROUP_NOT_FOUND',
        'message', 'El grupo no existe o no esta activo',
        'hint', 'El grupo especificado no se encontro o esta desactivado'
      )
    );
  END IF;

  -- ==========================================================
  -- Paso 4: Verificar que el caller es admin o coadmin (RN-007)
  -- ==========================================================
  SELECT mg.rol INTO v_caller_rol
  FROM public.miembros_grupo mg
  WHERE mg.grupo_id = p_grupo_id
    AND mg.usuario_id = v_caller_usuario_id
    AND mg.activo = true;

  IF v_caller_rol IS NULL OR v_caller_rol NOT IN ('admin', 'coadmin') THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'NOT_ADMIN_OR_COADMIN',
        'message', 'Solo el admin o co-admin pueden eliminar invitados',
        'hint', 'No tienes permisos para gestionar invitados en este grupo'
      )
    );
  END IF;

  -- ==========================================================
  -- Paso 5: Obtener datos del miembro target
  -- ==========================================================
  SELECT mg.id, mg.usuario_id, mg.rol, mg.activo, u.nombre_completo
  INTO v_miembro
  FROM public.miembros_grupo mg
  JOIN public.usuarios u ON u.id = mg.usuario_id
  WHERE mg.id = p_miembro_id
    AND mg.grupo_id = p_grupo_id;

  IF v_miembro IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'MEMBER_NOT_FOUND',
        'message', 'El miembro no fue encontrado en este grupo',
        'hint', 'El miembro especificado no existe o no pertenece a este grupo'
      )
    );
  END IF;

  -- Verificar que el miembro esta activo
  IF v_miembro.activo = false THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'MEMBER_NOT_FOUND',
        'message', 'El invitado ya fue eliminado del grupo',
        'hint', 'Este miembro ya esta inactivo'
      )
    );
  END IF;

  -- ==========================================================
  -- Paso 6: Verificar que el miembro es invitado
  -- ==========================================================
  IF v_miembro.rol != 'invitado' THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'NOT_INVITADO',
        'message', 'Este miembro no es un invitado',
        'hint', 'Solo se pueden eliminar miembros con rol invitado desde esta funcion. El miembro tiene rol: ' || v_miembro.rol
      )
    );
  END IF;

  -- ==========================================================
  -- Paso 7: Soft delete (RN-006: conservar historial)
  -- ==========================================================
  UPDATE public.miembros_grupo
  SET activo = false,
      updated_at = now()
  WHERE id = p_miembro_id;

  -- ==========================================================
  -- Retorno exitoso
  -- ==========================================================
  RETURN jsonb_build_object(
    'success', true,
    'data', jsonb_build_object(
      'miembro_id', p_miembro_id,
      'nombre', v_miembro.nombre_completo,
      'grupo_id', p_grupo_id
    ),
    'message', 'Invitado eliminado del grupo exitosamente'
  );
END;
$$;

-- Permisos para usuarios autenticados
GRANT EXECUTE ON FUNCTION public.registrar_invitado(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.eliminar_invitado(UUID, UUID) TO authenticated;

-- Comentarios
COMMENT ON FUNCTION public.registrar_invitado IS 'E002-HU-008: Registra un invitado ligero (solo nombre) en un grupo deportivo. Solo admin/coadmin.';
COMMENT ON FUNCTION public.eliminar_invitado IS 'E002-HU-008: Elimina (soft delete) un invitado de un grupo deportivo. Solo admin/coadmin.';
