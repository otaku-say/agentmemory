# agentmemory Docker Image

> Auto-built Docker image for [agentmemory](https://github.com/rohitg00/agentmemory) — the #1 AI agent persistent memory system.

[![Build Status](https://github.com/otaku-say/agentmemory/actions/workflows/build.yml/badge.svg)](https://github.com/otaku-say/agentmemory/actions/workflows/build.yml)

## Quick Start

### 1. Create your environment file

```bash
cp .env.example .env
# Edit .env — at minimum, set GEMINI_API_KEY
```

### 2. Run with Docker Compose

```bash
docker compose up -d
```

### 3. Access

| Service | URL | Notes |
|---------|-----|-------|
| REST API / MCP | `http://YOUR_IP:3111` | Used by Claude, Cursor, Windsurf |
| Viewer Web UI | `http://YOUR_IP:3113` | Memory visualization dashboard |
| Health check | `http://YOUR_IP:3111/agentmemory/livez` | Returns 200 when ready |

### 4. Connect to Claude Desktop

Add to `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "agentmemory": {
      "url": "http://YOUR_SERVER_IP:3111/mcp",
      "headers": {
        "Authorization": "Bearer YOUR_SECRET"
      }
    }
  }
}
```

---

## Image

```bash
docker pull ghcr.io/otaku-say/agentmemory:latest
```

**Registry**: `ghcr.io/otaku-say/agentmemory`

| Tag | Meaning |
|-----|---------|
| `latest` | Most recent stable upstream release |
| `v0.9.30` | Exact upstream version |
| `v0.9` | Minor version (updates with patches) |

**Platforms**: `linux/amd64`, `linux/arm64`

---

## Ports

| Port | Service | Required | Description |
|------|---------|----------|-------------|
| `3111` | REST API + MCP HTTP | ✅ Yes | Main API endpoint; all integrations connect here |
| `3113` | Viewer Web UI | Recommended | Web dashboard to browse and manage memories |
| `3112` | Stream service | Internal only | iii-engine event streams (not exposed externally) |
| `49134` | Engine WebSocket | Internal only | Worker registration (not exposed externally) |

---

## Configuration

All configuration is via environment variables — no secrets are baked into the image.

### Minimum required

| Variable | Description |
|----------|-------------|
| `GEMINI_API_KEY` | Google AI Studio API key for Gemini Embedding 2. [Get free key](https://aistudio.google.com/apikey) |

### Recommended

| Variable | Default | Description |
|----------|---------|-------------|
| `AGENTMEMORY_SECRET` | auto-generated | Bearer token for API auth. Auto-generated and persisted to `/data/.agentmemory_secret` if not set |

### LLM (optional, for AI-powered memory compression)

| Variable | Description |
|----------|-------------|
| `OPENAI_API_KEY` | OpenAI-compatible API key |
| `OPENAI_BASE_URL` | API base URL (for custom/self-hosted LLMs) |
| `OPENAI_MODEL` | Model name |
| `AGENTMEMORY_AUTO_COMPRESS` | Set `true` to enable auto compression (requires LLM key) |

See [`.env.example`](.env.example) for all available options.

---

## Data Persistence

All memory data is stored in the `/data` volume:

```
/data/
├── state_store.db          # SQLite — all memories, vectors, graph
├── stream_store/           # Event stream data
└── .agentmemory_secret     # Auto-generated API secret (back this up!)
```

**Back up your data volume regularly.** The secret file in `/data` is required to access the API — losing it means regenerating and updating all connected clients.

---

## Auto-update Mechanism

This repository automatically tracks upstream releases:

- **Hourly**: [`upstream-monitor.yml`](.github/workflows/upstream-monitor.yml) checks for new upstream releases
- **Daily at 06:00 UTC**: [`build.yml`](.github/workflows/build.yml) runs as a fallback check
- **On push**: Rebuilds when `Dockerfile`, `entrypoint.sh`, or workflow files change
- **Manual**: Use "Run workflow" in the Actions tab to force a specific version

When a new upstream release is detected, a build is automatically triggered and the `latest` tag is updated.

---

## Upstream

- **Source**: [rohitg00/agentmemory](https://github.com/rohitg00/agentmemory)
- **License**: Apache-2.0
- **Docs**: [agent-memory.dev](https://agent-memory.dev)
