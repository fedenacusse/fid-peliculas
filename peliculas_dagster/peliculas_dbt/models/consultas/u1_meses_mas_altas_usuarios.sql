-- U1. Meses en que más usuarios se dieron de alta
select
    to_char(date_trunc('month', alta), 'YYYY-MM') as mes,
    count(*)                                       as usuarios_nuevos
from {{ ref('usuario') }}
group by 1
order by usuarios_nuevos desc
