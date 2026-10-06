#!/usr/bin/env bash

# Based on the TeamSpeak 3 installer from Proxmox VE Helper-Scripts.
# Original project license: MIT | https://github.com/community-scripts/ProxmoxVE/blob/main/LICENSE
# Source: https://github.com/teamspeak/teamspeak6-server

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

latest_release() {
  curl -fsSL https://api.github.com/repos/teamspeak/teamspeak6-server/releases/latest |
    grep -m1 '"tag_name":' |
    cut -d '"' -f 4
}

server_architecture() {
  case "$(dpkg --print-architecture)" in
    amd64) echo "amd64" ;;
    arm64) echo "arm64" ;;
    *) msg_error "TeamSpeak 6 does not provide a server binary for this architecture."; exit 1 ;;
  esac
}

install_teamspeak6() {
  local release architecture asset_url temp_dir
  release="$(latest_release)"
  if [[ -z "$release" ]]; then
    msg_error "Could not determine the latest TeamSpeak 6 release."
    exit 1
  fi
  architecture="$(server_architecture)"

  msg_info "Installing dependencies"
  $STD apt-get install -y ca-certificates curl libstdc++6 tar xz-utils
  msg_ok "Installed dependencies"

  asset_url="https://github.com/teamspeak/teamspeak6-server/releases/download/$release/teamspeak6-server-linux-$architecture.tar.xz"
  temp_dir="$(mktemp -d)"
  mkdir -p "$temp_dir/unpacked" /opt/teamspeak6-server

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
  cp -a "$temp_dir/unpacked/." /opt/teamspeak6-server/
  rm -rf "$temp_dir"

  if ! getent passwd teamspeak6 >/dev/null; then
    useradd --system --user-group --home-dir /opt/teamspeak6-server --shell /usr/sbin/nologin --no-create-home teamspeak6
  fi
  chown -R teamspeak6:teamspeak6 /opt/teamspeak6-server
  echo "$release" >/opt/teamspeak6-server/.version

  msg_info "Creating TeamSpeak 6 service"
  cat <<'EOF' >/etc/systemd/system/teamspeak6-server.service
[Unit]
Description=TeamSpeak 6 Server
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
WorkingDirectory=/opt/teamspeak6-server
User=teamspeak6
Group=teamspeak6
ExecStart=/opt/teamspeak6-server/tsserver --accept-license
Restart=on-failure
RestartSec=5
LimitNOFILE=65535
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=full
ProtectHome=true
ReadWritePaths=/opt/teamspeak6-server

[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  systemctl enable -q --now teamspeak6-server
  msg_ok "Installed and started TeamSpeak 6 $release"
}

install_teamspeak6
