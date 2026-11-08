# SokoPrice: Terraform (Infrastructure as Code)

This directory describes the cloud infrastructure that SokoPrice runs on, as code. One command builds it, one command removes it, and every change is reviewed in a pull request like any other code.

Terraform **creates the server**. [Ansible](../ansible/README.md) then **configures it and deploys the application** onto it.

## What it builds

```
                          Internet
                              │
                     ┌────────▼────────┐
                     │ Internet gateway│
                     └────────┬────────┘
   ┌──────────────────────────┼──────────────────────────────┐
   │ VPC  (10.20.0.0/16)      │                              │
   │   ┌──────────────────────▼─────────┐  ┌───────────────┐ │
   │   │ Public subnet 1 (AZ a)         │  │ Public subnet │ │
   │   │  ┌──────────────────────────┐  │  │ 2 (AZ b)      │ │
   │   │  │ EC2 instance (Ubuntu LTS)│  │  │ (spare, for a │ │
   │   │  │  • Elastic IP            │  │  │ future load   │ │
   │   │  │  • encrypted disk, IMDSv2│  │  │ balancer)     │ │
   │   │  │  • IAM role (SSM only)   │  │  └───────────────┘ │
   │   │  └────────────▲─────────────┘  │                    │
   │   └───────────────┼────────────────┘                    │
   │        Security group (firewall)                        │
   │   in:  SSH from admin IPs only, API port               │
   │   out: HTTPS, HTTP, DNS to the VPC resolver only       │
   │                                                         │
   │   Flow logs ──► encrypted CloudWatch log group (KMS)   │
   └─────────────────────────────────────────────────────────┘
```

| Module | Resources |
|--------|-----------|
| [`modules/network`](modules/network) | VPC, locked-down default security group, internet gateway, public subnets, route table and associations, VPC flow logs with a KMS key, log group and IAM role |
| [`modules/security`](modules/security) | Security group with one rule resource per rule (SSH from admin addresses, API port, restricted outbound) |
| [`modules/compute`](modules/compute) | Ubuntu 24.04 LTS EC2 instance, key pair, IAM role and instance profile (SSM), Elastic IP |

Required components of the assignment: **VPC** (`aws_vpc`), **compute instance** (`aws_instance`), **network security rules** (`aws_security_group` and `aws_vpc_security_group_*_rule`).

## Files

```
terraform/
├── versions.tf                     # Terraform + provider version constraints, provider config
├── main.tf                         # Root module: wires the three modules together
├── variables.tf                    # All inputs, with descriptions, types and validation
├── outputs.tf                      # IDs, IP addresses, SSH command, ready-made Ansible inventory
├── terraform.tfvars.example        # Copy to terraform.tfvars and edit
├── backend.tf.example              # Optional remote state (S3 + locking)
├── environments/
│   ├── dev.tfvars.example          # Cheap development settings
│   └── prod.tfvars.example         # Production settings (separate CIDR range, monitoring on)
└── modules/
    ├── network/   (main.tf, variables.tf, outputs.tf)
    ├── security/  (main.tf, variables.tf, outputs.tf)
    └── compute/   (main.tf, variables.tf, outputs.tf)
```

## Prerequisites

