#!/usr/bin/env bash

version=$1

if [[ -z $version ]]
then
  me=`basename "$0"`
  echo "Usage: $me <version>"
  exit 1
fi

echo "Building image for ZeroTier v$version"
exec docker build zerotier --build-arg VERSION="$version"
echo "Done"