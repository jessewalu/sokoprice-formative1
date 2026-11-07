# SokoPrice: Ansible (configuration management)

Terraform [creates the server](../terraform/README.md). This playbook **configures it and deploys the application**: it installs Docker, hardens the firewall and SSH, and runs the SokoPrice container with its PostgreSQL database.

Every task is **idempotent**: run it ten times and the server ends up in the same state; the second run reports `changed=0`.

## What it does

| Role | What it does |
|------|--------------|
| [`common`](roles/common) | Base packages, time zone, automatic security updates |
| [`docker`](roles/docker) | Docker Engine and Compose plugin from Docker's official signed repository; daemon config (log rotation, `no-new-privileges`, live restore) |
| [`security`](roles/security) | UFW firewall (default deny, SSH rate limited, only the API port open); SSH hardening (no root, no passwords, key only, `AllowUsers`, limited retries); fail2ban; kernel network hardening |
| [`app`](roles/app) | Writes the secrets file (mode 0600) and the Compose file, pulls the image, starts app + database, waits until `/health` answers |

`site.yml` ties them together and finishes by calling `/health` from your computer through the firewall, which proves the deployment works end to end.

## Files

```
ansible/
├── ansible.cfg                 # Defaults (inventory, host-key checking, pipelining)
├── site.yml                    # The playbook
├── requirements.txt            # Python tools (ansible, ansible-lint), pinned
├── requirements.yml            # Ansible collections
├── .ansible-lint               # Lint profile: production (strictest)
├── inventory/
│   ├── hosts.ini               # Static inventory (generated from Terraform output)
│   └── aws_ec2.yml             # Dynamic inventory (finds the server by AWS tag)
├── group_vars/all/
│   ├── main.yml                # Non-secret settings
│   └── vault.yml.example       # Template for the encrypted secrets file
└── roles/{common,docker,security,app}/   # tasks, defaults, handlers, templates, meta
```

## Prerequisites

- Python 3.10 or newer on your computer (Linux, macOS, or Windows through WSL).
- The server from Terraform is running and your SSH key is the one given to Terraform.
- Your IP is in Terraform's `admin_cidrs` (otherwise the cloud firewall blocks SSH).

## Run it

All commands run inside `ansible/`.

### 1. Install the tools

```bash
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
ansible-galaxy collection install -r requirements.yml
```

### 2. Create the inventory

Option A, **static** (default): copy the ready-made inventory from Terraform.

```bash
terraform -chdir=../terraform output -raw ansible_inventory > inventory/hosts.ini
```

Option B, **dynamic**: no file to maintain; Ansible asks AWS for servers tagged `Project=sokoprice`.

```bash
export AWS_REGION=<your region>      # credentials as for Terraform
ansible-inventory -i inventory/aws_ec2.yml --graph
ansible-playbook -i inventory/aws_ec2.yml site.yml --private-key ~/.ssh/sokoprice
```

### 3. Create the encrypted secrets file

```bash
cp group_vars/all/vault.yml.example group_vars/all/vault.yml
# edit it: set vault_postgres_password to a long random value
ansible-vault encrypt group_vars/all/vault.yml
```

`vault.yml` is git-ignored. Without a password of at least 12 characters the `app` role stops before changing anything.

### 4. Check, then deploy

```bash
ansible-playbook site.yml --syntax-check
ansible-playbook site.yml --private-key ~/.ssh/sokoprice --ask-vault-pass --check --diff   # dry run
ansible-playbook site.yml --private-key ~/.ssh/sokoprice --ask-vault-pass                  # real run
```

### 5. Prove it is idempotent

Run the real command again. The summary must show `changed=0`.

### 6. Try the API

```bash
curl http://<server ip>/health
curl http://<server ip>/api/prices/maize
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
| SSH | `PermitRootLogin no`, `PasswordAuthentication no`, key only, `AllowUsers`, `MaxAuthTries 3`, no forwarding, verbose logs. Written to a drop-in file and **validated with `sshd -t` before use**, so a typo can never lock you out |
| Brute force | fail2ban bans an address after 4 failed logins |
| Kernel | Reverse-path filter, no redirects or source routing, SYN cookies, martian logging |
| Updates | Unattended security updates |
| Docker | Official signed repository; log rotation; `no-new-privileges`; containers run read-only, with all capabilities dropped; database not published on any port |
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
| Connection timeout | Your IP changed: update `admin_cidrs` in Terraform and apply |
| `Host key verification failed` | The server was recreated: `ssh-keygen -R <ip>` |
| `Set vault_postgres_password` | Create `group_vars/all/vault.yml` (step 3) |
| Image pull is denied | The package is private: either make it public in GitHub or add `vault_ghcr_username` and `vault_ghcr_token` (token with `read:packages` only) |
| `ERROR! couldn't resolve module` | Run `ansible-galaxy collection install -r requirements.yml` |
