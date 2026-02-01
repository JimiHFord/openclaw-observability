# OpenClaw Observability Stack

Local observability stack for [OpenClaw](https://github.com/openclaw/openclaw) using Podman.

## Components

| Service | Port | Purpose |
|---------|------|---------|
| **Langfuse** | 3100 | LLM tracing, prompt analytics, cost tracking |
| **Grafana** | 3000 | Dashboards & alerting |
| **Elasticsearch** | 9200 | Log & trace storage |
| **Kibana** | 5601 | Log exploration & search |
| **Logstash** | 5044 | Log ingestion pipeline |
| **OTel Collector** | 4318 | OTLP receiver, routes to all backends |

## Architecture

```
┌─────────────┐     OTLP/HTTP      ┌──────────────────┐
│  OpenClaw   │ ─────────────────► │  OTel Collector  │
│   Gateway   │      :4318         │                  │
└─────────────┘                    └────────┬─────────┘
                                            │
                    ┌───────────────────────┼───────────────────────┐
                    │                       │                       │
                    ▼                       ▼                       ▼
            ┌───────────────┐      ┌───────────────┐      ┌───────────────┐
            │   Langfuse    │      │ Elasticsearch │      │    Grafana    │
            │    :3100      │      │     :9200     │      │     :3000     │
            └───────────────┘      └───────┬───────┘      └───────────────┘
                                           │
                                           ▼
                                   ┌───────────────┐
                                   │    Kibana     │
                                   │     :5601     │
                                   └───────────────┘
```

## Prerequisites

- [Podman](https://podman.io/) with `podman-compose`
- macOS (tested on Apple Silicon)

```bash
brew install podman podman-compose
podman machine init --cpus 4 --memory 8192
podman machine start
```

## Quick Start

```bash
# Clone the repo
git clone https://github.com/JimiHFord/openclaw-observability.git
cd openclaw-observability

# Copy example env and configure
cp .env.example .env

# Start the stack
podman-compose up -d

# Check status
podman-compose ps
```

## Configure OpenClaw

Add to `~/.openclaw/openclaw.json`:

```json
{
  "plugins": {
    "allow": ["diagnostics-otel"]
  },
  "diagnostics": {
    "enabled": true,
    "otel": {
      "enabled": true,
      "endpoint": "http://localhost:4318",
      "serviceName": "openclaw-gateway",
      "traces": true,
      "metrics": true,
      "logs": true,
      "sampleRate": 1.0,
      "flushIntervalMs": 10000
    }
  }
}
```

Then restart the gateway:

```bash
openclaw gateway restart
```

## Access UIs

| Service | URL | Default Credentials |
|---------|-----|---------------------|
| Grafana | http://localhost:3000 | admin / admin |
| Kibana | http://localhost:5601 | — |
| Langfuse | http://localhost:3100 | (create account on first visit) |

## Services

### Langfuse

LLM-specific observability: traces, generations, costs, prompt management.

- View individual LLM calls with input/output
- Track token usage and costs over time
- Debug conversation flows

### Grafana

Metrics dashboards and alerting. Pre-configured datasources:

- Elasticsearch (logs)
- Prometheus (if enabled)

Import the included dashboards from `grafana/dashboards/`.

### ELK Stack

Full-text search and log analytics:

- **Elasticsearch**: Storage and search
- **Kibana**: Visualization and exploration
- **Logstash**: Ingestion pipeline (optional, for file logs)

## File Structure

```
.
├── compose.yaml              # Main compose file
├── .env.example              # Environment template
├── otel-collector/
│   └── config.yaml           # Collector pipeline config
├── grafana/
│   ├── provisioning/
│   │   ├── datasources/
│   │   └── dashboards/
│   └── dashboards/
│       └── openclaw.json     # Pre-built dashboard
├── logstash/
│   └── pipeline/
│       └── openclaw.conf     # Log parsing pipeline
└── elasticsearch/
    └── (data volume)
```

## Volumes

Persistent data is stored in Podman volumes:

- `openclaw-obs_elasticsearch-data`
- `openclaw-obs_grafana-data`
- `openclaw-obs_langfuse-postgres-data`

To reset everything:

```bash
podman-compose down -v
```

## Troubleshooting

### Elasticsearch won't start (memory)

Increase Podman machine memory:

```bash
podman machine stop
podman machine set --memory 8192
podman machine start
```

### OTel Collector not receiving data

Check OpenClaw logs:

```bash
openclaw logs --follow | grep -i otel
```

Verify collector is running:

```bash
podman logs otel-collector
```

### Langfuse database errors

The Postgres container needs time to initialize. Wait 30s and retry.

## License

MIT
