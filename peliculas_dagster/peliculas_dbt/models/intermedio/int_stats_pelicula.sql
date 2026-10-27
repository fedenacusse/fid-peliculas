-- Cantidad de votos y promedio por película (solo las que tienen votos).
select
    pelicula_id,
    titulo,
    fecha_estreno,
    count(*)                 as votos,
    round(avg(puntaje), 2)   as promedio
from {{ ref('int_votos') }}
group by pelicula_id, titulo, fecha_estreno
