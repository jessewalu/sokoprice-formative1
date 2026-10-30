# Formative 2: CI Pipeline for a Containerized Application

This guide shows how the repository meets each rubric criterion and tells the team exactly how to produce the **evidence** (CI runs, pull requests, code reviews, branch protection) that cannot be created by files alone.

## 1. Rubric map: where each criterion is satisfied

| Rubric criterion (20 pts each) | What delivers it | File(s) |
|---|---|---|
| **Dockerfile quality** | Multi-stage build, pinned base image, non-root numeric user, dependency layer caching, `HEALTHCHECK`, comments on every instruction | `Dockerfile`, `.dockerignore`, `scripts/healthcheck.py` |
| **Docker Compose** | `app` + `db` services, two networks (one `internal`), named volume, health checks, `depends_on: service_healthy`, restart policies, env-var management with safe defaults | `docker-compose.yml`, `.env.example` |
| **CI workflow configuration** | Correct triggers, lint + test + Docker build, matrix (Python 3.11/3.12), pip and Docker layer caching, uploaded test/coverage artifacts, publish to GHCR with `GITHUB_TOKEN` | `.github/workflows/ci.yml`, `.github/workflows/publish.yml` |
| **CI pipeline function** | Fails on lint errors, failing tests, coverage under 80% and a broken image or Compose stack; passes on clean code; concurrency control; status checks on PRs | `ci.yml`, `ruff.toml`, `tests/` |
| **Integration & evidence** | Branch protection requiring CI + review, multiple PRs with real reviews, runs history, board kept up to date | Sections 3-7 below (you create this on GitHub) |

## 2. Files in this package

```
Dockerfile                      docker-compose.yml          .dockerignore
.env.example                    requirements.txt            requirements-dev.txt
ruff.toml                       README.md
app/__init__.py  (changed)      app/db.py (new)
scripts/healthcheck.py          tests/test_db.py
.github/workflows/ci.yml        .github/workflows/publish.yml
.github/pull_request_template.md
docs/F2_EVIDENCE_GUIDE.md
```

Unzip the package over your repository root so each file lands in the same folder. `app/__init__.py`, `requirements.txt`, `.dockerignore`, `.env.example`, `Dockerfile`, `README.md` and `.github/workflows/ci.yml` **replace** existing files. If your own README already has changes (for example a link you added), compare before overwriting.

> If the Docker Compose pull request that Karabo already opened is still open, compare it with `docker-compose.yml` here. Either merge the best parts into one file or close it with a comment such as "Superseded by #N".

## 3. Recommended pull-request plan (shows real collaboration)

Do **not** push to `main` (it is protected). Use one branch for the containerization work and let each teammate commit their own part. Every push to a non-`main` branch starts a CI run, which creates your run history automatically.

```powershell
git checkout main
git pull
git checkout -b feature/docker-compose-ci
git push -u origin feature/docker-compose-ci
```

Teammates then run `git fetch`, `git checkout feature/docker-compose-ci` (they need write access as collaborators) and push their own commits, in this order:

| # | Who (suggested) | Files to commit | Commit message | Expected CI result |
|---|---|---|---|---|
| 1 | Karabo | `Dockerfile`, `.dockerignore`, `scripts/healthcheck.py` | `build: multi-stage Dockerfile with non-root user and health check` | Green (the existing CI still runs and builds the image) |
| 2 | Kadi | `.github/workflows/ci.yml`, `.github/workflows/publish.yml`, `ruff.toml`, `requirements.txt`, `requirements-dev.txt`, `.github/pull_request_template.md` | `ci: add lint, test matrix and Docker build pipeline` | **Red** at `docker-build`: `docker-compose.yml` does not exist yet |
| 3 | Jesse | `docker-compose.yml`, `.env.example`, `app/__init__.py`, `app/db.py`, `tests/test_db.py` | `feat: add PostgreSQL request log and Docker Compose stack` | Green: fixes the red run |
| 4 | Karabo | `README.md`, `docs/F2_EVIDENCE_GUIDE.md` | `docs: document Docker Compose and CI pipeline` | Green |

That gives you a failed run that is then fixed, and three or more green runs, just by following the order.

