#!/bin/bash

set -eo pipefail


init() {
  echo "Running init-db"
  yarn install
  yarn db:init
}

migrate() {
  echo "Running migrate-db"

  if [ -z "$TARGET_DB_HOST" ]; then
      echo "TARGET_DB_HOST is not set. Exiting."
      exit 1
  fi 

  if [ -z "$TARGET_DB_DATABASE" ]; then
      echo "TARGET_DB_DATABASE is not set. Exiting."
      exit 1
  fi

  if [ -z "$TARGET_DB_APP_USER" ]; then
      echo "TARGET_DB_APP_USER is not set. Exiting."
      exit 1
  fi

  if [ -z "$TARGET_DB_APP_PASSWORD" ]; then
      echo "TARGET_DB_APP_PASSWORD is not set. Exiting."
      exit 1
  fi

  if [ -z "$SOURCE_DB_HOST" ]; then
      echo "SOURCE_DB_HOST is not set. Exiting."
      exit 1
  fi

  if [ -z "$SOURCE_DB_DATABASE" ]; then
      echo "SOURCE_DB_DATABASE is not set. Exiting."
      exit 1
  fi

  if [ -z "$SOURCE_DB_USER" ]; then
      echo "SOURCE_DB_USER is not set. Exiting."
      exit 1
  fi

  if [ -z "$SOURCE_DB_PASSWORD" ]; then
      echo "SOURCE_DB_PASSWORD is not set. Exiting."
      exit 1
  fi

  if [ -z "$NODE_TYPE" ]; then
      echo "NODE_TYPE is not set. Exiting."
      exit 1
  fi

  if [ -z "$NODE_NUMBER" ]; then
      echo "NODE_NUMBER is not set. Exiting."
      exit 1
  fi

  if [ $NODE_TYPE == "stream" ]; then
    # The schema name is saved to /tmp/schema-name. read it, and use it:
    SCHEMA_NAME=$(cat /tmp/schema-name)
    echo "Schema name is $SCHEMA_NAME"

    git clone https://github.com/towns-protocol/towns

    echo "Building go migration tool"
    cd ./towns/core/tools/migrate_db

    git checkout crystal/mb-promotion-issue
    go build -o river_migrate_db .

    echo "Built river_migrate_db"

    export RIVER_DB_SOURCE_PASSWORD=$SOURCE_DB_PASSWORD
    export RIVER_DB_SOURCE_URL="postgres://${SOURCE_DB_USER}@${SOURCE_DB_HOST}:5432/river?pool_max_conns=50"

    export RIVER_DB_TARGET_PASSWORD=$TARGET_DB_APP_PASSWORD
    export RIVER_DB_TARGET_URL="postgres://${TARGET_DB_APP_USER}@${TARGET_DB_HOST}:5432/river?pool_max_conns=50"

    export RIVER_DB_NUM_WORKERS="12"
    export RIVER_DB_TX_SIZE="1"
    export RIVER_DB_PROGRESS_REPORT_INTERVAL="10s"
    export RIVER_DB_SCHEMA=$SCHEMA_NAME
    export RIVER_DB_PARTITION_TX_SIZE="16"
    export RIVER_DB_PARTITION_WORKERS="8"
    export RIVER_DB_ATTACH_WORKERS="1"

    echo "Calling target init"
    ./river_migrate_db target init

    echo "Calling copy"
    ./river_migrate_db copy --bypass --verbose

    echo "Finished migrate-db"
  elif [ $NODE_TYPE == "archive" ]; then
    echo "Archive node. Skipping pgdump and restore."
  else
    exit 1
  fi
}

init
migrate