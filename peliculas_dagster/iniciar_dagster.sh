#!/bin/bash
cd "$(dirname "$0")"
export DAGSTER_HOME="$PWD/.dagster_home"
mkdir -p "$DAGSTER_HOME"
dagster dev -f definitions.py -h 0.0.0.0 -p 3000
