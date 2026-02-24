-- ============================================================
-- E002-HU-009: Promover Invitado a Jugador
-- Fecha: 2026-02-21
-- Descripcion: RPC para promover un invitado registrado en el
--   grupo a jugador completo. Le asigna un celular, cambia su
--   rol de invitado a jugador en miembros_grupo, y actualiza
--   su email al formato estandar (celular@gestiondeportiva.app).
--   El historial se conserva automaticamente porque el usuario_id
--   no cambia.
--
-- Reglas de Negocio implementadas:
--   RN-001: Promocion manual, decision del admin
--   RN-002: Solo el admin creador puede promover (CA-008)
--   RN-003: Celular unico en el sistema (CA-003)
--   RN-004: Conservacion total del historial (CA-004)
--   RN-005: Inclusion retroactiva en rankings (CA-005)
--   RN-006: Validacion de limite de jugadores al promover (CA-007)
--   RN-007: Liberacion del cupo de invitado (CA-010)
--
-- Criterios de Aceptacion cubiertos:
--   CA-001: Promover invitado agregando celular
--   CA-002: Validar formato de celular
--   CA-003: Celular ya existe en el sistema
--   CA-004: Historial se conserva intacto (mismo usuario_id)
--   CA-005: Historial aparece en rankings (automatico)
--   CA-006: Jugador promovido puede activar su cuenta (estado pendiente_aprobacion)
--   CA-007: Limite de jugadores se valida al promover
--   CA-008: Solo el admin creador puede promover
--   CA-009: Confirmacion antes de promover (frontend)
--   CA-010: Cupo de invitado se libera (cambia rol a jugador)
-- ============================================================

