-- S12. Películas antiguas (antes de 1970) mejor votadas, mínimo 20 votos
select titulo, fecha_estreno, votos, promedio
from {{ ref('int_stats_pelicula') }}
where fecha_estreno < date '1970-01-01'
  and votos >= 20
order by promedio desc, votos desc
limit 20
