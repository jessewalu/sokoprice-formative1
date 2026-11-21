# Security

This document describes how SokoPrice is scanned for security problems, what the scans found, how each finding was handled, and which risks the team has knowingly accepted and why.

## Reporting a vulnerability

Please do **not** open a public issue for a security problem. Use GitHub's private reporting (**Security → Report a vulnerability** on this repository) or contact a maintainer directly (see `.github/CODEOWNERS`). We aim to acknowledge a report within 3 working days.

## Automated scanning

Five kinds of scan run in GitHub Actions ([`.github/workflows/ci.yml`](.github/workflows/ci.yml)) on **every push to a branch and every pull request to `main`**. A failing scan blocks the merge once the checks are marked required in branch protection. The deployment workflow ([`cd.yml`](.github/workflows/cd.yml)) runs all of them again on merge, and **scans the exact image with Trivy again before pushing it to the private registry**, so an image with a fixable HIGH or CRITICAL vulnerability is never published or deployed.

| Job | Scan type | Tool | Looks at | Fails the build when |
|-----|-----------|------|----------|----------------------|
| `dependency-scan` | Dependency (SCA) | pip-audit | `requirements.txt` | **any** known vulnerability is found |
| `sast-scan` | Static code analysis | Bandit | `app/`, `scripts/`, `run.py` | a finding of **medium or high** severity is found |
| `container-scan` | Container image | Trivy | The built Docker image (OS packages and libraries) | a **fixable HIGH or CRITICAL** vulnerability is found |
| `iac-scan` | Infrastructure as Code | Checkov | Terraform, Dockerfile, GitHub Actions workflows, Ansible, hard-coded secrets | **any** check fails (accepted risks are explicit skips, listed below) |
| `iac-validate` | IaC quality | `terraform fmt` and `validate`, `ansible-lint` (production profile) | `terraform/`, `ansible/` | formatting, syntax or lint errors |

Dependabot ([`.github/dependabot.yml`](.github/dependabot.yml)) opens pull requests weekly for outdated or vulnerable Python packages, Docker base images, GitHub Actions and Terraform providers.

The same scanners can be run locally:

```bash
pip install -r requirements-security.txt
pip-audit -r requirements.txt
bandit -r app scripts run.py --severity-level medium
checkov -d . --framework terraform dockerfile github_actions ansible secrets --compact --quiet --skip-download
```

### Why these thresholds

- **Dependencies, any finding:** the app has only three direct dependencies, so a vulnerability is rare and always worth a look.
- **Container, fixable HIGH/CRITICAL only:** a vulnerability with no available fix cannot be remediated by the team, so it is reported but does not block (`--ignore-unfixed`). Anything fixable at HIGH or above must be fixed first.
- **Code, medium and above:** low-severity Bandit findings are mostly style hints; medium and high are real risks.

## Findings and remediation

| # | Tool | Finding | Severity | Where | Remediation | Status |
|---|------|---------|----------|-------|-------------|--------|
| 1 | Bandit B104 | Server bound to all network interfaces (`0.0.0.0`) | Medium | `run.py` | The development server now binds to `127.0.0.1` by default; the address comes from the `HOST` environment variable. Production uses gunicorn inside the container (unchanged), where binding all interfaces is required and is limited by the container network and the firewall | **Fixed** |
| 2 | Bandit B310 | `urllib.request.urlopen` accepts any URL scheme (`file://` and others) | Medium | `scripts/healthcheck.py` | Replaced with `http.client.HTTPConnection("127.0.0.1", port)`, which can only make a plain HTTP request to the local app. Three new tests cover it (`tests/test_healthcheck.py`) | **Fixed** |
| 3 | pip-audit | Python dependencies | None | `requirements.txt` | No known vulnerabilities at the time of writing; the scan keeps checking on every pull request | Clean |
| 4 | Checkov | Missing encryption, open ports, wide permissions and similar in the first draft of the Terraform | Various | `terraform/` | Fixed in code: encrypted root disk, IMDSv2 required, flow logs with a customer-managed key and rotation, default security group locked, no public IP on launch, SSH never open to the world (validation), outbound traffic restricted, IAM limited. Remaining items are the accepted risks below | **Fixed**, accepted risks listed below |
| 5 | Checkov | Dockerfile, workflows, Ansible, secrets | None | repository | 0 failed checks | Clean |
| 6 | Trivy | Container image scan | See note | Docker image | The Dockerfile now applies the latest operating-system security patches (`apt-get upgrade`) and removes `pip`, `setuptools` and `wheel` from the final image to shrink the attack surface | See note |

> **Note on finding 6.** Trivy needs to download its vulnerability database and pull the base image, which was not possible from the environment where this document was prepared. Trivy therefore runs in CI only. The first CI run of `container-scan` is the evidence. Record its result here after the first run: *date, number of HIGH/CRITICAL findings, and what was done about each.* If a finding is fixable, bump the base image tag in the `Dockerfile` or the package in `requirements.txt` (Dependabot will usually open that pull request). If it is not fixable and the team accepts it, add it to the table below with a reason.

## Accepted risks

Every item below is also a comment next to the code (`#checkov:skip=ID:reason`), so the scanner and this document always agree.

