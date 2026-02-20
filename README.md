# Net Watchdog

![language](https://img.shields.io/badge/language-shell-green)
![license](https://img.shields.io/badge/license-MIT-blue)
![release](https://img.shields.io/github/v/release/lengordy/net-watchdog?label=release)
![status](https://img.shields.io/badge/status-production-brightgreen)

Production-grade self-healing watchdog for Docker-based VPS
infrastructure.

Designed to detect network degradation, container instability and
infrastructure anomalies, then apply prioritized recovery with anti-flap
protection and controlled escalation.

------------------------------------------------------------------------

## Overview

Net Watchdog is a lightweight infrastructure guardian for single-node
Docker VPS environments.

It continuously validates:

-   Network availability
-   DNS integrity
-   HTTPS reachability
-   Container health
-   Docker daemon state
-   Memory pressure
-   MTU viability

When degradation is confirmed (not just transient noise), it executes
structured recovery steps with cooldown validation and escalation
control.

No blind loops. No aggressive restarts. No false-positive storms.

------------------------------------------------------------------------

## Quick Start

``` bash
git clone https://github.com/lengordy/net-watchdog.git
cd net-watchdog
chmod +x net-watchdog.sh
```

Create environment configuration:

``` bash
cp .env.example .env
```

Or export variables manually:

``` bash
export TG_TOKEN=your_bot_token
export TG_CHAT_ID=your_chat_id
```

Run once:

``` bash
./net-watchdog.sh
```

------------------------------------------------------------------------

## Systemd Integration (Recommended)

``` bash
sudo cp examples/systemd/net-watchdog.* /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now net-watchdog.timer
```

------------------------------------------------------------------------

## Health Checks

-   Default route validation
-   Multi-target ICMP probing
-   DNS resolution check
-   HTTPS reachability test
-   Local TCP socket validation
-   Docker daemon health
-   Container runtime state
-   Docker internal DNS validation
-   Memory usage watchdog
-   MTU probing
-   Container uptime-based grace handling

------------------------------------------------------------------------

## Recovery Strategy

Recovery logic is deterministic and escalation-based.

Priority order:

1.  Restart target container
2.  Restart Docker daemon
3.  Restart `systemd-resolved`
4.  Restart `systemd-networkd`
5.  Optional controlled reboot (explicitly enabled)

Recovery is triggered only after:

-   Consecutive failure threshold
-   Cooldown validation
-   Anti-flap protection

This prevents oscillation and infrastructure thrashing.

------------------------------------------------------------------------

## Operating Modes

Diagnostic mode (no recovery):

``` bash
DIAG=1 ./net-watchdog.sh
```

Self-test mode:

``` bash
SELFTEST=1 ./net-watchdog.sh
```

Emergency reboot mode (explicitly enabled):

``` bash
FORCE_REBOOT=1 ./net-watchdog.sh
```

------------------------------------------------------------------------

## What's New (v1.1.0)

-   Container uptime-based VPN grace logic (`VPN_GRACE_SEC`)
-   Suppresses false alerts during planned restarts
-   Explicit `NET OK` notification after confirmed recovery
-   Improved Telegram state transitions
-   Added `.env.example` configuration template

------------------------------------------------------------------------

## License

MIT
