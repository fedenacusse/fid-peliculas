-- Un voto por cada género de la película votada
-- (una película de 3 géneros cuenta en los 3).
select
    v.*,
    g.nombre as genero
from {{ ref('int_votos') }} v
join {{ ref('pelicula_genero') }} pg using (pelicula_id)
join {{ ref('genero') }} g using (genero_id)
