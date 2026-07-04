#!/bin/sh
set -eu

VERSION="v1.21"
IMAGE_NAME="esurfing-dialer:v1.21"

info() {
  printf '%s\n' "$*"
}

fail() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

command -v docker >/dev/null 2>&1 || fail "Docker is not installed or not in PATH."
docker compose version >/dev/null 2>&1 || fail "Docker Compose plugin is not available. Please install docker compose first."

arch="$(uname -m 2>/dev/null || echo unknown)"
case "$arch" in
  x86_64|amd64)
    package_arch="amd64"
    ;;
  aarch64|arm64)
    package_arch="arm64"
    ;;
  *)
    fail "Unsupported CPU architecture: $arch"
    ;;
esac

free_kb="$(df -Pk . | awk 'NR==2 {print $4}')"
if [ -n "$free_kb" ] && [ "$free_kb" -lt 1048576 ]; then
  fail "Not enough free disk space. At least 1GB is recommended."
fi

image_file="images/esurfing-dialer-${VERSION}-${package_arch}.tar.gz"
[ -s "$image_file" ] || fail "Offline image not found: $image_file"

mkdir -p data

if [ -f ".env" ]; then
  info ".env already exists. Keeping existing configuration."
else
  printf 'Campus network account: '
  IFS= read -r dialer_user
  [ -n "$dialer_user" ] || fail "Account cannot be empty."

  printf 'Campus network password: '
  stty_state=""
  if [ -t 0 ]; then
    stty_state="$(stty -g 2>/dev/null || true)"
    stty -echo 2>/dev/null || true
  fi
  IFS= read -r dialer_password
  if [ -n "$stty_state" ]; then
    stty "$stty_state" 2>/dev/null || true
    printf '\n'
  fi
  [ -n "$dialer_password" ] || fail "Password cannot be empty."

  cat > .env <<EOF
DIALER_USER=$dialer_user
DIALER_PASSWORD=$dialer_password
DIALER_IMAGE=$IMAGE_NAME
DIALER_BACKEND=auto

DIALER_MAC_ADDRESS=
DIALER_CLIENT_ID=

LOGIN_RETRY_INITIAL_SECONDS=5
LOGIN_RETRY_MAX_SECONDS=60
HEARTBEAT_FAILURE_THRESHOLD=3
PORTAL_DETECTION_THRESHOLD=3
NETWORK_CHECK_INTERVAL_SECONDS=5
HEALTH_AUTH_MAX_AGE_SECONDS=300
LOG_RETENTION_DAYS=3
NETWORK_CHECK_URLS=http://www.gstatic.com/generate_204,http://connect.rom.miui.com/generate_204,http://www.msftconnecttest.com/connecttest.txt
EOF
  chmod 600 .env 2>/dev/null || true
fi

if [ -f "data/device-state.json" ]; then
  info "Keeping existing data/device-state.json device identity."
fi

info "Loading offline image: $image_file"
if command -v gzip >/dev/null 2>&1; then
  gzip -dc "$image_file" | docker load
else
  docker load -i "$image_file"
fi

info "Starting ESurfingDialer with local image only."
docker compose up -d --no-build --pull never

info "Container status:"
docker ps --filter "name=ESurfingDialer"

info "Recent logs:"
docker logs --tail 80 ESurfingDialer 2>/dev/null || true

if [ -f "data/health.json" ]; then
  info "Health file:"
  cat data/health.json
else
  info "data/health.json has not been created yet. Check logs after 30 seconds."
fi
