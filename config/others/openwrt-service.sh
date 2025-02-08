#!/bin/bash /etc/rc.common
# /etc/init.d/otelcol-contrib
# https://openwrt.org/docs/techref/initscripts
# https://openwrt.org/docs/guide-developer/procd-init-scripts

START=99

USE_PROCD=1
PROG=/usr/bin/otelcol-contrib

ARGS="--config=/etc/otelcol-contrib/config.yaml"
start_service() {
	procd_open_instance
	procd_set_param command "$PROG" "$ARGS"
	procd_set_param respawn
	procd_set_param env OTEL_BEARER_TOKEN="your_token" OTEL_CLOUD_REGION="your_region"
	procd_set_param file /etc/otelcol-contrib/config.yaml
	procd_set_param stdout 1
	procd_set_param stderr 1
	procd_set_param user root
	procd_close_instance
}
