#!/usr/bin/env bash
# Update the versions in docker-bake.hcl to the latest releases and print each change.
set -euo pipefail
cd "$(dirname "$0")/.."

current() {
  sed -n "s/^variable \"$1\" { default = \"\(.*\)\" }$/\1/p" docker-bake.hcl
}

set_version() {
  local name=$1 version=$2 old
  old=$(current "$name")
  if [ -z "$version" ]; then
    echo "Found no version for $name" >&2
    exit 1
  fi
  if [ "$old" != "$version" ]; then
    sed -i "s|^variable \"$name\" { default = \".*\" }$|variable \"$name\" { default = \"$version\" }|" docker-bake.hcl
    echo "$name: $old -> $version"
  fi
}

# The highest version of a package in an apt Packages index
apt_version() {
  curl -fsS "$1" | { if [[ $1 == *.gz ]]; then gunzip; else cat; fi; } |
    awk -v package="$2" '$1 == "Package:" { match_package = ($2 == package) } match_package && $1 == "Version:" { print $2 }' |
    sort -V | tail -1
}

major() {
  sed -E 's/^([0-9]+:)?([0-9]+).*/\2/' <<< "$1"
}

ubuntu=$(curl -fsS 'https://hub.docker.com/v2/repositories/library/ubuntu/tags?page_size=100&name=noble-' |
  jq -r '.results[].name' | grep -E '^noble-[0-9]{8}(\.[0-9]+)?$' | sort -V | tail -1)
set_version UBUNTU_IMAGE "ubuntu:$ubuntu"

node=$(curl -fsS https://nodejs.org/dist/index.json | jq -r '[.[] | select(.lts)][0].version')
set_version NODE_VERSION "${node#v}"

# Use the highest major that both platforms have, so that the arm64 build does not wait for its package
chrome_amd64=$(major "$(apt_version https://dl.google.com/linux/chrome/deb/dists/stable/main/binary-amd64/Packages google-chrome-stable)")
chrome_arm64=$(major "$(apt_version https://dl.google.com/linux/chrome/deb/dists/stable/main/binary-arm64/Packages google-chrome-stable)")
set_version CHROME_VERSION "$(( chrome_amd64 < chrome_arm64 ? chrome_amd64 : chrome_arm64 ))"

set_version FIREFOX_VERSION "$(major "$(apt_version https://packages.mozilla.org/apt/dists/mozilla/main/binary-amd64/Packages firefox)")"

set_version EDGE_VERSION "$(major "$(apt_version https://packages.microsoft.com/repos/edge/dists/stable/main/binary-amd64/Packages.gz microsoft-edge-stable)")"
