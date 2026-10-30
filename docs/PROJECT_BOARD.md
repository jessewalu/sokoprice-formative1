# SokoPrice: GitHub Projects Board, Backlog & User Stories

Board: **SokoPrice Board** (GitHub Projects, Board/Kanban view) with columns **Backlog → In Progress → Done**.

_Last updated for **Formative 2: CI/CD & Containerisation**._ Items 1-8 belong to Formative 1, items 9-21 to Formative 2 and 3.

**Status at a glance:** 13 items Done · 4 In Progress · 4 Backlog.

---

## A. How to create the board (5 minutes)

1. On GitHub, open your repo → **Projects** tab → **New project** → choose the **Board** template. Name it **SokoPrice Board**.
2. Set the Status columns to exactly: **Backlog**, **In Progress**, **Done**.
3. **Labels** (repo → Issues → Labels): `feature`, `bug`, `devops`, `security`, `documentation`, `testing`.
4. **Milestones** (repo → Issues → Milestones → New). Rename these to match your course and add the real due dates:
   - `Formative 1: Foundation & Secure Collaboration`
   - `Formative 2: CI/CD & Containerisation`
   - `Formative 3: Cloud Deployment & Monitoring`
5. Create one GitHub issue per item in section C (copy the text), then set label, milestone and assignee.
6. In the Project, click **Add item** and add each issue, then drag it to the column shown in the table.
7. Take a screenshot of the finished board for your submission (save it as `docs/screenshots/project-board.png`).

> Every issue must have: a user story, acceptance criteria, at least one label, an assignee and a milestone.
> Link each pull request to its issue with `Closes #<number>` so the board moves cards to **Done** automatically when the PR merges.

---

## B. Backlog overview (21 items)

| # | Title | Label(s) | Milestone | Column | Assignee |
|---|-------|----------|-----------|--------|----------|
| 1 | Write project description in README | `documentation` | Formative 1 | Done | @Karabo-jpg |
| 2 | Secure repo: `.gitignore` and `.env.example` | `security` | Formative 1 | Done | @Kkadi20 |
| 3 | Crop price lookup service and API | `feature` | Formative 1 | Done | @jessewalu |
| 4 | USSD 2-level menu | `feature` | Formative 1 | Done | @jessewalu |
| 5 | Unit tests for price logic, USSD and API | `testing` | Formative 1 | Done | @Karabo-jpg |
| 6 | Set up CI pipeline (GitHub Actions) | `devops` | Formative 1 | Done | @jessewalu |
| 7 | Containerise app with Docker (non-root, gunicorn) | `devops` `security` | Formative 1 | Done | @Karabo-jpg |
| 8 | Branch protection, LICENSE and CODEOWNERS | `security` `documentation` | Formative 1 | In Progress | @Kkadi20 |
| 9 | Store prices in PostgreSQL instead of JSON | `feature` | Formative 2 | In Progress | @jessewalu |
| 10 | Market agent price-submission endpoint with API-key auth | `feature` `security` | Formative 2 | Backlog | @Kkadi20 |
| 11 | Add lint step and coverage report to CI | `devops` `testing` | Formative 2 | Done | @Karabo-jpg |
| 12 | Price-change SMS alerts | `feature` | Formative 3 | Backlog | @Karabo-jpg |
| 13 | Configure Terraform for cloud infrastructure | `devops` | Formative 3 | Backlog | @jessewalu |
| 14 | Add Kinyarwanda language option to USSD | `feature` | Formative 3 | Backlog | @Kkadi20 |
| 15 | Harden Dockerfile: multi-stage build, health check, layer caching | `devops` `security` | Formative 2 | Done | @Karabo-jpg |
| 16 | Docker Compose: app + PostgreSQL with networks, volume and health checks | `devops` | Formative 2 | Done | @jessewalu |
| 17 | PostgreSQL USSD request log and `/api/stats` endpoint | `feature` `testing` | Formative 2 | Done | @jessewalu |
| 18 | CI: lint, test matrix, Docker build and Compose smoke test | `devops` `testing` | Formative 2 | Done | @jessewalu |
| 19 | Publish Docker image to GHCR after merge to `main` | `devops` | Formative 2 | Done | @jessewalu |
| 20 | Update branch protection to require the new CI checks | `security` `devops` | Formative 2 | In Progress | @Kkadi20 |
| 21 | Collect CI evidence: 3 green runs, 1 red-then-fixed run, reviewed PRs | `devops` `documentation` | Formative 2 | In Progress | @Karabo-jpg |

