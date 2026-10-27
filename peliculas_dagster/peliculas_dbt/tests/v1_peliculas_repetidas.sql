-- V1. Repetidos: la misma película cargada con dos id distintos.
-- Un test de dbt "falla" si la consulta devuelve filas; cada fila es un problema.
select
    titulo,
    anio_titulo,
    fecha_estreno,
    count(*)                                         as veces,
    string_agg(pelicula_id::text, ', ' order by pelicula_id) as ids
from {{ ref('pelicula') }}
group by titulo, anio_titulo, fecha_estreno
having count(*) > 1
