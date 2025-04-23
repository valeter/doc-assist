#!/bin/bash

source ./terraform-vars.sh

terraform -chdir=terraform/ $@
