#!/bin/bash
# Apaga todo el stack de la materia. Uso: ~/tpch_project/apagar.sh
cd ~/tpch_project
echo "==> Dagster";    pkill -f "dagster" 2>/dev/null
echo "==> Monitoreo";  (cd monitoreo && docker compose stop)
echo "==> Airbyte";    docker stop -t 60 airbyte-abctl-control-plane >/dev/null
echo "==> Postgres";   docker stop postgres-tpch >/dev/null
echo "Listo: no queda nada del stack corriendo."
