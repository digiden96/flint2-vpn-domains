#!/usr/bin/env python3
"""Build Happ routing profile and subscription deeplink from russia-domains.txt."""

import base64
import ipaddress
import json
import time
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "russia-domains.txt"
PROFILE_PATH = ROOT / "happ-routing.json"
LINK_PATH = ROOT / "happ-routing.txt"

PRIVATE_IPS = [
    "geoip:private",
    "10.0.0.0/8",
    "172.16.0.0/12",
    "192.168.0.0/16",
    "169.254.0.0/16",
    "224.0.0.0/4",
    "255.255.255.255",
]


def read_rules() -> tuple[list[str], list[str]]:
    domains: set[str] = set()
    networks: set[str] = set()
    for raw_line in SOURCE.read_text(encoding="utf-8").splitlines():
        entry = raw_line.strip().lower()
        if not entry or entry.startswith("#"):
            continue
        try:
            networks.add(str(ipaddress.ip_network(entry, strict=False)))
            continue
        except ValueError:
            pass
        if any(char.isspace() for char in entry) or "/" in entry:
            raise ValueError(f"Invalid domain or IP network in {SOURCE.name}: {entry}")
        domains.add(f"domain:{entry}")
    return sorted(domains), sorted(networks)


def main() -> None:
    direct_sites, source_networks = read_rules()
    profile = {
        "Name": "RU direct | Full tunnel",
        "GlobalProxy": "true",
        "RouteOrder": "direct-proxy-block",
        "DirectSites": direct_sites,
        "DirectIp": sorted(set(PRIVATE_IPS + source_networks)),
        "ProxySites": [],
        "ProxyIp": [],
        "BlockSites": [],
        "BlockIp": [],
        "DomainStrategy": "IPIfNonMatch",
        "FakeDNS": "false",
    }

    previous_updated = None
    if PROFILE_PATH.exists():
        try:
            previous = json.loads(PROFILE_PATH.read_text(encoding="utf-8"))
            old_rules = {key: value for key, value in previous.items() if key != "LastUpdated"}
            if old_rules == profile:
                previous_updated = previous.get("LastUpdated")
        except (json.JSONDecodeError, AttributeError):
            pass
    profile["LastUpdated"] = str(previous_updated or int(time.time()))

    profile_json = json.dumps(profile, ensure_ascii=False, indent=2) + "\n"
    PROFILE_PATH.write_text(profile_json, encoding="utf-8", newline="\n")
    encoded = base64.b64encode(profile_json.rstrip("\n").encode("utf-8")).decode("ascii")
    LINK_PATH.write_text(f"happ://routing/onadd/{encoded}\n", encoding="ascii", newline="\n")


if __name__ == "__main__":
    main()
