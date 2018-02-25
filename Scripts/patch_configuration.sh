#!/bin/bash

#source "secrets.sh"

cd "$PROJECT_DIR/$PROJECT_NAME"

declare -a confs
confs=(
    "TMDB_API_KEY=$TMDB_API_KEY"
)

cp Configuration.template.swift Configuration.swift

for i in "${confs[@]}"
do
    key=${i%%=*}
    searchkey="{\*\*$key\*\*}"
    value=${i#*=}
    echo $key $value
    sed -i "" "s/${searchkey}/${value}/g" Configuration.swift
done
