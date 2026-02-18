# Net Watchdog

![Shell](https://img.shields.io/badge/language-shell-green)
![License](https://img.shields.io/badge/license-MIT-blue)
![Release](https://img.shields.io/github/v/release/lengordy/net-watchdog)
![Status](https://img.shields.io/badge/status-production-brightgreen)

Production-grade self-healing network watchdog for Docker-based VPS environments.

Net Watchdog performs multi-layer health checks and applies prioritized recovery logic to automatically remediate network and container-level failures.

---

## Quick Start

1. Set Telegram credentials inside `net-watchdog.sh`:

    TG_TOKEN=your_bot_token  
    TG_CHAT_ID=your_chat_id  

2. Make executable:

    chmod +x net-watchdog.sh

3. Run once:

    ./net-watchdog.sh

4. (Optional) Install systemd timer:

    sudo cp examples/systemd/net-watchdog.service /etc/systemd/system/  
    sudo cp examples/systemd/net-watchdog.timer /etc/systemd/system/  
    sudo systemctl daemon-reload  
    sudo systemctl enable --now net-watchdog.timer  

---

## Overview

The watchdog evaluates multiple health layers:

- Default route availability
- Multi-target ping
- DNS resolution
- HTTPS reachability
- Local TCP port connectivity
- Docker daemon state
- Container running state
- Docker-internal DNS resolution
- Memory pressure
- MTU validation

Failures are counted and confirmed before recovery is attempted.

---

## Recovery Strategy

Recovery is triggered only after consecutive confirmed failures.

Actions are applied in the following order:

1. Restart container
2. Restart Docker daemon
3. Restart systemd-resolved
4. Restart systemd-networkd
5. Optional system reboot (if explicitly enabled)

Cooldown logic prevents flapping and aggressive restarts.

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

## Modes

Selftest (sends confirmation message):

    SELFTEST=1 ./net-watchdog.sh

Diagnostic mode (runs checks without recovery actions):

    DIAG=1 ./net-watchdog.sh

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
