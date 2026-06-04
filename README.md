# Homelab

End-to-end infrastructure for a self-hosted home server, captured as code.
A single repo that goes from a fresh Proxmox node to a running stack of
container apps, with three tools cleanly separated by responsibility.

## The pipeline

```
   Proxmox host
       |
       |  terraform apply
       v
   +------------------+         +-----------------+
   | ansible-host VM  |         | docker-host VM  |
   | (control node)   |  ---->  | (workload node) |
   +------------------+ ansible +-----------------+
                                       |
                                       |  docker compose up -d
                                       v
                              Traefik + n8n + Grafana
                              Prometheus + cAdvisor
                              AdGuard Home + Portainer
                              Cloudflare Tunnel
```

1. **Terraform** clones two Ubuntu cloud-init VMs on a Proxmox node: a
   minimal Ansible control node and a beefier docker host.
2. **Ansible** runs from the control node, hardens the docker host,
   installs Docker CE, and clones the application repo onto it.
3. **Docker Compose** brings up the application stack behind Traefik, with
   AdGuard Home doing LAN DNS rewrites and Cloudflare Tunnel publishing
   selected services to the public internet.

## Repo layout

```
.
|- terraform/      # Proxmox VM provisioning (cloud-init, networking, sizing)
|  |- ansible-host/    # Small VM that runs Ansible playbooks
|  \- production/      # Docker host VM
|
|- ansible/        # Configures the docker host and deploys the stack
|  |- playbooks/       # input_ssh_key.yml (vault), docker-host.yml (daily)
|  |- roles/docker/    # Docker CE install, systemd-resolved tweak, compose up
|  \- vars/vault.yml   # Encrypted secrets (deploy key, Cloudflare token)
|
\- docker/         # Compose stacks running on the docker host
   |- docker-compose.yml      # Traefik, n8n, Grafana, Prometheus, cAdvisor
   \- networking/              # AdGuard, Portainer, Cloudflare Tunnel
```

Each subdirectory has its own README with prerequisites and run order.

## Highlights for reviewers

- **Idempotent end-to-end.** A wiped Proxmox node and an empty laptop can
  rebuild the entire stack with three commands (Terraform, Ansible, Docker
  Compose) and no manual UI clicking.
- **Secrets stay out of the repo.** Terraform `tfvars`, Ansible inventories,
  and Docker `.env` files are gitignored; every directory ships a
  `*.example` template so a collaborator knows the shape of the input.
  Ansible Vault encrypts the GitHub deploy key and Cloudflare tunnel token
  at rest.
- **Label-driven service discovery.** Adding a new app is three Traefik
  labels on a container - no DNS edits, no port-mapping bookkeeping, no
  reverse-proxy config rewrites.
- **No inbound holes in the home router.** Public-facing services go out
  through a Cloudflare Tunnel rather than NAT port-forwards.
- **Observability built in.** Prometheus scrapes cAdvisor, Traefik metrics,
  and n8n; Grafana auto-loads the Prometheus datasource via provisioning.

## Quick start

Walk through the README in each directory in this order:

1. [`terraform/`](terraform/) - apply once per VM (`ansible-host` then
   `production`). Outputs the docker host's IP for the next step.
2. [`ansible/`](ansible/README.md) - copy the example inventory, encrypt
   `vault.yml`, run `input_ssh_key.yml` once then `docker-host.yml`.
3. [`docker/`](docker/README.md) - if you skip Ansible and want to run the
   stack standalone (e.g. on an existing host), follow the README here.

## Prerequisites

- Proxmox VE 8.x with an Ubuntu 24.04 cloud-init template
- A Proxmox API token with VM create/clone permissions
- A workstation with Terraform >= 1.5, Ansible >= 2.16, and `ssh-keygen`
- (Optional) a Cloudflare Zero Trust account for the public tunnel

## Stack at a glance

| Layer         | Tool                      | Purpose                                   |
| ------------- | ------------------------- | ----------------------------------------- |
| Hypervisor    | Proxmox VE                | Bare-metal VM host                        |
| Provisioning  | Terraform + cloud-init    | Reproducible VM creation                  |
| Configuration | Ansible                   | Idempotent host config and app deploy     |
| Runtime       | Docker CE + Compose v2    | Container orchestration                   |
| Ingress       | Traefik                   | Label-driven reverse proxy + TLS termination |
| DNS           | AdGuard Home              | LAN `*.home.arpa` rewrites + ad-blocking  |
| Public access | Cloudflare Tunnel         | Outbound-only ingress for selected apps   |
| Monitoring    | Prometheus + cAdvisor     | Metrics scraping                          |
| Dashboards    | Grafana                   | Visualisation with provisioned datasource |
| UI            | Portainer                 | Container management web UI               |
| Workflow      | n8n                       | Automation runtime                        |
| YT clipper    | youtube-downloader        | Tool used to clip parts of YT videos      |
