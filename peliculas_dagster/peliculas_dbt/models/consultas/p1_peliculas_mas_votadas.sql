-- P1 (= S5). Películas con más votos / calificaciones
select titulo, fecha_estreno, votos, promedio
from {{ ref('int_stats_pelicula') }}
order by votos desc
limit 20
