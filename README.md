# Pipeline de datos de películas

Trabajo de **Fundamentos de Ingeniería de Datos** (UTN-FRT, 2026).
Pipeline completo de ingesta, transformación, orquestación y observabilidad sobre el dataset
[dodobeatle/dataeng_peliculas](https://github.com/dodobeatle/dataeng_peliculas).

~~
GitHub (CSV) ──Airbyte──► Postgres (raw) ──dbt──► staging ► normalizado (3FN) ► consultas
                              │                └──────── orquestado por Dagster ────────┘
                              └──► Alloy ──► Prometheus ──► Grafana      (logs: Dozzle)
~~

## Stack

| Herramienta | Rol |
|---|---|
| **Airbyte** | Ingesta de los 3 CSV a `peliculas.raw` (Full refresh, Overwrite) |
| **PostgreSQL 16** | Almacenamiento (contenedor Docker) |
| **dbt** | Normalización a 3FN, 20 consultas analíticas y validaciones de calidad |
| **Dagster** | Orquestación: sincroniza Airbyte y después corre `dbt build`; schedule diario |
| **Grafana Alloy** | Recolección de métricas de Postgres (reemplaza a postgres_exporter) |
| **Prometheus + Grafana** | Almacenamiento y visualización de métricas |
| **Dozzle** | Logs centralizados de los contenedores |

## Estructura

- `peliculas_dagster/definitions.py`: assets de Airbyte y dbt, job y schedule.
- `peliculas_dagster/peliculas_dbt/`: proyecto dbt (ver su README).
  - `models/staging`: limpieza y tipos.
  - `models/normalizado`: modelo en 3FN (`pelicula`, `genero`, `pelicula_genero`, `usuario`, `ocupacion`, `calificacion`).
  - `models/consultas`: consultas U1–U3, P1–P5 y S1–S13.
  - `tests/`: validaciones (repetidos, nulos, nombres, fechas).
- `monitoreo/`: docker-compose de Alloy, Prometheus, Grafana y Dozzle.

## Cómo correrlo

~~bash
# Monitoreo
cd monitoreo && docker compose up -d
# Grafana: http://localhost:3001 · Alloy: http://localhost:12345 · Dozzle: http://localhost:8888

# Orquestación (requiere un .env con las credenciales de Airbyte)
conda activate fid
cd peliculas_dagster && ./iniciar_dagster.sh
# Dagster: http://localhost:3000
~~

> Las credenciales que aparecen en los archivos son de un entorno local de desarrollo.
