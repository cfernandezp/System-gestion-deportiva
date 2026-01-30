-- ============================================
-- E003-HU-003: Ver Inscritos
-- Fecha: 2026-01-27
-- Descripcion: Funcion RPC para obtener la lista de jugadores inscritos
--              a una fecha de pichanga, con soporte para Realtime
-- ============================================

-- ============================================
-- PARTE 1: FUNCION RPC obtener_inscritos_fecha
-- ============================================

-- ============================================
-- Funcion: obtener_inscritos_fecha
-- Descripcion: Obtiene la lista de jugadores inscritos a una fecha
-- Reglas: RN-001, RN-002, RN-003, RN-004
-- CA: CA-001, CA-002, CA-003, CA-004, CA-005
-- ============================================
CREATE OR REPLACE FUNCTION obtener_inscritos_fecha(
    p_fecha_id UUID
) RETURNS JSON AS $$
DECLARE
    v_error_hint TEXT;
    v_current_user_id UUID;
    v_current_user RECORD;
    v_fecha RECORD;
    v_inscritos JSON;
    v_total_inscritos INTEGER;
BEGIN
    -- ========================================
    -- RN-001: Validacion de usuario autenticado
    -- ========================================
    v_current_user_id := auth.uid();

    IF v_current_user_id IS NULL THEN
        v_error_hint := 'no_autenticado';
        RAISE EXCEPTION 'Debes iniciar sesion para ver la lista de inscritos';
    END IF;

    -- ========================================
    -- Validacion: Parametro obligatorio
    -- ========================================
    IF p_fecha_id IS NULL THEN
        v_error_hint := 'fecha_id_requerido';
        RAISE EXCEPTION 'El ID de la fecha es obligatorio';
    END IF;

    -- ========================================
    -- RN-001: Solo usuarios aprobados pueden ver
    -- ========================================
    SELECT id, rol, estado, nombre_completo
    INTO v_current_user
    FROM usuarios
    WHERE auth_user_id = v_current_user_id;

    IF NOT FOUND THEN
        v_error_hint := 'usuario_no_encontrado';
        RAISE EXCEPTION 'Usuario no encontrado en el sistema';
    END IF;

    IF v_current_user.estado != 'aprobado' THEN
        v_error_hint := 'usuario_no_aprobado';
        RAISE EXCEPTION 'Solo los usuarios aprobados pueden ver la lista de inscritos';
    END IF;

    -- ========================================
    -- Verificar que la fecha existe
    -- ========================================
    SELECT id, fecha_hora_inicio, lugar, estado
    INTO v_fecha
    FROM fechas
    WHERE id = p_fecha_id;

    IF NOT FOUND THEN
        v_error_hint := 'fecha_no_encontrada';
        RAISE EXCEPTION 'Fecha de pichanga no encontrada';
    END IF;

    -- ========================================
    -- RN-004: Contar total de inscritos (solo estado = 'inscrito')
    -- CA-003: Contador total
    -- ========================================
    SELECT COUNT(*) INTO v_total_inscritos
    FROM inscripciones
    WHERE fecha_id = p_fecha_id
    AND estado = 'inscrito';

    -- ========================================
    -- RN-002, RN-003, RN-004: Obtener lista de inscritos
    -- Solo campos publicos, ordenados por created_at ASC
    -- CA-002: Informacion de cada inscrito
    -- CA-005: Flag es_usuario_actual
    -- ========================================
    SELECT COALESCE(
        json_agg(
            json_build_object(
                'usuario_id', u.id,
                'foto_url', u.foto_url,
                'apodo', COALESCE(u.apodo, u.nombre_completo),
                'nombre_completo', u.nombre_completo,
                'posicion_preferida', u.posicion_preferida,
                'es_usuario_actual', (u.id = v_current_user.id),
                'inscrito_at', i.created_at AT TIME ZONE 'America/Lima',
                'inscrito_formato', TO_CHAR(i.created_at AT TIME ZONE 'America/Lima', 'DD/MM/YYYY HH24:MI')
            ) ORDER BY i.created_at ASC
        ),
        '[]'::json
    )
    INTO v_inscritos
    FROM inscripciones i
    JOIN usuarios u ON u.id = i.usuario_id
    WHERE i.fecha_id = p_fecha_id
    AND i.estado = 'inscrito';

    -- ========================================
    -- CA-004: Mensaje para lista vacia se maneja en frontend
    -- Retornamos lista vacia si no hay inscritos
    -- ========================================

    -- ========================================
    -- Retorno exitoso
    -- CA-001, CA-003: Acceso y contador
    -- ========================================
    RETURN json_build_object(
        'success', true,
        'data', json_build_object(
            'fecha_id', p_fecha_id,
            'fecha_info', json_build_object(
                'fecha_formato', TO_CHAR(v_fecha.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'DD/MM/YYYY'),
                'hora_formato', TO_CHAR(v_fecha.fecha_hora_inicio AT TIME ZONE 'America/Lima', 'HH24:MI'),
                'lugar', v_fecha.lugar,
                'estado', v_fecha.estado
            ),
            'total', v_total_inscritos,
            'inscritos', v_inscritos
        ),
        'message', CASE
            WHEN v_total_inscritos = 0 THEN 'Aun no hay jugadores anotados'
            WHEN v_total_inscritos = 1 THEN '1 jugador anotado'
            ELSE v_total_inscritos || ' jugadores anotados'
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- PARTE 2: PERMISOS
-- ============================================

-- Permisos para funcion RPC
GRANT EXECUTE ON FUNCTION obtener_inscritos_fecha TO authenticated, service_role;

-- ============================================
-- PARTE 3: HABILITAR SUPABASE REALTIME
-- RN-005: Actualizacion en tiempo real
-- CA-006: Actualizacion automatica sin recargar
-- ============================================

-- Habilitar Realtime para la tabla inscripciones
-- NOTA: En Supabase Cloud, esto tambien se puede hacer desde el Dashboard:
--       Database > Replication > Seleccionar tabla 'inscripciones'
--
-- El siguiente comando agrega la tabla inscripciones a la publicacion de Realtime
-- Si ya existe en la publicacion, el comando fallara silenciosamente

DO $$
BEGIN
    -- Verificar si la publicacion supabase_realtime existe
    IF EXISTS (
        SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime'
    ) THEN
        -- Intentar agregar la tabla a la publicacion
        -- Si ya existe, el error se ignora
        BEGIN
            ALTER PUBLICATION supabase_realtime ADD TABLE inscripciones;
            RAISE NOTICE 'Tabla inscripciones agregada a supabase_realtime';
        EXCEPTION
            WHEN duplicate_object THEN
                RAISE NOTICE 'Tabla inscripciones ya esta en supabase_realtime';
        END;
    ELSE
        RAISE NOTICE 'Publicacion supabase_realtime no encontrada. Habilitar desde Dashboard.';
    END IF;
END $$;

-- ============================================
-- PARTE 4: COMENTARIOS DE DOCUMENTACION
-- ============================================

COMMENT ON FUNCTION obtener_inscritos_fecha IS 'E003-HU-003: Obtiene lista de inscritos a una fecha (RN-001 a RN-004, CA-001 a CA-006)';

-- ============================================
-- DOCUMENTACION PARA FRONTEND (Supabase Realtime)
-- ============================================
/*
GUIA PARA SUSCRIPCION REALTIME EN FRONTEND (Flutter/Dart):

1. Suscribirse a cambios en la tabla inscripciones:

   final channel = supabase.channel('inscripciones_fecha_$fechaId');

   channel.onPostgresChanges(
     event: PostgresChangeEvent.all,
     schema: 'public',
     table: 'inscripciones',
     filter: PostgresChangeFilter(
       type: PostgresChangeFilterType.eq,
       column: 'fecha_id',
       value: fechaId,
     ),
     callback: (payload) {
       // Recargar lista de inscritos cuando hay cambios
       // payload.eventType: INSERT, UPDATE, DELETE
       // payload.newRecord: nuevos datos (para INSERT/UPDATE)
       // payload.oldRecord: datos anteriores (para UPDATE/DELETE)
       _cargarInscritos();
     },
   ).subscribe();

2. Cancelar suscripcion al salir de la pantalla:

   @override
   void dispose() {
     supabase.removeChannel(channel);
     super.dispose();
   }

3. Alternativa: Pull-to-refresh manual si falla Realtime (RN-005 caso especial):

   RefreshIndicator(
     onRefresh: () => _cargarInscritos(),
     child: ListView(...),
   )

EVENTOS QUE DISPARAN ACTUALIZACION:
- INSERT: Nuevo jugador se inscribe
- UPDATE: Cambio de estado (inscrito -> cancelado)
- DELETE: Inscripcion eliminada (poco comun)

LATENCIA ESPERADA: < 5 segundos (RN-005)
*/

-- ============================================
-- FIN DEL SCRIPT
-- ============================================