| # | Check | Where | Why it is accepted | Compensating control |
|---|-------|-------|--------------------|----------------------|
| A1 | CKV_AWS_260 (port 80 open to `0.0.0.0/0`) | `terraform/modules/security` | The API serves farmers and the USSD gateway from anywhere on the internet, so the web port must be public | Host firewall (UFW) allows only the API port and SSH; no secrets are served; the database is never published; SSH is restricted to admin addresses. **Planned:** TLS with a load balancer or reverse proxy and a domain name |
| A2 | CKV_AWS_109 and CKV_AWS_111 (KMS key policy allows `kms:*` to the account) | `terraform/modules/network` | This is the standard statement that lets IAM administer the key. Removing it makes the key unmanageable | Use of the key by the logging service is restricted with an encryption-context condition; key rotation is on |
| A3 | CKV_AWS_356 (resource `*` in a policy) | `terraform/modules/network` | In a KMS key policy `*` always means "this key"; it cannot be narrowed | None needed |
| A4 | CKV_AWS_394 (availability-zone data source) | `terraform/modules/network` | The number of subnets is fixed by a variable; a new availability zone cannot create any resource | None needed |
| A5 | CKV2_AWS_5 (security group not attached) | `terraform/modules/security` | **False positive.** The group is attached to the instance in another module; Checkov cannot follow a reference across modules | The attachment is visible in `terraform plan` |
| A6 | CKV_AWS_126 (detailed monitoring) | `terraform/modules/compute` | One-minute metrics cost extra. The setting is a variable, off for development and on in `environments/prod.tfvars.example` | Basic 5-minute metrics and flow logs remain on |
| A7 | Image tag `latest` in Ansible's `app_image` (manual runs only) | `ansible/group_vars/all/main.yml` | The pipeline always deploys an immutable commit-SHA tag (the registry refuses overwriting tags) | The image is built and scanned in CI before it is published; pin a version tag (or digest) for production |
| A8 | CKV_AWS_2, CKV_AWS_103, CKV2_AWS_20 (HTTP listener, no HTTPS redirect) | `terraform/modules/loadbalancer` | HTTPS needs a domain name and certificate, which the project does not have. The HTTPS listener and the redirect are already in the code and switch on when `certificate_arn` is set | No secrets or personal data are served; the database and servers are private. **Planned:** certificate and redirect |
| A9 | CKV_AWS_91 (no load balancer access logs), CKV2_AWS_28 (no web application firewall) | `terraform/modules/loadbalancer` | Cost and scope of a course project | Health checks, request metrics and alarms in CloudWatch; flow logs on the VPC. Future work |
| A10 | CKV_AWS_378 (HTTP between load balancer and server) | `terraform/modules/loadbalancer` | TLS ends at the load balancer | Traffic stays inside private subnets, limited by security groups |
| A11 | CKV_AWS_157, CKV_AWS_293, CKV_AWS_150 (Multi-AZ and deletion protection off) | `terraform/modules/database`, `loadbalancer` | They would make the lab environment expensive and impossible to destroy. They are variables, on in `environments/prod.tfvars.example` | Automated backups; the setting is documented per environment |
| A12 | CKV2_AWS_57 (no automatic secret rotation) | `terraform/modules/database` | Needs a rotation Lambda, out of scope | Random 32-character password, never shown in code, readable only by the pipeline role and administrators; rotate by changing the generated value and applying |
| A13 | CKV_AWS_353, CKV_AWS_354 (Performance Insights) | `terraform/modules/database` | Not offered on the small instance class used | Enhanced monitoring and CloudWatch metrics are on |
| A14 | CKV_AWS_355 (`*` resource for `ecr:GetAuthorizationToken`) | `terraform/modules/cicd` | AWS does not allow a resource for this action | Every other permission in the role is limited to one resource |
| A15 | Database connection uses `sslmode=require` (encrypted, server certificate not verified) | `ansible/roles/app` | Verifying needs the RDS CA bundle on the server | RDS refuses unencrypted connections (`rds.force_ssl=1`) and is reachable only from the app security group |
| A16 | Single NAT gateway and single app server | `terraform/` | Cost of a course project | Documented limit; Multi-AZ database in production settings |
| A17 | Bastion SSH is open to the runner's IP during a deployment | `.github/workflows/cd.yml` | GitHub-hosted runners have changing addresses | Rule is for the runner's own /32 only, port 22 only, and is revoked at the end of the run even when it fails (`if: always()`) |

## Security controls in the project

| Layer | Control |
|-------|---------|
| Source code | Branch protection, required reviews, CODEOWNERS, secrets and keys git-ignored, `.env.example` only |
| Pipeline | Least-privilege workflow permissions (`contents: read`), pinned scanner versions, scans on every pull request |
| Container | Multi-stage build, non-root user (UID 10001), read-only filesystem, all capabilities dropped, `no-new-privileges`, health check, patched base packages, no pip in the final image |
| Infrastructure | Servers and database in private subnets, bastion as the only way in, chained security groups, encrypted disks, database and logs, IMDSv2, no hard-coded credentials or regions, validated inputs |
| Deployment | OIDC instead of stored AWS keys, role limited to `main` and to one registry, one secret and one security group; image scanned before the push; immutable commit-SHA tags; automatic rollback |
| Server | UFW default deny, SSH key-only and no root login, fail2ban, kernel hardening, automatic security updates |
| Secrets | Database password generated by Terraform and kept in Secrets Manager (masked in logs, never in the repository); Ansible Vault for manual runs; `.env` on the server is mode 0600; Terraform state is git-ignored |
