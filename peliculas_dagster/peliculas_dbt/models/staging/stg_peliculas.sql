-- Limpieza de películas: tipos correctos y el título separado del año.
-- "Toy Story (1995)" -> titulo = 'Toy Story', anio_titulo = 1995
select
    id::int                                                          as pelicula_id,
    trim(regexp_replace(trim("Name"), '\s*\(\d{4}\)$', ''))          as titulo,
    substring(trim("Name") from '\((\d{4})\)$')::int                 as anio_titulo,
    nullif(trim("Release_Date"), '')::date                           as fecha_estreno,
    nullif(trim("IMDB_URL"), '')                                     as imdb_url
from {{ source('raw', 'peliculas') }}
