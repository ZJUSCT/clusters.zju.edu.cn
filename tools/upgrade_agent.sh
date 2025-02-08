#!/bin/bash
# curl https://raw.githubusercontent.com/ZJUSCT/clusters.zju.edu.cn/refs/heads/main/tools/upgrade_agent.sh | bash

set -xe

# require sudo
if [ "$(id -u)" -ne 0 ]; then
	echo "Please run as root"
	exit 1
fi

OTELCOL_VERSION="0.119.0"
OTELCOL_URL=https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v"$OTELCOL_VERSION"/otelcol-contrib_"$OTELCOL_VERSION"_

# check otelcol-contrib version
if command -v otelcol-contrib >/dev/null; then
	# output example: otelcol-contrib version 0.114.0
	ACTUAL_VERSION=$(otelcol-contrib --version | cut -d' ' -f3)
	if [ "$ACTUAL_VERSION" == "$OTELCOL_VERSION" ]; then
		echo "otelcol-contrib is already up-to-date"
		exit 0
	fi
fi

PREREQ=(
	"wget"
	"jq"
)

for cmd in "${PREREQ[@]}"; do
	if ! command -v "$cmd" >/dev/null; then
		echo "Please install $cmd"
		exit 1
	fi
done

# check os type, provide $ID
# https://www.freedesktop.org/software/systemd/man/latest/os-release.html
if [ -f /etc/os-release ]; then
	# for most linux distributions
	. /etc/os-release
elif [ "$(uname)" == "Darwin" ]; then
	# for macos
	ID="darwin"
else
	echo "Unsupported OS"
	exit 1
fi
# provide $ARCH
ARCH=$(uname -m)
if [ "$ARCH" == "x86_64" ]; then
	ARCH="amd64"
fi

case $ID in
ubuntu|debian|kali|linuxmint)
	OTELCOL_URL="$OTELCOL_URL"linux_"$ARCH".deb
	;;
arch|manjaro|openwrt)
	OTELCOL_URL="$OTELCOL_URL"linux_"$ARCH".tar.gz
	;;
fedora|rhel|rocky)
	OTELCOL_URL="$OTELCOL_URL"linux_"$ARCH".rpm
	;;
darwin)
	OTELCOL_URL="$OTELCOL_URL"darwin_"$ARCH".tar.gz
	;;
*)
	echo "Unsupported OS"
	exit 1
	;;
esac

# check if otelcol-contrib is running
if pgrep -x "otelcol-contrib" >/dev/null; then
	echo "Please stop otelcol-contrib first"
	exit 1
fi

# download to tmp and install
TMPFILE=$(mktemp)
wget -O "$TMPFILE" "$OTELCOL_URL"
case $ID in
ubuntu|debian|kali|linuxmint)
	dpkg -i "$TMPFILE"
	;;
fedora|rhel|rocky)
	rpm -i "$TMPFILE"
	;;
arch|manjaro|openwrt|darwin)
	# extract only otelcol-contrib
	tar -xzf "$TMPFILE" -C /usr/local/bin otelcol-contrib
	;;
esac
rm "$TMPFILE"

# download config file
if [ ! -d /etc/otelcol-contrib ]; then
	mkdir /etc/otelcol-contrib
fi
if [ -f /etc/otelcol-contrib/config.yaml ]; then
	mv /etc/otelcol-contrib/config.yaml /etc/otelcol-contrib/config.yaml.old
fi

wget https://raw.githubusercontent.com/ZJUSCT/clusters.zju.edu.cn/refs/heads/main/config/otelcol/agent.yaml -O /etc/otelcol-contrib/config.yaml || exit 1
