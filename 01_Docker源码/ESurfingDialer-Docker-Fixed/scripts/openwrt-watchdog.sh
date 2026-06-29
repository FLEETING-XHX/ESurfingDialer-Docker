#!/bin/sh
set -eu

CONTAINER_NAME="${CONTAINER_NAME:-ESurfingDialer}"
CHECK_URL="${CHECK_URL:-http://connect.rom.miui.com/generate_204}"
WAN_INTERFACE="${WAN_INTERFACE:-wan}"
FAIL_THRESHOLD="${FAIL_THRESHOLD:-3}"
REBOOT_COOLDOWN_SECONDS="${REBOOT_COOLDOWN_SECONDS:-21600}"
STATE_FILE="${STATE_FILE:-/tmp/esurfing-watchdog.state}"

fail_count=0

while true; do
  if wget -q -T 10 -O /dev/null "$CHECK_URL"; then
    fail_count=0
    sleep 60
    continue
  fi

  fail_count=$((fail_count + 1))
  [ "$fail_count" -lt "$FAIL_THRESHOLD" ] && sleep 30 && continue

  logger -t esurfing-watchdog "network check failed, restarting $CONTAINER_NAME"
  docker restart "$CONTAINER_NAME" >/dev/null 2>&1 || true
  sleep 60

  if wget -q -T 10 -O /dev/null "$CHECK_URL"; then
    fail_count=0
    continue
  fi

  logger -t esurfing-watchdog "container restart did not recover network, reconnecting $WAN_INTERFACE"
  ifdown "$WAN_INTERFACE" || true
  sleep 5
  ifup "$WAN_INTERFACE" || true
  sleep 90

  if wget -q -T 10 -O /dev/null "$CHECK_URL"; then
    docker restart "$CONTAINER_NAME" >/dev/null 2>&1 || true
    fail_count=0
    continue
  fi

  now="$(date +%s)"
  last_reboot="$(cat "$STATE_FILE" 2>/dev/null || echo 0)"
  if [ $((now - last_reboot)) -ge "$REBOOT_COOLDOWN_SECONDS" ]; then
    echo "$now" > "$STATE_FILE"
    logger -t esurfing-watchdog "WAN reconnect failed, rebooting router after cooldown"
    reboot
  else
    logger -t esurfing-watchdog "WAN reconnect failed, reboot cooldown active"
  fi

  fail_count=0
  sleep 300
done
