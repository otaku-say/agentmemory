#!/bin/sh
# =============================================================================
# agentmemory container entrypoint
# Handles:
#   1. UID/GID remapping via gosu (for volume permission compatibility)
#   2. Auto-generate AGENTMEMORY_SECRET if not provided
#   3. Launch agentmemory
# =============================================================================

set -e

# ---- UID/GID remapping ------------------------------------------------------
# Allows running as non-root with correct volume ownership
# Set AGENTMEMORY_DOCKER_UID / AGENTMEMORY_DOCKER_GID in docker-compose if needed
TARGET_UID="${AGENTMEMORY_DOCKER_UID:-}"
TARGET_GID="${AGENTMEMORY_DOCKER_GID:-}"

if [ -n "$TARGET_UID" ] && [ "$TARGET_UID" != "0" ]; then
  echo "[entrypoint] Remapping to uid=${TARGET_UID} gid=${TARGET_GID:-$TARGET_UID}"
  groupmod -g "${TARGET_GID:-$TARGET_UID}" node 2>/dev/null || true
  usermod  -u "$TARGET_UID" node 2>/dev/null || true
  chown -R node:node /opt/agentmemory 2>/dev/null || true
  exec gosu node "$0" "$@"
fi

# ---- Secret bootstrap -------------------------------------------------------
# If AGENTMEMORY_SECRET is not set, generate and persist one in /data
SECRET_FILE="/data/.agentmemory_secret"
if [ -z "${AGENTMEMORY_SECRET:-}" ]; then
  if [ -f "$SECRET_FILE" ]; then
    AGENTMEMORY_SECRET="$(cat "$SECRET_FILE")"
    echo "[entrypoint] Loaded existing secret from ${SECRET_FILE}"
  else
    mkdir -p /data
    # Generate a 32-byte hex secret
    AGENTMEMORY_SECRET="$(cat /dev/urandom | head -c 32 | od -An -tx1 | tr -d ' \n')"
    echo "$AGENTMEMORY_SECRET" > "$SECRET_FILE"
    chmod 600 "$SECRET_FILE"
    echo "[entrypoint] Generated new secret, saved to ${SECRET_FILE}"
    echo "[entrypoint] IMPORTANT: back up ${SECRET_FILE} to avoid losing access"
  fi
  export AGENTMEMORY_SECRET
fi

# ---- Ensure data directory exists -------------------------------------------
mkdir -p /data

# ---- Launch -----------------------------------------------------------------
echo "[entrypoint] Starting agentmemory ${AGENTMEMORY_VERSION:-} (iii-engine ${AGENTMEMORY_III_VERSION})"
echo "[entrypoint] REST API:  http://0.0.0.0:${III_REST_PORT:-3111}"
echo "[entrypoint] Viewer UI: http://0.0.0.0:${III_VIEWER_PORT:-3113}"
echo "[entrypoint] Data dir:  ${AGENTMEMORY_DATA_DIR:-/data}"

exec agentmemory "$@"
