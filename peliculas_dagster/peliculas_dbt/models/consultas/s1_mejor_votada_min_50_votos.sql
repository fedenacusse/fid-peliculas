-- S1. Mejor votada con al menos 50 votos
select titulo, votos, promedio
from {{ ref('int_stats_pelicula') }}
where votos >= 50
order by promedio desc, votos desc
limit 20
