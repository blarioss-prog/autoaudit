DROP SCHEMA IF EXISTS aud CASCADE;
CREATE SCHEMA aud;

CREATE TABLE aud.evento (
    id     SMALLINT PRIMARY KEY,
    codigo TEXT NOT NULL UNIQUE
);
INSERT INTO aud.evento VALUES (1,'INSERT'), (2,'UPDATE'), (3,'DELETE');
CREATE TABLE aud.tabla (
    id      SERIAL PRIMARY KEY,
    esquema TEXT NOT NULL,
    nombre  TEXT NOT NULL,
    activa  BOOLEAN NOT NULL DEFAULT TRUE,
    UNIQUE (esquema, nombre)
);

CREATE TABLE aud.columna (
    id       SERIAL PRIMARY KEY,
    tabla_id INT NOT NULL REFERENCES aud.tabla(id),
    nombre   TEXT NOT NULL,
    UNIQUE (tabla_id, nombre)
);

CREATE TABLE aud.configuracion (
    id         SERIAL PRIMARY KEY,
    columna_id INT NOT NULL REFERENCES aud.columna(id),
    evento_id  SMALLINT NOT NULL REFERENCES aud.evento(id),
    activa     BOOLEAN NOT NULL DEFAULT TRUE,
    UNIQUE (columna_id, evento_id)
);

CREATE TABLE aud.usuario (
    id     SERIAL PRIMARY KEY,
    nombre TEXT NOT NULL UNIQUE
);

CREATE TABLE aud.estacion (
    id SERIAL PRIMARY KEY,
    ip TEXT NOT NULL UNIQUE
);

CREATE TABLE aud.bitacora (
    id               BIGSERIAL PRIMARY KEY,
    configuracion_id INT NOT NULL REFERENCES aud.configuracion(id),
    usuario_id       INT NOT NULL REFERENCES aud.usuario(id),
    estacion_id      INT NOT NULL REFERENCES aud.estacion(id),
    fecha_hora       TIMESTAMPTZ NOT NULL DEFAULT now(),
    pk_registro      TEXT,
    valor_antiguo    TEXT,
    valor_nuevo      TEXT
);

CREATE INDEX ix_bitacora_usuario ON aud.bitacora (usuario_id, fecha_hora);
CREATE INDEX ix_bitacora_config  ON aud.bitacora (configuracion_id, fecha_hora);