-- =============================================
-- FIX DEFINITIVO V4: iniciar_fecha
-- Fecha: 2026-02-02
-- =============================================
-- BASADO EN schema_reference.md (SCHEMA REAL VERIFICADO)
--
-- CORRECCIONES APLICADAS:
-- 1. fechas.costo_por_jugador (NO costo_total)
-- 2. ENUM comparado directamente (NO LOWER())
-- 3. asignaciones_equipos para contar equipos
-- 4. notificaciones: usa 'general' como tipo y metadata para fecha_id
--    (tipo_notificacion ENUM solo tiene: nuevo_registro, cuenta_aprobada, cuenta_rechazada, general)
-- =============================================

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
  -- ========================================
  -- VALIDACIONES
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

  -- ========================================
  -- Obtener usuario actual
  -- ========================================
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

  -- ========================================
  -- Obtener fecha (usando costo_por_jugador - columna real)
  -- ========================================
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

  -- ========================================
  -- Validar permisos (ENUM comparado directamente, sin LOWER)
  -- ========================================
  IF NOT (
    (v_current_user.rol = 'admin' AND v_current_user.estado = 'aprobado')
    OR v_fecha.created_by = v_current_user.id
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

  -- ========================================
  -- Contar equipos desde asignaciones_equipos (tabla real)
  -- ========================================
  SELECT
    COUNT(DISTINCT ae.numero_equipo),
    COUNT(*)
  INTO v_total_equipos, v_total_jugadores
  FROM asignaciones_equipos ae
  WHERE ae.fecha_id = p_fecha_id;

  v_warning_sin_equipos := (v_total_equipos < 2);

  -- Construir detalle de equipos desde asignaciones_equipos
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

  -- ========================================
  -- Actualizar estado de la fecha
  -- ========================================
  UPDATE fechas
  SET
    estado = 'en_juego',
    iniciado_por = v_current_user.id,
    iniciado_at = NOW(),
    updated_at = NOW()
  WHERE id = p_fecha_id;

  -- ========================================
  -- Notificar a jugadores inscritos
  -- NOTA: notificaciones NO tiene fecha_id, usa metadata (jsonb)
  -- tipo_notificacion ENUM: nuevo_registro, cuenta_aprobada, cuenta_rechazada, general
  -- ========================================
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
        'general',  -- Usar tipo existente en ENUM
        'Pichanga iniciada',
        'La pichanga del ' || v_fecha.fecha_formato || ' en ' || v_fecha.lugar || ' ha comenzado!',
        jsonb_build_object('fecha_id', p_fecha_id, 'tipo_evento', 'fecha_iniciada'),  -- Guardar referencia en metadata
        false,
        NOW()
      );
      v_notificaciones_creadas := v_notificaciones_creadas + 1;
    END IF;
  END LOOP;

  -- ========================================
  -- Retornar éxito
  -- ========================================
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
      THEN 'Pichanga iniciada. Se notificó a ' || v_notificaciones_creadas || ' jugador(es).'
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
'E003-HU-012: Inicia pichanga.
V4 DEFINITIVO: Basado en schema_reference.md verificado.
- costo_por_jugador (no costo_total)
- ENUM sin LOWER()
- asignaciones_equipos para equipos
- notificaciones: tipo=general, fecha_id en metadata';

-- =============================================
-- FIN DEL SCRIPT
-- =============================================
