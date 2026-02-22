| seccion  | tipo_enum          | valores                                                    |
| -------- | ------------------ | ---------------------------------------------------------- |
| ## ENUMs | color_equipo       | naranja, verde, azul, rojo, amarillo, blanco               |
| ## ENUMs | estado_fecha       | abierta, cerrada, en_juego, finalizada, cancelada          |
| ## ENUMs | estado_inscripcion | inscrito, cancelado, ausente                               |
| ## ENUMs | estado_pago        | pendiente, pagado, anulado                                 |
| ## ENUMs | estado_partido     | pendiente, en_curso, pausado, finalizado, cancelado        |
| ## ENUMs | estado_usuario     | pendiente_aprobacion, aprobado, rechazado                  |
| ## ENUMs | posicion_jugador   | arquero, defensa, mediocampista, delantero                 |
| ## ENUMs | rol_en_grupo       | admin, coadmin, jugador, invitado                          |
| ## ENUMs | rol_usuario        | admin, jugador                                             |
| ## ENUMs | tipo_notificacion  | nuevo_registro, cuenta_aprobada, cuenta_rechazada, general |

| seccion          | table_name   | column_name | constraint_name              | valores_permitidos                                                  |
| ---------------- | ------------ | ----------- | ---------------------------- | ------------------------------------------------------------------- |
| ## CHECK Constr. | sesiones_log | evento      | sesiones_log_evento_check    | login, logout, password_reset_codigo, password_reset_pregunta       |

