-- S11. Meses en que más se votó
select
    to_char(date_trunc('month', fecha), 'YYYY-MM') as mes,
    count(*)                                        as votos
from {{ ref('calificacion') }}
group by 1
order by votos desc
