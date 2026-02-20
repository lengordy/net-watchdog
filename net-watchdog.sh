#!/usr/bin/env bash
set -euo pipefail

### ===== CONFIG (via ENV) ========================================

TG_TOKEN="${TG_TOKEN:-}"
TG_CHAT_ID="${TG_CHAT_ID:-}"

LOG="${LOG:-./net-watchdog.log}"

STATE_FAILS="${STATE_FAILS:-./.net-watchdog.fail}"
STATE_LAST_ACTION="${STATE_LAST_ACTION:-./.net-watchdog.last_action}"
STATE_LAST_STATUS="${STATE_LAST_STATUS:-./.net-watchdog.last_status}"
LOCK_FILE="${LOCK_FILE:-./.net-watchdog.lock}"

MAX_FAILS="${MAX_FAILS:-2}"
ACTION_COOLDOWN_SEC="${ACTION_COOLDOWN_SEC:-60}"
MAX_RAM_PERCENT="${MAX_RAM_PERCENT:-90}"
REBOOT_THRESHOLD="${REBOOT_THRESHOLD:-5}"

DNS_HOST="${DNS_HOST:-example.com}"
DNS_SERVER="${DNS_SERVER:-8.8.8.8}"
PING_TARGETS=("1.1.1.1" "8.8.8.8")

VPN_PORT="${VPN_PORT:-443}"
VPN_CONTAINER="${VPN_CONTAINER:-app}"
VPN_GRACE_SEC="${VPN_GRACE_SEC:-30}"

SELFTEST="${SELFTEST:-0}"
DIAG="${DIAG:-0}"
FORCE_REBOOT="${FORCE_REBOOT:-0}"

### ================================================================

ts() { date "+%Y-%m-%d %H:%M:%S"; }
now_epoch() { date +%s; }

log() {
  [[ -f "$LOG" && $(stat -c%s "$LOG") -gt 5000000 ]] && truncate -s 0 "$LOG"
  echo "$(ts) $*" >> "$LOG"
}

tg() {
  [[ -z "$TG_TOKEN" || -z "$TG_CHAT_ID" ]] && return 0
  curl -s --max-time 8 \
    -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
    -d chat_id="${TG_CHAT_ID}" \
    --data-urlencode "text=$1" >/dev/null || true
}

with_lock() {
  exec 9>"$LOCK_FILE"
  if ! flock -n 9; then
    log "[INFO] another instance running, skip"
    exit 0
  fi
}

cooldown_ok() {
  local last=0
  [[ -f "$STATE_LAST_ACTION" ]] && last=$(cat "$STATE_LAST_ACTION" 2>/dev/null || echo 0)
  (( $(now_epoch) - last >= ACTION_COOLDOWN_SEC ))
}

mark_action() { now_epoch > "$STATE_LAST_ACTION"; }

fail_inc() {
  local n=0
  [[ -f "$STATE_FAILS" ]] && n=$(cat "$STATE_FAILS" 2>/dev/null || echo 0)
  n=$((n + 1))
  echo "$n" >"$STATE_FAILS"
  echo "$n"
}

fail_reset() { rm -f "$STATE_FAILS"; }

status_changed() {
  local s="$1"
  [[ -f "$STATE_LAST_STATUS" && "$(cat "$STATE_LAST_STATUS")" == "$s" ]] && return 1
  echo "$s" >"$STATE_LAST_STATUS"
  return 0
}

get_container_uptime() {
  command -v docker >/dev/null 2>&1 || return 0
  local started
  started=$(docker inspect -f '{{.State.StartedAt}}' "$VPN_CONTAINER" 2>/dev/null) || return 0
  local now started_epoch
  now=$(date +%s)
  started_epoch=$(date -d "$started" +%s 2>/dev/null) || return 0
  echo $(( now - started_epoch ))
}

# ---------------- system info ----------------

