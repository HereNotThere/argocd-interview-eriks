#!/bin/bash

set -eo pipefail


init() {
  echo "Running init-db"
  yarn install
  yarn db:init
}

init