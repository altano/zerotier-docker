#!/usr/bin/env bash

if [ -z "$ZEROTIER_NETWORKS" ]
then
  echo "No networks found in ZEROTIER_NETWORKS environment variable"
  exit 1
fi

ZEROTIER_NETWORKS_ARR=($ZEROTIER_NETWORKS)

for i in "${ZEROTIER_NETWORKS_ARR[@]}"
do
  status=$(zerotier-cli -j listnetworks | jq -r --arg NETWORK "$i" '
    .[]
    | select(.id==$NETWORK) 
    | .status
  ')
  if [ "$?" -ne 0 ] || [ -z "$status" ]
  then
    echo "$i -> Status=<unknown>"
    exit 1
  elif [ "$status" = "OK" ]
  then
    continue
  else
    echo "$i -> Status=$status"
    exit 1
  fi
done