# Ansible — homelab configuration

Configures the Docker host VM that Terraform provisions and brings up the
container stacks (AdGuard Home, reverse proxy, Cloudflare Tunnel).

## Layout

```
ansible/
├── ansible.cfg               # Defaults: inventory path, YAML callback, ssh pipelining
├── requirements.yml          # Galaxy collections (community.docker, ansible.posix)
├── inventory/
│   ├── inventory             # Real inventory (gitignored)
│   └── inventory.example     # Template — copy and fill in
├── playbooks/
│   ├── input_ssh_key.yml     # One-shot bootstrap (needs vault password)
│   └── docker-host.yml       # Day-to-day configure + deploy
├── roles/
│   └── docker/               # Installs Docker CE, brings up compose stacks
└── vars/
    ├── vault.yml             # AES-encrypted secrets (deploy key, CF token)
    └── vault.yml.example     # Plaintext template of expected vars
```

## Prerequisites

1. Docker-host VM provisioned by `terraform/production/` and reachable via SSH
   as the `ansible` user (key seeded by cloud-init).
2. Ansible 2.16+ on the control node.
3. `ansible-galaxy collection install -r requirements.yml`
4. Copy `inventory/inventory.example` → `inventory/inventory` and fill in the
   VM's IP (or generate it from `terraform output -raw vm_ipv4`).
5. Copy `vars/vault.yml.example` → `vars/vault.yml`, paste real secrets,
   then `ansible-vault encrypt vars/vault.yml`.

## Running

```bash
# First time only — installs the GitHub deploy key and Cloudflare token.
ansible-playbook playbooks/input_ssh_key.yml --ask-vault-pass

# Every subsequent run — idempotent configure + deploy.
ansible-playbook playbooks/docker-host.yml
```

## Design notes

- **Two playbooks on purpose.** `input_ssh_key.yml` is the only thing that
  needs the vault password, so day-to-day runs of `docker-host.yml` are
  unattended.
- **Two inventory groups for one host.** `[docker]` connects as the privileged
  `ansible` user; `[github]` connects as `steven` so the cloned repo is owned
  by the human operator, not root.
- **Docker CE, not docker.io.** The role installs Docker's official packages
  via the upstream apt repository to get the Compose v2 plugin and current
  releases.
