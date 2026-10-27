select
    pelicula_id,
    titulo,
    anio_titulo,
    fecha_estreno,
    imdb_url
from {{ ref('stg_peliculas') }}
