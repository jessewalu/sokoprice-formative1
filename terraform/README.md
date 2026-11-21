# SokoPrice: Terraform (Infrastructure as Code)

This directory describes the whole cloud environment SokoPrice runs in, as code. One command builds it, one command removes it, and every change is reviewed in a pull request like any other code.

Terraform **creates the infrastructure**. [Ansible](../ansible/README.md) **configures the server and deploys the app** onto it, and the [CD workflow](../.github/workflows/cd.yml) runs Ansible automatically on every merge to `main`.

## What it builds

```
                                 Internet
                                    │
                         ┌──────────▼──────────┐
                         │   Internet gateway   │
                         └───┬──────────────┬───┘
 ┌───────────────────────────┼──────────────┼────────────────────────────┐
 │ VPC 10.20.0.0/16          │              │                            │
 │  ┌────────────────────────▼──────────────▼───────────────────────┐    │
 │  │ PUBLIC subnets (2 availability zones)                         │    │
 │  │   Application Load Balancer ◄── port 80/443 from the internet │    │
 │  │   Bastion host (SSH jump box, Elastic IP, admin IPs only)     │    │
 │  │   NAT gateway (outbound-only internet for the private subnets)│    │
 │  └───────────────┬─────────────────────────────┬─────────────────┘    │
 │       app port   │                    SSH      │                      │
 │  ┌───────────────▼─────────────────────────────▼─────────────────┐    │
 │  │ PRIVATE subnets (no public IPs, no inbound route from outside)│    │
 │  │   App server (EC2, Docker + Compose, set up by Ansible)       │    │
 │  │        │ PostgreSQL 5432, TLS                                 │    │
 │  │   Managed database (Amazon RDS PostgreSQL, encrypted)         │    │
 │  └───────────────────────────────────────────────────────────────┘    │
 └───────────────────────────────────────────────────────────────────────┘
  Outside the VPC:  ECR (private image registry) · Secrets Manager (DB password)
                    CloudWatch (logs, alarms, dashboard) · SNS (alerts)
                    IAM role for GitHub Actions (OIDC, no stored keys)
```

Traffic path for a user: **internet → load balancer → app server (private) → database (private)**. The only way an administrator reaches the private server is **through the bastion**.

| Module | Resources |
|--------|-----------|
| [`modules/network`](modules/network) | VPC, locked-down default security group, internet gateway, public and private subnets, NAT gateway, route tables, VPC flow logs (KMS-encrypted) |
| [`modules/security`](modules/security) | Four security groups (load balancer, bastion, app, database) chained together: each rule's source is another group, never a wide CIDR, except the public web port and admin SSH |
| [`modules/compute`](modules/compute) | Bastion host (public subnet) and application server (**private** subnet), key pair, IAM roles (SSM, CloudWatch Logs), Elastic IP for the bastion |
| [`modules/database`](modules/database) | Amazon RDS PostgreSQL in the private subnets: encrypted, TLS enforced, backups, generated password stored in Secrets Manager (customer-managed KMS key) |
| [`modules/registry`](modules/registry) | Private ECR repository: scan on push, immutable tags, KMS encryption, lifecycle policy |
| [`modules/loadbalancer`](modules/loadbalancer) | Application Load Balancer, target group with health check, HTTP listener (HTTPS and redirect when `certificate_arn` is set) |
| [`modules/cicd`](modules/cicd) | GitHub OIDC provider and a least-privilege role that only `main` of this repository can assume |
| [`modules/monitoring`](modules/monitoring) | Encrypted CloudWatch log group, alarms (CPU, unhealthy targets, 5xx, DB CPU/storage), dashboard, SNS topic |

Required components of the assignment and where they are: **VPC** `modules/network`, **VM in a private subnet** `modules/compute`, **bastion in a public subnet** `modules/compute`, **managed database** `modules/database`, **security groups** `modules/security`, **private container registry** `modules/registry`.

## Files

| File | Purpose |
|------|---------|
| `versions.tf` | Terraform and provider version constraints |
| `main.tf` | Calls every module and wires their outputs and inputs together |
| `variables.tf` | Every input, with type, description, default (where safe) and validation |
| `outputs.tf` | Live URL, IPs, registry URL, database endpoint, GitHub variables, Ansible inventory |
| `terraform.tfvars.example` | Template for your own values (copy to `terraform.tfvars`, never commit it) |
| `environments/dev.tfvars.example`, `prod.tfvars.example` | Cheap lab settings and production settings (Multi-AZ, deletion protection, 7-day backups, 1-minute metrics) |
| `backend.tf.example` | Optional remote state in S3 with locking |
| `modules/*` | The eight modules above (`main.tf`, `variables.tf`, `outputs.tf` each) |

## Prerequisites

- Terraform 1.9 or newer, AWS CLI, an AWS account and an IAM user with an access key (`aws configure`).
- An SSH key pair. Create one once (Git Bash):

```bash
ssh-keygen -t ed25519 -f ~/.ssh/sokoprice -C "sokoprice" -N ""
```

## How to initialise and apply

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`: set `admin_cidrs` to **your public IP followed by /32** (find it with `curl -s https://checkip.amazonaws.com`) and `ssh_public_key` to the contents of `~/.ssh/sokoprice.pub`. Never use `0.0.0.0/0` for SSH; validation rejects it.

