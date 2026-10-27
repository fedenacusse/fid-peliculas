-- V3b. El año que figura en el título no coincide con el de la fecha de estreno
-- (suelen ser reestrenos, como "Taxi Driver (1976)" estrenada en 1996).
select
    pelicula_id,
    titulo,
    anio_titulo,
    fecha_estreno
from {{ ref('pelicula') }}
where anio_titulo <> extract(year from fecha_estreno)