| seccion   | table_name            | column_name                | data_type                | tipo_real          | is_nullable | column_default                         |
| --------- | --------------------- | -------------------------- | ------------------------ | ------------------ | ----------- | -------------------------------------- |
| ## Tablas | asignaciones_equipos  | id                         | uuid                     | uuid               | NO          | gen_random_uuid()                      |
| ## Tablas | asignaciones_equipos  | fecha_id                   | uuid                     | uuid               | NO          | null                                   |
| ## Tablas | asignaciones_equipos  | usuario_id                 | uuid                     | uuid               | NO          | null                                   |
| ## Tablas | asignaciones_equipos  | color_equipo               | USER-DEFINED             | color_equipo       | NO          | null                                   |
| ## Tablas | asignaciones_equipos  | created_at                 | timestamp with time zone | timestamptz        | NO          | now()                                  |
| ## Tablas | asignaciones_equipos  | updated_at                 | timestamp with time zone | timestamptz        | NO          | now()                                  |
| ## Tablas | asignaciones_equipos  | numero_equipo              | integer                  | int4               | NO          | 1                                      |
| ## Tablas | asignaciones_equipos  | asignado_por               | uuid                     | uuid               | YES         | null                                   |
| ## Tablas | asignaciones_equipos  | asignado_at                | timestamp with time zone | timestamptz        | YES         | now()                                  |
| ## Tablas | codigos_recuperacion  | id                         | uuid                     | uuid               | NO          | gen_random_uuid()                      |
| ## Tablas | codigos_recuperacion  | usuario_id                 | uuid                     | uuid               | NO          | null                                   |
| ## Tablas | codigos_recuperacion  | codigo_hash                | text                     | text               | NO          | null                                   |
| ## Tablas | codigos_recuperacion  | generado_por               | uuid                     | uuid               | YES         | null                                   |
| ## Tablas | codigos_recuperacion  | tipo                       | character varying        | varchar            | NO          | null                                   |
| ## Tablas | codigos_recuperacion  | expira_at                  | timestamp with time zone | timestamptz        | NO          | null                                   |
| ## Tablas | codigos_recuperacion  | usado                      | boolean                  | bool               | NO          | false                                  |
| ## Tablas | codigos_recuperacion  | usado_at                   | timestamp with time zone | timestamptz        | YES         | null                                   |
| ## Tablas | codigos_recuperacion  | intentos_fallidos          | integer                  | int4               | NO          | 0                                      |
| ## Tablas | codigos_recuperacion  | created_at                 | timestamp with time zone | timestamptz        | NO          | now()                                  |
| ## Tablas | fechas                | id                         | uuid                     | uuid               | NO          | gen_random_uuid()                      |
| ## Tablas | fechas                | fecha_hora_inicio          | timestamp with time zone | timestamptz        | NO          | null                                   |
| ## Tablas | fechas                | duracion_horas             | integer                  | int4               | NO          | null                                   |
| ## Tablas | fechas                | lugar                      | text                     | text               | NO          | null                                   |
| ## Tablas | fechas                | num_equipos                | integer                  | int4               | NO          | null                                   |
| ## Tablas | fechas                | costo_por_jugador          | numeric                  | numeric            | NO          | null                                   |
| ## Tablas | fechas                | estado                     | USER-DEFINED             | estado_fecha       | NO          | 'abierta'::estado_fecha                |
| ## Tablas | fechas                | created_by                 | uuid                     | uuid               | NO          | null                                   |
| ## Tablas | fechas                | created_at                 | timestamp with time zone | timestamptz        | NO          | now()                                  |
| ## Tablas | fechas                | updated_at                 | timestamp with time zone | timestamptz        | NO          | now()                                  |
| ## Tablas | fechas                | cerrado_por                | uuid                     | uuid               | YES         | null                                   |
| ## Tablas | fechas                | cerrado_at                 | timestamp with time zone | timestamptz        | YES         | null                                   |
| ## Tablas | fechas                | reabierto_por              | uuid                     | uuid               | YES         | null                                   |
| ## Tablas | fechas                | reabierto_at               | timestamp with time zone | timestamptz        | YES         | null                                   |
| ## Tablas | fechas                | finalizado_por             | uuid                     | uuid               | YES         | null                                   |
| ## Tablas | fechas                | finalizado_at              | timestamp with time zone | timestamptz        | YES         | null                                   |
| ## Tablas | fechas                | comentarios_finalizacion   | text                     | text               | YES         | null                                   |
| ## Tablas | fechas                | hubo_incidente             | boolean                  | bool               | YES         | false                                  |
| ## Tablas | fechas                | descripcion_incidente      | text                     | text               | YES         | null                                   |
| ## Tablas | fechas                | limite_jugadores           | integer                  | int4               | YES         | null                                   |
| ## Tablas | fechas                | iniciado_por               | uuid                     | uuid               | YES         | null                                   |
| ## Tablas | fechas                | iniciado_at                | timestamp with time zone | timestamptz        | YES         | null                                   |
| ## Tablas | goles                 | id                         | uuid                     | uuid               | NO          | gen_random_uuid()                      |
| ## Tablas | goles                 | partido_id                 | uuid                     | uuid               | NO          | null                                   |
| ## Tablas | goles                 | equipo_anotador            | USER-DEFINED             | color_equipo       | NO          | null                                   |
| ## Tablas | goles                 | jugador_id                 | uuid                     | uuid               | YES         | null                                   |
| ## Tablas | goles                 | minuto                     | integer                  | int4               | NO          | null                                   |
| ## Tablas | goles                 | es_autogol                 | boolean                  | bool               | NO          | false                                  |
| ## Tablas | goles                 | created_by                 | uuid                     | uuid               | NO          | null                                   |
| ## Tablas | goles                 | created_at                 | timestamp with time zone | timestamptz        | NO          | now()                                  |
| ## Tablas | goles                 | anulado                    | boolean                  | bool               | NO          | false                                  |
| ## Tablas | goles                 | anulado_at                 | timestamp with time zone | timestamptz        | YES         | null                                   |
| ## Tablas | goles                 | anulado_por                | uuid                     | uuid               | YES         | null                                   |
| ## Tablas | grupos                | id                         | uuid                     | uuid               | NO          | gen_random_uuid()                      |
| ## Tablas | grupos                | nombre                     | character varying        | varchar            | NO          | null                                   |
| ## Tablas | grupos                | logo_url                   | text                     | text               | YES         | null                                   |
| ## Tablas | grupos                | lema                       | character varying        | varchar            | YES         | null                                   |
| ## Tablas | grupos                | reglas                     | text                     | text               | YES         | null                                   |
| ## Tablas | grupos                | tipo_deporte               | character varying        | varchar            | NO          | 'Futbol'::character varying            |
| ## Tablas | grupos                | admin_creador_id           | uuid                     | uuid               | NO          | null                                   |
| ## Tablas | grupos                | plan_id                    | uuid                     | uuid               | NO          | null                                   |
| ## Tablas | grupos                | limite_jugadores           | integer                  | int4               | NO          | 25                                     |
| ## Tablas | grupos                | activo                     | boolean                  | bool               | NO          | true                                   |
| ## Tablas | grupos                | created_at                 | timestamp with time zone | timestamptz        | NO          | now()                                  |
| ## Tablas | grupos                | updated_at                 | timestamp with time zone | timestamptz        | NO          | now()                                  |
| ## Tablas | inscripciones         | id                         | uuid                     | uuid               | NO          | gen_random_uuid()                      |
| ## Tablas | inscripciones         | fecha_id                   | uuid                     | uuid               | NO          | null                                   |
| ## Tablas | inscripciones         | usuario_id                 | uuid                     | uuid               | NO          | null                                   |
| ## Tablas | inscripciones         | estado                     | USER-DEFINED             | estado_inscripcion | NO          | 'inscrito'::estado_inscripcion         |
| ## Tablas | inscripciones         | created_at                 | timestamp with time zone | timestamptz        | NO          | now()                                  |
| ## Tablas | inscripciones         | updated_at                 | timestamp with time zone | timestamptz        | NO          | now()                                  |
| ## Tablas | inscripciones         | cancelado_at               | timestamp with time zone | timestamptz        | YES         | null                                   |
| ## Tablas | inscripciones         | cancelado_por              | uuid                     | uuid               | YES         | null                                   |
| ## Tablas | inscripciones         | inscrito_por               | uuid                     | uuid               | YES         | null                                   |
| ## Tablas | inscripciones         | inscripcion_tardia         | boolean                  | bool               | NO          | false                                  |
| ## Tablas | intentos_login        | id                         | uuid                     | uuid               | NO          | gen_random_uuid()                      |
| ## Tablas | intentos_login        | email                      | character varying        | varchar            | NO          | null                                   |
| ## Tablas | intentos_login        | intentos_fallidos          | integer                  | int4               | NO          | 0                                      |
| ## Tablas | intentos_login        | bloqueado_hasta            | timestamp with time zone | timestamptz        | YES         | null                                   |
| ## Tablas | intentos_login        | ultimo_intento_at          | timestamp with time zone | timestamptz        | YES         | null                                   |
| ## Tablas | intentos_login        | created_at                 | timestamp with time zone | timestamptz        | NO          | now()                                  |
| ## Tablas | intentos_login        | updated_at                 | timestamp with time zone | timestamptz        | NO          | now()                                  |
| ## Tablas | intentos_recuperacion | id                         | uuid                     | uuid               | NO          | gen_random_uuid()                      |
| ## Tablas | intentos_recuperacion | celular                    | character varying        | varchar            | NO          | null                                   |
| ## Tablas | intentos_recuperacion | intentos_fallidos          | integer                  | int4               | NO          | 0                                      |
| ## Tablas | intentos_recuperacion | bloqueado_hasta            | timestamp with time zone | timestamptz        | YES         | null                                   |
| ## Tablas | intentos_recuperacion | ultimo_intento_at          | timestamp with time zone | timestamptz        | YES         | null                                   |
| ## Tablas | intentos_recuperacion | created_at                 | timestamp with time zone | timestamptz        | NO          | now()                                  |
| ## Tablas | intentos_recuperacion | updated_at                 | timestamp with time zone | timestamptz        | NO          | now()                                  |
| ## Tablas | miembros_grupo        | id                         | uuid                     | uuid               | NO          | gen_random_uuid()                      |
| ## Tablas | miembros_grupo        | grupo_id                   | uuid                     | uuid               | NO          | null                                   |
| ## Tablas | miembros_grupo        | usuario_id                 | uuid                     | uuid               | NO          | null                                   |
| ## Tablas | miembros_grupo        | rol                        | USER-DEFINED             | rol_en_grupo       | NO          | 'jugador'::rol_en_grupo                |
| ## Tablas | miembros_grupo        | activo                     | boolean                  | bool               | NO          | true                                   |
| ## Tablas | miembros_grupo        | created_at                 | timestamp with time zone | timestamptz        | NO          | now()                                  |
| ## Tablas | miembros_grupo        | updated_at                 | timestamp with time zone | timestamptz        | NO          | now()                                  |
| ## Tablas | miembros_grupo        | ultimo_acceso              | timestamp with time zone | timestamptz        | YES         | null                                   |
| ## Tablas | notificaciones        | id                         | uuid                     | uuid               | NO          | gen_random_uuid()                      |
| ## Tablas | notificaciones        | usuario_id                 | uuid                     | uuid               | NO          | null                                   |
| ## Tablas | notificaciones        | tipo                       | USER-DEFINED             | tipo_notificacion  | NO          | 'general'::tipo_notificacion           |
| ## Tablas | notificaciones        | titulo                     | character varying        | varchar            | NO          | null                                   |
| ## Tablas | notificaciones        | mensaje                    | text                     | text               | NO          | null                                   |
| ## Tablas | notificaciones        | metadata                   | jsonb                    | jsonb              | YES         | '{}'::jsonb                            |
| ## Tablas | notificaciones        | leida                      | boolean                  | bool               | NO          | false                                  |
| ## Tablas | notificaciones        | created_at                 | timestamp with time zone | timestamptz        | NO          | now()                                  |
| ## Tablas | pagos                 | id                         | uuid                     | uuid               | NO          | gen_random_uuid()                      |
| ## Tablas | pagos                 | inscripcion_id             | uuid                     | uuid               | NO          | null                                   |
| ## Tablas | pagos                 | usuario_id                 | uuid                     | uuid               | NO          | null                                   |
| ## Tablas | pagos                 | fecha_id                   | uuid                     | uuid               | NO          | null                                   |
| ## Tablas | pagos                 | monto                      | numeric                  | numeric            | NO          | null                                   |
| ## Tablas | pagos                 | estado                     | USER-DEFINED             | estado_pago        | NO          | 'pendiente'::estado_pago               |
| ## Tablas | pagos                 | fecha_pago                 | timestamp with time zone | timestamptz        | YES         | null                                   |
| ## Tablas | pagos                 | registrado_por             | uuid                     | uuid               | YES         | null                                   |
| ## Tablas | pagos                 | notas                      | text                     | text               | YES         | null                                   |
| ## Tablas | pagos                 | created_at                 | timestamp with time zone | timestamptz        | NO          | now()                                  |
| ## Tablas | pagos                 | updated_at                 | timestamp with time zone | timestamptz        | NO          | now()                                  |
| ## Tablas | partidos              | id                         | uuid                     | uuid               | NO          | gen_random_uuid()                      |
| ## Tablas | partidos              | fecha_id                   | uuid                     | uuid               | NO          | null                                   |
| ## Tablas | partidos              | equipo_local               | USER-DEFINED             | color_equipo       | NO          | null                                   |
| ## Tablas | partidos              | equipo_visitante           | USER-DEFINED             | color_equipo       | NO          | null                                   |
| ## Tablas | partidos              | duracion_minutos           | integer                  | int4               | NO          | null                                   |
| ## Tablas | partidos              | estado                     | USER-DEFINED             | estado_partido     | NO          | 'pendiente'::estado_partido            |
| ## Tablas | partidos              | hora_inicio                | timestamp with time zone | timestamptz        | YES         | null                                   |
| ## Tablas | partidos              | hora_fin_estimada          | timestamp with time zone | timestamptz        | YES         | null                                   |
| ## Tablas | partidos              | tiempo_pausado_segundos    | integer                  | int4               | NO          | 0                                      |
| ## Tablas | partidos              | pausado_at                 | timestamp with time zone | timestamptz        | YES         | null                                   |
| ## Tablas | partidos              | created_by                 | uuid                     | uuid               | NO          | null                                   |
| ## Tablas | partidos              | created_at                 | timestamp with time zone | timestamptz        | NO          | now()                                  |
| ## Tablas | partidos              | updated_at                 | timestamp with time zone | timestamptz        | NO          | now()                                  |
| ## Tablas | partidos              | goles_local                | integer                  | int4               | NO          | 0                                      |
| ## Tablas | partidos              | goles_visitante            | integer                  | int4               | NO          | 0                                      |
| ## Tablas | planes                | id                         | uuid                     | uuid               | NO          | gen_random_uuid()                      |
| ## Tablas | planes                | nombre                     | character varying        | varchar            | NO          | null                                   |
| ## Tablas | planes                | slug                       | character varying        | varchar            | NO          | null                                   |
| ## Tablas | planes                | precio_mensual             | numeric                  | numeric            | NO          | 0                                      |
| ## Tablas | planes                | max_grupos_por_admin       | integer                  | int4               | NO          | null                                   |
| ## Tablas | planes                | max_jugadores_por_grupo    | integer                  | int4               | NO          | null                                   |
| ## Tablas | planes                | max_invitados_por_grupo    | integer                  | int4               | NO          | null                                   |
| ## Tablas | planes                | max_coadmins_por_grupo     | integer                  | int4               | NO          | null                                   |
| ## Tablas | planes                | max_equipos_por_fecha      | integer                  | int4               | NO          | null                                   |
| ## Tablas | planes                | max_tamano_logo_mb         | integer                  | int4               | NO          | 2                                      |
| ## Tablas | planes                | estadisticas_avanzadas     | boolean                  | bool               | NO          | false                                  |
| ## Tablas | planes                | temas_personalizados_grupo | boolean                  | bool               | NO          | false                                  |
| ## Tablas | planes                | activo                     | boolean                  | bool               | NO          | true                                   |
| ## Tablas | planes                | orden                      | integer                  | int4               | NO          | 0                                      |
| ## Tablas | planes                | created_at                 | timestamp with time zone | timestamptz        | NO          | now()                                  |
| ## Tablas | planes                | updated_at                 | timestamp with time zone | timestamptz        | NO          | now()                                  |
| ## Tablas | sesiones_log          | id                         | uuid                     | uuid               | NO          | gen_random_uuid()                      |
| ## Tablas | sesiones_log          | usuario_id                 | uuid                     | uuid               | NO          | null                                   |
| ## Tablas | sesiones_log          | auth_user_id               | uuid                     | uuid               | NO          | null                                   |
| ## Tablas | sesiones_log          | evento                     | character varying        | varchar(50)        | NO          | null                                   |
| ## Tablas | sesiones_log          | ip_address                 | inet                     | inet               | YES         | null                                   |
| ## Tablas | sesiones_log          | user_agent                 | text                     | text               | YES         | null                                   |
| ## Tablas | sesiones_log          | fecha_evento               | timestamp with time zone | timestamptz        | NO          | now()                                  |
| ## Tablas | sesiones_log          | created_at                 | timestamp with time zone | timestamptz        | NO          | now()                                  |
| ## Tablas | tokens_recuperacion   | id                         | uuid                     | uuid               | NO          | gen_random_uuid()                      |
| ## Tablas | tokens_recuperacion   | usuario_id                 | uuid                     | uuid               | NO          | null                                   |
| ## Tablas | tokens_recuperacion   | token_hash                 | text                     | text               | NO          | null                                   |
| ## Tablas | tokens_recuperacion   | expira_at                  | timestamp with time zone | timestamptz        | NO          | null                                   |
| ## Tablas | tokens_recuperacion   | usado                      | boolean                  | bool               | NO          | false                                  |
| ## Tablas | tokens_recuperacion   | usado_at                   | timestamp with time zone | timestamptz        | YES         | null                                   |
| ## Tablas | tokens_recuperacion   | created_at                 | timestamp with time zone | timestamptz        | NO          | now()                                  |
| ## Tablas | usuarios              | id                         | uuid                     | uuid               | NO          | gen_random_uuid()                      |
| ## Tablas | usuarios              | auth_user_id               | uuid                     | uuid               | YES         | null                                   |
| ## Tablas | usuarios              | nombre_completo            | character varying        | varchar            | NO          | null                                   |
| ## Tablas | usuarios              | email                      | character varying        | varchar            | NO          | null                                   |
| ## Tablas | usuarios              | estado                     | USER-DEFINED             | estado_usuario     | NO          | 'pendiente_aprobacion'::estado_usuario |
| ## Tablas | usuarios              | rol                        | USER-DEFINED             | rol_usuario        | NO          | 'jugador'::rol_usuario                 |
| ## Tablas | usuarios              | motivo_rechazo             | text                     | text               | YES         | null                                   |
| ## Tablas | usuarios              | aprobado_por               | uuid                     | uuid               | YES         | null                                   |
| ## Tablas | usuarios              | aprobado_rechazado_at      | timestamp with time zone | timestamptz        | YES         | null                                   |
| ## Tablas | usuarios              | created_at                 | timestamp with time zone | timestamptz        | NO          | now()                                  |
| ## Tablas | usuarios              | updated_at                 | timestamp with time zone | timestamptz        | NO          | now()                                  |
| ## Tablas | usuarios              | apodo                      | character varying        | varchar            | YES         | null                                   |
| ## Tablas | usuarios              | telefono                   | character varying        | varchar            | YES         | null                                   |
| ## Tablas | usuarios              | posicion_preferida         | USER-DEFINED             | posicion_jugador   | YES         | null                                   |
| ## Tablas | usuarios              | foto_url                   | text                     | text               | YES         | null                                   |
| ## Tablas | usuarios              | celular                    | character varying        | varchar            | YES         | null                                   |
| ## Tablas | usuarios              | pregunta_seguridad         | text                     | text               | YES         | null                                   |
| ## Tablas | usuarios              | respuesta_seguridad        | text                     | text               | YES         | null                                   |
| ## Tablas | usuarios              | email_respaldo             | character varying        | varchar            | YES         | null                                   |
| ## Tablas | usuarios              | plan_id                    | uuid                     | uuid               | YES         | null                                   |