> Items 6, 7 and 8 were first delivered in Formative 1 and are extended by items 15, 18 and 20. When you maintain the real board, keep the Column values here in sync with it.
> Item 21 is a **team** task: all three members must contribute reviewed pull requests.

---

## C. Issue text (copy/paste into GitHub issues)

### #1 Write project description in README
**As a** course assessor, **I want** a clear project description **so that** I can understand the problem, users and scope quickly.
**Acceptance criteria**
- [x] Project name and tagline
- [x] Problem statement and target users
- [x] 3-5 core features and technology stack
- [x] Setup and run instructions

### #2 Secure repo: `.gitignore` and `.env.example`
**As a** developer, **I want** secrets and clutter excluded from git **so that** credentials are never leaked.
**Acceptance criteria**
- [x] `.gitignore` covers IDE files, dependencies, env files/secrets, build artifacts and logs
- [x] `.env.example` contains placeholders only
- [x] No secrets exist anywhere in git history

### #3 Crop price lookup service and API
**As a** farmer, **I want** to see a crop's price in each market **so that** I know where my crop is worth the most.
**Acceptance criteria**
- [x] `GET /api/prices/<crop>` returns per-market prices
- [x] Unknown crop returns 404
- [x] `GET /api/crops` lists crops and markets
- [x] `GET /api/best-market/<crop>` returns best market to sell and cheapest to buy

### #4 USSD 2-level menu
**As a** farmer with a feature phone, **I want** to check prices by dialling a code **so that** I don't need internet or a smartphone.
**Acceptance criteria**
- [x] Main menu → crop menu → result (at least 2 levels)
- [x] Options: check price, best market to sell, cheapest market to buy, exit
- [x] Invalid input ends the session with a clear message

### #5 Unit tests for price logic, USSD and API
**As a** developer, **I want** automated tests **so that** changes don't break core features.
**Acceptance criteria**
- [x] Tests for best/cheapest market and unknown crop
- [x] Tests for every USSD path including invalid input
- [x] Tests for REST endpoints and `/health`
- [x] Tests for the PostgreSQL request log (integration test runs in CI)
- [x] All tests pass with `pytest -q`

