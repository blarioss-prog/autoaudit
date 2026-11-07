-- 1. Tablas existentes (candidatas a auditar)
SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_type = 'BASE TABLE'
  AND table_schema NOT IN ('pg_catalog', 'information_schema', 'aud')
ORDER BY table_schema, table_name;

-- 2. Columnas de una tabla (cambia el nombre de la tabla)
SELECT column_name, data_type, is_nullable, ordinal_position
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'cliente'
ORDER BY ordinal_position;

-- 3. Diccionario de datos completo del sistema de auditoría
SELECT table_name AS tabla, ordinal_position AS pos, column_name AS columna,
       data_type AS tipo, is_nullable AS acepta_nulos, column_default AS valor_defecto
FROM information_schema.columns
WHERE table_schema = 'aud'
ORDER BY table_name, ordinal_position;