**Open the pull request into `main` right after commit 1 is pushed** (GitHub shows a "Compare & pull request" banner). Until your new `ci.yml` arrives in commit 2, the old workflow only runs for pull requests, so opening the PR early is what produces the first run. Later pushes to the branch update the same PR, and from commit 2 onward every push also runs the new pipeline.

Before each push, check who you are committing as:

```powershell
git config user.name
git config user.email
```

### Second pull request: deliberate failure demo (strong evidence)

This proves the pipeline really blocks bad code. One person does this on a throw-away branch:

```powershell
git checkout main; git pull
git checkout -b ci/demo-failing-checks
```

1. Add an unused import at the top of `scripts/healthcheck.py` (for example `import json`), commit as `test: introduce lint error to prove CI fails` and push. Open a PR: the **lint** check goes red and the merge button is blocked.
2. Remove the line, commit as `fix: remove unused import`, push. Lint turns green.
3. Optionally repeat with a failing test: change `assert response.status_code == 200` in a test to `== 500`, push (the **test** checks go red), then revert it.
4. Take screenshots of the red and the green runs, ask a teammate to review, then either merge or close the PR with a note. Closed or merged both count as evidence.

### Reviewing is a graded skill

The reviewer should open **Files changed** and leave real comments on specific lines, then click **Review changes → Approve**. Ideas for meaningful review points:

- Dockerfile: is the user non-root, is the base image pinned, is the dependency layer cached, is the `HEALTHCHECK` correct?
- Compose: does the database stay private, is the volume named, are secrets read from environment variables?
- CI: do the triggers match the assignment, does any step fail the job on error?
- Tests: do they cover failure cases, not only the happy path?

Answer each comment in the thread and click **Resolve conversation** (the branch protection rule requires this).

## 4. Update branch protection (do this before merging the first PR)

Repository → **Settings → Branches → Branch protection rule for `main` → Edit**.

1. Tick **Require a pull request before merging**
   - **Require approvals**: 1
   - **Dismiss stale pull request approvals when new commits are pushed**
2. Tick **Require status checks to pass before merging**
   - Tick **Require branches to be up to date before merging**
   - In the search box add these checks: **`lint`**, **`test (py3.11)`**, **`test (py3.12)`**, **`docker-build`**
3. Tick **Require conversation resolution before merging**
4. Tick **Do not allow bypassing the above settings** (this is "Include administrators")
5. Click **Save changes**.

Important details:

- A check name only appears in the search box **after it has run at least once**. Push the branch first (section 3), wait for the run to finish, then add the checks.
- If you previously required a check named plain **`test`**, **remove it**. The pipeline now reports `test (py3.11)` and `test (py3.12)`, and a required check that never reports leaves every PR stuck on "Expected: waiting for status".
- Take a screenshot of the finished rule for your submission.

## 5. Merge, then check the publish workflow

After the PR is approved and all checks are green, click **Merge pull request** and delete the branch. The merge to `main` starts `publish.yml`, which pushes the image to `ghcr.io/jessewalu/sokoprice-formative1`. Find it under the repo's **Packages** section. If the push is denied, open **Settings → Actions → General → Workflow permissions** and select **Read and write permissions**.

## 6. Keep the project board up to date

Add these items to **SokoPrice Board** (milestone: *Formative 2*), set labels and assignees, and move each card as you work. Assignees below are suggestions; change them to match who really does the work.

| # | Title | Labels | Suggested assignee | Column when you submit |
|---|-------|--------|--------------------|------------------------|
| F2-1 | Multi-stage Dockerfile with non-root user and health check | `devops` `security` | Karabo | Done |
| F2-2 | Docker Compose stack with PostgreSQL, networks and volume | `devops` | Jesse | Done |
| F2-3 | Record USSD requests in PostgreSQL | `feature` | Jesse | Done |
| F2-4 | Add Ruff linting and a coverage gate | `devops` `testing` | Karabo | Done |
| F2-5 | CI workflow: lint, test matrix, Docker build | `devops` | Kadi | Done |
| F2-6 | Publish Docker image to GHCR on merge | `devops` `security` | Jesse | Done |
| F2-7 | Require CI checks in branch protection | `security` | Kadi | Done |
| F2-8 | Demonstrate a failing then fixed CI run | `devops` `testing` | Kadi | Done |
| F2-9 | Add pull request template and review checklist | `documentation` | Karabo | Done |

