#!/bin/bash
# export GHPROXY=https://ghfast.top/
# curl "$GHPROXY"https://raw.githubusercontent.com/ZJUSCT/clusters.zju.edu.cn/refs/heads/main/tools/upgrade_agent.sh | sudo -E bash

set -xe

# require sudo
if [ "$(id -u)" -ne 0 ]; then
	echo "Please run as root"
	exit 1
fi

# https://ghproxy.link/
# $GHPROXY can be used
echo "using $GHPROXY"
OTELCOL_VERSION="0.119.0"
OTELCOL_URL="$GHPROXY"https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v"$OTELCOL_VERSION"/otelcol-contrib_"$OTELCOL_VERSION"_

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
fedora|rhel|rocky|centos)
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
fedora|rhel|rocky|centos)
	rpm -i "$TMPFILE"
	;;
arch|manjaro|darwin)
	# extract only otelcol-contrib
	tar -xzf "$TMPFILE" -C /usr/local/bin otelcol-contrib
	;;
openwrt)
	tar -xzf "$TMPFILE" -C /usr/bin otelcol-contrib
	;;
esac
rm "$TMPFILE"

# download config file
if [ ! -d /etc/otelcol-contrib ]; then
	mkdir /etc/otelcol-contrib
fi

wget "$GHPROXY"https://raw.githubusercontent.com/ZJUSCT/clusters.zju.edu.cn/refs/heads/main/config/otelcol/agent.yaml -O /etc/otelcol-contrib/config.yaml.latest || exit 1

# diff
if [ -f /etc/otelcol-contrib/config.yaml ]; then
	if ! diff -q /etc/otelcol-contrib/config.yaml /etc/otelcol-contrib/config.yaml.latest; then
		echo "New config file is different from the current one"
		echo "Please check the diff and merge manually"
		exit 1
	fi
fi

# service management
case $ID in
darwin)
	# check /Library/LaunchDaemons/otelcol-contrib.plist
	if [ ! -f /Library/LaunchDaemons/otelcol-contrib.plist ]; then
		wget "$GHPROXY"https://raw.githubusercontent.com/ZJUSCT/clusters.zju.edu.cn/refs/heads/main/config/others/launchctl-otelcol.plist -O /Library/LaunchDaemons/otelcol-contrib.plist || exit 1
		xattr -rd com.apple.quarantine /Library/LaunchDaemons/otelcol-contrib.plist
		echo "+ LaunchDaemon installed"
	fi
	;;
openwrt)
	# check /etc/init.d/otelcol-contrib
	if [ ! -f /etc/init.d/otelcol-contrib ]; then
		wget "$GHPROXY"https://raw.githubusercontent.com/ZJUSCT/clusters.zju.edu.cn/refs/heads/main/config/others/openwrt-service.sh -O /etc/init.d/otelcol-contrib || exit 1
		chmod +x /etc/init.d/otelcol-contrib
		echo "+ OpenWRT service installed"
	fi
	;;
*)
	# check /etc/systemd/system/otelcol-contrib.service.d/override.conf
	if [ ! -f /etc/systemd/system/otelcol-contrib.service.d/override.conf ]; then
		wget "$GHPROXY"https://raw.githubusercontent.com/ZJUSCT/clusters.zju.edu.cn/refs/heads/main/config/others/systemd-override.conf -O /etc/systemd/system/otelcol-contrib.service.d/override.conf || exit 1
		echo "+ systemd override installed"
	fi
esac
