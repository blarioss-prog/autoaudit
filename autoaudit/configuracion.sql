-- Auxiliares: obtienen (o crean) el usuario y la estación que hacen el cambio
CREATE OR REPLACE FUNCTION aud.id_usuario() RETURNS int AS $$
DECLARE v int;
BEGIN
    INSERT INTO aud.usuario (nombre) VALUES (session_user)
    ON CONFLICT (nombre) DO UPDATE SET nombre = EXCLUDED.nombre
    RETURNING id INTO v;
    RETURN v;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = aud, pg_temp;

CREATE OR REPLACE FUNCTION aud.id_estacion() RETURNS int AS $$
DECLARE
    v_ip text := COALESCE(host(inet_client_addr()), 'local');
    v int;
BEGIN
    INSERT INTO aud.estacion (ip) VALUES (v_ip)
    ON CONFLICT (ip) DO UPDATE SET ip = EXCLUDED.ip
    RETURNING id INTO v;
    RETURN v;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = aud, pg_temp;

-- El generador: crea la función y el trigger de UNA tabla según la configuración
CREATE OR REPLACE FUNCTION aud.generar_trigger(p_esquema text, p_tabla text)
RETURNS text AS $gen$
DECLARE
    v_eventos text;
    v_pk      text[];
    v_fn      text := 'tg_' || p_esquema || '_' || p_tabla;
    v_tg      text := 'trg_aud_' || p_tabla;
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = p_esquema AND table_name = p_tabla
          AND table_type = 'BASE TABLE') THEN
        RAISE EXCEPTION 'La tabla %.% no existe', p_esquema, p_tabla;
    END IF;

    SELECT string_agg(DISTINCT e.codigo, ' OR ' ORDER BY e.codigo) INTO v_eventos
    FROM aud.configuracion cf
    JOIN aud.columna c ON c.id = cf.columna_id
    JOIN aud.tabla   t ON t.id = c.tabla_id
    JOIN aud.evento  e ON e.id = cf.evento_id
    WHERE t.esquema = p_esquema AND t.nombre = p_tabla
      AND t.activa AND cf.activa;

    IF v_eventos IS NULL THEN
        EXECUTE format('DROP TRIGGER IF EXISTS %I ON %I.%I', v_tg, p_esquema, p_tabla);
        RETURN 'Sin configuración activa: trigger eliminado';
    END IF;

    SELECT array_agg(a.attname::text ORDER BY k.ord) INTO v_pk
    FROM pg_index i
    CROSS JOIN LATERAL unnest(i.indkey) WITH ORDINALITY AS k(attnum, ord)
    JOIN pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = k.attnum
    WHERE i.indrelid = format('%I.%I', p_esquema, p_tabla)::regclass
      AND i.indisprimary;
    v_pk := COALESCE(v_pk, ARRAY[]::text[]);

    EXECUTE format($f$
        CREATE OR REPLACE FUNCTION aud.%1$I() RETURNS trigger
        LANGUAGE plpgsql SECURITY DEFINER SET search_path = aud, pg_temp
        AS $b$
        DECLARE
            v_old jsonb;
            v_new jsonb;
            v_row jsonb;
            v_pk  text;
            v_usr int;
            v_est int;
        BEGIN
            IF TG_OP IN ('UPDATE','DELETE') THEN v_old := to_jsonb(OLD); END IF;
            IF TG_OP IN ('INSERT','UPDATE') THEN v_new := to_jsonb(NEW); END IF;
            v_row := COALESCE(v_new, v_old);

            SELECT string_agg(v_row ->> k, ',') INTO v_pk
            FROM unnest(%4$L::text[]) AS k;

            v_usr := aud.id_usuario();
            v_est := aud.id_estacion();

            INSERT INTO aud.bitacora
                (configuracion_id, usuario_id, estacion_id, pk_registro, valor_antiguo, valor_nuevo)
            SELECT cf.id, v_usr, v_est, v_pk, v_old ->> c.nombre, v_new ->> c.nombre
            FROM aud.configuracion cf
            JOIN aud.columna c ON c.id = cf.columna_id
            JOIN aud.tabla   t ON t.id = c.tabla_id
            JOIN aud.evento  e ON e.id = cf.evento_id
            WHERE t.esquema = %2$L AND t.nombre = %3$L
              AND t.activa AND cf.activa AND e.codigo = TG_OP
              AND (TG_OP <> 'UPDATE'
                   OR (v_old ->> c.nombre) IS DISTINCT FROM (v_new ->> c.nombre));

            RETURN NULL;
        END;
        $b$
    $f$, v_fn, p_esquema, p_tabla, v_pk);

    EXECUTE format('DROP TRIGGER IF EXISTS %I ON %I.%I', v_tg, p_esquema, p_tabla);
    EXECUTE format(
        'CREATE TRIGGER %I AFTER %s ON %I.%I FOR EACH ROW EXECUTE FUNCTION aud.%I()',
        v_tg, v_eventos, p_esquema, p_tabla, v_fn);

    RETURN 'Trigger ' || v_tg || ' creado para: ' || v_eventos;
END;
$gen$ LANGUAGE plpgsql;

-- Seguridad: nadie escribe directo en la bitácora, solo los triggers
REVOKE INSERT, UPDATE, DELETE ON aud.bitacora FROM PUBLIC;