HOST=$(hostname 2>/dev/null || echo "unknown")
UPTIME=$(uptime -p 2>/dev/null || echo "unknown")
PUB_IP=$(curl -s --max-time 3 https://api.ipify.org || echo "n/a")

# ---------------- checks ----------------

check_route() { ip route show default >/dev/null 2>&1; }

check_ping() {
  for t in "${PING_TARGETS[@]}"; do
    ping -c1 -W1 "$t" >/dev/null 2>&1 && return 0
  done
  return 1
}

check_dns() {
  timeout 3 dig +time=2 +tries=1 @"$DNS_SERVER" "$DNS_HOST" A >/dev/null 2>&1
}

check_https() {
  timeout 4 curl -s --connect-timeout 3 https://"$DNS_HOST" >/dev/null 2>&1
}

check_vpn_port() {
  ss -lnt 2>/dev/null | awk '{print $4}' | grep -qE "(:|\\])${VPN_PORT}\$"
}

check_vpn_tcp() {
  timeout 3 bash -c "</dev/tcp/127.0.0.1/${VPN_PORT}" >/dev/null 2>&1
}

check_container_running() {
  command -v docker >/dev/null 2>&1 || return 0
  timeout 3 docker inspect -f '{{.State.Running}}' "$VPN_CONTAINER" 2>/dev/null | grep -q true
}

check_docker_dns() {
  command -v docker >/dev/null 2>&1 || return 0
  timeout 3 docker exec "$VPN_CONTAINER" sh -lc \
    "getent ahosts $DNS_HOST >/dev/null 2>&1" >/dev/null 2>&1
}

check_docker_alive() {
  command -v docker >/dev/null 2>&1 || return 0
  timeout 3 docker info >/dev/null 2>&1
}

check_memory() {
  local used
  used=$(free | awk '/Mem:/ {printf("%.0f"), $3/$2*100}')
  [[ "$used" -lt "$MAX_RAM_PERCENT" ]]
}

mtu_probe() {
  ping -c1 -W1 -M do -s 1472 1.1.1.1 >/dev/null 2>&1 && { echo "mtu>=1500"; return; }
  ping -c1 -W1 -M do -s 1360 1.1.1.1 >/dev/null 2>&1 && { echo "mtu>=1388"; return; }
  echo "mtu_fail"
}

# ---------------- main ----------------

[[ "$SELFTEST" != "1" && "$DIAG" != "1" ]] && with_lock

if [[ "$SELFTEST" == "1" ]]; then
  tg "NET SELFTEST OK

Host: $HOST
Uptime: $UPTIME
IP: $PUB_IP"
  exit 0
fi

ROUTE=0 PING=0 DNS=0 HTTPS=0 VPN=0 DOCKER_DNS=0 DOCKER_ALIVE=0 RAM=0 CONTAINER=0
MTU_NOTE=$(mtu_probe)

check_route && ROUTE=1
check_ping && PING=1
check_dns && DNS=1
check_https && HTTPS=1
check_vpn_port && check_vpn_tcp && VPN=1
check_docker_dns && DOCKER_DNS=1
check_docker_alive && DOCKER_ALIVE=1
check_memory && RAM=1
check_container_running && CONTAINER=1

STATUS="route=$ROUTE ping=$PING dns=$DNS https=$HTTPS vpn=$VPN docker_dns=$DOCKER_DNS docker=$DOCKER_ALIVE container=$CONTAINER ram=$RAM $MTU_NOTE"

# ---------- ALL OK ----------
if [[ $ROUTE -eq 1 && $PING -eq 1 && $DNS -eq 1 && $VPN -eq 1 && $RAM -eq 1 ]]; then
  if [[ -f "$STATE_FAILS" ]]; then
    tg "NET OK

Host: $HOST
IP: $PUB_IP

$STATUS"
  fi
  fail_reset
  echo "OK" > "$STATE_LAST_STATUS"
  exit 0
fi

# ---- GRACE FOR CONTAINER RESTART ----
if [[ $VPN -eq 0 ]]; then
  UPTIME_SEC=$(get_container_uptime)
  if [[ "$UPTIME_SEC" -lt "$VPN_GRACE_SEC" ]]; then
    log "[INFO] vpn fail ignored (uptime ${UPTIME_SEC}s < ${VPN_GRACE_SEC}s)"
    exit 0
  fi
fi

FAILS=$(fail_inc)
log "[WARN] $STATUS fail=$FAILS"

if status_changed "$STATUS" || [[ $FAILS -ge $MAX_FAILS ]]; then
  tg "NET DEGRADED ($FAILS/$MAX_FAILS)

$STATUS"
fi

[[ $FAILS -lt $MAX_FAILS ]] && exit 0
! cooldown_ok && exit 0

mark_action
tg "RECOVERY ATTEMPT

$STATUS"

[[ $RAM -eq 0 ]] && fix_container
[[ $VPN -eq 0 ]] && fix_container
[[ $DOCKER_DNS -eq 0 || $DOCKER_ALIVE -eq 0 ]] && fix_docker
[[ $DNS -eq 0 && $PING -eq 1 ]] && fix_resolved
[[ $ROUTE -eq 0 || $PING -eq 0 ]] && fix_networkd

sleep 4

ROUTE=0 PING=0 DNS=0 VPN=0 RAM=0
check_route && ROUTE=1
check_ping && PING=1
check_dns && DNS=1
check_vpn_port && check_vpn_tcp && VPN=1
check_memory && RAM=1

if [[ $ROUTE -eq 1 && $PING -eq 1 && $DNS -eq 1 && $VPN -eq 1 && $RAM -eq 1 ]]; then
  tg "NET RESTORED"
  fail_reset
else
  if [[ $FAILS -ge $REBOOT_THRESHOLD && "$FORCE_REBOOT" == "1" ]]; then
    tg "CRITICAL FAILURE - REBOOTING"
    sleep 2
    reboot
  else
    tg "STILL BROKEN"
  fi
fi
