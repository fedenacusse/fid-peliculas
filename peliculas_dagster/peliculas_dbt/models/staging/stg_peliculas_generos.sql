-- Las 19 columnas 0/1 de géneros (grupo repetitivo, viola la 1FN)
-- pasan a filas: una por cada par película-género.
select
    p.id::int as pelicula_id,
    g.genero
from {{ source('raw', 'peliculas') }} p
cross join lateral (values
    ('unknown',     p."unknown"),
    ('Action',      p."Action"),
    ('Adventure',   p."Adventure"),
    ('Animation',   p."Animation"),
    ('Children''s', p."Children_s"),
    ('Comedy',      p."Comedy"),
    ('Crime',       p."Crime"),
    ('Documentary', p."Documentary"),
    ('Drama',       p."Drama"),
    ('Fantasy',     p."Fantasy"),
    ('Film-Noir',   p."Film_Noir"),
    ('Horror',      p."Horror"),
    ('Musical',     p."Musical"),
    ('Mystery',     p."Mystery"),
    ('Romance',     p."Romance"),
    ('Sci-Fi',      p."Sci_Fi"),
    ('Thriller',    p."Thriller"),
    ('War',         p."War"),
    ('Western',     p."Western")
) as g(genero, flag)
where g.flag::int = 1
