#!/bin/bash
set -e

# source and export environment variables
source .env.template
# here we need word splitting, so we disable the warning
# shellcheck disable=SC2046
export $(cut -d= -f1 .env.template)

set -x

# validate otelcol config
for file in ./config/otelcol/*.yaml; do
  otelcol-contrib validate --config "$file"
done

# validate compose file
docker compose config > /dev/null

echo "Validation successful"