### #6 Set up CI pipeline
**As a** developer, **I want** tests to run automatically on every push and pull request **so that** bugs are caught early.
**Acceptance criteria**
- [x] GitHub Actions workflow runs `pytest`
- [x] Docker image build runs after tests pass
- [x] Job names are available as required status checks (see #20 for the current names)

### #7 Containerise the app with Docker
**As a** DevOps engineer, **I want** a Docker image **so that** the app runs the same on every machine and in the cloud.
**Acceptance criteria**
- [x] Image builds from `Dockerfile`
- [x] App runs under gunicorn as a non-root user
- [x] `.dockerignore` keeps secrets and tests out of the image
- [x] Container responds on port 5000

### #8 Branch protection, LICENSE and CODEOWNERS
**As a** team member, **I want** `main` protected and the repo properly licensed **so that** all changes are reviewed and the project follows professional standards.
**Acceptance criteria**
- [x] `LICENSE` (MIT) added
- [x] `.github/CODEOWNERS` added
- [ ] Require a pull request before merging
- [ ] Require 1 approval and dismiss stale approvals
- [ ] Require branches to be up to date
- [ ] Require conversation resolution
- [ ] Include administrators
- [ ] Issues and Projects enabled; instructor added as collaborator (or repo public)
- _These are GitHub settings, not files, so tick each box once you have confirmed it in Settings → Branches. Required status check names are covered in #20._

### #9 Store prices in PostgreSQL
**As a** market agent, **I want** prices stored in a database **so that** they can be updated without redeploying the app.
**Acceptance criteria**
- [ ] Prices table created and seeded from `data/prices.json`
- [ ] API and USSD read prices from the database
- [x] Connection string comes from an environment variable (`DATABASE_URL`)
- [x] `docker-compose.yml` runs the app and database together
- [x] Existing tests still pass

_Progress: PostgreSQL is already wired up and runs in Compose (see #16, #17); only the prices themselves still come from `data/prices.json`._

### #10 Market agent price submission
**As a** market agent, **I want** to submit today's prices **so that** farmers always see fresh data.
**Acceptance criteria**
- [ ] `POST /api/prices` accepts crop, market and price
- [ ] Request requires an API key read from an environment variable
- [ ] Invalid or negative prices are rejected with 400
- [ ] Requests without a valid key get 401
- [ ] Tests cover success and failure cases

### #11 Add lint step and coverage report to CI
**As a** developer, **I want** style and coverage checks in CI **so that** code quality stays high as the team grows.
**Acceptance criteria**
- [x] Lint step (Ruff) runs in CI
- [x] Coverage report generated, shown in CI logs and uploaded as an artifact
- [x] Pipeline fails on lint errors
- [x] Pipeline fails when coverage drops below 80%

### #12 Price-change SMS alerts
**As a** farmer, **I want** an SMS when my crop's price rises **so that** I can sell at the best time.
**Acceptance criteria**
- [ ] Farmer can subscribe a phone number to a crop via USSD
- [ ] SMS sent when price rises above a set threshold
- [ ] Gateway credentials are stored in environment variables, never in code

### #13 Configure Terraform for cloud infrastructure
**As a** DevOps engineer, **I want** infrastructure as code **so that** deployments are repeatable and reviewable.
**Acceptance criteria**
- [ ] Terraform config provisions a container host and database
- [ ] State files and `.tfvars` are git-ignored
- [ ] `terraform plan` runs cleanly in CI
- [ ] Deployment steps documented in the README

### #14 Add Kinyarwanda language option to USSD
**As a** Kinyarwanda-speaking farmer, **I want** menus in my own language **so that** I can use the service easily.
**Acceptance criteria**
- [ ] First menu lets the user choose English or Kinyarwanda
- [ ] All menus and results are translated
- [ ] Tests cover both languages

### #15 Harden Dockerfile: multi-stage build, health check, layer caching
**As a** DevOps engineer, **I want** a small, secure and reproducible image **so that** it is safe to run anywhere.
**Acceptance criteria**
- [x] Pinned base image (`python:3.12-slim-bookworm`), no `latest`
- [x] Multi-stage build (`builder` and `runtime`); no build tooling in the final image
- [x] Runs as a non-root user (UID 10001)
- [x] Dependencies installed before code is copied (layer caching)
- [x] `HEALTHCHECK` using `scripts/healthcheck.py`
- [x] Every instruction is commented
- [x] `.dockerignore` excludes `.git`, `.env`, tests, docs and caches

### #16 Docker Compose: app + PostgreSQL
**As a** developer, **I want** one command to start the whole stack **so that** local development is easy and consistent.
**Acceptance criteria**
- [x] `docker compose up --build` starts `app` (built from the Dockerfile) and `db` (`postgres:16-alpine`)
- [x] `frontend` network for the host and an internal `backend` network for app ↔ db
- [x] Named volume `pgdata` keeps the database data across restarts
- [x] Environment variables with safe defaults, overridable via `.env`
- [x] Health checks, `restart: unless-stopped`, and `depends_on: service_healthy`
- [x] Hardening: read-only filesystem, `cap_drop: ALL`, `no-new-privileges`
- [x] README documents the commands, variables and troubleshooting

### #17 PostgreSQL USSD request log and `/api/stats`
**As a** project team, **I want** to know which crops farmers ask about most **so that** we can improve the service, without storing personal data.
**Acceptance criteria**
- [x] Each USSD request's menu path is stored with a timestamp
- [x] No phone numbers or personal data are stored
- [x] The app works when no database is configured
- [x] `GET /api/stats` reports `disabled`, `unavailable` or `connected` and the request count
- [x] Tests cover the request log (PostgreSQL integration test runs in CI)

### #18 CI: lint, test matrix, Docker build and Compose smoke test
**As a** developer, **I want** every push and pull request validated automatically **so that** broken code never reaches `main`.
**Acceptance criteria**
- [x] Triggers on pushes to any branch except `main` and on pull requests targeting `main`
- [x] `lint` job runs `ruff check .` and fails on any error
- [x] `test` job runs on Python 3.11 and 3.12 with a PostgreSQL service and fails on test failure or coverage < 80%
- [x] `docker-build` job (after lint and tests) builds the image and fails if the build fails
- [x] Smoke test: container becomes healthy and `/health`, `/api/prices/maize`, `/ussd` answer
- [x] Full Compose stack is started and `/api/stats` reports `connected`
- [x] Build cache, least-privilege permissions, concurrency control and uploaded test/coverage artifacts
- [x] Workflow YAML validated (stray character removed from `ci.yml`)

### #19 Publish Docker image to GHCR
**As a** DevOps engineer, **I want** merged code published as an image **so that** it can be deployed in Formative 3.
**Acceptance criteria**
- [x] `publish.yml` runs on push to `main` only
- [x] Logs in with the automatic `GITHUB_TOKEN` (no stored credentials)
- [x] Pushes `ghcr.io/jessewalu/sokoprice-formative1` tagged `latest` and `sha-<short>`

### #20 Update branch protection to require the new CI checks
**As a** team member, **I want** `main` to require the CI checks **so that** nothing merges unless lint, tests and the Docker build pass.
**Acceptance criteria**
- [ ] Required status checks set to `lint`, `test (py3.11)`, `test (py3.12)` and `docker-build`
- [ ] "Require branches to be up to date" still enabled
- [ ] 1 approval, stale-approval dismissal, conversation resolution and "include administrators" still enabled
- [ ] A PR with a failing check is shown as **blocked from merging**
- [ ] Screenshot saved as `docs/screenshots/branch-protection.png`

_Tip: a check only appears in the dropdown after it has run at least once, so push a branch first._

### #21 Collect CI evidence
**As a** course assessor, **I want** clear evidence that CI works **so that** I can verify the pipeline enforces quality.
**Acceptance criteria**
- [ ] At least 3 successful CI runs (links in the README, section 9)
- [ ] At least 1 failed run (deliberate lint error or failing test) followed by a fix that turns it green
- [ ] At least 1 pull request showing CI status checks and a code review with meaningful comments
- [ ] Pull requests authored and reviewed by all three team members
- [ ] Board screenshot saved as `docs/screenshots/project-board.png`

---

## D. Submission checklist

**Formative 1 (foundation)**
- [x] README has name, tagline, problem, users, 3-5 features, stack, run instructions
- [ ] Board has 12+ items with user stories, acceptance criteria, labels, assignees and milestones _(create the issues from section C)_
- [x] Board has feature items **and** DevOps items (CI, Docker, Terraform)
- [ ] Columns are Backlog / In Progress / Done _(verify on GitHub)_
- [x] `.gitignore`, `LICENSE` and `CODEOWNERS` present
- [ ] Teammates have contributed via pull requests with reviews
- [ ] All team members added as collaborators
- [ ] Repo is public or instructor added as collaborator
- [ ] Team participation sheet completed by the team lead and submitted

**Formative 2 (containerisation and CI)**
- [x] `Dockerfile`: pinned base image, non-root user, multi-stage, health check, commented
- [x] `docker-compose.yml`: app + PostgreSQL, networks, volume, environment variables, `docker compose up`
- [x] `.dockerignore` present
- [x] README updated with Docker, Docker Compose and CI instructions
- [x] `.github/workflows/ci.yml`: valid YAML, correct triggers, checkout, setup, install, lint, test, Docker build
- [x] Lint, test and Docker build failures each fail the pipeline
- [x] At least 1 test (35 tests, about 96% coverage)
- [ ] Branch protection requires the CI checks `lint`, `test (py3.11)`, `test (py3.12)`, `docker-build` _(item #20, must be done on GitHub)_
- [ ] At least 3 successful CI runs _(item #21)_
- [ ] At least 1 failed CI run that was then fixed _(item #21)_
- [ ] At least 1 pull request showing CI integration and code review _(item #21)_
- [ ] Multiple team members contributing, with reviews on pull requests
- [ ] Project board kept up to date and screenshot included
