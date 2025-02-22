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
  elif [ $NODE_TYPE == "archive" ]; then
    SCHEMA_NAME="arch${NODE_NUMBER}"
  else
    exit 1
  fi

  echo "Schema name is $SCHEMA_NAME"
  echo "Beginning pgdump... on $SOURCE_DB_HOST"


  # 1) Set the source DB password for pg_dump
  export PGPASSWORD="$SOURCE_DB_PASSWORD"

  # 2) Run pg_dump in directory format with parallel jobs
  pg_dump \
    -F d          \            # "directory" format (allows parallel dump/restore)
    -j 12         \            # use 12 parallel jobs
    -Z 0          \            # disable compression for speed
    -v            \            # verbose output
    -h "$SOURCE_DB_HOST" \
    -U "$SOURCE_DB_USER" \
    -d "$SOURCE_DB_DATABASE" \
    -n "$SCHEMA_NAME"          # dump only this schema 
    -f /tmp/dump


  echo "Finished pgdump. Restoring to target db..."

  # 1) Set the target DB password for pg_restore
  export PGPASSWORD="$TARGET_DB_APP_PASSWORD"

  # 2) Run pg_restore with the same parallelism
  pg_restore \
    -F d         \        # directory format
    -j 12        \        # parallel jobs
    -v           \        # verbose output
    -O           \        # skip restoring original ownership
    -x           \        # skip ACLs (privileges)
    -h "$TARGET_DB_HOST" \
    -U "$TARGET_DB_APP_USER" \
    -d "$TARGET_DB_DATABASE" \
    /tmp/dump

  echo "Finished migrate-db"
}

init
migrate