#!/bin/bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
cd "$SCRIPT_DIR"/.. || exit

credential_names=(
	"OTEL_BEARER_TOKEN"
	"GF_SECURITY_ADMIN_PASSWORD"
	"GF_TG_BOT_TOKEN"
	"GF_TG_CHAT_ID"
	"INFLUXDB_PASSWORD"
	"INFLUXDB_TOKEN"
	"SNMP_PRIVATE_KEY"
	"SNMP_AUTH_KEY"
	"CLICKHOUSE_PASSWORD"
)

. tools/common-function.sh

bw_login

# create .env file
if [ -f .env ]; then
	rm .env
fi

# for each credential name, get the password, append it to .env using format CREDENTIAL_NAME=PASSWORD
for credential_name in "${credential_names[@]}"; do
	echo "Getting $credential_name"
	password=$(bw get password "$credential_name")
	if [ -z "$password" ]; then
		echo "Failed to get $credential_name"
		continue
	fi
	echo "$credential_name=\"$password\"" >>.env
done

bw logout
