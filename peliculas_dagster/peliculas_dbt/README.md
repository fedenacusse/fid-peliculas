# peliculas_dbt

Proyecto dbt de Fundamentos de Ingeniería de Datos (UTN-FRT).
Dataset: [dodobeatle/dataeng_peliculas](https://github.com/dodobeatle/dataeng_peliculas).

## Flujo

```
GitHub (CSV) ──Airbyte──► peliculas.raw ──dbt──► staging ► normalizado (3FN) ► intermedio ► consultas
```

| Schema | Qué tiene | Materialización |
|---|---|---|
| `raw` | Tablas tal cual las carga Airbyte | (no lo toca dbt) |
| `staging` | Tipos limpios, título separado del año, géneros pasados a filas | vistas |
| `normalizado` | Modelo en 3FN: `ocupacion`, `usuario`, `pelicula`, `genero`, `pelicula_genero`, `calificacion` | tablas |
| `intermedio` | Joins reutilizables (`int_votos`, `int_votos_genero`, `int_stats_pelicula`) | vistas |
| `consultas` | Las consultas del pizarrón (U1–U3, P1–P5, S1–S13) | vistas |

## Normalización (de raw a 3FN)

- Las 19 columnas 0/1 de géneros eran un grupo repetitivo (no cumple 1FN) → `genero` + `pelicula_genero`.
- `Name` mezclaba título y año ("Toy Story (1995)") → `titulo` + `anio_titulo`.
- La ocupación se repetía como texto en cada usuario → tabla `ocupacion`.
- `index` y `Unnamed__0` son índices de pandas → se descartan.
- La integridad referencial se verifica con tests de dbt (`unique`, `not_null`, `relationships`).

## Validaciones (carpeta `tests/`)

Tests singulares con severidad `warn`: avisan pero no frenan el pipeline.

| Test | Qué detecta |
|---|---|
| `v1_peliculas_repetidas` | Misma película con dos id |
| `v2_peliculas_con_nulos` | Películas sin fecha, URL o año |
| `v3_titulos_con_nombre_original` | Títulos con el nombre original del país entre paréntesis |
| `v3_anio_titulo_distinto_estreno` | Año del título distinto al de estreno |
| `v4_votos_antes_del_estreno` | Votos anteriores al estreno |
| `v4_votos_antes_del_alta` | Votos anteriores al alta del usuario |
| `v5_ocupaciones_sospechosas` | Ocupaciones como "itba", "none", "other" |

## Uso

```bash
conda activate fid
cd ~/tpch_project/peliculas_dbt
dbt debug     # prueba la conexión
dbt build     # corre modelos + tests en orden
dbt docs generate && dbt docs serve --port 8081   # documentación y grafo de linaje
```
