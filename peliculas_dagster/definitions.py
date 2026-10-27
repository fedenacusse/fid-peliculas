from pathlib import Path

import dagster as dg
from dagster_airbyte import (
    AirbyteWorkspace,
    DagsterAirbyteTranslator,
    build_airbyte_assets_definitions,
)
from dagster_dbt import DbtCliResource, DbtProject, dbt_assets

# ---------------------------------------------------------------- Airbyte
airbyte = AirbyteWorkspace(
    rest_api_base_url=dg.EnvVar("AIRBYTE_REST_API_BASE_URL"),
    configuration_api_base_url=dg.EnvVar("AIRBYTE_CONFIGURATION_API_BASE_URL"),
    workspace_id=dg.EnvVar("AIRBYTE_WORKSPACE_ID"),
    client_id=dg.EnvVar("AIRBYTE_CLIENT_ID"),
    client_secret=dg.EnvVar("AIRBYTE_CLIENT_SECRET"),
)


class TraductorAirbyte(DagsterAirbyteTranslator):
    """Nombra cada stream como raw/<tabla>, igual que las sources de dbt."""

    def get_asset_spec(self, props):
        spec = super().get_asset_spec(props)
        return spec.replace_attributes(
            key=dg.AssetKey(["raw", props.stream_name]),
            group_name="ingesta",
        )


airbyte_assets = build_airbyte_assets_definitions(
    workspace=airbyte,
    dagster_airbyte_translator=TraductorAirbyte(),
    connection_selector_fn=lambda conexion: "Postgres peliculas" in conexion.name,
)

# -------------------------------------------------------------------- dbt
DBT_DIR = Path(__file__).parent / "peliculas_dbt"

dbt_project = DbtProject(project_dir=DBT_DIR, profiles_dir=DBT_DIR)
dbt_project.prepare_if_dev()


@dbt_assets(manifest=dbt_project.manifest_path)
def peliculas_dbt(context: dg.AssetExecutionContext, dbt: DbtCliResource):
    """Corre `dbt build`: modelos + tests, en el orden del grafo de linaje."""
    yield from dbt.cli(["build"], context=context).stream()


# ------------------------------------------------------- job y schedule
pipeline_peliculas = dg.define_asset_job(
    name="pipeline_peliculas",
    selection=dg.AssetSelection.all(),
)

pipeline_diario = dg.ScheduleDefinition(
    job=pipeline_peliculas,
    cron_schedule="0 8 * * *",
    execution_timezone="America/Argentina/Buenos_Aires",
)

defs = dg.Definitions(
    assets=[*airbyte_assets, peliculas_dbt],
    jobs=[pipeline_peliculas],
    schedules=[pipeline_diario],
    resources={
        "airbyte": airbyte,
        "dbt": DbtCliResource(project_dir=dbt_project, profiles_dir=str(DBT_DIR)),
    },
)
