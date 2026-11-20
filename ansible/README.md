# SokoPrice: Ansible (configuration management)

Terraform [creates the infrastructure](../terraform/README.md). This playbook **configures the servers and deploys the application**: it hardens the bastion host, then, on the **private** application server, installs Docker and Docker Compose, hardens the firewall and SSH, logs in to the private registry (ECR), pulls the image and runs `docker compose up -d`. The database is Amazon RDS, so only the app container runs on the server.

The [CD workflow](../.github/workflows/cd.yml) runs this playbook automatically after every merge to `main`. You can also run it by hand (below).

Every task is **idempotent**: run it ten times and the servers end up in the same state; the second run reports `changed=0`.

## How Ansible reaches a private server

The app server has no public address. Ansible connects **through the bastion** with an SSH `ProxyCommand`, defined once in [`group_vars/app.yml`](group_vars/app.yml) from the inventory's `bastion` group. Nothing else is needed on your side except the SSH key.

## What it does

| Play / role | What it does |
|-------------|--------------|
| Play 1, hosts `bastion` | Roles `common` and `security`: base packages, automatic updates, UFW (SSH only), SSH hardening that still allows forwarding to the private network |
| Play 2, hosts `sokoprice` (the app server) | Roles below, then verifies the live URL |
| [`common`](roles/common) | Base packages, time zone, automatic security updates |
| [`docker`](roles/docker) | Docker Engine and Compose plugin from Docker's official signed repository; daemon config (log rotation, `no-new-privileges`, live restore) |
| [`security`](roles/security) | UFW firewall (default deny, only the app port and SSH open); SSH hardening (no root, no passwords, key only, limited retries); fail2ban; kernel network hardening |
| [`app`](roles/app) | Writes the secrets file (mode 0600, holds the RDS connection string) and the Compose file, logs in to ECR, pulls the image, runs `docker compose up -d`, waits for `/health`, and **rolls back** to the previous image if the new one is not healthy |

The playbook finishes by calling `/health` and `/api/stats` on the **public URL** (`APP_URL`), which proves load balancer, server and database work together.

## Files

```
ansible/
├── ansible.cfg                 # Defaults (inventory, host-key checking, pipelining)
├── site.yml                    # The playbook (bastion play + app server play)
├── requirements.txt            # Python tools (ansible, ansible-lint), pinned
├── requirements.yml            # Ansible collections
├── .ansible-lint               # Lint profile: production (strictest)
├── inventory/
│   ├── production.yml          # Used by the pipeline (addresses from environment variables)
│   ├── hosts.ini               # Static inventory for manual runs (generated from Terraform)
│   └── aws_ec2.yml             # Dynamic inventory (finds servers by AWS tag)
├── group_vars/
│   ├── all/main.yml            # Settings (image, registry, DB password) read from the environment
│   ├── all/vault.yml.example   # Template for manual runs (encrypted secrets file)
│   ├── bastion.yml             # Bastion settings (no public app port, SSH forwarding allowed)
│   └── app.yml                 # ProxyCommand through the bastion
└── roles/{common,docker,security,app}/   # tasks, defaults, handlers, templates, meta
```

## Prerequisites

- Python 3.10 or newer (Linux, macOS, or Windows through WSL: **Ansible does not run in Git Bash**).
- The infrastructure from Terraform is running and you have its SSH key (`~/.ssh/sokoprice`).
- Your IP is in Terraform's `admin_cidrs` (otherwise the cloud firewall blocks SSH to the bastion).

## Run it by hand

All commands run inside `ansible/`.

### 1. Install the tools

```bash
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
ansible-galaxy collection install -r requirements.yml
```

### 2. Create the inventory

Option A, **static**: copy the ready-made inventory from Terraform (run from Git Bash or WSL).

```bash
terraform -chdir=../terraform output -raw ansible_inventory | tr -d '\r' > inventory/hosts.ini
```

Option B, **dynamic**: Ansible asks AWS for servers tagged `Project=sokoprice`.

