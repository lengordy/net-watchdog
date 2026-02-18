# Net Watchdog

![Shell](https://img.shields.io/badge/language-shell-green)
![License](https://img.shields.io/badge/license-MIT-blue)
![Release](https://img.shields.io/github/v/release/lengordy/net-watchdog)
![Status](https://img.shields.io/badge/status-production-brightgreen)

Production-grade self-healing network watchdog for Docker-based VPS environments.

Net Watchdog performs multi-layer health checks and applies prioritized recovery logic to automatically remediate network and container-level failures.

---

## Features

- Multi-layer health checks (route, ping, DNS, HTTPS)
- Local TCP port verification
- Docker daemon health check
- Docker container state verification
- Docker-internal DNS probe
- RAM usage threshold monitoring
- MTU probe
- Anti-flap fail counter
- Cooldown between recovery attempts
- Prioritized recovery strategy
- SELFTEST mode
- DIAG mode
- Optional auto-reboot (disabled by default)
- Log auto-truncation

---

## Architecture

Health layers evaluated:

1. Network connectivity (route + ping)
2. DNS resolution
3. HTTPS reachability
4. Local TCP port
5. Docker daemon state
6. Container running state
7. Docker internal DNS
8. Memory pressure

Recovery order:

1. Restart container
2. Restart Docker
3. Restart systemd-resolved
4. Restart systemd-networkd
5. Optional system reboot (if explicitly enabled)

Recovery is triggered only after consecutive confirmed failures.

---

## Requirements

- Linux
- bash
- curl
- iproute2
- ping
- dig
- docker (optional but recommended)
- systemd (for restart logic)

---

## Configuration

Configuration is handled via environment variables.

Required (Telegram alerts):

TG_TOKEN=your_bot_token  
TG_CHAT_ID=your_chat_id  

Optional:

DNS_HOST=example.com  
DNS_SERVER=8.8.8.8  
VPN_PORT=443  
VPN_CONTAINER=app  

MAX_FAILS=2  
ACTION_COOLDOWN_SEC=60  
MAX_RAM_PERCENT=90  
REBOOT_THRESHOLD=5  
FORCE_REBOOT=0  

Custom paths (optional):

LOG=./net-watchdog.log  
STATE_FAILS=./.net-watchdog.fail  
STATE_LAST_ACTION=./.net-watchdog.last_action  
STATE_LAST_STATUS=./.net-watchdog.last_status  
LOCK_FILE=./.net-watchdog.lock  

---

## Usage

Make executable:

chmod +x net-watchdog.sh

Run once:

./net-watchdog.sh

---

## Modes

Selftest (sends confirmation message):

SELFTEST=1 ./net-watchdog.sh

Diagnostic mode (runs checks without recovery):

DIAG=1 ./net-watchdog.sh

---

## Recovery Logic

Recovery actions are applied only if:

- MAX_FAILS consecutive checks fail
- Cooldown period has elapsed

This prevents flapping and aggressive restarts.

---

## Auto Reboot

Emergency reboot can be enabled explicitly:

FORCE_REBOOT=1 ./net-watchdog.sh

Reboot occurs only if failures exceed REBOOT_THRESHOLD.

---

## License

MIT
