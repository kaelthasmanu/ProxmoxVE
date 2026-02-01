#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: kaelthasmanu (Manuel)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/kaelthasmanu/SquidStats

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y curl wget git python3 python3-pip python3-venv libmariadb-dev squid
msg_ok "Installed Dependencies"

msg_info "Configuring Squid"
cat <<'EOF' >> /etc/squid/squid.conf

# SquidStats Configuration
logformat detailed \
  "%ts.%03tu %>a %ui %un [%tl] \"%rm %ru HTTP/%rv\" %>Hs %<st %rm %ru %>a %mt %<a %<rm %Ss/%Sh %<st"

access_log /var/log/squid/access.log detailed

# Cache manager access for SquidStats
acl manager proto cache_object
acl localhost src 127.0.0.1/32 ::1
http_access allow localhost manager
http_access deny manager
EOF
$STD systemctl enable squid
$STD systemctl restart squid
msg_ok "Configured Squid"

msg_info "Installing SquidStats"
$STD wget https://github.com/kaelthasmanu/SquidStats/releases/download/2.2/install.sh -O /tmp/squidstats-install.sh
$STD chmod +x /tmp/squidstats-install.sh
# Run installation script in non-interactive mode
$STD /tmp/squidstats-install.sh --non-interactive
msg_ok "Installed SquidStats"

msg_info "Verifying SquidStats Service"
if systemctl is-active --quiet squidstats; then
  msg_ok "SquidStats service is running"
else
  msg_info "Starting SquidStats service"
  $STD systemctl enable squidstats
  $STD systemctl start squidstats
  msg_ok "SquidStats service started"
fi

motd_ssh
customize
cleanup_lxc
