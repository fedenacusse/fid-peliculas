-- V2. Nulos: películas sin fecha de estreno, sin URL o sin año en el título
select
    pelicula_id,
    titulo,
    fecha_estreno,
    imdb_url,
    anio_titulo
from {{ ref('pelicula') }}
where fecha_estreno is null
   or imdb_url is null
   or anio_titulo is null
