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

---

## D. Submission checklist

- [ ] README has name, tagline, problem, users, 3-5 features, stack
- [ ] Run instructions in README tested on a clean machine
- [ ] Board has ≥ 8-10 items, user stories, DevOps + feature tasks
- [ ] Three columns: Backlog / In Progress / Done
- [ ] Every item has an assignee and a label
- [ ] Milestones aligned to formative deadlines
- [ ] `.gitignore` covers IDE, dependencies, env/secrets, build, logs
- [ ] No secrets in git history (`git log -p | grep -i key` to double check)
- [ ] Commits from **all** team members, with meaningful messages
