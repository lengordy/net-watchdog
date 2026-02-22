# Net Watchdog Architecture

## 1. Design Philosophy

Net Watchdog is designed as a **single-node, self-healing guardian**
for Docker-based VPS environments.

Key principles:

- Deterministic recovery logic
- Noise-resistant degradation detection
- Anti-flap protection
- Minimal external dependencies
- No persistent daemon process
- Systemd timer-driven execution

The watchdog assumes a single-host infrastructure model and focuses on
stability, not clustering or high-availability orchestration.

---

## 2. Execution Model

Net Watchdog runs as a `systemd` timer-triggered one-shot service.

Flow:

1. Timer triggers execution.
2. Script performs a full health validation cycle.
3. If healthy → exit immediately.
4. If degraded → confirm consecutive failures.
5. If threshold reached → execute prioritized recovery.
6. Apply cooldown before further actions.

There is no background loop. Each run is isolated and state-aware.

---

## 3. State Tracking

State is maintained using lightweight runtime files:

- `STATE_FAILS` — consecutive failure counter
- `STATE_LAST_ACTION` — last recovery timestamp
- `STATE_LAST_STATUS` — last reported status

This enables:

- Failure confirmation logic
- Anti-flap protection
- Cooldown enforcement
- Clean state reset on recovery

All state is ephemeral and stored locally.

---

## 4. Health Verification Layers

Net Watchdog validates multiple infrastructure layers:

### Network Layer
- Default route validation
- Multi-target ICMP probing
- MTU viability probing

### DNS Layer
- UDP resolution (primary)
- TCP resolution fallback
- Jitter-resistant degradation detection

DNS is considered degraded **only if both UDP and TCP fail**.

### Application Layer
- HTTPS reachability
- Local TCP socket validation

### Container Layer
- Container running state
- Docker internal DNS resolution
- Docker daemon health

### Resource Layer
- Memory pressure validation

---

## 5. Failure Confirmation Model

A degradation state is only acknowledged after:

- Consecutive failure threshold (`MAX_FAILS`)
- Status change validation
- Cooldown compliance

This prevents:

- Transient network jitter alerts
- Restart storms
- Oscillation loops

---

## 6. Recovery Escalation Order

Recovery actions are deterministic and prioritized:

1. Restart target container
2. Restart Docker daemon
3. Restart `systemd-resolved`
4. Restart `systemd-networkd`
5. Optional forced reboot (explicitly enabled)

Each recovery attempt is rate-limited by cooldown logic.

---

## 7. Grace Logic

When a container restart is detected, a grace window
(`VPN_GRACE_SEC`) suppresses false VPN degradation alerts.

This prevents watchdog interference during planned updates.

---

## 8. Security & Safety

- No privileged background daemon
- No remote control endpoints
- No automatic reboot unless explicitly enabled
- No external configuration dependencies beyond ENV

---

## 9. Intended Use Case

Net Watchdog is designed for:

- Single-node VPS environments
- Docker-based infrastructure
- VPN nodes
- Self-managed personal infrastructure
- Lightweight production setups

It is not intended for clustered HA systems.

---

## 10. Architectural Scope

This project focuses on:

- Stability
- Predictability
- Controlled recovery
- Infrastructure hygiene

It deliberately avoids:

- Distributed coordination
- Complex orchestration
- External monitoring dependencies
