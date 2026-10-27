-- V3a. Discrepancia de nombres según país: títulos que traen el nombre
-- original entre paréntesis, por ejemplo "Nikita (La Femme Nikita)".
select pelicula_id, titulo
from {{ ref('pelicula') }}
where titulo ~ '\(.+\)'
