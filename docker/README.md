# Docker stacks

Two compose projects that together run every service on the homelab docker
host. Traefik fronts everything; AdGuard Home resolves `*.home.arpa` to the
docker host so each app gets a friendly hostname on the LAN.

```
docker/
|- docker-compose.yml         # App stack: Traefik, n8n, Grafana, Prometheus, cAdvisor, yt-clip
|- .env.example               # Template - copy to .env
|- grafana/provisioning/      # Auto-loaded Grafana datasources
|- prometheus/prometheus.yml  # Scrape targets
|- traefik/traefik.yml        # Static config (entrypoints, api, metrics)
|- youtube-downloader/        # Flask + yt-dlp clipping app (built from source)
\- networking/
   |- docker-compose.yml      # AdGuard Home, Portainer, Cloudflare Tunnel
   \- .env.example
```

## Prerequisites

1. A docker host provisioned by `terraform/production/` and configured by
   `ansible/playbooks/docker-host.yml` (installs Docker CE, creates the
   shared `proxy` network).
2. The Ansible bootstrap play `input_ssh_key.yml` has run, which seeds
   `networking/.env` with the Cloudflare tunnel token on the host.

## Running

```bash
# from ./docker
cp .env.example .env && $EDITOR .env
docker compose up -d

# from ./docker/networking
cp .env.example .env && $EDITOR .env
docker compose up -d
```

## Design notes

- **Two compose projects on purpose.** The public-facing tunnel and the LAN
  app stack are decoupled so the tunnel can be torn down without touching
  the apps. They share an external `proxy` network created by Ansible.
- **Routing via labels.** Adding a new service means adding three Traefik
  labels, not editing a config file or opening a port on the host.
- **Hostname pattern `<app>.${DOMAIN_SUFFIX}`.** AdGuard Home rewrites the
  wildcard `*.home.arpa` to the docker host's IP so the LAN sees friendly
  names without per-app DNS entries.
- **Secrets stay in `.env`.** Grafana admin password, Traefik dashboard
  basic-auth hash, and the Cloudflare tunnel token never sit in compose YAML.
- **`api.insecure: false` in Traefik.** The dashboard is only reachable via
  a routed service guarded by basic-auth middleware.
