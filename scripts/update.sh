#!/usr/bin/env sh
set -eu

SOURCE_URL="https://raw.githubusercontent.com/itdoginfo/allow-domains/main/Russia/inside-raw.lst"
TEMP_FILE="$(mktemp)"
trap 'rm -f "$TEMP_FILE"' EXIT

curl --fail --silent --show-error --location "$SOURCE_URL" > "$TEMP_FILE"

{
  cat "$TEMP_FILE"
  cat custom-domains.txt
} |
  tr '[:upper:]' '[:lower:]' |
  tr -d '\r' |
  sed 's/[[:space:]]*#.*$//' |
  sed 's/^[[:space:]]*//;s/[[:space:]]*$//' |
  awk '
    /^$/ { next }
    /^\./ { next }
    /^[-a-z0-9]+([.][-a-z0-9]+)+$/ { print }
  ' |
  sort -u > domains.txt