Suggested user story and acceptance criteria for each (copy into the issue):

- **F2-1** *As a DevOps engineer, I want a hardened image so that the app runs the same and safely everywhere.* Criteria: pinned base image; multi-stage; non-root user; `HEALTHCHECK`; builds with `docker build .`.
- **F2-2** *As a developer, I want one command to start the app and database so that onboarding takes minutes.* Criteria: `docker compose up --build` works; DB not exposed to host; data survives `down`/`up`.
- **F2-3** *As a project owner, I want to see which crops farmers query so that we can improve the service.* Criteria: each USSD request stored without phone numbers; `/api/stats` shows the count; app keeps working if the DB is down.
- **F2-4** *As a developer, I want automatic style and coverage checks so that code quality stays high.* Criteria: `ruff check .` passes; coverage gate of 80%.
- **F2-5** *As a team member, I want every push and PR checked automatically so that bugs are caught early.* Criteria: triggers on non-main pushes and PRs to main; lint, test and Docker build jobs.
- **F2-6** *As a DevOps engineer, I want merged code published as an image so that it is ready to deploy.* Criteria: image in GHCR tagged `latest` and commit SHA; no stored passwords.
- **F2-7** *As a maintainer, I want broken code blocked from `main` so that `main` is always releasable.* Criteria: required checks listed in section 4; screenshot saved.
- **F2-8** *As a reviewer, I want proof the pipeline fails on bad code so that I can trust it.* Criteria: one red run and the fixing green run linked below.
- **F2-9** *As a reviewer, I want a standard PR description so that reviews are faster.* Criteria: template appears on new PRs.

Also keep the **Formative 1** items closed, and link each PR to its issue with `Closes #N` (GitHub's real number, which differs from the number in the title).

## 7. Evidence tracker (fill this in and keep it in the repo)

Collect links from the repository's **Actions** and **Pull requests** tabs.

| Evidence required | Link | Who |
|---|---|---|
| Successful CI run 1 | https://github.com/jessewalu/sokoprice-formative1/actions/runs/41044648209 | Karabo |
| Successful CI run 2 | https://github.com/jessewalu/sokoprice-formative1/actions/runs/41061590854 | Team (Publish to GHCR) |
| Successful CI run 3 | https://github.com/jessewalu/sokoprice-formative1/actions/runs/41047000861 | Jesse / Karabo |
| Failed CI run (and its cause) | https://github.com/jessewalu/sokoprice-formative1/actions/runs/41034821146 (pytest fails: missing psycopg runtime dependency) | Jesse |
| Fixing run (green) after the failure | https://github.com/jessewalu/sokoprice-formative1/actions/runs/41061590854 | Kadi / Team |
| Pull request with CI checks visible | https://github.com/jessewalu/sokoprice-formative1/pull/16 | Karabo |
| Pull request with review comments and approval | https://github.com/jessewalu/sokoprice-formative1/pull/15 (and PR #17) | Karabo (Reviewer) |
| Branch protection screenshot | *(Pending screenshot of Settings -> Branches)* | Karabo / Kadi |
| Published image in Packages | https://github.com/users/jessewalu/packages/container/package/sokoprice-formative1 | Jesse / Team |
| Board screenshot (Backlog / In Progress / Done) | *(Pending screenshot of Project Board)* | Team |

Screenshots to take: the Actions list showing red and green runs; one PR page showing the checks and the "Approved" review; the branch protection rule; the Packages page; the project board.

## 8. Final self-check before you submit

- [ ] `docker compose up --build` works on a clean clone and `http://localhost:5000/health` answers
- [ ] `/api/stats` shows `"database": "connected"` after a USSD request
- [ ] `ruff check .` and `pytest` pass locally
- [ ] At least 3 green runs, 1 red run followed by a green fix
- [ ] At least 1 merged PR with CI checks and a real review, ideally 2 or 3 PRs from different authors
- [ ] Branch protection requires PRs, 1 approval, `lint`, `test (py3.11)`, `test (py3.12)`, `docker-build`, up-to-date branches, conversation resolution and includes administrators
- [ ] All three teammates have commits and reviews
- [ ] Board updated, contribution tracker updated, repository URL submitted on Canvas
