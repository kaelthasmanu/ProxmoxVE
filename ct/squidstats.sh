#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: kaelthasmanu (Manuel)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/kaelthasmanu/SquidStats

APP="SquidStats"
var_tags="${var_tags:-proxy;monitoring;dashboard}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-16}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/squidstats ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  RELEASE=$(curl -fsSL https://api.github.com/repos/kaelthasmanu/SquidStats/releases/latest | jq -r .tag_name)
  if [[ ! -f /opt/squidstats_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/squidstats_version.txt)" ]]; then
    msg_info "Updating ${APP} to v${RELEASE}"

    # Backup user data
    msg_info "Backing up current installation"
    $STD cp -r /opt/SquidStats /opt/SquidStats-backup

    msg_info "Updating SquidStats"
    cd /opt/SquidStats || exit
    $STD git pull
    source venv/bin/activate
    $STD pip install -r requirements.txt --upgrade

    # Restore user config if exists
    if [[ -f /opt/SquidStats-backup/.env ]]; then
      msg_info "Restoring configuration"
      $STD cp /opt/SquidStats-backup/.env /opt/SquidStats/.env
    fi

    # Update version file
    echo "${RELEASE}" >"/opt/squidstats_version.txt"

    $STD systemctl restart squidstats
    msg_ok "Updated successfully!"

    # Cleanup
    rm -rf /opt/SquidStats-backup
  else
    msg_ok "No update required. ${APP} is already at v${RELEASE}."
  fi
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access SquidStats using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:5000${CL}"
echo -e "${INFO}${YW} Squid Proxy is running on port:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3128${CL}"
echo -e "${INFO}${YW} Default credentials: Check SquidStats documentation${CL}"
echo -e "${INFO}${YW} Configuration files:${CL}"
echo -e "${TAB}${GATEWAY}- SquidStats: /opt/squidstats/.env${CL}"
echo -e "${TAB}${GATEWAY}- Squid: /etc/squid/squid.conf${CL}"
