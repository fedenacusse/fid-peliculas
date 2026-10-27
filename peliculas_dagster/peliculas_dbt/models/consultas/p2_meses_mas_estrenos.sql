-- P2. Meses con más estrenos.
-- Ojo: muchas fechas son "AAAA-01-01" porque el dataset solo sabía el año,
-- así que enero sale inflado. La columna sin_fecha_aproximada lo descuenta.
select
    extract(month from fecha_estreno)::int                                    as mes,
    count(*)                                                                  as estrenos,
    count(*) filter (where to_char(fecha_estreno, 'MM-DD') <> '01-01')       as sin_fecha_aproximada
from {{ ref('pelicula') }}
where fecha_estreno is not null
group by 1
order by estrenos desc
