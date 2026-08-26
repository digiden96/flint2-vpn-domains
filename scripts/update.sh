#!/usr/bin/env sh
set -eu

VPN_SOURCE_URL="https://raw.githubusercontent.com/itdoginfo/allow-domains/main/Russia/inside-raw.lst"
TELEGRAM_SOURCE_URL="https://core.telegram.org/resources/cidr.txt"
RUSSIA_SOURCE_URL="https://raw.githubusercontent.com/UnRKN/ru-blocklist/main/ru-blocklist.txt"
TEMP_VPN_DOMAINS="$(mktemp)"
TEMP_TELEGRAM="$(mktemp)"
TEMP_RUSSIA_DOMAINS="$(mktemp)"
trap 'rm -f "$TEMP_VPN_DOMAINS" "$TEMP_TELEGRAM" "$TEMP_RUSSIA_DOMAINS"' EXIT

curl --fail --silent --show-error --location "$VPN_SOURCE_URL" > "$TEMP_VPN_DOMAINS"
curl --fail --silent --show-error --location "$TELEGRAM_SOURCE_URL" > "$TEMP_TELEGRAM"
curl --fail --silent --show-error --location "$RUSSIA_SOURCE_URL" > "$TEMP_RUSSIA_DOMAINS"

build_list() {
  output="$1"
  shift

  cat "$@" |
    tr '[:upper:]' '[:lower:]' |
    tr -d '\r' |
    sed 's/[[:space:]]*#.*$//' |
    sed 's/^[[:space:]]*//;s/[[:space:]]*$//' |
    awk '
    function is_ipv4_cidr(value, sections, octets, count, i) {
      count = split(value, sections, "/")
      if (count > 2) return 0
      if (count == 2 && (sections[2] !~ /^[0-9]+$/ || sections[2] > 32)) return 0

      count = split(sections[1], octets, ".")
      if (count != 4) return 0
      for (i = 1; i <= 4; i++) {
        if (octets[i] !~ /^[0-9]+$/ || octets[i] > 255) return 0
      }
      return 1
    }

    /^$/ { next }
    /^\./ { next }
    is_ipv4_cidr($0) { print; next }
    /^[a-z][-a-z0-9]*([.][-a-z0-9]+)+$/ { print }
    ' |
    sort -u > "$output"
}

build_list domains.txt \
  "$TEMP_VPN_DOMAINS" \
  "$TEMP_TELEGRAM" \
  custom-domains.txt

build_list russia-domains.txt \
  "$TEMP_RUSSIA_DOMAINS" \
  custom-russia-domains.txt
