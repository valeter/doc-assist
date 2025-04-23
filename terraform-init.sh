#!/bin/bash

source ./terraform-vars.sh

terraform -chdir=terraform/ init -reconfigure -backend-config="access_key=$ACCESS_KEY" -backend-config="secret_key=$SECRET_KEY"