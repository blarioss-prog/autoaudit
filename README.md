# AutoAudit – Sistema de auditoría automatizado

Proyecto del curso de Bases de Datos – Universidad Mariano Gálvez de Guatemala.

AutoAudit es un sistema de auditoría configurable para PostgreSQL. El administrador elige qué tablas, columnas y eventos (INSERT, UPDATE, DELETE) se auditan, y el sistema **genera automáticamente los triggers** que registran cada cambio en una bitácora central, con valor antiguo, valor nuevo, usuario, IP y fecha y hora.

## Características

- Configuración por tabla, columna y tipo de operación.
- Validación de que tablas y columnas existen (vía `information_schema`) antes de activar.
- Generación dinámica de triggers `AFTER`, uno por tabla origen.
- Bitácora central que conserva los datos aunque el registro original se elimine.
- Consultas de historial por usuario y por columna.
- Escritura en la bitácora restringida a los triggers.

## Requisitos

- PostgreSQL (probado en 16.15; el enunciado pide 18)
- Ubuntu
- Cliente SQL: DBeaver o `psql`

## Contenido del repositorio

| Archivo | Descripción |
|---|---|
| `01_tablas.sql` | Esquema `aud` y las 7 tablas del sistema |
| `02_diccionario.sql` | Consultas al diccionario de datos |
| `03_configuracion.sql` | Función `aud.configurar` y tabla de práctica |
| `04_generador_triggers.sql` | Generador dinámico de triggers |
| `05_consultas.sql` | Consultas de historial por usuario y columna |
| `06_pruebas.sql` | Casos de prueba y prueba de rendimiento |

## Instalación

```bash
sudo apt update
sudo apt install -y postgresql postgresql-contrib
sudo -u postgres psql -c "CREATE DATABASE autoaudit;"
```

Ejecuta los scripts en orden sobre la base `autoaudit`:

```bash
sudo -u postgres psql -d autoaudit -f 01_tablas.sql
sudo -u postgres psql -d autoaudit -f 03_configuracion.sql
sudo -u postgres psql -d autoaudit -f 04_generador_triggers.sql
sudo -u postgres psql -d autoaudit -f 05_consultas.sql
```

## Uso rápido

```sql
-- 1. Configurar qué auditar
SELECT aud.configurar('public', 'cliente',
       ARRAY['nombre','telefono'],
       ARRAY['INSERT','UPDATE','DELETE']);

-- 2. Generar el trigger
SELECT aud.generar_trigger('public', 'cliente');

-- 3. Consultar el historial
SELECT * FROM aud.historial_usuario('postgres');
SELECT * FROM aud.historial_columna('public', 'cliente', 'telefono');
```

Después de cambiar la configuración de una tabla, vuelve a ejecutar `aud.generar_trigger()`.

## Modelo de datos

Esquema `aud`: `evento`, `tabla`, `columna`, `configuracion`, `usuario`, `estacion` y `bitacora`.
Diagrama y diccionario de datos completos en el manual técnico.

## Pruebas

`06_pruebas.sql` incluye casos para INSERT, UPDATE (valor antiguo y nuevo), DELETE (datos conservados en la bitácora) y una prueba de rendimiento con volumen creciente.

## Autor
BREYNER ORLANDO LARIOS SERECH     CARNET: 1990-23-1411
