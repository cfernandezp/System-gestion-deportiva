-- ============================================================
-- Gestion Flexible de Equipos y Jugadores durante Pichanga en_juego
-- Fecha: 2026-02-22
-- Descripcion: Permite agregar jugadores tardios, marcar ausentes,
--   y gestionar equipos durante estado en_juego.
--
-- Cambios:
-- 1. Agregar 'ausente' al enum estado_inscripcion
-- 2. Agregar columna inscripcion_tardia a inscripciones
-- 3. Modificar inscribir_jugador_admin para permitir en_juego
-- 4. Crear RPC marcar_ausente
-- 5. Modificar asignar_equipo para permitir en_juego
-- 6. Modificar desasignar_equipo para permitir en_juego
-- 7. Modificar obtener_asignaciones para incluir ausentes
-- 8. Modificar iniciar_partido con validacion EQUIPO_SIN_JUGADORES
-- 9. Modificar iniciar_fecha: quitar validacion obligatoria de equipos
-- 10. Crear RPC registrar_invitado_y_inscribir (combo rapido)
-- ============================================================

-- ============================================================
-- DROP FUNCTIONS: Necesario porque cambiaron de JSON a JSONB
-- PostgreSQL no permite cambiar el tipo de retorno con
-- CREATE OR REPLACE. Se hace DROP IF EXISTS antes de recrear.
-- Solo aplica a funciones que existian con RETURNS JSON
-- y ahora retornan JSONB.
-- ============================================================
DROP FUNCTION IF EXISTS inscribir_jugador_admin(UUID, UUID);
DROP FUNCTION IF EXISTS iniciar_fecha(UUID);
DROP FUNCTION IF EXISTS listar_jugadores_disponibles_inscripcion(UUID);


-- ============================================================
-- 1. Agregar 'ausente' al enum estado_inscripcion
-- ============================================================
DO $$
BEGIN
  -- Verificar si 'ausente' ya existe en el enum
  IF NOT EXISTS (
    SELECT 1
    FROM pg_enum e
    JOIN pg_type t ON e.enumtypid = t.oid
    WHERE t.typname = 'estado_inscripcion'
    AND e.enumlabel = 'ausente'
  ) THEN
    ALTER TYPE estado_inscripcion ADD VALUE 'ausente';
  END IF;
END$$;

-- ============================================================
-- 2. Agregar columna inscripcion_tardia a inscripciones
-- ============================================================
ALTER TABLE inscripciones
  ADD COLUMN IF NOT EXISTS inscripcion_tardia BOOLEAN DEFAULT false;

COMMENT ON COLUMN inscripciones.inscripcion_tardia IS
  'True si el jugador fue inscrito durante estado en_juego (inscripcion tardia por admin/coadmin)';

-- ============================================================
-- 3. Modificar inscribir_jugador_admin para permitir en_juego
-- Ahora acepta estado 'abierta' o 'en_juego' (con flag tardia)
-- ============================================================
CREATE OR REPLACE FUNCTION inscribir_jugador_admin(
  p_fecha_id UUID,
  p_jugador_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_auth_user_id UUID;
  v_admin RECORD;
  v_jugador RECORD;
  v_fecha RECORD;
  v_inscripcion_existente RECORD;
  v_inscripcion_id UUID;
  v_pago_id UUID;
  v_total_inscritos INT;
  v_es_tardia BOOLEAN := false;
  v_grupo_id UUID;
  v_admin_rol_grupo TEXT;
BEGIN
  -- ========================================
  -- Validar autenticacion
  -- ========================================
  v_auth_user_id := auth.uid();
  IF v_auth_user_id IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'AUTH_ERROR',
        'message', 'No autenticado',
        'hint', 'no_autenticado'
      )
    );
  END IF;

  -- ========================================
  -- Obtener admin que ejecuta
  -- ========================================
  SELECT id, rol, estado, nombre_completo
  INTO v_admin
  FROM usuarios
  WHERE auth_user_id = v_auth_user_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'USER_NOT_FOUND',
        'message', 'Usuario no encontrado',
        'hint', 'usuario_no_encontrado'
      )
    );
  END IF;

  -- ========================================
  -- Obtener fecha
  -- ========================================
  SELECT
    f.id,
    f.estado,
    f.costo_por_jugador,
    f.lugar,
    f.limite_jugadores,
    f.created_by,
    TO_CHAR(f.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY HH24:MI') as fecha_formato
  INTO v_fecha
  FROM fechas f
  WHERE f.id = p_fecha_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'NOT_FOUND',
        'message', 'Fecha no encontrada',
        'hint', 'fecha_no_encontrada'
      )
    );
  END IF;

  -- ========================================
  -- Validar permisos: admin global O coadmin del grupo
  -- ========================================
  -- Obtener grupo_id de la fecha via created_by
  SELECT mg.grupo_id, mg.rol::text
  INTO v_grupo_id, v_admin_rol_grupo
  FROM miembros_grupo mg
  JOIN fechas f ON f.created_by = mg.usuario_id AND f.id = p_fecha_id
  WHERE mg.usuario_id = v_admin.id
  AND mg.activo = true
  LIMIT 1;

  -- Si no encontro grupo directamente, buscar si es admin global
  IF v_grupo_id IS NULL THEN
    -- Verificar si es admin global aprobado
    IF NOT (v_admin.rol = 'admin' AND v_admin.estado = 'aprobado') THEN
      RETURN jsonb_build_object(
        'success', false,
        'error', jsonb_build_object(
          'code', 'FORBIDDEN',
          'message', 'No tienes permisos para inscribir jugadores',
          'hint', 'sin_permisos'
        )
      );
    END IF;
  ELSE
    -- Verificar que tiene rol admin o coadmin en el grupo
    IF v_admin_rol_grupo NOT IN ('admin', 'coadmin') THEN
      -- Verificar si es admin global como fallback
      IF NOT (v_admin.rol = 'admin' AND v_admin.estado = 'aprobado') THEN
        RETURN jsonb_build_object(
          'success', false,
          'error', jsonb_build_object(
            'code', 'FORBIDDEN',
            'message', 'No tienes permisos para inscribir jugadores',
            'hint', 'sin_permisos'
          )
        );
      END IF;
    END IF;
  END IF;

  -- ========================================
  -- Validar estado de fecha: abierta O en_juego (para admin/coadmin)
  -- ========================================
  IF v_fecha.estado = 'en_juego' THEN
    v_es_tardia := true;
  ELSIF v_fecha.estado != 'abierta' THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'INVALID_STATE',
        'message', 'Solo se puede inscribir jugadores a fechas abiertas o en juego. Estado actual: ' || v_fecha.estado::text,
        'hint', 'fecha_no_abierta'
      )
    );
  END IF;

  -- ========================================
  -- Validar jugador destino
  -- ========================================
  SELECT id, nombre_completo, apodo, estado
  INTO v_jugador
  FROM usuarios
  WHERE id = p_jugador_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'NOT_FOUND',
        'message', 'Jugador no encontrado',
        'hint', 'jugador_no_encontrado'
      )
    );
  END IF;

  -- Permitir inscribir a jugadores aprobados O invitados (estado pendiente sin auth)
  IF v_jugador.estado != 'aprobado' AND v_jugador.estado != 'pendiente_aprobacion' THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'INVALID_STATE',
        'message', 'El jugador no tiene estado valido para inscripcion',
        'hint', 'jugador_no_aprobado'
      )
    );
  END IF;

  -- No auto-inscripcion
  IF p_jugador_id = v_admin.id THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'FORBIDDEN',
        'message', 'No puedes inscribirte a ti mismo con esta funcion. Usa la inscripcion normal.',
        'hint', 'no_auto_inscripcion'
      )
    );
  END IF;

  -- ========================================
  -- Verificar que no esta ya inscrito (activo)
  -- ========================================
  SELECT id, estado
  INTO v_inscripcion_existente
  FROM inscripciones
  WHERE fecha_id = p_fecha_id
  AND usuario_id = p_jugador_id
  AND estado = 'inscrito';

  IF FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'DUPLICATE',
        'message', 'Este jugador ya esta inscrito a esta fecha',
        'hint', 'ya_inscrito'
      )
    );
  END IF;

  -- ========================================
  -- Validar limite de cupos
  -- ========================================
  SELECT COUNT(*) INTO v_total_inscritos
  FROM inscripciones
  WHERE fecha_id = p_fecha_id
  AND estado = 'inscrito';

  IF v_fecha.limite_jugadores IS NOT NULL AND v_total_inscritos >= v_fecha.limite_jugadores THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'LIMIT_REACHED',
        'message', 'Se alcanzo el limite de cupos (' || v_fecha.limite_jugadores || ' jugadores)',
        'hint', 'limite_cupos'
      )
    );
  END IF;

  -- ========================================
  -- Crear inscripcion
  -- ========================================
  INSERT INTO inscripciones (
    fecha_id, usuario_id, estado, inscrito_por, inscripcion_tardia, created_at, updated_at
  ) VALUES (
    p_fecha_id, p_jugador_id, 'inscrito', v_admin.id, v_es_tardia, NOW(), NOW()
  )
  RETURNING id INTO v_inscripcion_id;

  -- ========================================
  -- Crear pago pendiente
  -- ========================================
  INSERT INTO pagos (
    inscripcion_id, usuario_id, fecha_id, monto, estado, registrado_por, created_at, updated_at
  ) VALUES (
    v_inscripcion_id, p_jugador_id, p_fecha_id, v_fecha.costo_por_jugador, 'pendiente', v_admin.id, NOW(), NOW()
  )
  RETURNING id INTO v_pago_id;

  -- ========================================
  -- Crear notificacion
  -- ========================================
  INSERT INTO notificaciones (
    usuario_id, tipo, titulo, mensaje, metadata, leida, created_at
  ) VALUES (
    p_jugador_id,
    'general',
    CASE WHEN v_es_tardia THEN 'Te agregaron a la pichanga en curso' ELSE 'Te inscribieron a una pichanga' END,
    'Te han inscrito a la pichanga del ' || v_fecha.fecha_formato || ' en ' || v_fecha.lugar,
    jsonb_build_object(
      'fecha_id', p_fecha_id,
      'tipo_evento', CASE WHEN v_es_tardia THEN 'inscripcion_tardia' ELSE 'inscripcion_admin' END,
      'inscrito_por', v_admin.id
    ),
    false,
    NOW()
  );

  -- Contar inscritos actualizados
  SELECT COUNT(*) INTO v_total_inscritos
  FROM inscripciones
  WHERE fecha_id = p_fecha_id
  AND estado = 'inscrito';

  -- ========================================
  -- Retornar exito
  -- ========================================
  RETURN jsonb_build_object(
    'success', true,
    'data', jsonb_build_object(
      'inscripcion_id', v_inscripcion_id,
      'fecha_id', p_fecha_id,
      'jugador_id', p_jugador_id,
      'jugador_nombre', COALESCE(v_jugador.apodo, v_jugador.nombre_completo),
      'fecha_formato', v_fecha.fecha_formato,
      'lugar', v_fecha.lugar,
      'costo_por_jugador', v_fecha.costo_por_jugador,
      'costo_formato', 'S/ ' || TO_CHAR(v_fecha.costo_por_jugador, 'FM999990.00'),
      'pago_id', v_pago_id,
      'estado_inscripcion', 'inscrito',
      'estado_pago', 'pendiente',
      'total_inscritos', v_total_inscritos,
      'inscrito_por_id', v_admin.id,
      'inscrito_por_nombre', v_admin.nombre_completo,
      'inscripcion_tardia', v_es_tardia
    ),
    'message', CASE
      WHEN v_es_tardia THEN 'Jugador ' || COALESCE(v_jugador.apodo, v_jugador.nombre_completo) || ' agregado a la pichanga en curso'
      ELSE 'Jugador ' || COALESCE(v_jugador.apodo, v_jugador.nombre_completo) || ' inscrito exitosamente'
    END
  );

EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'SERVER_ERROR',
        'message', 'Error interno: ' || SQLERRM,
        'hint', 'error_interno'
      )
    );
END;
$$;

GRANT EXECUTE ON FUNCTION inscribir_jugador_admin(UUID, UUID) TO authenticated;
COMMENT ON FUNCTION inscribir_jugador_admin(UUID, UUID) IS
  'Inscribe jugador por admin. Permite estado abierta o en_juego (tardia). V2 con soporte en_juego.';


-- ============================================================
-- 4. Crear RPC marcar_ausente
-- Marca inscripcion como ausente y elimina asignacion de equipo
-- ============================================================
CREATE OR REPLACE FUNCTION marcar_ausente(
  p_fecha_id UUID,
  p_inscripcion_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_auth_user_id UUID;
  v_admin RECORD;
  v_fecha RECORD;
  v_inscripcion RECORD;
  v_jugador_nombre TEXT;
  v_equipo_anterior TEXT;
  v_grupo_id UUID;
  v_admin_rol_grupo TEXT;
BEGIN
  -- ========================================
  -- Validar autenticacion
  -- ========================================
  v_auth_user_id := auth.uid();
  IF v_auth_user_id IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'AUTH_ERROR',
        'message', 'No autenticado',
        'hint', 'no_autenticado'
      )
    );
  END IF;

  -- ========================================
  -- Obtener usuario que ejecuta
  -- ========================================
  SELECT id, rol, estado, nombre_completo
  INTO v_admin
  FROM usuarios
  WHERE auth_user_id = v_auth_user_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'USER_NOT_FOUND',
        'message', 'Usuario no encontrado',
        'hint', 'usuario_no_encontrado'
      )
    );
  END IF;

  -- ========================================
  -- Obtener fecha
  -- ========================================
  SELECT id, estado, created_by
  INTO v_fecha
  FROM fechas
  WHERE id = p_fecha_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'NOT_FOUND',
        'message', 'Fecha no encontrada',
        'hint', 'fecha_no_encontrada'
      )
    );
  END IF;

  -- ========================================
  -- Validar que la fecha esta en_juego
  -- ========================================
  IF v_fecha.estado != 'en_juego' THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'INVALID_STATE',
        'message', 'Solo se puede marcar ausente cuando la pichanga esta en juego. Estado actual: ' || v_fecha.estado::text,
        'hint', 'estado_invalido'
      )
    );
  END IF;

  -- ========================================
  -- Validar permisos: admin global O coadmin del grupo
  -- ========================================
  SELECT mg.grupo_id, mg.rol::text
  INTO v_grupo_id, v_admin_rol_grupo
  FROM miembros_grupo mg
  WHERE mg.usuario_id = v_admin.id
  AND mg.activo = true
  AND mg.rol IN ('admin', 'coadmin')
  LIMIT 1;

  IF v_grupo_id IS NULL AND NOT (v_admin.rol = 'admin' AND v_admin.estado = 'aprobado') THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'FORBIDDEN',
        'message', 'No tienes permisos para marcar ausentes',
        'hint', 'sin_permisos'
      )
    );
  END IF;

  -- ========================================
  -- Obtener inscripcion
  -- ========================================
  SELECT i.id, i.usuario_id, i.estado,
         COALESCE(u.apodo, u.nombre_completo) as nombre_display
  INTO v_inscripcion
  FROM inscripciones i
  JOIN usuarios u ON u.id = i.usuario_id
  WHERE i.id = p_inscripcion_id
  AND i.fecha_id = p_fecha_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'NOT_FOUND',
        'message', 'Inscripcion no encontrada en esta fecha',
        'hint', 'inscripcion_no_encontrada'
      )
    );
  END IF;

  IF v_inscripcion.estado != 'inscrito' THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'INVALID_STATE',
        'message', 'Solo se puede marcar como ausente a jugadores inscritos. Estado actual: ' || v_inscripcion.estado::text,
        'hint', 'inscripcion_estado_invalido'
      )
    );
  END IF;

  v_jugador_nombre := v_inscripcion.nombre_display;

  -- ========================================
  -- Verificar si tiene equipo asignado y guardarlo
  -- ========================================
  SELECT ae.color_equipo::text
  INTO v_equipo_anterior
  FROM asignaciones_equipos ae
  WHERE ae.fecha_id = p_fecha_id
  AND ae.usuario_id = v_inscripcion.usuario_id;

  -- ========================================
  -- Validar que no hay partido en_curso con ese equipo
  -- ========================================
  IF v_equipo_anterior IS NOT NULL THEN
    IF EXISTS (
      SELECT 1 FROM partidos
      WHERE fecha_id = p_fecha_id
      AND estado IN ('en_curso', 'pausado')
      AND (equipo_local::text = v_equipo_anterior OR equipo_visitante::text = v_equipo_anterior)
    ) THEN
      RETURN jsonb_build_object(
        'success', false,
        'error', jsonb_build_object(
          'code', 'PARTIDO_EN_CURSO',
          'message', 'No se puede marcar como ausente mientras su equipo tiene un partido en curso',
          'hint', 'partido_en_curso_equipo'
        )
      );
    END IF;
  END IF;

  -- ========================================
  -- Marcar inscripcion como ausente
  -- ========================================
  UPDATE inscripciones
  SET estado = 'ausente',
      cancelado_at = NOW(),
      cancelado_por = v_admin.id,
      updated_at = NOW()
  WHERE id = p_inscripcion_id;

  -- ========================================
  -- Eliminar asignacion de equipo (si existe)
  -- ========================================
  DELETE FROM asignaciones_equipos
  WHERE fecha_id = p_fecha_id
  AND usuario_id = v_inscripcion.usuario_id;

  -- ========================================
  -- Retornar exito
  -- ========================================
  RETURN jsonb_build_object(
    'success', true,
    'data', jsonb_build_object(
      'inscripcion_id', p_inscripcion_id,
      'fecha_id', p_fecha_id,
      'usuario_id', v_inscripcion.usuario_id,
      'jugador_nombre', v_jugador_nombre,
      'equipo_anterior', v_equipo_anterior,
      'estado_nuevo', 'ausente',
      'marcado_por', v_admin.nombre_completo
    ),
    'message', v_jugador_nombre || ' marcado como ausente'
  );

EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'SERVER_ERROR',
        'message', 'Error interno: ' || SQLERRM,
        'hint', 'error_interno'
      )
    );
END;
$$;

GRANT EXECUTE ON FUNCTION marcar_ausente(UUID, UUID) TO authenticated;
COMMENT ON FUNCTION marcar_ausente(UUID, UUID) IS
  'Marca un jugador como ausente durante pichanga en_juego. Elimina asignacion de equipo. Solo admin/coadmin.';


-- ============================================================
-- 5. Modificar asignar_equipo para permitir en_juego
-- Ahora acepta estado 'cerrada' O 'en_juego'
-- Con validacion: no cambiar si partido en_curso con ese equipo
-- ============================================================
CREATE OR REPLACE FUNCTION asignar_equipo(
  p_fecha_id UUID,
  p_usuario_id UUID,
  p_equipo TEXT
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_usuario RECORD;
  v_fecha RECORD;
  v_inscripcion RECORD;
  v_asignacion_existente RECORD;
  v_asignacion_id UUID;
  v_es_actualizacion BOOLEAN := false;
  v_equipo_cast color_equipo;
  v_error_hint TEXT;
  v_colores_permitidos TEXT[];
  v_equipo_anterior TEXT;
BEGIN
  -- Validar autenticacion
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    v_error_hint := 'no_autenticado';
    RAISE EXCEPTION 'Usuario no autenticado';
  END IF;

  -- Validar que es admin/coadmin
  SELECT id, rol, estado, nombre_completo
  INTO v_usuario
  FROM usuarios
  WHERE auth_user_id = v_user_id;

  IF NOT FOUND THEN
    v_error_hint := 'usuario_no_encontrado';
    RAISE EXCEPTION 'Usuario no encontrado';
  END IF;

  -- Verificar permisos (admin global o coadmin en grupo)
  IF NOT (v_usuario.rol = 'admin' AND v_usuario.estado = 'aprobado') THEN
    -- Verificar si es coadmin en algun grupo activo
    IF NOT EXISTS (
      SELECT 1 FROM miembros_grupo
      WHERE usuario_id = v_usuario.id
      AND activo = true
      AND rol IN ('admin', 'coadmin')
    ) THEN
      v_error_hint := 'sin_permisos';
      RAISE EXCEPTION 'Solo administradores o co-administradores pueden asignar equipos';
    END IF;
  END IF;

  -- Obtener fecha
  SELECT id, estado, num_equipos
  INTO v_fecha
  FROM fechas
  WHERE id = p_fecha_id;

  IF NOT FOUND THEN
    v_error_hint := 'fecha_no_encontrada';
    RAISE EXCEPTION 'Fecha no encontrada: %', p_fecha_id;
  END IF;

  -- Validar estado: cerrada O en_juego
  IF v_fecha.estado NOT IN ('cerrada', 'en_juego') THEN
    v_error_hint := 'estado_invalido';
    RAISE EXCEPTION 'Solo se puede asignar equipos cuando la fecha esta cerrada o en juego. Estado actual: %', v_fecha.estado;
  END IF;

  -- Validar color de equipo
  BEGIN
    v_equipo_cast := LOWER(p_equipo)::color_equipo;
  EXCEPTION
    WHEN invalid_text_representation THEN
      v_error_hint := 'color_invalido';
      RAISE EXCEPTION 'Color de equipo no valido: %. Colores validos: naranja, verde, azul, rojo, amarillo, blanco', p_equipo;
  END;

  -- Validar color segun num_equipos
  IF v_fecha.num_equipos = 2 THEN
    v_colores_permitidos := ARRAY['naranja', 'verde'];
  ELSIF v_fecha.num_equipos = 3 THEN
    v_colores_permitidos := ARRAY['naranja', 'verde', 'azul'];
  ELSIF v_fecha.num_equipos = 4 THEN
    v_colores_permitidos := ARRAY['naranja', 'verde', 'azul', 'rojo'];
  ELSE
    v_colores_permitidos := ARRAY['naranja', 'verde', 'azul', 'rojo', 'amarillo', 'blanco'];
  END IF;

  IF NOT (LOWER(p_equipo) = ANY(v_colores_permitidos)) THEN
    v_error_hint := 'color_no_permitido';
    RAISE EXCEPTION 'Color % no permitido para % equipos. Colores validos: %', p_equipo, v_fecha.num_equipos, array_to_string(v_colores_permitidos, ', ');
  END IF;

  -- Validar que el usuario esta inscrito (estado inscrito)
  SELECT id INTO v_inscripcion
  FROM inscripciones
  WHERE fecha_id = p_fecha_id
  AND usuario_id = p_usuario_id
  AND estado = 'inscrito';

  IF NOT FOUND THEN
    v_error_hint := 'usuario_no_inscrito';
    RAISE EXCEPTION 'El usuario no esta inscrito a esta fecha';
  END IF;

  -- Si estamos en en_juego, validar que no hay partido en_curso con el equipo destino
  IF v_fecha.estado = 'en_juego' THEN
    IF EXISTS (
      SELECT 1 FROM partidos
      WHERE fecha_id = p_fecha_id
      AND estado IN ('en_curso', 'pausado')
      AND (equipo_local::text = LOWER(p_equipo) OR equipo_visitante::text = LOWER(p_equipo))
    ) THEN
      v_error_hint := 'partido_en_curso_equipo';
      RAISE EXCEPTION 'No se puede asignar al equipo % mientras tiene un partido en curso', p_equipo;
    END IF;
  END IF;

  -- Verificar si ya tiene asignacion (upsert)
  SELECT id, color_equipo::text as equipo_actual
  INTO v_asignacion_existente
  FROM asignaciones_equipos
  WHERE fecha_id = p_fecha_id
  AND usuario_id = p_usuario_id;

  IF FOUND THEN
    v_es_actualizacion := true;
    v_equipo_anterior := v_asignacion_existente.equipo_actual;

    -- Si estamos en en_juego, validar que equipo anterior no tiene partido en_curso
    IF v_fecha.estado = 'en_juego' AND v_equipo_anterior IS NOT NULL THEN
      IF EXISTS (
        SELECT 1 FROM partidos
        WHERE fecha_id = p_fecha_id
        AND estado IN ('en_curso', 'pausado')
        AND (equipo_local::text = v_equipo_anterior OR equipo_visitante::text = v_equipo_anterior)
      ) THEN
        v_error_hint := 'partido_en_curso_equipo';
        RAISE EXCEPTION 'No se puede mover jugador del equipo % mientras tiene un partido en curso', v_equipo_anterior;
      END IF;
    END IF;

    UPDATE asignaciones_equipos
    SET color_equipo = v_equipo_cast,
        numero_equipo = CASE
          WHEN LOWER(p_equipo) = 'naranja' THEN 1
          WHEN LOWER(p_equipo) = 'verde' THEN 2
          WHEN LOWER(p_equipo) = 'azul' THEN 3
          WHEN LOWER(p_equipo) = 'rojo' THEN 4
          WHEN LOWER(p_equipo) = 'amarillo' THEN 5
          ELSE 6
        END,
        asignado_por = v_usuario.id,
        asignado_at = NOW(),
        updated_at = NOW()
    WHERE id = v_asignacion_existente.id
    RETURNING id INTO v_asignacion_id;
  ELSE
    INSERT INTO asignaciones_equipos (
      fecha_id, usuario_id, color_equipo, numero_equipo,
      asignado_por, asignado_at, created_at, updated_at
    ) VALUES (
      p_fecha_id, p_usuario_id, v_equipo_cast,
      CASE
        WHEN LOWER(p_equipo) = 'naranja' THEN 1
        WHEN LOWER(p_equipo) = 'verde' THEN 2
        WHEN LOWER(p_equipo) = 'azul' THEN 3
        WHEN LOWER(p_equipo) = 'rojo' THEN 4
        WHEN LOWER(p_equipo) = 'amarillo' THEN 5
        ELSE 6
      END,
      v_usuario.id, NOW(), NOW(), NOW()
    )
    RETURNING id INTO v_asignacion_id;
  END IF;

  -- Retornar resultado
  RETURN json_build_object(
    'success', true,
    'data', json_build_object(
      'asignacion_id', v_asignacion_id,
      'usuario_nombre', (SELECT COALESCE(apodo, nombre_completo) FROM usuarios WHERE id = p_usuario_id),
      'equipo', LOWER(p_equipo),
      'es_actualizacion', v_es_actualizacion
    ),
    'message', CASE
      WHEN v_es_actualizacion THEN 'Jugador movido al equipo ' || p_equipo
      ELSE 'Jugador asignado al equipo ' || p_equipo
    END
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
$$;

GRANT EXECUTE ON FUNCTION asignar_equipo(UUID, UUID, TEXT) TO anon, authenticated, service_role;
COMMENT ON FUNCTION asignar_equipo(UUID, UUID, TEXT) IS
  'E003-HU-005: Asigna jugador a equipo. V2: permite en_juego + validacion partido en curso.';


-- ============================================================
-- 6. Modificar desasignar_equipo para permitir en_juego
-- ============================================================
CREATE OR REPLACE FUNCTION desasignar_equipo(
  p_fecha_id UUID,
  p_usuario_id UUID
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_usuario RECORD;
  v_fecha RECORD;
  v_asignacion RECORD;
  v_error_hint TEXT;
BEGIN
  -- Validar autenticacion
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    v_error_hint := 'no_autenticado';
    RAISE EXCEPTION 'Usuario no autenticado';
  END IF;

  -- Validar permisos
  SELECT id, rol, estado
  INTO v_usuario
  FROM usuarios
  WHERE auth_user_id = v_user_id;

  IF NOT FOUND THEN
    v_error_hint := 'usuario_no_encontrado';
    RAISE EXCEPTION 'Usuario no encontrado';
  END IF;

  IF NOT (v_usuario.rol = 'admin' AND v_usuario.estado = 'aprobado') THEN
    IF NOT EXISTS (
      SELECT 1 FROM miembros_grupo
      WHERE usuario_id = v_usuario.id AND activo = true AND rol IN ('admin', 'coadmin')
    ) THEN
      v_error_hint := 'sin_permisos';
      RAISE EXCEPTION 'Solo administradores o co-administradores pueden desasignar equipos';
    END IF;
  END IF;

  -- Obtener fecha
  SELECT id, estado
  INTO v_fecha
  FROM fechas
  WHERE id = p_fecha_id;

  IF NOT FOUND THEN
    v_error_hint := 'fecha_no_encontrada';
    RAISE EXCEPTION 'Fecha no encontrada';
  END IF;

  -- Validar estado: cerrada O en_juego
  IF v_fecha.estado NOT IN ('cerrada', 'en_juego') THEN
    v_error_hint := 'estado_invalido';
    RAISE EXCEPTION 'Solo se puede desasignar cuando la fecha esta cerrada o en juego. Estado actual: %', v_fecha.estado;
  END IF;

  -- Obtener asignacion actual
  SELECT ae.id, ae.color_equipo::text as equipo,
         COALESCE(u.apodo, u.nombre_completo) as nombre
  INTO v_asignacion
  FROM asignaciones_equipos ae
  JOIN usuarios u ON u.id = ae.usuario_id
  WHERE ae.fecha_id = p_fecha_id
  AND ae.usuario_id = p_usuario_id;

  IF NOT FOUND THEN
    v_error_hint := 'sin_asignacion';
    RAISE EXCEPTION 'El usuario no tiene equipo asignado en esta fecha';
  END IF;

  -- Validar que no hay partido en_curso con el equipo
  IF v_fecha.estado = 'en_juego' THEN
    IF EXISTS (
      SELECT 1 FROM partidos
      WHERE fecha_id = p_fecha_id
      AND estado IN ('en_curso', 'pausado')
      AND (equipo_local::text = v_asignacion.equipo OR equipo_visitante::text = v_asignacion.equipo)
    ) THEN
      v_error_hint := 'partido_en_curso_equipo';
      RAISE EXCEPTION 'No se puede desasignar del equipo % mientras tiene un partido en curso', v_asignacion.equipo;
    END IF;
  END IF;

  -- Eliminar asignacion
  DELETE FROM asignaciones_equipos
  WHERE id = v_asignacion.id;

  RETURN json_build_object(
    'success', true,
    'data', json_build_object(
      'usuario_id', p_usuario_id,
      'usuario_nombre', v_asignacion.nombre,
      'equipo_anterior', v_asignacion.equipo
    ),
    'message', v_asignacion.nombre || ' removido del equipo ' || v_asignacion.equipo
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
$$;

GRANT EXECUTE ON FUNCTION desasignar_equipo(UUID, UUID) TO anon, authenticated, service_role;
COMMENT ON FUNCTION desasignar_equipo(UUID, UUID) IS
  'Desasigna jugador de equipo. V2: permite en_juego + validacion partido en curso.';


-- ============================================================
-- 7. Modificar obtener_asignaciones para incluir ausentes
-- Ahora retorna seccion adicional de ausentes
-- ============================================================
CREATE OR REPLACE FUNCTION obtener_asignaciones(p_fecha_id UUID)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_fecha RECORD;
  v_colores_disponibles TEXT[];
  v_jugadores JSON;
  v_equipos JSON;
  v_ausentes JSON;
  v_total_inscritos INT;
  v_total_asignados INT;
  v_sin_asignar INT;
  v_total_ausentes INT;
BEGIN
  -- Obtener fecha
  SELECT id, estado, num_equipos
  INTO v_fecha
  FROM fechas
  WHERE id = p_fecha_id;

  IF NOT FOUND THEN
    RETURN json_build_object(
      'success', false,
      'error', json_build_object(
        'code', 'NOT_FOUND',
        'message', 'Fecha no encontrada',
        'hint', 'fecha_no_encontrada'
      )
    );
  END IF;

  -- Colores disponibles
  IF v_fecha.num_equipos = 2 THEN
    v_colores_disponibles := ARRAY['naranja', 'verde'];
  ELSIF v_fecha.num_equipos = 3 THEN
    v_colores_disponibles := ARRAY['naranja', 'verde', 'azul'];
  ELSIF v_fecha.num_equipos = 4 THEN
    v_colores_disponibles := ARRAY['naranja', 'verde', 'azul', 'rojo'];
  ELSE
    v_colores_disponibles := ARRAY['naranja', 'verde'];
  END IF;

  -- Lista de jugadores inscritos (NO ausentes) con asignacion
  SELECT COALESCE(json_agg(
    json_build_object(
      'usuario_id', sub.usuario_id,
      'nombre_completo', sub.nombre_completo,
      'apodo', sub.apodo,
      'foto_url', sub.foto_url,
      'equipo', sub.equipo,
      'asignado', sub.asignado,
      'inscripcion_id', sub.inscripcion_id,
      'inscripcion_tardia', sub.inscripcion_tardia
    ) ORDER BY sub.asignado DESC, sub.nombre_completo
  ), '[]'::json)
  INTO v_jugadores
  FROM (
    SELECT
      i.usuario_id,
      u.nombre_completo,
      u.apodo,
      u.foto_url,
      ae.color_equipo::text as equipo,
      (ae.id IS NOT NULL) as asignado,
      i.id as inscripcion_id,
      COALESCE(i.inscripcion_tardia, false) as inscripcion_tardia
    FROM inscripciones i
    JOIN usuarios u ON u.id = i.usuario_id
    LEFT JOIN asignaciones_equipos ae ON ae.fecha_id = i.fecha_id AND ae.usuario_id = i.usuario_id
    WHERE i.fecha_id = p_fecha_id
    AND i.estado = 'inscrito'
  ) sub;

  -- Lista de ausentes
  SELECT COALESCE(json_agg(
    json_build_object(
      'usuario_id', sub.usuario_id,
      'nombre_completo', sub.nombre_completo,
      'apodo', sub.apodo,
      'inscripcion_id', sub.inscripcion_id
    ) ORDER BY sub.nombre_completo
  ), '[]'::json)
  INTO v_ausentes
  FROM (
    SELECT
      i.usuario_id,
      u.nombre_completo,
      u.apodo,
      i.id as inscripcion_id
    FROM inscripciones i
    JOIN usuarios u ON u.id = i.usuario_id
    WHERE i.fecha_id = p_fecha_id
    AND i.estado = 'ausente'
  ) sub;

  -- Resumen por equipo
  SELECT COALESCE(json_agg(
    json_build_object(
      'equipo', sub.equipo,
      'cantidad', sub.cantidad,
      'jugadores', sub.jugadores
    ) ORDER BY sub.equipo
  ), '[]'::json)
  INTO v_equipos
  FROM (
    SELECT
      ae.color_equipo::text as equipo,
      COUNT(*) as cantidad,
      json_agg(
        json_build_object(
          'usuario_id', ae.usuario_id,
          'nombre_completo', u.nombre_completo,
          'apodo', u.apodo
        )
      ) as jugadores
    FROM asignaciones_equipos ae
    JOIN usuarios u ON u.id = ae.usuario_id
    WHERE ae.fecha_id = p_fecha_id
    -- Solo contar jugadores cuya inscripcion sea 'inscrito'
    AND EXISTS (
      SELECT 1 FROM inscripciones i
      WHERE i.fecha_id = p_fecha_id
      AND i.usuario_id = ae.usuario_id
      AND i.estado = 'inscrito'
    )
    GROUP BY ae.color_equipo
  ) sub;

  -- Contadores
  SELECT COUNT(*) INTO v_total_inscritos
  FROM inscripciones
  WHERE fecha_id = p_fecha_id AND estado = 'inscrito';

  SELECT COUNT(*) INTO v_total_asignados
  FROM asignaciones_equipos ae
  WHERE ae.fecha_id = p_fecha_id
  AND EXISTS (
    SELECT 1 FROM inscripciones i
    WHERE i.fecha_id = p_fecha_id
    AND i.usuario_id = ae.usuario_id
    AND i.estado = 'inscrito'
  );

  v_sin_asignar := v_total_inscritos - v_total_asignados;

  SELECT COUNT(*) INTO v_total_ausentes
  FROM inscripciones
  WHERE fecha_id = p_fecha_id AND estado = 'ausente';

  RETURN json_build_object(
    'success', true,
    'data', json_build_object(
      'fecha', json_build_object(
        'id', v_fecha.id,
        'num_equipos', v_fecha.num_equipos,
        'estado', v_fecha.estado::text,
        'puede_asignar', v_fecha.estado IN ('cerrada', 'en_juego')
      ),
      'colores_disponibles', to_json(v_colores_disponibles),
      'jugadores', v_jugadores,
      'equipos', v_equipos,
      'ausentes', v_ausentes,
      'resumen', json_build_object(
        'total_inscritos', v_total_inscritos,
        'total_asignados', v_total_asignados,
        'sin_asignar', v_sin_asignar,
        'total_ausentes', v_total_ausentes,
        'asignacion_completa', v_sin_asignar = 0 AND v_total_inscritos > 0
      )
    ),
    'message', 'Asignaciones obtenidas exitosamente'
  );
END;
$$;

GRANT EXECUTE ON FUNCTION obtener_asignaciones(UUID) TO anon, authenticated, service_role;
COMMENT ON FUNCTION obtener_asignaciones(UUID) IS
  'Obtiene asignaciones de equipos. V2: incluye ausentes, permite en_juego, inscripcion_tardia.';


-- ============================================================
-- 8. Modificar iniciar_partido con validacion EQUIPO_SIN_JUGADORES
-- La validacion ya existia (lineas 92-112 de fix_iniciar_partido.sql)
-- Solo cambiar el codigo de error a EQUIPO_SIN_JUGADORES
-- ============================================================
CREATE OR REPLACE FUNCTION iniciar_partido(
    p_fecha_id UUID,
    p_equipo_local TEXT,
    p_equipo_visitante TEXT
) RETURNS JSON AS $$
DECLARE
    v_user_id UUID;
    v_usuario RECORD;
    v_fecha RECORD;
    v_partido_id UUID;
    v_duracion_minutos INTEGER;
    v_hora_inicio TIMESTAMPTZ;
    v_hora_fin_estimada TIMESTAMPTZ;
    v_equipo_local_info JSON;
    v_equipo_visitante_info JSON;
    v_jugadores_local INTEGER;
    v_jugadores_visitante INTEGER;
    v_error_hint TEXT;
BEGIN
    -- RN-001: Validar autenticacion
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        v_error_hint := 'no_autenticado';
        RAISE EXCEPTION 'Usuario no autenticado';
    END IF;

    -- RN-001: Validar que es admin o coadmin
    SELECT * INTO v_usuario
    FROM usuarios
    WHERE auth_user_id = v_user_id;

    IF NOT FOUND THEN
        v_error_hint := 'usuario_no_encontrado';
        RAISE EXCEPTION 'Usuario no encontrado';
    END IF;

    -- Verificar permisos: admin global o coadmin
    IF NOT (v_usuario.rol = 'admin' AND v_usuario.estado = 'aprobado') THEN
        IF NOT EXISTS (
            SELECT 1 FROM miembros_grupo
            WHERE usuario_id = v_usuario.id AND activo = true AND rol IN ('admin', 'coadmin')
        ) THEN
            v_error_hint := 'sin_permisos';
            RAISE EXCEPTION 'Solo administradores o co-administradores pueden iniciar partidos';
        END IF;
    END IF;

    -- RN-002: Validar que la fecha existe y esta en_juego
    SELECT * INTO v_fecha
    FROM fechas
    WHERE id = p_fecha_id;

    IF NOT FOUND THEN
        v_error_hint := 'fecha_no_encontrada';
        RAISE EXCEPTION 'Fecha no encontrada: %', p_fecha_id;
    END IF;

    IF v_fecha.estado != 'en_juego' THEN
        v_error_hint := 'fecha_no_en_juego';
        RAISE EXCEPTION 'La fecha debe estar en estado en_juego. Estado actual: %', v_fecha.estado;
    END IF;

    -- RN-005: Validar que no hay otro partido activo
    IF EXISTS (
        SELECT 1 FROM partidos
        WHERE fecha_id = p_fecha_id
        AND estado IN ('en_curso', 'pausado')
    ) THEN
        v_error_hint := 'partido_activo_existe';
        RAISE EXCEPTION 'Ya existe un partido activo en esta fecha';
    END IF;

    -- RN-006: Validar que los equipos son diferentes
    IF LOWER(p_equipo_local) = LOWER(p_equipo_visitante) THEN
        v_error_hint := 'equipos_iguales';
        RAISE EXCEPTION 'Los equipos deben ser diferentes';
    END IF;

    -- RN-003: Validar que el equipo local tiene jugadores (>= 1)
    SELECT COUNT(*) INTO v_jugadores_local
    FROM asignaciones_equipos ae
    WHERE ae.fecha_id = p_fecha_id
    AND ae.color_equipo::text = LOWER(p_equipo_local)
    -- Solo contar jugadores con inscripcion activa
    AND EXISTS (
      SELECT 1 FROM inscripciones i
      WHERE i.fecha_id = p_fecha_id
      AND i.usuario_id = ae.usuario_id
      AND i.estado = 'inscrito'
    );

    IF v_jugadores_local = 0 THEN
        v_error_hint := 'EQUIPO_SIN_JUGADORES';
        RAISE EXCEPTION 'El equipo % no tiene jugadores asignados', p_equipo_local;
    END IF;

    -- RN-003: Validar que el equipo visitante tiene jugadores (>= 1)
    SELECT COUNT(*) INTO v_jugadores_visitante
    FROM asignaciones_equipos ae
    WHERE ae.fecha_id = p_fecha_id
    AND ae.color_equipo::text = LOWER(p_equipo_visitante)
    AND EXISTS (
      SELECT 1 FROM inscripciones i
      WHERE i.fecha_id = p_fecha_id
      AND i.usuario_id = ae.usuario_id
      AND i.estado = 'inscrito'
    );

    IF v_jugadores_visitante = 0 THEN
        v_error_hint := 'EQUIPO_SIN_JUGADORES';
        RAISE EXCEPTION 'El equipo % no tiene jugadores asignados', p_equipo_visitante;
    END IF;

    -- RN-004: Calcular duracion segun num_equipos
    IF v_fecha.num_equipos = 2 THEN
        v_duracion_minutos := 20;
    ELSE
        v_duracion_minutos := 10;
    END IF;

    -- Calcular tiempos
    v_hora_inicio := NOW();
    v_hora_fin_estimada := v_hora_inicio + (v_duracion_minutos || ' minutes')::INTERVAL;

    -- Crear el partido
    INSERT INTO partidos (
        fecha_id,
        equipo_local,
        equipo_visitante,
        duracion_minutos,
        estado,
        hora_inicio,
        hora_fin_estimada,
        tiempo_pausado_segundos,
        created_by
    ) VALUES (
        p_fecha_id,
        LOWER(p_equipo_local)::color_equipo,
        LOWER(p_equipo_visitante)::color_equipo,
        v_duracion_minutos,
        'en_curso',
        v_hora_inicio,
        v_hora_fin_estimada,
        0,
        v_usuario.id
    )
    RETURNING id INTO v_partido_id;

    -- Construir info del equipo local
    SELECT json_build_object(
        'color', LOWER(p_equipo_local),
        'jugadores_count', v_jugadores_local,
        'jugadores', COALESCE(
            (SELECT json_agg(json_build_object(
                'id', u.id,
                'nombre_completo', u.nombre_completo
            ))
            FROM asignaciones_equipos ae
            JOIN usuarios u ON u.id = ae.usuario_id
            WHERE ae.fecha_id = p_fecha_id
            AND ae.color_equipo::text = LOWER(p_equipo_local)),
            '[]'::json
        )
    ) INTO v_equipo_local_info;

    -- Construir info del equipo visitante
    SELECT json_build_object(
        'color', LOWER(p_equipo_visitante),
        'jugadores_count', v_jugadores_visitante,
        'jugadores', COALESCE(
            (SELECT json_agg(json_build_object(
                'id', u.id,
                'nombre_completo', u.nombre_completo
            ))
            FROM asignaciones_equipos ae
            JOIN usuarios u ON u.id = ae.usuario_id
            WHERE ae.fecha_id = p_fecha_id
            AND ae.color_equipo::text = LOWER(p_equipo_visitante)),
            '[]'::json
        )
    ) INTO v_equipo_visitante_info;

    -- Retornar resultado exitoso
    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'partido_id', v_partido_id,
            'fecha_id', p_fecha_id,
            'equipo_local', v_equipo_local_info,
            'equipo_visitante', v_equipo_visitante_info,
            'duracion_minutos', v_duracion_minutos,
            'estado', 'en_curso',
            'hora_inicio_formato', TO_CHAR(v_hora_inicio AT TIME ZONE 'America/Lima', 'HH24:MI:SS'),
            'hora_fin_estimada_formato', TO_CHAR(v_hora_fin_estimada AT TIME ZONE 'America/Lima', 'HH24:MI:SS'),
            'tiempo_restante_segundos', v_duracion_minutos * 60
        ),
        'message', 'Partido iniciado: ' || UPPER(p_equipo_local) || ' vs ' || UPPER(p_equipo_visitante) || ' - ' || v_duracion_minutos || ' minutos'
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

GRANT EXECUTE ON FUNCTION iniciar_partido(UUID, TEXT, TEXT) TO anon, authenticated, service_role;
COMMENT ON FUNCTION iniciar_partido IS
  'E004-HU-001: Inicia partido. V2: hint EQUIPO_SIN_JUGADORES, filtra ausentes, permisos coadmin.';


-- ============================================================
-- 9. Modificar iniciar_fecha: quitar validacion de equipos
-- La pichanga se puede iniciar sin equipos completos
-- (warning_sin_equipos se mantiene pero no bloquea)
-- ============================================================
-- La funcion actual (V4 DEFINITIVO) ya NO bloquea por equipos:
-- Solo muestra warning_sin_equipos. No se necesita cambio.
-- Se re-crea solo para asegurar compatibilidad con permisos coadmin.
CREATE OR REPLACE FUNCTION iniciar_fecha(p_fecha_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_auth_user_id UUID;
  v_current_user RECORD;
  v_fecha RECORD;
  v_total_equipos INT;
  v_total_jugadores INT;
  v_equipos_detalle JSONB;
  v_warning_sin_equipos BOOLEAN;
  v_notificaciones_creadas INT := 0;
  v_inscrito RECORD;
BEGIN
  -- Validaciones
  v_auth_user_id := auth.uid();
  IF v_auth_user_id IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'AUTH_ERROR',
        'message', 'No autenticado',
        'hint', 'no_autenticado'
      )
    );
  END IF;

  IF p_fecha_id IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'INVALID_PARAM',
        'message', 'El ID de la fecha es requerido',
        'hint', 'fecha_id_requerido'
      )
    );
  END IF;

  -- Obtener usuario actual
  SELECT id, rol, estado, nombre_completo
  INTO v_current_user
  FROM usuarios
  WHERE auth_user_id = v_auth_user_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'USER_NOT_FOUND',
        'message', 'Usuario no encontrado en el sistema',
        'hint', 'usuario_no_encontrado'
      )
    );
  END IF;

  -- Obtener fecha
  SELECT
    f.id,
    f.fecha_hora_inicio,
    f.duracion_horas,
    f.lugar,
    f.estado,
    f.created_by,
    f.costo_por_jugador,
    f.num_equipos,
    TO_CHAR(f.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY HH24:MI') as fecha_formato,
    TO_CHAR(f.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'HH24:MI') as hora_pactada
  INTO v_fecha
  FROM fechas f
  WHERE f.id = p_fecha_id;

  IF v_fecha.id IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'NOT_FOUND',
        'message', 'Fecha no encontrada',
        'hint', 'fecha_no_encontrada'
      )
    );
  END IF;

  -- Validar permisos: admin global, creador, o coadmin del grupo
  IF NOT (
    (v_current_user.rol = 'admin' AND v_current_user.estado = 'aprobado')
    OR v_fecha.created_by = v_current_user.id
    OR EXISTS (
      SELECT 1 FROM miembros_grupo
      WHERE usuario_id = v_current_user.id
      AND activo = true
      AND rol IN ('admin', 'coadmin')
    )
  ) THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'FORBIDDEN',
        'message', 'No tienes permisos para iniciar esta pichanga.',
        'hint', 'sin_permisos'
      )
    );
  END IF;

  -- Validar estado cerrada
  IF v_fecha.estado != 'cerrada' THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'INVALID_STATE',
        'message', 'Solo se puede iniciar una pichanga con inscripciones cerradas. Estado actual: ' || v_fecha.estado,
        'hint', 'estado_invalido'
      )
    );
  END IF;

  -- Contar equipos (warning, no bloquea)
  SELECT
    COUNT(DISTINCT ae.numero_equipo),
    COUNT(*)
  INTO v_total_equipos, v_total_jugadores
  FROM asignaciones_equipos ae
  WHERE ae.fecha_id = p_fecha_id;

  v_warning_sin_equipos := (v_total_equipos < 2);

  -- Construir detalle de equipos
  SELECT COALESCE(
    jsonb_agg(
      jsonb_build_object(
        'numero', numero,
        'color', color,
        'jugadores', cant
      )
      ORDER BY numero
    ),
    '[]'::jsonb
  )
  INTO v_equipos_detalle
  FROM (
    SELECT
      ae.numero_equipo as numero,
      ae.color_equipo::text as color,
      COUNT(*) as cant
    FROM asignaciones_equipos ae
    WHERE ae.fecha_id = p_fecha_id
    GROUP BY ae.numero_equipo, ae.color_equipo
  ) sub;

  -- Actualizar estado de la fecha
  UPDATE fechas
  SET
    estado = 'en_juego',
    iniciado_por = v_current_user.id,
    iniciado_at = NOW(),
    updated_at = NOW()
  WHERE id = p_fecha_id;

  -- Notificar a jugadores inscritos
  FOR v_inscrito IN
    SELECT i.usuario_id
    FROM inscripciones i
    WHERE i.fecha_id = p_fecha_id
      AND i.estado = 'inscrito'
  LOOP
    IF v_inscrito.usuario_id != v_current_user.id THEN
      INSERT INTO notificaciones (
        usuario_id, tipo, titulo, mensaje, metadata, leida, created_at
      ) VALUES (
        v_inscrito.usuario_id,
        'general',
        'Pichanga iniciada',
        'La pichanga del ' || v_fecha.fecha_formato || ' en ' || v_fecha.lugar || ' ha comenzado!',
        jsonb_build_object('fecha_id', p_fecha_id, 'tipo_evento', 'fecha_iniciada'),
        false,
        NOW()
      );
      v_notificaciones_creadas := v_notificaciones_creadas + 1;
    END IF;
  END LOOP;

  -- Retornar exito
  RETURN jsonb_build_object(
    'success', true,
    'data', jsonb_build_object(
      'fecha_id', p_fecha_id,
      'fecha_formato', v_fecha.fecha_formato,
      'lugar', v_fecha.lugar,
      'estado_anterior', 'cerrada',
      'estado_nuevo', 'en_juego',
      'hora_pactada', v_fecha.hora_pactada,
      'hora_inicio_real', TO_CHAR(NOW() AT TIME ZONE 'America/Lima', 'HH24:MI'),
      'iniciado_por', v_current_user.id,
      'iniciado_por_nombre', v_current_user.nombre_completo,
      'iniciado_at', NOW(),
      'total_equipos', v_total_equipos,
      'total_jugadores', v_total_jugadores,
      'equipos_detalle', v_equipos_detalle,
      'warning_sin_equipos', v_warning_sin_equipos,
      'notificaciones_enviadas', v_notificaciones_creadas,
      'costo_por_jugador', v_fecha.costo_por_jugador
    ),
    'message', CASE
      WHEN v_notificaciones_creadas > 0
      THEN 'Pichanga iniciada. Se notifico a ' || v_notificaciones_creadas || ' jugador(es).'
      ELSE 'Pichanga iniciada exitosamente.'
    END
  );

EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'SERVER_ERROR',
        'message', 'Error interno: ' || SQLERRM,
        'hint', 'error_interno'
      )
    );
END;
$$;

GRANT EXECUTE ON FUNCTION iniciar_fecha(UUID) TO authenticated;
COMMENT ON FUNCTION iniciar_fecha(UUID) IS
  'E003-HU-012: Inicia pichanga. V5: permite coadmin, no bloquea por equipos.';


-- ============================================================
-- 10. Crear RPC registrar_invitado_y_inscribir
-- Combo rapido: registra invitado en grupo + inscribe a fecha
-- ============================================================
CREATE OR REPLACE FUNCTION registrar_invitado_y_inscribir(
  p_grupo_id UUID,
  p_fecha_id UUID,
  p_nombre TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_auth_uid UUID := auth.uid();
  v_caller_usuario_id UUID;
  v_caller_rol TEXT;
  v_grupo_activo BOOLEAN;
  v_plan_nombre TEXT;
  v_max_invitados INT;
  v_invitados_actuales INT;
  v_nombre_limpio TEXT;
  v_nuevo_usuario_id UUID;
  v_nuevo_miembro_id UUID;
  v_email_ficticio TEXT;
  v_fecha RECORD;
  v_inscripcion_id UUID;
  v_pago_id UUID;
  v_total_inscritos INT;
  v_es_tardia BOOLEAN := false;
BEGIN
  -- Validar autenticacion
  IF v_auth_uid IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'NO_AUTH',
        'message', 'Debes iniciar sesion',
        'hint', 'no_autenticado'
      )
    );
  END IF;

  -- Obtener caller
  SELECT id INTO v_caller_usuario_id
  FROM usuarios
  WHERE auth_user_id = v_auth_uid;

  IF v_caller_usuario_id IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'USER_NOT_FOUND',
        'message', 'Usuario no encontrado',
        'hint', 'usuario_no_encontrado'
      )
    );
  END IF;

  -- Verificar permisos en grupo
  SELECT mg.rol::text
  INTO v_caller_rol
  FROM miembros_grupo mg
  WHERE mg.grupo_id = p_grupo_id
  AND mg.usuario_id = v_caller_usuario_id
  AND mg.activo = true;

  IF v_caller_rol IS NULL OR v_caller_rol NOT IN ('admin', 'coadmin') THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'FORBIDDEN',
        'message', 'Solo admin o coadmin pueden registrar invitados',
        'hint', 'sin_permisos'
      )
    );
  END IF;

  -- Verificar grupo activo
  SELECT g.activo INTO v_grupo_activo
  FROM grupos g
  WHERE g.id = p_grupo_id;

  IF NOT v_grupo_activo THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'GRUPO_INACTIVO',
        'message', 'El grupo no esta activo',
        'hint', 'grupo_inactivo'
      )
    );
  END IF;

  -- Validar nombre
  v_nombre_limpio := TRIM(p_nombre);
  IF v_nombre_limpio IS NULL OR LENGTH(v_nombre_limpio) < 2 THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'INVALID_NAME',
        'message', 'El nombre debe tener al menos 2 caracteres',
        'hint', 'nombre_invalido'
      )
    );
  END IF;

  -- Verificar limite de invitados del plan
  SELECT p.nombre, p.max_invitados_por_grupo
  INTO v_plan_nombre, v_max_invitados
  FROM grupos g
  JOIN planes p ON p.id = g.plan_id
  WHERE g.id = p_grupo_id;

  SELECT COUNT(*) INTO v_invitados_actuales
  FROM miembros_grupo
  WHERE grupo_id = p_grupo_id
  AND rol = 'invitado'
  AND activo = true;

  IF v_invitados_actuales >= v_max_invitados THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'LIMITE_INVITADOS',
        'message', 'Se alcanzo el limite de invitados (' || v_max_invitados || ') del plan ' || v_plan_nombre,
        'hint', 'limite_invitados'
      )
    );
  END IF;

  -- Obtener fecha
  SELECT f.id, f.estado, f.costo_por_jugador, f.lugar, f.limite_jugadores,
         TO_CHAR(f.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY HH24:MI') as fecha_formato
  INTO v_fecha
  FROM fechas f
  WHERE f.id = p_fecha_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'NOT_FOUND',
        'message', 'Fecha no encontrada',
        'hint', 'fecha_no_encontrada'
      )
    );
  END IF;

  -- Validar estado de fecha
  IF v_fecha.estado = 'en_juego' THEN
    v_es_tardia := true;
  ELSIF v_fecha.estado NOT IN ('abierta', 'cerrada') THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'INVALID_STATE',
        'message', 'No se puede inscribir a esta fecha. Estado: ' || v_fecha.estado::text,
        'hint', 'fecha_no_abierta'
      )
    );
  END IF;

  -- Verificar limite de cupos
  SELECT COUNT(*) INTO v_total_inscritos
  FROM inscripciones
  WHERE fecha_id = p_fecha_id AND estado = 'inscrito';

  IF v_fecha.limite_jugadores IS NOT NULL AND v_total_inscritos >= v_fecha.limite_jugadores THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'LIMIT_REACHED',
        'message', 'Se alcanzo el limite de cupos',
        'hint', 'limite_cupos'
      )
    );
  END IF;

  -- Crear usuario invitado (sin auth)
  v_email_ficticio := 'invitado_' || gen_random_uuid()::text || '@invitado.local';

  INSERT INTO usuarios (
    nombre_completo, email, estado, rol, celular, created_at, updated_at
  ) VALUES (
    v_nombre_limpio, v_email_ficticio, 'pendiente_aprobacion', 'jugador', NULL, NOW(), NOW()
  )
  RETURNING id INTO v_nuevo_usuario_id;

  -- Agregar como miembro del grupo con rol invitado
  INSERT INTO miembros_grupo (
    grupo_id, usuario_id, rol, activo, created_at, updated_at
  ) VALUES (
    p_grupo_id, v_nuevo_usuario_id, 'invitado', true, NOW(), NOW()
  )
  RETURNING id INTO v_nuevo_miembro_id;

  -- Inscribir a la fecha
  INSERT INTO inscripciones (
    fecha_id, usuario_id, estado, inscrito_por, inscripcion_tardia, created_at, updated_at
  ) VALUES (
    p_fecha_id, v_nuevo_usuario_id, 'inscrito', v_caller_usuario_id, v_es_tardia, NOW(), NOW()
  )
  RETURNING id INTO v_inscripcion_id;

  -- Crear pago pendiente
  INSERT INTO pagos (
    inscripcion_id, usuario_id, fecha_id, monto, estado, registrado_por, created_at, updated_at
  ) VALUES (
    v_inscripcion_id, v_nuevo_usuario_id, p_fecha_id, v_fecha.costo_por_jugador, 'pendiente', v_caller_usuario_id, NOW(), NOW()
  )
  RETURNING id INTO v_pago_id;

  -- Contar inscritos actualizados
  SELECT COUNT(*) INTO v_total_inscritos
  FROM inscripciones
  WHERE fecha_id = p_fecha_id AND estado = 'inscrito';

  RETURN jsonb_build_object(
    'success', true,
    'data', jsonb_build_object(
      'usuario_id', v_nuevo_usuario_id,
      'miembro_id', v_nuevo_miembro_id,
      'inscripcion_id', v_inscripcion_id,
      'pago_id', v_pago_id,
      'nombre', v_nombre_limpio,
      'fecha_id', p_fecha_id,
      'grupo_id', p_grupo_id,
      'inscripcion_tardia', v_es_tardia,
      'total_inscritos', v_total_inscritos
    ),
    'message', 'Invitado ' || v_nombre_limpio || ' registrado e inscrito exitosamente'
  );

EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'SERVER_ERROR',
        'message', 'Error interno: ' || SQLERRM,
        'hint', 'error_interno'
      )
    );
END;
$$;

GRANT EXECUTE ON FUNCTION registrar_invitado_y_inscribir(UUID, UUID, TEXT) TO authenticated;
COMMENT ON FUNCTION registrar_invitado_y_inscribir(UUID, UUID, TEXT) IS
  'Combo: registra invitado en grupo + inscribe a fecha. Soporta inscripcion tardia durante en_juego.';


-- ============================================================
-- 11. Modificar listar_jugadores_disponibles_inscripcion
-- para que funcione tambien cuando fecha esta en_juego
-- ============================================================
CREATE OR REPLACE FUNCTION listar_jugadores_disponibles_inscripcion(p_fecha_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_auth_user_id UUID;
  v_admin RECORD;
  v_fecha RECORD;
  v_jugadores JSONB;
  v_total INT;
BEGIN
  -- Validar autenticacion
  v_auth_user_id := auth.uid();
  IF v_auth_user_id IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'AUTH_ERROR',
        'message', 'No autenticado',
        'hint', 'no_autenticado'
      )
    );
  END IF;

  -- Obtener admin
  SELECT id, rol, estado
  INTO v_admin
  FROM usuarios
  WHERE auth_user_id = v_auth_user_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'USER_NOT_FOUND',
        'message', 'Usuario no encontrado',
        'hint', 'usuario_no_encontrado'
      )
    );
  END IF;

  -- Verificar permisos
  IF NOT (v_admin.rol = 'admin' AND v_admin.estado = 'aprobado') THEN
    IF NOT EXISTS (
      SELECT 1 FROM miembros_grupo
      WHERE usuario_id = v_admin.id AND activo = true AND rol IN ('admin', 'coadmin')
    ) THEN
      RETURN jsonb_build_object(
        'success', false,
        'error', jsonb_build_object(
          'code', 'FORBIDDEN',
          'message', 'Sin permisos',
          'hint', 'sin_permisos'
        )
      );
    END IF;
  END IF;

  -- Obtener fecha
  SELECT id, estado
  INTO v_fecha
  FROM fechas
  WHERE id = p_fecha_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'NOT_FOUND',
        'message', 'Fecha no encontrada',
        'hint', 'fecha_no_encontrada'
      )
    );
  END IF;

  -- Validar estado: abierta o en_juego
  IF v_fecha.estado NOT IN ('abierta', 'en_juego') THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'INVALID_STATE',
        'message', 'Solo se puede listar jugadores para fechas abiertas o en juego',
        'hint', 'fecha_no_abierta'
      )
    );
  END IF;

  -- Obtener jugadores disponibles (miembros del grupo, no inscritos actualmente)
  SELECT COALESCE(jsonb_agg(
    jsonb_build_object(
      'id', sub.id,
      'nombre_completo', sub.nombre_completo,
      'apodo', sub.apodo,
      'nombre_display', COALESCE(sub.apodo, sub.nombre_completo),
      'posicion_preferida', sub.posicion_preferida,
      'foto_url', sub.foto_url,
      'rol_en_grupo', sub.rol_grupo
    ) ORDER BY sub.nombre_completo
  ), '[]'::jsonb),
  COUNT(*)
  INTO v_jugadores, v_total
  FROM (
    SELECT DISTINCT ON (u.id)
      u.id,
      u.nombre_completo,
      u.apodo,
      u.posicion_preferida::text,
      u.foto_url,
      mg.rol::text as rol_grupo
    FROM usuarios u
    JOIN miembros_grupo mg ON mg.usuario_id = u.id AND mg.activo = true
    WHERE u.id != v_admin.id -- Excluir al admin que ejecuta
    AND NOT EXISTS (
      SELECT 1 FROM inscripciones i
      WHERE i.fecha_id = p_fecha_id
      AND i.usuario_id = u.id
      AND i.estado = 'inscrito'
    )
  ) sub;

  RETURN jsonb_build_object(
    'success', true,
    'data', jsonb_build_object(
      'jugadores', v_jugadores,
      'total', v_total
    ),
    'message', 'Lista de jugadores disponibles obtenida exitosamente'
  );

EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', jsonb_build_object(
        'code', 'SERVER_ERROR',
        'message', 'Error interno: ' || SQLERRM,
        'hint', 'error_interno'
      )
    );
END;
$$;

GRANT EXECUTE ON FUNCTION listar_jugadores_disponibles_inscripcion(UUID) TO authenticated;
COMMENT ON FUNCTION listar_jugadores_disponibles_inscripcion(UUID) IS
  'Lista jugadores disponibles para inscripcion. V2: permite en_juego, incluye invitados del grupo.';


-- ============================================================
-- VERIFICACION
-- ============================================================
SELECT
    routine_name as funcion,
    routine_type as tipo
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name IN (
  'inscribir_jugador_admin',
  'marcar_ausente',
  'asignar_equipo',
  'desasignar_equipo',
  'obtener_asignaciones',
  'iniciar_partido',
  'iniciar_fecha',
  'registrar_invitado_y_inscribir',
  'listar_jugadores_disponibles_inscripcion'
)
ORDER BY routine_name;

-- ============================================================
-- FIN DEL SCRIPT
-- ============================================================
