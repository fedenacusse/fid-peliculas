-- S13. Mejor votada por estacionalidad: según la estación del año en que se votó.
-- Estaciones del hemisferio norte, porque los datos son de EE.UU. (mínimo 15 votos)
with v as (
    select
        *,
        case
            when extract(month from fecha) in (12, 1, 2) then 'invierno'
            when extract(month from fecha) in (3, 4, 5)  then 'primavera'
            when extract(month from fecha) in (6, 7, 8)  then 'verano'
            else 'otoño'
        end as estacion
    from {{ ref('int_votos') }}
),
stats as (
    select
        estacion,
        titulo,
        count(*)                 as votos,
        round(avg(puntaje), 2)   as promedio
    from v
    group by estacion, pelicula_id, titulo
    having count(*) >= 15
)
select distinct on (estacion) estacion, titulo, promedio, votos
from stats
order by estacion, promedio desc, votos desc
