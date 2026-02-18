# Net Watchdog

Self-healing network watchdog for Docker-based services.

Production-grade Bash watchdog designed for VPS environments running Docker workloads.
Implements multi-layer health checks, anti-flap logic, prioritized recovery and optional Telegram alerts.

---

## Features

- Default route check
- Multi-target ping check
- DNS resolution check (custom DNS server supported)
- HTTPS reachability probe
- Local TCP port verification
- Docker daemon health check
- Docker container state verification
- Docker-internal DNS probe
- RAM usage threshold monitoring
- MTU probe
- Anti-flap fail counter
- Cooldown between recovery attempts
- Prioritized recovery logic
- SELFTEST mode
- DIAG mode
- Optional auto-reboot (disabled by default)
- Log auto-truncation

---

## Architecture

The watchdog evaluates multiple health layers:

1. Network layer (route + ping)
2. DNS layer
3. HTTPS reachability
4. Local service port (TCP connect)
5. Docker daemon health
6. Container running state
7. Docker internal DNS resolution
8. Memory pressure

Recovery actions are prioritized:

1. Restart container
2. Restart Docker
3. Restart systemd-resolved
4. Restart systemd-networkd
5. Optional system reboot (if explicitly enabled)

---

## Requirements

- Linux
- bash
- curl
- iproute2
- ping
- dig
- docker (optional but recommended)
- systemd (for network/docker restart logic)

---

## Configuration

All configuration is handled via environment variables.

Minimum required (for Telegram alerts):

TG_TOKEN=your_bot_token  
TG_CHAT_ID=your_chat_id  

Optional configuration:

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

## Selftest Mode

Simulates success and sends a confirmation message:

SELFTEST=1 ./net-watchdog.sh

SELFTEST and DIAG bypass the lock mechanism.

---

## Diagnostic Mode

Runs all checks but performs no recovery:

DIAG=1 ./net-watchdog.sh

Useful for troubleshooting and monitoring validation.

---

## Recovery Logic

The watchdog only attempts recovery after:

- MAX_FAILS consecutive failed checks
- Cooldown period has elapsed

This prevents flapping and aggressive restarts.

---

## Auto Reboot (Disabled by Default)

To enable emergency reboot after repeated confirmed failures:

FORCE_REBOOT=1 ./net-watchdog.sh

Reboot will only occur if failures exceed REBOOT_THRESHOLD.

---

## Notes

- Designed for single-node VPS environments.
- Portable by default (does not require /run or /var/log).
- Safe to run via cron or systemd timer.
- Does not expose infrastructure-specific values.

---

## License

MIT
