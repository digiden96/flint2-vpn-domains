#!/usr/bin/env sh
set -eu

VPN_SOURCE_URL="https://raw.githubusercontent.com/itdoginfo/allow-domains/main/Russia/inside-raw.lst"
TELEGRAM_SOURCE_URL="https://core.telegram.org/resources/cidr.txt"
RUSSIA_SOURCE_URL="https://raw.githubusercontent.com/UnRKN/ru-blocklist/main/ru-blocklist.txt"
GEOBLOCK_SOURCE_URL="https://raw.githubusercontent.com/itdoginfo/allow-domains/main/Categories/geoblock.lst"
META_SOURCE_URL="https://raw.githubusercontent.com/itdoginfo/allow-domains/main/Services/meta.lst"
TIKTOK_SOURCE_URL="https://raw.githubusercontent.com/itdoginfo/allow-domains/main/Services/tiktok.lst"
TWITTER_SOURCE_URL="https://raw.githubusercontent.com/itdoginfo/allow-domains/main/Services/twitter.lst"
TEMP_VPN_DOMAINS="$(mktemp)"
TEMP_TELEGRAM="$(mktemp)"
TEMP_RUSSIA_DOMAINS="$(mktemp)"
TEMP_FORCE_VPN="$(mktemp)"
TEMP_ALL_DOMAINS="$(mktemp)"
TEMP_NORMALIZED_FORCE="$(mktemp)"
trap 'rm -f "$TEMP_VPN_DOMAINS" "$TEMP_TELEGRAM" "$TEMP_RUSSIA_DOMAINS" "$TEMP_FORCE_VPN" "$TEMP_ALL_DOMAINS" "$TEMP_NORMALIZED_FORCE"' EXIT

curl --fail --silent --show-error --location "$VPN_SOURCE_URL" > "$TEMP_VPN_DOMAINS"
curl --fail --silent --show-error --location "$TELEGRAM_SOURCE_URL" > "$TEMP_TELEGRAM"
curl --fail --silent --show-error --location "$RUSSIA_SOURCE_URL" > "$TEMP_RUSSIA_DOMAINS"
for url in "$GEOBLOCK_SOURCE_URL" "$META_SOURCE_URL" "$TIKTOK_SOURCE_URL" "$TWITTER_SOURCE_URL"; do
  curl --fail --silent --show-error --location "$url" >> "$TEMP_FORCE_VPN"
  printf '\n' >> "$TEMP_FORCE_VPN"
done

build_list() {
  output="$1"
  shift
  normalized_output="$(mktemp)"

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
    sort -u > "$normalized_output"
  mv "$normalized_output" "$output"
}

build_list "$TEMP_ALL_DOMAINS" "$TEMP_VPN_DOMAINS"
build_list "$TEMP_NORMALIZED_FORCE" "$TEMP_FORCE_VPN" custom-domains.txt

# A candidate is handled by zapret2 only when neither it nor a parent domain is
# present in the force-VPN list. Manual zapret entries are always included.
awk '
NR == FNR { excluded[$0] = 1; next }
{
  domain = $0
  probe = domain
  blocked = 0
  while (probe != "") {
    if (probe in excluded) { blocked = 1; break }
    dot = index(probe, ".")
    if (!dot) break
    probe = substr(probe, dot + 1)
  }
  if (!blocked) print domain
}
' "$TEMP_NORMALIZED_FORCE" "$TEMP_ALL_DOMAINS" > zapret-domains.txt

build_list zapret-domains.txt zapret-domains.txt custom-zapret-domains.txt

# Everything excluded from zapret2, plus manual entries, remains on the VPS.
awk '
NR == FNR { direct[$0] = 1; next }
!($0 in direct) { print }
' zapret-domains.txt "$TEMP_ALL_DOMAINS" > podkop-domains.txt
build_list podkop-domains.txt podkop-domains.txt custom-domains.txt

build_list podkop-subnets.txt "$TEMP_TELEGRAM"

# Backward-compatible combined list for clients that accept domains and CIDRs
# in one subscription.
build_list domains.txt podkop-domains.txt podkop-subnets.txt

# Podkop expects domain names and IP/CIDR networks in separate URL fields.
build_list russia-domains.txt \
  "$TEMP_RUSSIA_DOMAINS" \
  custom-russia-domains.txt
