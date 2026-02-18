# Net Watchdog

![shell](https://img.shields.io/badge/language-shell-green)
![license](https://img.shields.io/badge/license-MIT-blue)
![release](https://img.shields.io/github/v/release/lengordy/net-watchdog?label=release)
![status](https://img.shields.io/badge/status-production-brightgreen)

Production-grade self-healing watchdog for Docker-based VPS environments.

Detects network degradation and applies controlled, prioritized recovery.

---

## Quick Start

```bash
git clone https://github.com/lengordy/net-watchdog.git
cd net-watchdog
chmod +x net-watchdog.sh
```

Set required environment variables:

```bash
export TG_TOKEN=your_bot_token
export TG_CHAT_ID=your_chat_id
```

Run once:

```bash
./net-watchdog.sh
```

Optional: enable systemd timer

```bash
sudo cp examples/systemd/net-watchdog.* /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now net-watchdog.timer
```

---

## What It Checks

- Default route
- Multi-target ping
- DNS resolution
- HTTPS reachability
- Local TCP port
- Docker daemon
- Container state
- Docker internal DNS
- Memory pressure
- MTU viability

---

## Recovery Strategy

Recovery is controlled and anti-flap protected.

Priority order:

1. Restart container
2. Restart Docker
3. Restart systemd-resolved
4. Restart systemd-networkd
5. Optional reboot (explicitly enabled only)

Actions are triggered only after consecutive failures and cooldown validation.

---

## Modes

Run diagnostic only:

```bash
DIAG=1 ./net-watchdog.sh
```

Run self-test:

```bash
SELFTEST=1 ./net-watchdog.sh
```

Force emergency reboot after threshold:

```bash
FORCE_REBOOT=1 ./net-watchdog.sh
```

---

## License

MIT
