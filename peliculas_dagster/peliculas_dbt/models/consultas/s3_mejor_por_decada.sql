-- S3. Mejor película por década de estreno (mínimo 10 votos)
select distinct on (decada)
    decada,
    titulo,
    promedio,
    votos
from (
    select (extract(year from fecha_estreno)::int / 10) * 10 as decada, *
    from {{ ref('int_stats_pelicula') }}
    where fecha_estreno is not null and votos >= 10
) s
order by decada, promedio desc, votos desc
