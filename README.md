# Net Watchdog

![Shell](https://img.shields.io/badge/language-shell-green)
![License](https://img.shields.io/badge/license-MIT-blue)
![Release](https://img.shields.io/github/v/release/lengordy/net-watchdog)
![Status](https://img.shields.io/badge/status-production-brightgreen)

Self-healing network watchdog for Docker-based VPS environments.

Detects network degradation and applies controlled, prioritized recovery.

---

## Quick Start

Clone the repository:

```bash
git clone https://github.com/lengordy/net-watchdog.git
cd net-watchdog
```

Set Telegram credentials inside `net-watchdog.sh`:

```bash
export TG_TOKEN=your_bot_token
export TG_CHAT_ID=your_chat_id
```

Run once:

```bash
bash net-watchdog.sh
```

Optional: enable systemd timer:

```bash
sudo cp examples/systemd/net-watchdog.* /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now net-watchdog.timer
```

---

## Overview

Net Watchdog evaluates multiple health layers:

- Default route availability
- Multi-target ping
- DNS resolution
- HTTPS reachability
- Local TCP port connectivity
- Docker daemon state
- Container running state
- Docker-internal DNS
- Memory pressure
- MTU validation

Failures are confirmed before any recovery action is triggered.

---

## Recovery Strategy

Recovery is applied in controlled stages:

1. Restart container  
2. Restart Docker daemon  
3. Restart systemd-resolved  
4. Restart systemd-networkd  
5. Optional system reboot (explicitly enabled)

Anti-flap logic and cooldown intervals prevent aggressive restarts.

---

## Modes

Selftest:

```bash
SELFTEST=1 bash net-watchdog.sh
```

Diagnostic mode (no recovery):

```bash
DIAG=1 bash net-watchdog.sh
```

---

## Configuration

All configuration is environment-based.

Required:

```bash
TG_TOKEN=your_bot_token
TG_CHAT_ID=your_chat_id
```

Optional tuning:

```bash
DNS_HOST=example.com
DNS_SERVER=8.8.8.8
VPN_PORT=443
VPN_CONTAINER=app

MAX_FAILS=2
ACTION_COOLDOWN_SEC=60
MAX_RAM_PERCENT=90
REBOOT_THRESHOLD=5
FORCE_REBOOT=0
```

---

## Requirements

- Linux
- bash
- curl
- iproute2
- ping
- dig
- docker (recommended)
- systemd

---

## License

MIT
