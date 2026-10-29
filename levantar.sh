#!/bin/bash
# Levanta todo el stack de la materia. Uso: ~/tpch_project/levantar.sh
# Al final deja Dagster corriendo en esta terminal (Ctrl+C lo corta).
cd ~/tpch_project

echo "==> Postgres"
docker start postgres-tpch >/dev/null

echo "==> Airbyte"
docker start airbyte-abctl-control-plane >/dev/null

echo "==> Monitoreo (Alloy, Prometheus, Grafana, Dozzle)"
(cd monitoreo && docker compose up -d)

echo "==> Esperando a Airbyte en localhost:8000 (1 a 3 minutos)..."
listo=no
for i in $(seq 1 60); do
  code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000 || true)
  case "$code" in 000|502|503|504) sleep 5 ;; *) listo=si; break ;; esac
done
if [ "$listo" = si ]; then echo "    Airbyte listo"; else echo "    Airbyte sigue arrancando; Dagster igual se levanta"; fi

echo "==> Dagster en http://localhost:3000 (Ctrl+C para cortarlo)"
pkill -f "dagster dev" 2>/dev/null
source ~/miniconda3/etc/profile.d/conda.sh
conda activate fid
exec ./peliculas_dagster/iniciar_dagster.sh
