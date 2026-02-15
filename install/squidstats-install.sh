#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Copyright (c) 2021-2026 community-scripts ORG
# Author: kaelthasmanu (Manuel)
# License: MIT
# Source: https://github.com/kaelthasmanu/SquidStats

# Load helper framework
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

TMP_INSTALL="/tmp/squidstats-install.sh"
API_URL="https://api.github.com/repos/kaelthasmanu/SquidStats/releases/latest"

cleanup() {
  rm -f "$TMP_INSTALL"
}
trap cleanup EXIT

msg_info "Fetching Latest SquidStats Release"
RELEASE="$(curl -fsSL "$API_URL" | jq -r .tag_name)"

if [[ -z "$RELEASE" || "$RELEASE" == "null" ]]; then
  msg_error "Failed to fetch latest SquidStats release"
  exit 1
fi
msg_ok "Latest Version: $RELEASE"

msg_info "Installing Dependencies"
$STD apt install -y curl wget jq libmariadb-dev squid git python3 python3-{pip,venv}
msg_ok "Installed Dependencies"

msg_info "Configuring Squid"

SQUID_CONF="/etc/squid/squid.conf"

if ! grep -q "### SQUIDSTATS CONFIG START ###" "$SQUID_CONF"; then
  cat <<'EOF' >> "$SQUID_CONF"

### SQUIDSTATS CONFIG START ###
logformat detailed \
  "%ts.%03tu %>a %ui %un [%tl] \"%rm %ru HTTP/%rv\" %>Hs %<st %rm %ru %>a %mt %<a %<rm %Ss/%Sh %<st"

access_log /var/log/squid/access.log detailed

acl manager proto cache_object
acl localhost src 127.0.0.1/32 ::1
http_access allow localhost manager
http_access deny manager
### SQUIDSTATS CONFIG END ###
EOF
fi

systemctl enable --now squid
msg_ok "Configured and Started Squid"

msg_info "Downloading SquidStats Installer"
wget -q --show-progress -O "$TMP_INSTALL" \
  "https://github.com/kaelthasmanu/SquidStats/releases/download/${RELEASE}/install.sh"

if [[ ! -s "$TMP_INSTALL" ]]; then
  msg_error "Failed to download SquidStats installer"
  exit 1
fi

chmod +x "$TMP_INSTALL"

msg_info "Installing SquidStats"
$STD "$TMP_INSTALL" --non-interactive
msg_ok "Installed SquidStats"

echo "$RELEASE" > /opt/squidstats_version.txt

msg_info "Ensuring SquidStats Service is Enabled and Running"
systemctl enable -q --now squidstats
msg_ok "SquidStats service is active"

motd_ssh
customize
cleanup_lxc
