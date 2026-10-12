# =============================================================================
# agentmemory Docker Image
# Upstream: https://github.com/rohitg00/agentmemory
# Registry: ghcr.io/otaku-say/agentmemory
#
# Architecture:
#   - Stage 1: Extract iii-engine binary from official iiidev/iii image
#   - Stage 2: node:lts-slim (Debian Bookworm) + npm install agentmemory
#
# Ports:
#   3111  REST API + MCP HTTP  (required, public)
#   3113  Viewer Web UI        (optional, recommended)
# =============================================================================

# ---- Stage 1: pull iii-engine binary ----------------------------------------
ARG III_VERSION=0.22.1
FROM iiidev/iii:${III_VERSION} AS iii-image

# ---- Stage 2: runtime -------------------------------------------------------
FROM node:lts-slim

# Build-time args injected by GitHub Actions
ARG AGENTMEMORY_VERSION
ARG III_VERSION=0.22.1
ARG III_SDK_VERSION=0.22.1

LABEL org.opencontainers.image.title="agentmemory" \
      org.opencontainers.image.description="AI agent persistent memory - Docker image build" \
      org.opencontainers.image.source="https://github.com/otaku-say/agentmemory" \
      org.opencontainers.image.upstream="https://github.com/rohitg00/agentmemory" \
      org.opencontainers.image.version="${AGENTMEMORY_VERSION}" \
      org.opencontainers.image.licenses="Apache-2.0"

# Runtime system dependencies
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
       openssl \
       ca-certificates \
       tini \
       gosu \
       curl \
  && rm -rf /var/lib/apt/lists/*

# Copy iii-engine binary from official image (version-locked to agentmemory's requirement)
COPY --from=iii-image /app/iii /usr/local/bin/iii

# Install agentmemory from npm
# - iii-sdk override ensures exact version alignment with iii-engine binary
# - --omit=optional skips local embedding (we use Gemini cloud API)
WORKDIR /opt/agentmemory
RUN printf '{"name":"agentmemory-deploy","version":"1.0.0","private":true,"overrides":{"iii-sdk":"%s"}}\n' \
      "${III_SDK_VERSION}" > package.json \
  && npm install "@agentmemory/agentmemory@${AGENTMEMORY_VERSION}" \
       --omit=optional \
       --no-fund \
       --no-audit \
  && ln -s /opt/agentmemory/node_modules/.bin/agentmemory /usr/local/bin/agentmemory \
  && npm cache clean --force

# Runtime environment defaults (all overridable via docker run -e / docker-compose env)
ENV AGENTMEMORY_III_VERSION=${III_VERSION} \
    TINI_SUBREAPER=1 \
    NODE_ENV=production \
    # Data directory - mount a volume here for persistence
    AGENTMEMORY_DATA_DIR=/data \
    # Port defaults
    III_REST_PORT=3111 \
    III_STREAM_PORT=3112 \
    III_VIEWER_PORT=3113 \
    III_ENGINE_PORT=49134 \
    # Embedding: gemini (set GEMINI_API_KEY at runtime, never bake into image)
    EMBEDDING_PROVIDER=gemini \
    # Disable telemetry
    III_TELEMETRY_ENABLED=false \
    # Memory limit tuning for glibc
    MALLOC_ARENA_MAX=2

# Persistent memory data volume
VOLUME ["/data"]

# Entry point script (handles gosu uid/gid remapping + secret bootstrap)
COPY --chmod=0755 entrypoint.sh /usr/local/bin/agentmemory-entrypoint.sh

# REST API + MCP HTTP (required)
EXPOSE 3111
# Viewer Web UI (optional, enable in docker-compose as needed)
EXPOSE 3113

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/agentmemory-entrypoint.sh"]
