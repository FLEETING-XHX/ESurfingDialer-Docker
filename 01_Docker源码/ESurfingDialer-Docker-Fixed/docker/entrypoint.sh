#!/bin/sh
set -eu

if [ -z "${DIALER_USER:-}" ]; then
  echo "ERROR: DIALER_USER is required" >&2
  exit 2
fi

if [ -z "${DIALER_PASSWORD:-}" ]; then
  echo "ERROR: DIALER_PASSWORD is required" >&2
  exit 2
fi

mkdir -p "${STATE_DIR:-/data}"
chown -R esurfing:esurfing "${STATE_DIR:-/data}" 2>/dev/null || true

exec su-exec esurfing java ${JAVA_OPTS:-} \
  -jar /app/client.jar \
  -u "${DIALER_USER}" \
  -p "${DIALER_PASSWORD}" \
  -d
