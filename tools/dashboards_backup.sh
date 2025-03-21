#!/bin/bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
cd "$SCRIPT_DIR"/.. || exit

# check if gdg is installed
if ! command -v gdg &>/dev/null; then
	echo "gdg could not be found"
	echo "get it from https://github.com/esnet/gdg"
	exit
fi

source .env
export GDG_CONTEXTS__ZJUSCT__PASSWORD=$GF_SECURITY_ADMIN_PASSWORD

# test grafana up
if ! curl -f https://grafana.clusters.zjusct.io/api/health; then
	echo "Grafana is down"
	exit
fi

# backup dashboards
gdg backup dashboards list --config tools/gdg/importer.yml
gdg backup dashboards download --config tools/gdg/importer.yml