| Tool | Version | Check |
|------|---------|-------|
| [Terraform](https://developer.hashicorp.com/terraform/install) (or OpenTofu) | 1.5 or newer | `terraform version` |
| An AWS account and a user or role that may create VPC, EC2, IAM, KMS and CloudWatch resources | | `aws sts get-caller-identity` |
| An SSH key pair | | see step 1 |

**Credentials are never written in code.** Configure them on your own computer with `aws configure` (or `aws configure sso`), or the environment variables `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` and optionally `AWS_SESSION_TOKEN`. The provider picks them up automatically. Do not put them in `.tf` or `.tfvars` files, and never commit them.

## How to initialise and apply

All commands run inside the `terraform/` directory.

### 1. Create an SSH key (once)

```bash
ssh-keygen -t ed25519 -f ~/.ssh/sokoprice -C "sokoprice"
cat ~/.ssh/sokoprice.pub        # this PUBLIC text goes into the tfvars file
```

Keep `~/.ssh/sokoprice` (the private key) on your computer only.

### 2. Create your variable file

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:

- `aws_region`: the region to use.
- `admin_cidrs`: **your public IP with `/32`**. Find it with `curl https://checkip.amazonaws.com`. `0.0.0.0/0` is rejected on purpose: SSH must not be open to the world.
- `ssh_public_key`: the text printed by the `cat` command above.

`terraform.tfvars` is git-ignored.

### 3. Initialise

```bash
terraform init
```

Downloads the AWS provider and sets up the modules. Commit the generated `.terraform.lock.hcl` file so everyone uses the same provider version. Never commit the `.terraform/` folder.

### 4. Check the code (no AWS account needed)

```bash
terraform fmt -recursive -check   # formatting
terraform validate                # syntax and internal consistency
```

These two commands also run in CI on every pull request.

### 5. Preview

```bash
terraform plan -out=tfplan
```

Read the plan. It should show about 28 resources to add and nothing to change or destroy on a first run.

### 6. Apply

```bash
terraform apply tfplan
```

Takes about two minutes. When finished, Terraform prints the outputs.

### 7. Read the outputs

```bash
terraform output                          # everything
terraform output instance_public_ip       # one value
terraform output -raw ssh_command         # ssh -p 22 ubuntu@<ip>
```

| Output | Meaning |
|--------|---------|
| `vpc_id` | ID of the VPC |
| `public_subnet_ids` | IDs of the public subnets |
| `security_group_id` | ID of the firewall group |
| `instance_id` | ID of the EC2 instance |
| `instance_public_ip` | Elastic IP of the server |
| `instance_private_ip` | Address inside the VPC |
| `app_url` | `http://<ip>:<port>` once the app is deployed |
| `ssh_command` | Ready-to-use SSH command (add `-i ~/.ssh/sokoprice`) |
| `ansible_inventory` | A complete Ansible inventory for this server |

### 8. Hand over to Ansible

```bash
terraform output -raw ansible_inventory > ../ansible/inventory/hosts.ini
cd ../ansible
ansible-playbook site.yml --private-key ~/.ssh/sokoprice
```

See [`ansible/README.md`](../ansible/README.md).

### 9. Remove everything when you are finished

```bash
terraform destroy
```

Always destroy lab infrastructure when you stop working on it. Anything left running keeps costing money (the instance, the Elastic IP, the log storage).

## Environments

Environment-specific values never live in the code. Use one variable file per environment:

```bash
cp environments/dev.tfvars.example  environments/dev.tfvars
cp environments/prod.tfvars.example environments/prod.tfvars

terraform plan -var-file=environments/dev.tfvars
terraform plan -var-file=environments/prod.tfvars
```

Use a separate state for each environment (separate backend `key`, or Terraform workspaces) so that `dev` and `prod` never share state.

## Variables

Defined in [`variables.tf`](variables.tf). Variables with no default are **required**.

| Variable | Default | Purpose |
|----------|---------|---------|
| `aws_region` | *required* | Region to deploy into (no region is hard-coded anywhere) |
| `admin_cidrs` | *required* | IPs allowed to use SSH. Validation rejects an empty list and `0.0.0.0/0` |
| `ssh_public_key` | *required* | Public SSH key for the server. Validation checks the format |
| `project_name` | `sokoprice` | Used in names and tags |
| `environment` | `dev` | `dev`, `staging` or `prod` |
| `vpc_cidr` | `10.20.0.0/16` | VPC address range |
| `public_subnet_cidrs` | two `/24` ranges | One public subnet per availability zone |
| `ssh_port` | `22` | SSH port (must match Ansible `security_ssh_port`) |
| `app_port` | `80` | Public port of the API |
| `app_allowed_cidrs` | `["0.0.0.0/0"]` | Who may reach the API (public by design) |
| `instance_type` | `t3.micro` | EC2 size |
| `root_volume_size` | `20` | Encrypted disk size in GiB |
| `enable_flow_logs` | `true` | VPC flow logs to an encrypted log group |
| `flow_log_retention_days` | `365` | Log retention (allowed CloudWatch values only) |
| `enable_detailed_monitoring` | `false` | 1-minute EC2 metrics (extra cost) |
| `ami_owner_id` / `ami_name_pattern` | Canonical / Ubuntu 24.04 | Which image to use (publisher is pinned) |
| `extra_tags` | `{}` | Extra tags on every resource |

There are **no secrets** in this configuration. The only key-related value is the *public* SSH key.

## Security design

- **Least-privilege firewall:** SSH only from `admin_cidrs`; outbound traffic limited to HTTPS, HTTP and DNS to the VPC resolver.
- **No open SSH:** validation refuses `0.0.0.0/0` for administrators.
- **Encrypted everything:** encrypted root volume; flow logs encrypted with a customer-managed KMS key with rotation enabled.
- **IMDSv2 required** with hop limit 1: stops server-side request forgery from stealing instance credentials, and containers cannot reach the metadata service.
- **Default security group locked down** so nothing can use it by accident.
- **Pinned image publisher** (Canonical) so a look-alike image cannot be chosen.
- **IAM role limited to Systems Manager**, so the server can also be reached with Session Manager without opening any port.
- **Elastic IP instead of auto-assigned public IP**, so the address is stable.
- **Provider version range** is pinned in `versions.tf`; commit `.terraform.lock.hcl`.
- **State files** can contain sensitive values and are git-ignored (`*.tfstate`). A team should use remote state: see [`backend.tf.example`](backend.tf.example).

Every Checkov skip in the code carries a written reason, and all of them are explained in [`SECURITY.md`](../SECURITY.md).

## Scanning and validation in CI

Pull requests run these checks automatically (see [`.github/workflows/ci.yml`](../.github/workflows/ci.yml)):

| Check | Tool | Purpose |
|-------|------|---------|
| Formatting | `terraform fmt -check -recursive` | Consistent style |
| Validation | `terraform init -backend=false` and `terraform validate` | Valid syntax and references |
| Security scan | Checkov | Misconfigurations (open ports, missing encryption, and so on) |

Run the same locally:

```bash
terraform fmt -recursive -check && terraform validate
pip install checkov && checkov -d . --framework terraform --compact --quiet --skip-download
```

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `No valid credential sources found` | Run `aws configure` or export the AWS environment variables |
| `admin_cidrs must not be 0.0.0.0/0` | Use your own address with `/32` |
| `InvalidKeyPair.Format` or key validation error | `ssh_public_key` must be the **public** key (the `.pub` file), starting with `ssh-ed25519` or `ssh-rsa` |
| `UnauthorizedOperation` for an instance type | The type is not available to your account or region; set `instance_type` to another |
| Region not enabled | Opt-in regions (for example `af-south-1`) must be enabled in the AWS account settings first |
| `terraform fmt -check` fails in CI | Run `terraform fmt -recursive` locally and commit the result |
| Can no longer SSH after my IP changed | Update `admin_cidrs` and run `terraform apply` |

## Cost note

A `t3.micro` instance may be covered by the AWS free tier for new accounts (check the current terms). The Elastic IP, encrypted volume, KMS key and log storage are small but not free. Run `terraform destroy` when you are not using the environment.
