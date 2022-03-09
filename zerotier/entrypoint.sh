#!/usr/bin/env bash

if [ -z "$ZEROTIER_NETWORKS" ]
then
  echo "No networks found in ZEROTIER_NETWORKS environment variable"
  exit 1
fi

ZEROTIER_NETWORKS_ARR=($ZEROTIER_NETWORKS)

isonline() {
  info=$(zerotier-cli -j info)
  if [ "$?" -ne 0 ]
  then
    echo "Online state: <unknown>"
    return 1
  fi

  online=$(echo "$info" | jq '.online')
  if [ -z "$online" ]
  then
    echo "Online state: <unknown>"
  else
    echo "Online state: $online"
    [ "$online" = "true" ]
  fi
}

mkztfile() {
  file=$1
  mode=$2
  content=$3

  mkdir -p /var/lib/zerotier-one
  echo "$content" > "/var/lib/zerotier-one/$file"
  chmod "$mode" "/var/lib/zerotier-one/$file"
}

if [ "x$ZEROTIER_API_SECRET" != "x" ]
then
  mkztfile authtoken.secret 0600 "$ZEROTIER_API_SECRET"
fi

if [ "x$ZEROTIER_IDENTITY_PUBLIC" != "x" ]
then
  mkztfile identity.public 0644 "$ZEROTIER_IDENTITY_PUBLIC"
fi

if [ "x$ZEROTIER_IDENTITY_SECRET" != "x" ]
then
  mkztfile identity.secret 0600 "$ZEROTIER_IDENTITY_SECRET"
fi

mkztfile zerotier-one.port 0600 "9993"

killzerotier() {
  echo "*** Killing zerotier"
  kill $(cat /var/lib/zerotier-one/zerotier-one.pid)  
  exit 0
}

trap killzerotier INT TERM

# Start ZeroTier, backgrounded
nohup /usr/sbin/zerotier-one &

# Wait for identity
echo "*** Waiting for identity generation..."
while [ ! -f /var/lib/zerotier-one/identity.secret ]; do
	sleep 1
done
ztaddr=$(cat /var/lib/zerotier-one/identity.public | cut -d : -f 1)
echo "*** Success! You are ZeroTier address [ $ztaddr ]."

# Wait for ZeroTier to be online
echo "*** Waiting for zerotier to be online"
until isonline
do
  sleep 1
done

# Join networks
echo "*** Joining networks: $ZEROTIER_NETWORKS"
for i in "${ZEROTIER_NETWORKS_ARR[@]}"
do
  echo "*** Joining $i"
  if ! zerotier-cli join "$i"
  then
    echo "Joining $i failed with error code $?"
    exit 1
  fi
done

# Wait on networks to have STATUS = OK
for i in "${ZEROTIER_NETWORKS_ARR[@]}"
do
  echo "*** Waiting for network $i to have STATUS = OK"
  while :
  do
    status=$(zerotier-cli -j listnetworks | jq -r --arg NETWORK "$i" '
      .[]
      | select(.id==$NETWORK) 
      | .status
    ')
    if [ "$?" -ne 0 ] || [ -z "$status" ]
    then
      echo "$i -> Status=<unknown>"
    elif [ "$status" = "OK" ]
    then
      echo "$i -> Status=OK"
      break
    elif [ "$status" = "NOT_FOUND" ]
    then
      echo "$i -> Status=NOT_FOUND (has the network been deleted?)"
    elif [ "$status" = "ACCESS_DENIED" ]
    then
      echo "$i -> Status=ACCESS_DENIED (authorize address $ztaddr to continue)"
    else
      echo "$i -> Status=$status"
    fi
    # echo "*** Waiting 3 seconds before next check of network $i"
    sleep 3
  done
done

sleep infinity
