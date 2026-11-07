# Formative 3: Evidence and Submission Guide

Terraform, Ansible and DevSecOps. This guide tells each member what to do, in order, and what proof to keep. Commands are for PowerShell (Windows) unless marked.

## 1. Who does what (three pull requests)

| Member | Branch | Pull request contains | Rubric part |
|--------|--------|----------------------|-------------|
| Jesse (@jessewalu) | `feature/terraform` | `terraform/`, `.gitignore` additions, fixes to `run.py` and `scripts/healthcheck.py`, `tests/test_healthcheck.py` | Part 1 (40) |
| Karabo (@Karabo-jpg) | `feature/ansible` | `ansible/`, `docs/F3_EVIDENCE_GUIDE.md` | Part 2 (30) |
| Kadi (@Kkadi20) | `feature/devsecops` | `.github/workflows/ci.yml`, `.github/dependabot.yml`, `.github/CODEOWNERS`, `requirements-security.txt`, `Dockerfile`, `SECURITY.md`, `README.md`, `docs/PROJECT_BOARD.md` | Part 3 (30) |

Each author opens a pull request to `main`; **another member reviews and approves** (CODEOWNERS enforces this). Merge order: Kadi's PR last, so the scans see the Terraform and Ansible code.

Branch and commit for each member (example for Jesse):

```powershell
git checkout main
git pull
git checkout -b feature/terraform
# copy the files listed for your PR into the repo, then:
git add terraform .gitignore run.py scripts/healthcheck.py tests/test_healthcheck.py
git commit -m "feat(terraform): VPC, security group and EC2 modules with variables and outputs"
git push -u origin feature/terraform
```

Then open the pull request on GitHub and ask a teammate to review it.

## 2. Check everything locally first

| What | Command | Expected |
|------|---------|----------|
| Python lint and tests | `ruff check .` then `pytest -q` | all pass |
| Terraform | `cd terraform; terraform init -backend=false; terraform fmt -recursive -check; terraform validate` | `Success! The configuration is valid.` |
| Ansible | `cd ansible; ansible-lint; ansible-playbook site.yml --syntax-check` | passed |
| Scans | `pip install -r requirements-security.txt` then `pip-audit -r requirements.txt` and `bandit -r app scripts run.py --severity-level medium` | no findings |

Ansible does not run natively on Windows: use WSL (Ubuntu) or the Linux/macOS machine of a teammate.

## 3. Branch protection: add the new required checks (Kadi)

Settings, Branches, edit the rule for `main`, **Require status checks to pass**, add:

- `dependency-scan (pip-audit)`
- `sast-scan (Bandit)`
- `container-scan (Trivy)`
- `iac-scan (Checkov)`
- `iac-validate (Terraform + Ansible)`

They only appear in the search box after they have run once, so open a pull request first. Screenshot the rule as `docs/screenshots/branch-protection-f3.png`.

## 4. Record the first Trivy result (Kadi)

Open the `container-scan` job in the first CI run. In `SECURITY.md`, finding 6, write the date, the number of HIGH/CRITICAL findings and what was done. If it is green, write that no fixable HIGH or CRITICAL vulnerabilities were found. Do not guess: copy what the log says.

## 5. Evidence to collect

| Evidence | Where from | Save as |
|----------|-----------|---------|
| Terraform plan | `terraform plan` output (screenshot or text) | `docs/screenshots/terraform-plan.png` |
| Terraform apply and outputs (needs an AWS account) | `terraform apply`, `terraform output` | `docs/screenshots/terraform-apply.png` |
| Ansible run | `ansible-playbook site.yml` | `docs/screenshots/ansible-first-run.png` |
| Ansible second run, `changed=0` | run it again | `docs/screenshots/ansible-second-run.png` |
| App answering | `curl http://<ip>/health` | `docs/screenshots/app-health.png` |
| CI run with all scan jobs green | Actions tab | link in README |
| A scan failing, then fixed | e.g. a pull request that adds an open `0.0.0.0/0` SSH rule, then the fix | links in README |
| Reviewed pull requests from all three members | Pull requests tab | links in README |
| `terraform destroy` finished (stop the bill) | terminal | optional |

No AWS account? Submit the `terraform plan` output if you can run it with temporary credentials, otherwise the CI `terraform validate` and Checkov results, and say so plainly in the README. Do not invent screenshots.

## 6. Final checklist

- [ ] `terraform/`: VPC, instance, security rules, variables (no secrets or hard-coded region), outputs, README
- [ ] `ansible/`: playbook, roles, inventory, firewall and SSH hardening, README
- [ ] At least two scan types in GitHub Actions on every pull request (we have four)
- [ ] Severity thresholds documented (README section 17, `SECURITY.md`)
- [ ] `SECURITY.md` has findings, remediation, accepted risks and the first Trivy result
- [ ] New checks added to branch protection
- [ ] Three reviewed pull requests, one per member
- [ ] `.terraform.lock.hcl` committed after the first `terraform init`; no `terraform.tfvars`, state or `vault.yml` committed
- [ ] Contribution tracker updated
