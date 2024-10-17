#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR/..

# check if gdg is installed
if ! command -v gdg &> /dev/null
then
    echo "gdg could not be found"
    echo "get it from https://github.com/esnet/gdg"
    exit
fi

# # anonymous access enabled, no need to login
# source ../.env
# export GDG_CONTEXTS__ZJUSCT__PASSWORD=$GF_SECURITY_ADMIN_PASSWORD

# backup dashboards
gdg backup dashboards list --config tools/gdg/importer.yml
gdg backup dashboards download --config tools/gdg/importer.yml