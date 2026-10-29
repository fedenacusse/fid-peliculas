# Guía del stack de datos de películas

Airbyte trae los CSV de películas a Postgres, dbt los limpia, normaliza y arma las consultas, y Dagster ordena todo con un botón; Alloy, Prometheus y Grafana vigilan la base, y Dozzle junta los logs.

## Cómo encajan las piezas

~~~
                ┌──────────────────────── Dagster · orquestador ───────────────────────┐
                │   Materialize all o schedule de las 8:00: primero Airbyte, después dbt │
                └──────────┬──────────────────────────────────────────────┬────────────┘
                     1. sincroniza                                   2. dbt build
                           ▼                                              ▼
┌───────────────┐   ┌───────────────┐   ┌──────────────────┐   ┌──────────────────┐
│ GitHub        │──►│ Airbyte       │──►│ PostgreSQL       │◄─►│ dbt              │
│ 3 CSV del     │   │ copia los CSV │   │ base peliculas:  │   │ lee raw, escribe │
│ profe         │   │ a raw         │   │ raw, staging,    │   │ las otras capas  │
└───────────────┘   │ (Overwrite)   │   │ normalizado,     │   │ y corre tests    │
                    └───────────────┘   │ intermedio,      │   └──────────────────┘
                                        │ consultas        │
                                        └────────┬─────────┘
                                                 │ métricas
┌─ Monitoreo (contenedores fid-, red monitoreo) ─▼──────────────────────────────────────┐
│  Grafana Alloy ──► Prometheus ──► Grafana (dashboard 9628)        Dozzle (logs)       │
└───────────────────────────────────────────────────────────────────────────────────────┘
~~~

Se lee de izquierda a derecha y de arriba abajo: Dagster dispara primero a Airbyte, que copia los CSV a `raw`, y después a dbt, que construye las otras capas dentro de la misma base. Por debajo, Alloy lee las estadísticas de Postgres y las pasa a Prometheus, que es lo que dibuja Grafana.

## Las piezas de un vistazo

Todo corre en la notebook con Fedora y **nada arranca solo al prenderla**: el stack entero se levanta con `~/tpch_project/levantar.sh` y se apaga con `~/tpch_project/apagar.sh`. Desde la notebook, las direcciones son `localhost`; desde la PC de casa, cambiás `localhost` por `192.168.1.6`.

| Herramienta | Función en el stack | Dónde corre | Dirección | Usuario / contraseña | Cómo arranca |
| --- | --- | --- | --- | --- | --- |
| PostgreSQL 16 | Guarda los datos: bases `tpch` y `peliculas` | Contenedor `postgres-tpch` | `localhost:5432` | `admin` / `password123` | `levantar.sh` |
| Airbyte | Ingesta: copia los 3 CSV de GitHub a `peliculas.raw` | Kubernetes local (abctl), contenedor `airbyte-abctl-control-plane` | `http://localhost:8000` | `admin@admin.com` / `password123` | `levantar.sh` |
| dbt | Transformación: limpia, normaliza a 3FN, arma las consultas y valida | Programa de Python en el entorno `fid` | Sin interfaz (documentación con `dbt docs serve`) | Usa `profiles.yml` | Lo ejecuta Dagster |
| Dagster | Orquestación: corre Airbyte y después dbt, en orden, con historial y schedule | Programa de Python en el entorno `fid` | `http://localhost:3000` | Sin login | `levantar.sh` (al final, en primer plano) |
| Grafana Alloy | Recolecta métricas de Postgres y las manda a Prometheus | Contenedor `fid-alloy` | `http://localhost:12345` | Sin login | `levantar.sh` |
| Prometheus | Guarda las métricas como series de tiempo | Contenedor `fid-prometheus` | `http://localhost:9090` | Sin login | `levantar.sh` |
| Grafana | Muestra las métricas en dashboards | Contenedor `fid-grafana` | `http://localhost:3001` | `admin` / `admin` | `levantar.sh` |
| Dozzle | Junta los logs de todos los contenedores | Contenedor `fid-dozzle` | `http://localhost:8888` | Sin login | `levantar.sh` |

