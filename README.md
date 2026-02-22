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

It continuously validates infrastructure integrity using resilient,
multi-layer health verification::

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
-   Dual-protocol DNS validation (UDP primary + TCP fallback)
-   HTTPS reachability test
-   Local TCP socket validation
-   Docker daemon health
-   Container runtime state
-   Docker internal DNS validation
-   Memory usage watchdog
-   MTU probing
-   Container uptime-based grace handling

------------------------------------------------------------------------

### DNS Stability Design

DNS verification uses UDP as primary transport with TCP fallback.
If UDP resolution fails but TCP succeeds, the event is treated as
transient network jitter and does not trigger degradation state.

Only simultaneous UDP and TCP failure is considered DNS degradation.

This design eliminates false-positive alerts in real-world VPS
environments where occasional UDP packet loss may occur.

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

## What's New (v1.2.0)

-   Resilient dual-protocol DNS validation (UDP primary + TCP fallback)
-   Eliminates false-positive DNS degradation caused by transient UDP jitter
-   Improved production stability under network micro-fluctuations
-   No additional services required (no local DNS cache dependency)
-   Maintains deterministic recovery logic and anti-flap protection

------------------------------------------------------------------------

## License

MIT

---

## Execution Flow

```mermaid
flowchart TD

A[systemd timer] --> B[watchdog execution]
B --> C{health validation}

C -->|healthy| D[exit]

C -->|degraded| E[increment failure counter]

E --> F{threshold reached}

F -->|no| D

F -->|yes| G{cooldown satisfied?}

G -->|no| D

G -->|yes| H[execute recovery sequence]

H --> I[re-validate infrastructure]

I -->|recovered| J[reset state + notify]

I -->|still degraded| K[wait for next cycle or escalate]
