-- "index" y "Unnamed__0" son índices de pandas sin significado: se descartan.
select
    user_id::int        as usuario_id,
    movie_id::int       as pelicula_id,
    rating::int         as puntaje,
    "Date"::timestamp   as fecha
from {{ source('raw', 'scores') }}
