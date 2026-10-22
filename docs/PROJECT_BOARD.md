<<<<<<< HEAD
# SokoPrice: GitHub Projects Board Setup & Backlog

## A. How to create the board (5 minutes)

1. On GitHub, open your repo → **Projects** tab → **New project** (or from your profile/org → Projects → New project).
2. Choose the **Board** template (Kanban). Name it **SokoPrice Board**.
3. Rename/arrange the Status columns to exactly: **Backlog**, **In Progress**, **Done**.
4. **Labels** (repo → Issues → Labels → New label): `feature`, `bug`, `devops`, `security`, `documentation`, `testing`.
5. **Milestones** (repo → Issues → Milestones → New): create one per formative deadline, e.g.
   - `Formative 1: Planning & Initial Codebase` (due: your Formative 1 date)
   - `Formative 2: CI/CD & Containerisation`
   - `Formative 3: Cloud Deployment`
   (Rename to match your course's actual names/dates.)
6. Create each issue below (Issues → New issue), set label, milestone, assignee, then in the Project click **Add item** and add the issue.
7. Move items already done (marked ✅ below) into **Done**, the one you're working on into **In Progress**, the rest stay in **Backlog**.

> Tip: assign **every** issue to a specific team member, and take a screenshot of the finished board for your submission.

---

## B. Backlog (13 items)

| # | Title | Type / Label | Milestone | Suggested column | Assignee |
|---|-------|--------------|-----------|------------------|----------|
| 1 | Write project description in README | `documentation` | Formative 1 | ✅ Done | Member 1 |
| 2 | Set up secure repo: `.gitignore`, `.env.example` | `security` | Formative 1 | ✅ Done | Member 2 |
| 3 | Price lookup endpoint (`/api/prices/<crop>`) | `feature` | Formative 1 | ✅ Done | Member 1 |
| 4 | USSD 2-level menu | `feature` | Formative 1 | ✅ Done | Member 4 |
| 5 | Unit tests for price logic and USSD | `testing` | Formative 1 | In Progress | Member 3 |
| 6 | Set up CI pipeline (GitHub Actions: test + Docker build) | `devops` | Formative 2 | In Progress | Member 2 |
| 7 | Containerise app with Docker (non-root) | `devops` | Formative 2 | Backlog | Member 2 |
| 8 | Store prices in PostgreSQL instead of JSON | `feature` | Formative 2 | Backlog | Member 1 |
| 9 | Market agent price-submission endpoint with API-key auth | `feature` `security` | Formative 2 | Backlog | Member 4 |
| 10 | Price-change SMS alerts | `feature` | Formative 3 | Backlog | Member 4 |
| 11 | Configure Terraform for cloud infrastructure | `devops` | Formative 3 | Backlog | Member 2 |
| 12 | Add Kinyarwanda language option to USSD | `feature` | Formative 3 | Backlog | Member 3 |
| 13 | Add monitoring and health-check alerts | `devops` | Formative 3 | Backlog | Member 2 |

---

## C. Issue text (copy/paste)

### #1 Write project description in README
**As a** course assessor, **I want** a clear project description **so that** I can understand the problem and scope quickly.
- [x] Name, tagline, problem, users, 3-5 features, tech stack

### #2 Set up secure repo
**As a** developer, **I want** secrets and clutter excluded from git **so that** credentials are never leaked.
- [x] Comprehensive `.gitignore` (IDE, deps, env, build, logs)
- [x] `.env.example` with placeholders only

### #3 Price lookup endpoint
**As a** farmer, **I want** to see crop prices in each market **so that** I know where my crop is worth the most.
- [x] `GET /api/prices/<crop>` returns per-market prices; 404 for unknown crop

### #4 USSD 2-level menu
**As a** farmer with a feature phone, **I want** to check prices by dialling a code **so that** I don't need internet.
- [x] Main menu → crop menu → result
- [x] Handles invalid input

### #5 Unit tests for price logic and USSD
**As a** developer, **I want** automated tests **so that** changes don't break core features.
- [x] Tests for best/cheapest market, USSD flow, API
- [ ] Add coverage report

### #6 Set up CI pipeline
**As a** developer, **I want** tests to run on every push **so that** bugs are caught early.
- [x] Workflow runs `pytest`
- [ ] Add lint step (ruff/flake8)

### #7 Containerise the app
**As a** DevOps engineer, **I want** a Docker image **so that** the app runs the same everywhere.
- [ ] Verify image builds in CI; run container locally
- [ ] Add `docker-compose.yml` with the database

### #8 Store prices in PostgreSQL
**As a** developer, **I want** prices in a database **so that** they can be updated without redeploying.

### #9 Market agent price submission
**As a** market agent, **I want** to submit today's prices **so that** farmers see fresh data.
- [ ] `POST /api/prices` protected by API key from env var

### #10 Price-change SMS alerts
**As a** farmer, **I want** an SMS when my crop's price rises **so that** I can sell at the best time.

### #11 Terraform
**As a** DevOps engineer, **I want** infrastructure as code **so that** deployments are repeatable.

### #12 Kinyarwanda support
**As a** Kinyarwanda-speaking farmer, **I want** menus in my language **so that** I can use the service easily.

### #13 Monitoring
**As a** maintainer, **I want** alerts when `/health` fails **so that** downtime is noticed quickly.
=======
# SokoPrice: GitHub Projects Board, Backlog & User Stories

Board: **SokoPrice Board** (GitHub Projects, Board/Kanban view) with columns **Backlog → In Progress → Done**.

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
7. Take a screenshot of the finished board for your submission.

> Every issue must have: a user story, acceptance criteria, at least one label, an assignee and a milestone.

---

## B. Backlog overview (14 items)

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
| 9 | Store prices in PostgreSQL instead of JSON | `feature` | Formative 2 | Backlog | @jessewalu |
| 10 | Market agent price-submission endpoint with API-key auth | `feature` `security` | Formative 2 | Backlog | @Kkadi20 |
| 11 | Add lint step and coverage report to CI | `devops` `testing` | Formative 2 | Backlog | @Karabo-jpg |
| 12 | Price-change SMS alerts | `feature` | Formative 3 | Backlog | @Karabo-jpg |
| 13 | Configure Terraform for cloud infrastructure | `devops` | Formative 3 | Backlog | @jessewalu |
| 14 | Add Kinyarwanda language option to USSD | `feature` | Formative 3 | Backlog | @Kkadi20 |

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
- [x] All tests pass with `pytest -q`

### #6 Set up CI pipeline
**As a** developer, **I want** tests to run automatically on every push and pull request **so that** bugs are caught early.
**Acceptance criteria**
- [x] GitHub Actions workflow runs `pytest`
- [x] Docker image build runs after tests pass
- [x] Job names `test` and `docker-build` are available as required status checks

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
- [ ] Require a pull request before merging
- [ ] Require 1 approval and dismiss stale approvals
- [ ] Require status checks `test` and `docker-build`, and require branches to be up to date
- [ ] Require conversation resolution
- [ ] Include administrators
- [ ] `LICENSE` (MIT) added
- [ ] `.github/CODEOWNERS` added
- [ ] Issues and Projects enabled; instructor added as collaborator (or repo public)

### #9 Store prices in PostgreSQL
**As a** market agent, **I want** prices stored in a database **so that** they can be updated without redeploying the app.
**Acceptance criteria**
- [ ] Prices table created and seeded from `data/prices.json`
- [ ] API and USSD read prices from the database
- [ ] Connection string comes from an environment variable
- [ ] `docker-compose.yml` runs the app and database together
- [ ] Existing tests still pass

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
- [ ] Lint step (ruff or flake8) runs in CI
- [ ] Coverage report generated and shown in CI logs
- [ ] Pipeline fails on lint errors

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
>>>>>>> 4cf6e5b5af1dc8039d3ff53052c51f073dfad52a

---

## D. Submission checklist

<<<<<<< HEAD
- [ ] README has name, tagline, problem, users, 3-5 features, stack
- [ ] Run instructions in README tested on a clean machine
- [ ] Board has ≥ 8-10 items, user stories, DevOps + feature tasks
- [ ] Three columns: Backlog / In Progress / Done
- [ ] Every item has an assignee and a label
- [ ] Milestones aligned to formative deadlines
- [ ] `.gitignore` covers IDE, dependencies, env/secrets, build, logs
- [ ] No secrets in git history (`git log -p | grep -i key` to double check)
- [ ] Commits from **all** team members, with meaningful messages
=======
- [ ] README has name, tagline, problem, users, 3-5 features, stack, run instructions
- [ ] Board has 12+ items with user stories, acceptance criteria, labels, assignees and milestones
- [ ] Board has feature items **and** DevOps items (CI, Docker, Terraform)
- [ ] Columns are Backlog / In Progress / Done
- [ ] `.gitignore`, `LICENSE` and `CODEOWNERS` present
- [ ] Branch protection enabled on `main` (all 7 settings)
- [ ] Teammates have contributed via pull requests with reviews
- [ ] All team members added as collaborators
- [ ] Repo is public or instructor added as collaborator
- [ ] Team participation sheet completed by the team lead and submitted
>>>>>>> 4cf6e5b5af1dc8039d3ff53052c51f073dfad52a