-- ============================================================
-- FUNCION: promover_invitado_a_jugador
-- Promueve un invitado activo a jugador en el grupo.
-- Solo el admin creador del grupo puede ejecutar (RN-002).
-- Asigna celular, cambia email y estado, cambia rol en grupo.
-- El historial se conserva porque el usuario_id no cambia (RN-004).
-- ============================================================
CREATE OR REPLACE FUNCTION public.promover_invitado_a_jugador(
  p_grupo_id UUID,
  p_miembro_id UUID,
  p_celular TEXT
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_auth_uid UUID := auth.uid();
  v_caller_usuario_id UUID;
  v_admin_creador_id UUID;
  v_miembro RECORD;
  v_celular_limpio VARCHAR(9);
  v_max_jugadores INT;
  v_jugadores_actuales INT;
  v_plan_nombre TEXT;
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
  -- Obtener admin_creador_id para validacion RN-002
  -- ==========================================================
  SELECT g.admin_creador_id INTO v_admin_creador_id
  FROM public.grupos g
  WHERE g.id = p_grupo_id AND g.activo = true;

  IF v_admin_creador_id IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'GROUP_NOT_FOUND',
        'message', 'El grupo no existe o no esta activo',
        'hint', 'No se encontro el grupo especificado o esta desactivado'
      )
    );
  END IF;

  -- ==========================================================
  -- Paso 4: RN-002 / CA-008: Solo el admin creador puede promover
  -- Co-admins NO pueden promover invitados
  -- ==========================================================
  IF v_caller_usuario_id != v_admin_creador_id THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'NOT_ADMIN_CREATOR',
        'message', 'Solo el administrador creador del grupo puede promover invitados',
        'hint', 'Esta accion es exclusiva del admin creador del grupo'
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
        'message', 'El miembro no esta activo en el grupo',
        'hint', 'Solo se pueden promover miembros activos'
      )
    );
  END IF;

  -- Verificar que el miembro tiene rol invitado
  IF v_miembro.rol != 'invitado' THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'NOT_INVITADO',
        'message', 'Este miembro no es un invitado',
        'hint', 'Solo se pueden promover miembros con rol invitado. El miembro tiene rol: ' || v_miembro.rol
      )
    );
  END IF;

  -- ==========================================================
  -- Paso 6: Validar celular no vacio
  -- ==========================================================
  IF p_celular IS NULL OR BTRIM(p_celular) = '' THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'CELULAR_REQUERIDO',
        'message', 'El numero de celular es obligatorio para promover un invitado',
        'hint', 'Debes ingresar el numero de celular del invitado'
      )
    );
  END IF;

  -- Limpiar celular (solo digitos)
  v_celular_limpio := REGEXP_REPLACE(BTRIM(p_celular), '[^0-9]', '', 'g');

  -- ==========================================================
  -- Paso 7: Validar formato celular Peru (9 digitos, inicia con 9)
  -- ==========================================================
  IF LENGTH(v_celular_limpio) != 9 THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'CELULAR_FORMATO_INVALIDO',
        'message', 'El celular debe tener exactamente 9 digitos',
        'hint', 'Formato Peru: 9 digitos, debe iniciar con 9 (ej: 987654321)'
      )
    );
  END IF;

  IF LEFT(v_celular_limpio, 1) != '9' THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'CELULAR_FORMATO_INVALIDO',
        'message', 'El celular debe iniciar con el digito 9',
        'hint', 'Formato Peru: 9 digitos, debe iniciar con 9 (ej: 987654321)'
      )
    );
  END IF;

  -- ==========================================================
  -- Paso 8: RN-003 / CA-003: Verificar celular unico en el sistema
  -- ==========================================================
  IF EXISTS (SELECT 1 FROM public.usuarios WHERE celular = v_celular_limpio) THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'CELULAR_YA_EXISTE',
        'message', 'Este numero de celular ya esta registrado en el sistema',
        'hint', 'El celular ' || v_celular_limpio || ' ya pertenece a otro usuario. Puedes invitar a ese usuario al grupo en lugar de promover al invitado.'
      )
    );
  END IF;

  -- ==========================================================
  -- Paso 9: RN-006 / CA-007: Verificar limite de jugadores del grupo
  -- Jugadores = miembros con rol admin, coadmin o jugador activos
  -- El invitado promovido contara como jugador
  -- ==========================================================
  SELECT p.max_jugadores_por_grupo, p.nombre
  INTO v_max_jugadores, v_plan_nombre
  FROM public.grupos g
  JOIN public.planes p ON p.id = g.plan_id
  WHERE g.id = p_grupo_id;

  SELECT COUNT(*) INTO v_jugadores_actuales
  FROM public.miembros_grupo
  WHERE grupo_id = p_grupo_id
    AND rol IN ('admin', 'coadmin', 'jugador')
    AND activo = true;

  IF v_jugadores_actuales >= v_max_jugadores THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'JUGADOR_LIMIT_REACHED',
        'message', 'Se alcanzo el limite de jugadores para este grupo ('
          || v_max_jugadores || ' max en plan ' || v_plan_nombre || ')',
        'hint', 'Limite: ' || v_max_jugadores || ' jugadores en plan '
          || v_plan_nombre || '. Elimina un jugador o mejora tu plan para liberar cupo.'
      )
    );
  END IF;

  -- ==========================================================
  -- Paso 10: Actualizar registro en usuarios
  -- - Asignar celular
  -- - Cambiar email ficticio al formato estandar (celular@gestiondeportiva.app)
  -- - Estado a pendiente_aprobacion (para que active su cuenta via E001-HU-005)
  -- - auth_user_id sigue NULL (se crea cuando el jugador activa su cuenta)
  -- ==========================================================
  UPDATE public.usuarios
  SET celular = v_celular_limpio,
      email = v_celular_limpio || '@gestiondeportiva.app',
      estado = 'pendiente_aprobacion',
      updated_at = now()
  WHERE id = v_miembro.usuario_id;

  -- ==========================================================
  -- Paso 11: Actualizar rol en miembros_grupo
  -- De invitado a jugador (RN-007: libera cupo de invitado)
  -- ==========================================================
  UPDATE public.miembros_grupo
  SET rol = 'jugador',
      updated_at = now()
  WHERE id = p_miembro_id
    AND grupo_id = p_grupo_id;

  -- ==========================================================
  -- Retorno exitoso
  -- CA-004/RN-004: El historial se conserva porque usuario_id no cambia
  -- CA-005/RN-005: Rankings incluiran automaticamente al jugador promovido
  -- CA-010/RN-007: Cupo de invitado liberado (rol cambio a jugador)
  -- ==========================================================
  RETURN jsonb_build_object(
    'success', true,
    'data', jsonb_build_object(
      'miembro_id', p_miembro_id,
      'usuario_id', v_miembro.usuario_id,
      'nombre', v_miembro.nombre_completo,
      'celular', v_celular_limpio,
      'nuevo_rol', 'jugador',
      'estado', 'pendiente_aprobacion',
      'jugadores_actuales', v_jugadores_actuales + 1,
      'max_jugadores', v_max_jugadores
    ),
    'message', 'Invitado promovido a jugador exitosamente. Ya puede activar su cuenta.'
  );
END;
$$;

-- Permisos para usuarios autenticados
GRANT EXECUTE ON FUNCTION public.promover_invitado_a_jugador(UUID, UUID, TEXT) TO authenticated;

-- Comentario
COMMENT ON FUNCTION public.promover_invitado_a_jugador IS 'E002-HU-009: Promueve un invitado a jugador asignandole un celular. Solo admin creador. Conserva historial.';