```bash
export AWS_REGION=<your region>      # credentials as for Terraform
ansible-inventory -i inventory/aws_ec2.yml --graph
```

### 3. Create the encrypted secrets file

```bash
cp group_vars/all/vault.yml.example group_vars/all/vault.yml
# set vault_db_password to the RDS password (terraform output -raw db_password_command shows how to read it)
ansible-vault encrypt group_vars/all/vault.yml
```

`vault.yml` is git-ignored. Without a valid password the `app` role stops before changing anything. In the pipeline there is no vault file: the password is read from Secrets Manager at run time and masked in the logs.

### 4. Set the deployment values and deploy

```bash
export APP_IMAGE=<ecr repository url>:<tag>      # e.g. 123456789012.dkr.ecr.eu-north-1.amazonaws.com/sokoprice:latest
export REGISTRY_HOST=<account>.dkr.ecr.<region>.amazonaws.com
export REGISTRY_USERNAME=AWS
export REGISTRY_TOKEN="$(aws ecr get-login-password --region <region>)"
export APP_DB_HOST=<terraform output db_endpoint, without the port>
export APP_URL=<terraform output app_url>

ansible-playbook site.yml --syntax-check
ansible-playbook site.yml --private-key ~/.ssh/sokoprice --ask-vault-pass --check --diff   # dry run
ansible-playbook site.yml --private-key ~/.ssh/sokoprice --ask-vault-pass                  # real run
```

### 5. Prove it is idempotent

Run the real command again. The summary must show `changed=0` (apart from the registry login/logout, which are marked unchanged).

### 6. Try the API

```bash
curl "$APP_URL/health"
curl "$APP_URL/api/prices/maize"
```

### Run only one part

```bash
ansible-playbook site.yml --tags security      # firewall + SSH only
ansible-playbook site.yml --tags app           # redeploy the app (new image)
```

## Security hardening

| Area | Setting |
|------|---------|
| Firewall | UFW: default deny incoming; SSH rate limited; only the API port open. Second layer behind the AWS security group |
| SSH | `PermitRootLogin no`, `PasswordAuthentication no`, key only, `AllowUsers`, `MaxAuthTries 3`, TCP forwarding only on the bastion (needed to reach the private server), verbose logs. Written to a drop-in file and **validated with `sshd -t` before use**, so a typo can never lock you out |
| Brute force | fail2ban bans an address after 4 failed logins |
| Kernel | Reverse-path filter, no redirects or source routing, SYN cookies, martian logging |
| Updates | Unattended security updates |
| Docker | Official signed repository; log rotation; `no-new-privileges`; containers run read-only, with all capabilities dropped; the database is managed RDS, reachable only from the app security group |
| Secrets | Only in the encrypted vault; `.env` on the server is mode 0600; `no_log` hides them from output |

## Error handling

- `assert` checks (supported OS, vault password present and strong) fail early with a clear message.
- `block/rescue` around the firewall, SSH and deploy steps: a failure prints what went wrong (and the last container log lines) and never leaves SSH half-configured.
- Network steps retry (`until/retries`) so a slow mirror does not fail the run.
- The deploy waits for the health endpoint before reporting success.

## Quality checks (also run in CI)

```bash
ansible-lint              # production profile
ansible-playbook site.yml --syntax-check
```

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `Permission denied (publickey)` | Pass the right key: `--private-key ~/.ssh/sokoprice` |
| Connection timeout | Your IP changed: update `admin_cidrs` in Terraform and apply. For the pipeline, check `BASTION_HOST` is current |
| `Host key verification failed` | The server was recreated: `ssh-keygen -R <ip>` |
| `Set vault_db_password` | Create `group_vars/all/vault.yml` (step 3) |
| Image pull is denied | The ECR token lasts 12 hours: create a new one with `aws ecr get-login-password` and check `REGISTRY_HOST` has no path (host only) |
| `ERROR! couldn't resolve module` | Run `ansible-galaxy collection install -r requirements.yml` |
