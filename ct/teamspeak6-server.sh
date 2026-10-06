#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")

# Based on the TeamSpeak 3 helper script from Proxmox VE Helper-Scripts.
# Original project license: MIT | https://github.com/community-scripts/ProxmoxVE/blob/main/LICENSE
# Source: https://github.com/teamspeak/teamspeak6-server
APP="Teamspeak6-Server"
var_tags="${var_tags:-voice;communication}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-4}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="yes"
var_unprivileged="1"

header_info "$APP"
variables
color
catch_errors

latest_release() {
  curl -fsSL https://api.github.com/repos/teamspeak/teamspeak6-server/releases/latest |
    grep -m1 '"tag_name":' |
    cut -d '"' -f 4
}

update_deb_based() {
  if [[ ! -d /opt/teamspeak6-server ]]; then
    msg_error "No ${APP} installation found!"
    exit 1
  fi

  local release current_version architecture asset_url temp_dir
  release="$(latest_release)"
  if [[ -z "$release" ]]; then
    msg_error "Could not determine the latest TeamSpeak 6 release."
    exit 1
  fi

  current_version="$(cat /opt/teamspeak6-server/.version 2>/dev/null || true)"
  if [[ "$release" == "$current_version" ]]; then
    msg_ok "TeamSpeak 6 is already up to date ($release)."
    return
  fi

  case "$(dpkg --print-architecture)" in
    amd64) architecture="amd64" ;;
    arm64) architecture="arm64" ;;
    *) msg_error "TeamSpeak 6 does not provide a server binary for this architecture."; exit 1 ;;
  esac

  asset_url="https://github.com/teamspeak/teamspeak6-server/releases/download/$release/teamspeak6-server-linux-$architecture.tar.xz"
  temp_dir="$(mktemp -d)"
  mkdir -p "$temp_dir/unpacked"
  msg_info "Downloading TeamSpeak 6 $release"
  if ! curl -fsSL --retry 3 "$asset_url" -o "$temp_dir/server.tar.xz"; then
    rm -rf "$temp_dir"
    msg_error "Could not download TeamSpeak 6 $release."
    exit 1
  fi
  if ! tar -xJf "$temp_dir/server.tar.xz" -C "$temp_dir/unpacked"; then
    rm -rf "$temp_dir"
    msg_error "Could not unpack TeamSpeak 6 $release."
    exit 1
  fi

  msg_info "Stopping TeamSpeak 6"
  systemctl stop teamspeak6-server
  msg_ok "Stopped TeamSpeak 6"
  cp -a "$temp_dir/unpacked/." /opt/teamspeak6-server/
  echo "$release" >/opt/teamspeak6-server/.version
  chown -R teamspeak6:teamspeak6 /opt/teamspeak6-server
  rm -rf "$temp_dir"
  msg_ok "Updated TeamSpeak 6 to $release"

  msg_info "Starting TeamSpeak 6"
  systemctl start teamspeak6-server
  msg_ok "Started TeamSpeak 6"
}

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  run_os_update
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Connect to the server on the container IP. Default voice port: UDP 9987.${CL}"
echo -e "${INFO}${YW}Default file-transfer port: TCP 30033.${CL}"
