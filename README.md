# TeamSpeak 6 Proxmox HelperScript

Creates a Debian 13 LXC container and installs the latest official TeamSpeak 6 Server beta release. The helper supports Debian `amd64` and `arm64` containers and runs the server as an unprivileged system user under systemd.

## Use from Proxmox VE

Run the following on the Proxmox host:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/PfefferT/proxmox-teamspeak6-helper/main/ct/teamspeak6-server.sh)"
```

The script sets `COMMUNITY_SCRIPTS_URL` to this repository before loading the Community Scripts core, so the core fetches the matching installer here. If you use a fork, set `COMMUNITY_SCRIPTS_URL` to your fork's raw base URL before running the script.

## Network ports

- Voice: UDP `9987`
- File transfer: TCP `30033`
- Optional ServerQuery ports depend on the server configuration.

Allow the required ports in the Proxmox firewall and any firewall in front of the host.

## Updating

Use the normal Proxmox VE Helper-Scripts update action in the container. It checks the latest official GitHub release and preserves files in `/opt/teamspeak6-server` while replacing the server files.

## Beta notice

The official TeamSpeak 6 self-hosted server is beta software. Its included beta license currently has a 32-slot limit and is renewed by TeamSpeak during the beta period. TeamSpeak 3 licenses do not work with TeamSpeak 6, and the official project currently documents no TS3-to-TS6 migration path.

## Attribution

The helper layout is adapted from the [Proxmox VE TeamSpeak 3 helper](https://github.com/community-scripts/ProxmoxVE/blob/main/ct/teamspeak-server.sh). That project is licensed under MIT. The TeamSpeak 6 server binaries are downloaded from the [official TeamSpeak 6 Server releases](https://github.com/teamspeak/teamspeak6-server/releases).
