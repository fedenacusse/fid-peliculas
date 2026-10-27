select
    row_number() over (order by genero)::int as genero_id,
    genero                                    as nombre
from (select distinct genero from {{ ref('stg_peliculas_generos') }}) g
