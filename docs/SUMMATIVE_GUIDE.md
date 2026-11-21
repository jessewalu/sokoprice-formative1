# Summative: Evidence, Submission and Demo Guide

Complete DevOps pipeline. This guide tells each member what to push, in what order to set things up, what proof to keep, and how to plan the video. Commands are for **Git Bash** unless marked **WSL** (Ansible only runs in WSL).

## 1. Who does what (three pull requests)

| Member | Branch | Pull request contains | Rubric area |
|--------|--------|----------------------|-------------|
| Jesse (@jessewalu) | `feature/summative-terraform-cd` | `terraform/` (all modules, README, examples), `.github/workflows/cd.yml`, `.github/workflows/ci.yml` | IaC (20), Continuous Deployment (15) |
| Karabo (@Karabo-jpg) | `feature/summative-ansible-docs` | `ansible/`, `README.md`, `CHANGELOG.md`, `docs/SUMMATIVE_GUIDE.md`, `docs/PROJECT_BOARD.md` | Configuration management (20), Documentation (20) |
| Kadi (@Kkadi20) | `feature/summative-security` | `SECURITY.md`, repository settings (variables, secret, environment, required checks) | DevSecOps (20), repository security |

Merge order: Jesse's PR first (it creates the infrastructure code), then Karabo's, then Kadi's. **Merging to `main` triggers the CD workflow**, so complete section 2 *before* the first merge, or the first CD run will fail (that is harmless, but then you re-run it).

Each author opens a pull request; another member reviews and approves (CODEOWNERS enforces this).

## 2. Set up and deploy (in this order)

1. **Remove the Formative 3 infrastructure** (it uses the same names): `cd terraform && terraform destroy` with the old code, **before** you replace the files.
2. Copy the new files in, then `terraform init`, `terraform fmt -check -recursive`, `terraform validate`.
3. `cp terraform.tfvars.example terraform.tfvars`: set `admin_cidrs` (your IP `/32`) and `ssh_public_key`. Never commit this file.
4. `terraform plan -out=tfplan`, read it, then `terraform apply tfplan` (10 to 15 minutes).
5. Set the GitHub values: `terraform output -raw github_cli_commands | bash` and `gh secret set DEPLOY_SSH_PRIVATE_KEY < ~/.ssh/sokoprice`.
6. GitHub: create the environment `production`; add the new status checks to the `main` branch protection rule.
7. Merge the pull requests. Watch **Actions → CD**. When it is green, open `terraform output app_url`.
8. Put the real URL in `README.md` (the "Live application" line) and commit it in a small follow-up pull request.

## 3. Evidence to collect (before you destroy anything)

| # | Evidence | Rubric area |
|---|----------|-------------|
| 1 | `terraform plan` output and `terraform apply` "Apply complete" with the outputs | IaC |
| 2 | AWS console: VPC, the two subnet types, the app server **without a public IP**, the bastion **with** one, RDS, ECR repository, load balancer | IaC |
| 3 | Security groups showing the chained rules (source = another group) | IaC |
| 4 | Ansible run summary (`ok`/`changed`) and a **second run with `changed=0`** (idempotency), from WSL | Configuration management |
| 5 | A CI run with Trivy and Checkov **passing**, and (if you tried it) one **failing** because of a real finding, then the fix | DevSecOps |
| 6 | The CD run: all three jobs green, the image tag in ECR equal to the commit SHA | Continuous Deployment |
| 7 | The live URL answering `/health`, `/api/prices/maize` and `/api/stats` | Operational readiness |
| 8 | CloudWatch: the application log group with entries, the dashboard, the alarm list | Observability |
| 9 | The README operations manual and `CHANGELOG.md` on GitHub | Documentation |
| 10 | Pull requests from all members with reviews; the project board | Continuity and integrity |

Take screenshots of what **really happened**. Do not edit or recreate evidence: if a step failed and you fixed it, that story is worth more than a perfect screenshot.

## 4. Video demo plan (25 points: demo, continuity, integrity)

The narration must be **your own words** and describe **what you really did**. This plan lists what to show; it is not a script.

**Show continuity across the three stages** (about 8 to 12 minutes total):

1. **Formative 1, the foundation:** the repository, the app answering a request, the project board, a pull request with review.
2. **Formative 2, containers and CI:** the Dockerfile (multi-stage, non-root), `docker compose up`, a CI run.
3. **Formative 3, IaC and security:** the first Terraform and Ansible, the scans and `SECURITY.md`.
4. **Summative, the finished pipeline:**
   - Make a small change (for example one line in the README or a price), open a pull request, show CI running and the review.
   - Merge it and show the **CD run**: tests and scans, Trivy, push to ECR, Ansible through the bastion.
   - Open the **live URL** and show the change; show `/api/stats` (database connection).
   - Show the architecture in the console: private server (no public IP), bastion, RDS, ECR, load balancer.
   - Show logs, the dashboard and an alarm in CloudWatch.
   - Show the rollback safeguard: explain it, or demonstrate it with a deliberately broken image tag on a branch if you have time.

**Reflection (integrity).** Each member says, in their own words: what they built, one thing that failed or surprised them and how they fixed it, one trade-off the team accepted (see the accepted-risks table in `SECURITY.md`), and what they would do next (HTTPS, WAF, Multi-AZ). Be honest about anything that does not work or that you needed help with.

Checklist before recording: the environment is deployed and CD is green; the browser tabs you need are open (GitHub Actions, the live URL, the AWS console, CloudWatch); no secrets or access keys are visible on screen (hide the IAM console key page, the `terraform.tfvars` file and the `DEPLOY_SSH_PRIVATE_KEY`).

## 5. After the demo (cost and security)

1. `terraform destroy` (the load balancer, NAT gateway and database cost money by the hour).
2. Delete the IAM access key you created for Terraform (IAM → Users → Security credentials).
3. Check in **Billing** that nothing is still running.
4. Tag the final state: `git tag -a v4.0-summative -m "Summative: complete DevOps pipeline" && git push --tags`.

## 6. Requirement checklist

| Requirement | Where it is met |
|-------------|-----------------|
| Modular Terraform in `terraform/` | `terraform/modules/*` |
| Private network, VM in a private subnet | `modules/network`, `modules/compute` |
| Bastion host in a public subnet | `modules/compute` |
| Managed database | `modules/database` (RDS) |
| Security groups | `modules/security` |
| Private container registry | `modules/registry` (ECR) |
| Ansible installs Docker and Docker Compose | `ansible/roles/docker`, `site.yml` |
| Container image scan (Trivy), fails on critical | `ci.yml` job `container-scan`, `cd.yml` job `build-and-push` |
| IaC scan (Checkov), fails the build | `ci.yml` job `iac-scan` |
| `cd.yml` only on merge to `main` | `.github/workflows/cd.yml` (`on: push: branches: [main]`) |
| CD runs CI checks first | job `ci` (reusable workflow) |
| Build, push to the private registry | job `build-and-push` |
| Authenticate to cloud, run Ansible on the VM | job `deploy` (OIDC, then `ansible-playbook`) |
| Live app on a public URL | `terraform output app_url` |
| README operations manual with diagram and live link | `README.md` sections 15 to 20 |
| `CHANGELOG.md` for F1, F2, Summative | `CHANGELOG.md` |
