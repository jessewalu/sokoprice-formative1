# Changelog

All notable changes to SokoPrice, by assignment stage. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); the project uses stage tags (`v1.0-formative1`, `v2.0-formative2`, `v3.0-formative3`, `v4.0-summative`).

## [Summative] - Complete DevOps pipeline

### Added
- **Terraform (8 modules):** private network with public and private subnets and a NAT gateway; application server in a **private subnet**; **bastion host** in a public subnet; managed **Amazon RDS PostgreSQL** (encrypted, TLS enforced, password generated and stored in Secrets Manager); four chained **security groups** (load balancer, bastion, app, database); private **Amazon ECR** registry (scan on push, immutable tags, lifecycle policy); **Application Load Balancer** (public URL, health check); GitHub **OIDC** role for the pipeline (no stored AWS keys); CloudWatch log group, alarms, dashboard and SNS alerts.
- **Terraform outputs** for the live URL, registry URL, bastion and server addresses, and ready-made GitHub variables (`github_cli_commands`) and Ansible inventory.
- **Ansible:** play for the bastion and play for the private app server (reached through the bastion with a `ProxyCommand`); roles `common`, `docker` (Docker Engine and Compose), `security`, `app`; registry login, `docker compose up -d`, health verification through the public URL, **automatic rollback** to the previous image, container logs shipped to CloudWatch; pipeline inventory `inventory/production.yml`.
- **`cd.yml`:** continuous deployment on merge to `main`: reuses every CI job, builds the image, scans it with Trivy, pushes it to ECR, authenticates to AWS with OIDC and runs Ansible through the bastion; one deployment at a time; temporary SSH rule and key removed even on failure.
- **CI:** `workflow_call` trigger so CD runs the same checks.
- `CHANGELOG.md`, operations manual and architecture diagram in the README, `docs/SUMMATIVE_GUIDE.md` (evidence checklist and demo-video plan).

### Fixed (found during the first live deployment)
- The first CD run stopped at the AWS login: GitHub now sends the repository in an immutable form (`owner@id/repo@id`), and the deploy job's `production` environment uses a different subject. The role in `terraform/modules/cicd` now trusts the name-based and immutable forms for `main` and for the `production` environment.
- The bastion server showed as "to be replaced" on every plan because its Elastic IP makes AWS report a public address; `associate_public_ip_address` is now ignored for that instance (`terraform/modules/compute`).
- `APP_LOG_GROUP` was set with a Windows path by Git Bash; documented the `MSYS_NO_PATHCONV=1` fix in the operations manual.

### Delivered
- Live application on an AWS load balancer address, and the video demo, both linked from the top of the README.

### Changed
- The database moved from a container on the server to managed RDS; the server runs the app container only.
- `SECURITY.md`: new controls and accepted risks for the load balancer, NAT, RDS and pipeline.
- Ansible secrets: `vault_postgres_password` is now `vault_db_password` (manual runs only; the pipeline reads Secrets Manager).
- README sections 15 to 21 (architecture, Terraform, Ansible, DevSecOps, CD, operations manual).

### Security
- Checkov: 285 passed, 0 failed on Terraform (31 documented skips); 0 failed on the workflows.
- Container image scanned by Trivy twice (CI and before the push); IaC scanned on every pull request and before every deployment.

## [Formative 3] - Terraform, Ansible and DevSecOps

### Added
- Terraform: VPC, security group and EC2 instance modules, VPC flow logs, variables, outputs, environment examples.
- Ansible: roles `common`, `docker`, `security`, `app`; static and dynamic inventory; Ansible Vault for the database password; idempotent tasks with error handling.
- DevSecOps in CI: pip-audit, Bandit, Trivy, Checkov; `iac-validate` (Terraform fmt/validate, ansible-lint); Dependabot; `SECURITY.md` with findings and accepted risks.

### Fixed
- Bandit B104 (server bound to all interfaces) and B310 (URL scheme in the health check script).

## [Formative 2] - Containers and CI

### Added
- Multi-stage `Dockerfile` (non-root user, health check), `docker-compose.yml` with PostgreSQL, volumes and networks.
- GitHub Actions CI (lint, test matrix, Docker build), image publishing to GitHub Container Registry on merge to `main`.
- Branch protection, CODEOWNERS, pull-request template and collaboration evidence.

## [Formative 1] - The application and the team workflow

### Added
- SokoPrice Flask application: REST API for crop prices, USSD menu endpoint, health check.
- Tests, Ruff linting, README, project board and user stories, contribution tracker.
- Repository conventions: branches, meaningful commits, pull requests with review.