```bash
terraform init
terraform fmt -check -recursive
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

The first apply takes about 10 to 15 minutes (the database is the slow part). Then read the outputs:

```bash
terraform output app_url                 # the live URL (load balancer)
terraform output ssh_bastion_command     # how to log in to the bastion
terraform output ssh_app_command         # how to reach the private server through it
terraform output -raw db_password_command   # how to read the database password
```

### Connect the pipeline (once)

```bash
terraform output -raw github_cli_commands | bash     # sets the 12 repository variables
gh secret set DEPLOY_SSH_PRIVATE_KEY < ~/.ssh/sokoprice   # the only secret
```

Variables set: `AWS_REGION`, `AWS_ROLE_ARN`, `ECR_REPOSITORY_URL`, `BASTION_HOST`, `BASTION_SG_ID`, `APP_PRIVATE_IP`, `DB_HOST`, `DB_NAME`, `DB_USER`, `DB_SECRET_ARN`, `APP_URL`, `APP_LOG_GROUP`. They are not secrets (addresses and names). The AWS credentials are **never stored**: the workflow gets short-lived credentials through OIDC.

### First deployment by hand (optional)

```bash
terraform output -raw ansible_inventory | tr -d '\r' > ../ansible/inventory/hosts.ini
```

Then follow [`ansible/README.md`](../ansible/README.md). Normally you skip this: merge a pull request to `main` and the CD pipeline does it.

### Remove everything when you are finished

```bash
terraform destroy
```

The registry is created with `ecr_force_delete = true` and the database with `db_skip_final_snapshot = true` and no deletion protection in the dev settings, so a destroy leaves nothing behind. In production settings both are protected. Afterwards delete the IAM access key you used.

## Environments

| Setting | dev (lab) | prod |
|---------|-----------|------|
| Database Multi-AZ | off | on |
| Database deletion protection and final snapshot | off | on |
| Backup retention | 1 day | 7 days |
| Detailed (1-minute) monitoring | off | on |
| ALB deletion protection | off | on |
| HTTPS (`certificate_arn`) | optional | required |

Use `terraform plan -var-file=environments/prod.tfvars` (after copying the example to a real file).

## Variables (summary)

The complete list, with validation rules, is in [`variables.tf`](variables.tf).

| Group | Variables |
|-------|-----------|
| General | `aws_region`, `project_name`, `environment`, `extra_tags` |
| Network | `vpc_cidr`, `public_subnet_cidrs` (at least 2), `private_subnet_cidrs`, `enable_flow_logs`, `flow_log_retention_days` |
| Access | `admin_cidrs`, `ssh_port`, `app_port`, `alb_allowed_cidrs`, `certificate_arn`, `ssh_public_key` |
| Compute | `bastion_instance_type`, `instance_type`, `root_volume_size`, `ami_owner_id`, `ami_name_pattern`, `enable_detailed_monitoring` |
| Database | `db_name`, `db_username`, `db_engine_version`, `db_parameter_group_family`, `db_instance_class`, `db_allocated_storage`, `db_multi_az`, `db_backup_retention_days`, `db_deletion_protection`, `db_skip_final_snapshot`, `db_secret_recovery_window_days` |
| Registry and ALB | `ecr_force_delete`, `health_check_path`, `alb_deletion_protection` |
| Pipeline and operations | `github_repository`, `github_branch`, `create_github_oidc_provider`, `alert_email`, `log_retention_days` |

No secret is a variable with a default: the database password is generated by Terraform (`random_password`) and stored in Secrets Manager; it never appears in the repository.

## Security design

- **Private by default:** the application server and the database have no public IP and sit in subnets with no route from the internet. Only the load balancer and the bastion are public.
- **Chained security groups:** internet → ALB (80/443) → app (app port, source = ALB group) → database (5432, source = app group). SSH to the app comes only from the bastion group; SSH to the bastion only from `admin_cidrs` (and, during a deployment, the runner's own /32, removed afterwards).
- **Encryption:** encrypted disks, RDS storage encrypted with a customer-managed key, TLS enforced by the database parameter group (`rds.force_ssl=1`), encrypted registry and logs.
- **Secrets:** generated database password in Secrets Manager; GitHub uses OIDC with a role limited to `main` and to the one registry, one secret and one security group it needs.
- **Metadata and access:** IMDSv2 required; administration through SSH keys and SSM, no password logins.
- **Least privilege and provenance:** every resource is tagged (`default_tags`), providers are pinned, inputs are validated.

Scan result: **Checkov 285 passed, 0 failed**. The 31 skipped checks are each an inline `#checkov:skip=ID:reason` comment, and the real accepted risks are listed in [`SECURITY.md`](../SECURITY.md).

## Scanning and validation in CI

The `iac-validate` job runs `terraform fmt -check`, `terraform init -backend=false` and `terraform validate`; the `iac-scan` job runs Checkov on `terraform/`. Both must pass before a merge, and `cd.yml` runs them again before it deploys.

## Troubleshooting

| Symptom | Cause and fix |
|---------|---------------|
| `Error: Invalid CIDR` or validation failure on `admin_cidrs` | Use `x.x.x.x/32`; `0.0.0.0/0` is rejected on purpose |
| `RDS ... backup retention period` error | Some AWS free-plan accounts limit backups to 1 day: keep `db_backup_retention_days = 1` |
| `OpenIDConnect provider already exists` | Another stack in the account owns it: set `create_github_oidc_provider = false` |
| `EntityAlreadyExists` for roles or groups from an earlier run | An earlier stack is still deployed: run `terraform destroy` there first |
| Target group shows **unhealthy** after apply | Expected until the first deployment: no container runs yet. Merge to `main` (or run Ansible by hand) |
| `ssh` to the private server times out | Use `terraform output ssh_app_command` (it jumps through the bastion); check `admin_cidrs` is your **current** IP |
| `Error acquiring the state lock` | A previous run was interrupted: wait, or `terraform force-unlock <ID>` |

## Cost note

The lab environment is not free: the **NAT gateway**, the **load balancer** and the **database** are billed by the hour (roughly 3 to 4 US dollars per day together at the time of writing, check the AWS pricing pages). Apply it for the demo and run `terraform destroy` straight after.