Las carpetas: el proyecto vive en `~/tpch_project`. Dagster y dbt están en `peliculas_dagster/` (dbt adentro, en `peliculas_dbt/`) y el monitoreo en `monitoreo/`. El código está en [github.com/fedenacusse/fid-peliculas](https://github.com/fedenacusse/fid-peliculas).

## Cada herramienta en detalle

### PostgreSQL: el almacén

Es la base de datos donde termina todo. Tiene dos bases: `tpch` (el benchmark OLTP vs OLAP) y `peliculas` (este proyecto). Dentro de `peliculas` hay un schema por capa: `raw`, `staging`, `normalizado`, `intermedio` y `consultas`.

- Se relaciona con: Airbyte escribe en `raw`, dbt lee y escribe las otras capas, Alloy lee sus estadísticas.
- Está en dos redes de Docker: `kind` (para que Airbyte la encuentre por el nombre `postgres-tpch`) y `monitoreo` (para que la encuentre Alloy).
- Entrar a la consola: `docker exec -it postgres-tpch psql -U admin -d peliculas` (salir con `\q`).

### Airbyte: la ingesta

Copia datos de un origen a un destino sin escribir código. Acá tiene 3 orígenes (los CSV `peliculas`, `usuarios` y `scores` del repo del profe, por HTTPS) y 1 destino (`Postgres peliculas`, schema `raw`).

- Cada conexión usa Full refresh | Overwrite: en cada sincronización borra la tabla y la vuelve a cargar entera. Por eso es idempotente: correrla 10 veces da lo mismo que una.
- Le agrega a cada tabla columnas propias que empiezan con `_airbyte_` y renombra las columnas con espacios o símbolos (`Release Date` pasa a `Release_Date`).
- Corre sobre un Kubernetes chiquito que instaló `abctl`; cada sincronización levanta su propio pod (`replication-job-...`).
- El schedule de las conexiones está en Manual: quien las dispara es Dagster.
- Credenciales: `abctl local credentials`.

### dbt: la transformación

Convierte archivos SQL en tablas y vistas, en el orden correcto. Cada modelo es un `SELECT`; dbt decide el orden leyendo los `ref()` y arma el grafo de linaje.

- `staging` (tablas): tipos limpios, el título separado del año, los 19 géneros pasados de columnas a filas.
- `normalizado` (tablas): el modelo en 3FN con `pelicula`, `genero`, `pelicula_genero`, `usuario`, `ocupacion` y `calificacion`.
- `intermedio` (vistas): uniones que reutilizan varias consultas, como `int_votos` y `int_stats_pelicula`.
- `consultas` (vistas): las 20 consultas del pizarrón (U1–U3, P1–P5 y S1–S13; S5 es la misma que P1).
- `tests/`: las validaciones del pizarrón. Están en `warn`: avisan pero no frenan, porque los problemas del dataset son reales y queremos verlos.
- Comandos (con `conda activate fid`, desde `peliculas_dagster/peliculas_dbt`): `dbt debug` prueba la conexión, `dbt build` corre todo, `dbt docs generate` y `dbt docs serve --port 8081` muestran la documentación y el grafo.

### Dagster: el orquestador

Decide qué se ejecuta, en qué orden y cuándo, y guarda qué pasó. Trabaja con assets (datos que existen): cada tabla de Airbyte y cada modelo de dbt es un asset, y sus dependencias forman el grafo de Lineage.

- Grupo `ingesta`: las 3 tablas `raw`. Al materializarlas, Dagster le pide a Airbyte que sincronice y espera a que termine.
- Grupo `default`: los 33 modelos de dbt. Al materializarlos corre `dbt build`; los tests aparecen como checks.
- Materialize all corre primero Airbyte y después dbt, porque dbt depende de `raw`.
- Tiene un schedule diario a las 8:00 (hora argentina) en Automation; viene apagado y se prende con el switch.
- Las credenciales de Airbyte están en `peliculas_dagster/.env` (no se sube a GitHub). El historial queda en `peliculas_dagster/.dagster_home`.
- Iniciar: lo hace `levantar.sh` al final (por dentro activa `fid` y corre `peliculas_dagster/iniciar_dagster.sh`). Detener: Ctrl+C en esa terminal, o `pkill -f dagster` desde otra.

### Grafana Alloy: el recolector

Es un agente que junta telemetría y la reenvía. Su configuración (`monitoreo/config.alloy`) tiene 3 componentes encadenados:

1. `prometheus.exporter.postgres`: se conecta a Postgres y lee sus estadísticas. Reemplaza al contenedor viejo `postgres-exporter`.
2. `prometheus.scrape`: cada 15 segundos toma esas métricas.
3. `prometheus.remote_write`: las envía a Prometheus.

En `http://localhost:12345` se ve cada componente con su estado (Healthy) y el grafo que los une.

### Prometheus: la base de métricas

Guarda las métricas como series de tiempo (un valor por momento). Acá no sale a buscarlas: las recibe de Alloy, por eso arranca con la opción `--web.enable-remote-write-receiver`. Para probar si hay datos: en `http://localhost:9090` consultá `pg_up` (1 = Postgres arriba).

### Grafana: los tableros

Dibuja lo que guarda Prometheus. El datasource Prometheus se carga solo desde `monitoreo/grafana/datasources.yml`. El tablero es el 9628, PostgreSQL Database: arriba elegís Instance y Database `peliculas`, y en Database Stats se ven transacciones, inserts, deletes y lecturas. Los paneles de CPU y memoria quedan en No data porque medían el proceso del exporter, que ahora vive dentro de Alloy.

### Dozzle: los logs

Muestra en una sola página los logs en vivo de todos los contenedores, con su CPU y memoria. Sirve para ver qué dice un contenedor cuando algo falla, sin tipear `docker logs`. Lee Docker a través de `/var/run/docker.sock`.

### El monitoreo en conjunto

Los 4 contenedores `fid-...` se definen en `monitoreo/docker-compose.yml`, comparten la red `monitoreo` y tienen `restart: "no"`, así que no arrancan solos. Los levanta `levantar.sh`; a mano: `cd ~/tpch_project/monitoreo && docker compose up -d` y `docker compose stop`.

## La rutina

Nada del stack arranca al prender la notebook, así que no consume recursos cuando la usás para otra cosa. Dos scripts hacen todo:

| Script | Qué hace |
| --- | --- |
| `~/tpch_project/levantar.sh` | Prende Postgres, Airbyte y el monitoreo, espera a que Airbyte esté listo y deja Dagster corriendo en esa terminal |
| `~/tpch_project/apagar.sh` | Corta Dagster y apaga el monitoreo, Airbyte y Postgres. Los datos quedan guardados |

**Al llegar a la facultad (en la terminal de la notebook):**

1. `~/tpch_project/levantar.sh` y esperá "Serving dagster-webserver" (Airbyte tarda 1 a 3 minutos). Esa terminal queda ocupada con Dagster.
2. Abrí en el navegador lo que necesites: Dagster `localhost:3000`, Airbyte `localhost:8000`, Grafana `localhost:3001`, Dozzle `localhost:8888`.
3. Para correr el pipeline completo: Dagster, Lineage, Materialize all.

**Al terminar:**

1. Ctrl+C en la terminal de Dagster.
2. `~/tpch_project/apagar.sh` (en esa misma terminal o en otra). Si te olvidás, al apagar la notebook se cierra todo igual y la próxima vez no arranca solo.

**Para ver qué está prendido:** `docker ps --format "table {{.Names}}\t{{.Status}}"`.

**Desde la PC de casa (por SSH):**

- Ventana A, Dagster y túnel: `ssh -L 8000:localhost:8000 fedenacusse@192.168.1.6`, después `~/tpch_project/levantar.sh`. No se cierra.
- Ventana B, comandos: `ssh fedenacusse@192.168.1.6`.
- En el navegador de la PC, `192.168.1.6` en lugar de `localhost` (Airbyte sí va por `localhost:8000`, gracias al túnel).
- Si el prompt dice `PS C:\...` estás en Windows, no en la notebook: se cortó el SSH.

**Subir cambios a GitHub:** `cd ~/tpch_project`, `git add .`, `git commit -m "qué cambié"`, `git push`.

- [ ] Cuando termine la cursada, volver a activar la suspensión: `sudo systemctl unmask sleep.target suspend.target hibernate.target hybrid-sleep.target`
- [ ] Antes del 25/01/2027, regenerar el token de GitHub `notebook fedora`

## Mostrar las consultas en clase

Cada consulta del pizarrón es una vista del schema `consultas`: se ejecuta con un `SELECT` y devuelve el resultado al instante. Para variantes como "la más votada de tal año", se filtra la vista `intermedio.int_stats_pelicula` con un `WHERE`.

**1. Entrar a la base** (en la terminal de la notebook):

```bash
docker exec -it postgres-tpch psql -U admin -d peliculas
```

Adentro, `\dv consultas.*` lista todas las consultas, `\x` alterna la vista en columnas o en fichas (útil cuando el resultado es ancho) y `\q` sale.

**2. Ejecutar una consulta del pizarrón:**

```sql
SELECT * FROM consultas.s1_mejor_votada_min_50_votos LIMIT 5;
```

**3. Mostrarle al profe cómo está hecha:** `\d+ consultas.s1_mejor_votada_min_50_votos` muestra el SQL de la vista. El archivo original, con comentarios, está en `peliculas_dagster/peliculas_dbt/models/consultas/s1_mejor_votada_min_50_votos.sql`.

**4. Variantes con filtro**, para lo que pida en el momento:

```sql
-- Película más votada (más votos) de 1997
SELECT titulo, votos, promedio
FROM intermedio.int_stats_pelicula
WHERE extract(year FROM fecha_estreno) = 1997
ORDER BY votos DESC
LIMIT 5;

-- Mejor puntuada de 1997, con al menos 20 votos
SELECT titulo, votos, promedio
FROM intermedio.int_stats_pelicula
WHERE extract(year FROM fecha_estreno) = 1997 AND votos >= 20
ORDER BY promedio DESC
LIMIT 5;

-- Mejores comedias (cualquier género: cambiá 'Comedy')
SELECT titulo, count(*) AS votos, round(avg(puntaje), 2) AS promedio
FROM intermedio.int_votos_genero
WHERE genero = 'Comedy'
GROUP BY pelicula_id, titulo
HAVING count(*) >= 20
ORDER BY promedio DESC
LIMIT 5;

-- Comparar cómo votan dos ocupaciones
SELECT ocupacion, count(*) AS votos, round(avg(puntaje), 2) AS promedio
FROM intermedio.int_votos
WHERE ocupacion IN ('student', 'programmer')
GROUP BY ocupacion;
```

Resultados de referencia: la más votada de 1997 es Fargo (165 votos, 4,29) y la mejor puntuada de ese año es Titanic (4,32). Ojo con un detalle que sirve para explicar las validaciones: Return of the Jedi aparece como de 1997 porque esa es la fecha de su reestreno. Es uno de los 109 casos que detecta `v3_anio_titulo_distinto_estreno`.

**Las tablas para armar consultas nuevas:**

| Tabla o vista | Una fila por | Columnas útiles |
| --- | --- | --- |
| `intermedio.int_stats_pelicula` | película votada | `titulo`, `fecha_estreno`, `votos`, `promedio` |
| `intermedio.int_votos` | voto | `usuario_id`, `ocupacion`, `titulo`, `puntaje`, `fecha`, `fecha_estreno` |
| `intermedio.int_votos_genero` | voto × género de la película | lo mismo que `int_votos` + `genero` |
| `normalizado.pelicula` | película (incluye las nunca votadas) | `pelicula_id`, `titulo`, `anio_titulo`, `fecha_estreno` |

Los géneros se escriben en inglés y con mayúscula (`Comedy`, `Drama`, `Sci-Fi`), y las ocupaciones en minúscula (`student`, `engineer`). Para ver la lista: `SELECT nombre FROM normalizado.genero;` y `SELECT nombre FROM normalizado.ocupacion;`.

## Problemas que ya resolvimos

Cada uno enseña algo del stack; si vuelve a pasar, la solución está en la tabla.

| Síntoma | Por qué pasaba | Solución |
| --- | --- | --- |
| Airbyte da timeout al conectar con Postgres | Airbyte corre dentro de Kubernetes (kind) y no ve `localhost` ni siempre `host.docker.internal` | Conectar `postgres-tpch` a la red `kind` y usar el host `postgres-tpch`, que no depende del Wi-Fi |
| La sincronización falla con "cannot drop table because other objects depend on it" | Overwrite borra `raw.*` en cada sync, y las vistas de `staging` dependían de esas tablas | `staging` pasó a ser tablas (`+materialized: table`), que no quedan atadas a `raw` |
| Dagster muestra "Unexpected error" o se corta todo | La notebook se suspendía sola y cortaba SSH, Dagster y el túnel | `sudo systemctl mask` de los targets de suspensión (se deshace con `unmask`) |
| Grafana no puede usar el puerto 3000 | Dagster ya ocupa el 3000 | Grafana nuevo en el 3001 |
| Paneles de CPU y memoria en No data | Medían el proceso del exporter, que ahora está dentro de Alloy | Mirar la sección Database Stats |
| Ctrl+C no corta un programa en PowerShell | La ventana quedó en modo selección ("Seleccionar" en el título) | Esc y después Ctrl+C, o `pkill -f dagster` desde otra terminal |
| `conda activate` da "does not accept more than one argument" | Dos comandos en la misma línea | Un comando por línea; Tab completa los nombres de carpeta |
| Comandos de Linux dan error en Windows | Se cortó el SSH y el prompt volvió a `PS C:\...` | Reconectar con `ssh fedenacusse@192.168.1.6` |
| `git push` rechaza la contraseña | GitHub no acepta la contraseña de la cuenta, solo tokens | Token fine-grained con Contents: Read and write sobre `fid-peliculas` |
| pip instaló una beta de dbt en `(base)` | Se corrió sin activar el entorno | Entorno `fid` con Python 3.12 y versiones fijas: `dbt-core~=1.12.0`, `dbt-postgres~=1.11.0` |
