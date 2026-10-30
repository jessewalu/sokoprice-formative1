<<<<<<< HEAD
# SokoPrice
=======
# SokoPrice 🌽
>>>>>>> origin/main

> **Know the market price before you sell.**
> Crop price tracking for Rwandan smallholder farmers, accessible from any phone via USSD or a simple web API.

[![CI](https://github.com/jessewalu/sokoprice-formative1/actions/workflows/ci.yml/badge.svg)](https://github.com/jessewalu/sokoprice-formative1/actions/workflows/ci.yml)
[![Publish image](https://github.com/jessewalu/sokoprice-formative1/actions/workflows/publish.yml/badge.svg)](https://github.com/jessewalu/sokoprice-formative1/actions/workflows/publish.yml)
<<<<<<< HEAD

**Contents:** [Problem](#1-problem-statement) · [Users](#2-target-users) · [Features](#3-core-features) · [Stack](#4-technology-stack) · [Run locally](#5-how-to-run-the-app) · [Docker](#6-containerisation-with-docker) · [Docker Compose](#7-docker-compose) · [CI pipeline](#8-continuous-integration-github-actions) · [Branch protection](#9-branch-protection-and-collaboration-evidence) · [Structure](#10-project-structure) · [Security](#11-security-practices-shift-left) · [Project management](#12-project-management) · [Contributing](#13-contributing) · [Team](#14-team) · [License](#15-license)
=======
>>>>>>> origin/main

---

## 1. Problem Statement

Smallholder farmers in Rwanda and across East Africa often sell their harvest without knowing what the crop is worth in nearby markets. Price information is held by middlemen, so farmers frequently accept low prices and lose income. Most farmers use **feature phones without internet access**, so web-only or smartphone-only apps do not reach them.

**SokoPrice** closes this information gap by letting farmers (and buyers) check current market prices for common crops in major markets, and see which market offers the best price, using a USSD menu that works on any phone, plus a REST API that other apps can build on.

## 2. Target Users

| User | Need |
|------|------|
| **Smallholder farmers** | Decide where and when to sell, and avoid being underpaid by middlemen |
| **Small traders / buyers** | Find the cheapest market to buy from |
| **Cooperatives & extension officers** | Share reliable price data with members |
| **Developers / NGOs** | Integrate price data into other tools via the API |

## 3. Core Features

1. **Crop price lookup**: view the per-kg price of a crop in every tracked market.
2. **Best-market-to-sell finder**: shows the market paying the highest price for a crop.
3. **Cheapest-market-to-buy finder**: shows the lowest-priced market for buyers.
4. **USSD menu (2 levels)**: feature-phone friendly navigation (Africa's Talking compatible).
<<<<<<< HEAD
5. **REST API**: JSON endpoints for crops, prices, best markets and request statistics, plus a `/health` check used by Docker and CI.
6. **Optional PostgreSQL request log**: every USSD menu path is stored (no phone numbers, no personal data) so the team can see which crops farmers ask about most. The app works without the database.

*Planned (backlog):* prices stored in PostgreSQL, price submission by market agents, price-change SMS alerts, Kinyarwanda language support, Terraform cloud deployment.
=======
5. **REST API**: JSON endpoints for crops, prices, best markets, usage stats and a health check.
6. **Request log (PostgreSQL)**: every USSD menu path is stored (no phone numbers) so we can see which crops farmers ask about most.

*Planned (backlog):* price-change SMS alerts, price submission by market agents, Kinyarwanda language support, Terraform cloud deployment.
>>>>>>> origin/main

## 4. Technology Stack

| Layer | Technology |
|-------|-----------|
| Language | Python 3.12 (CI also tests 3.11) |
| Framework | Flask 3 |
| Production server | Gunicorn |
<<<<<<< HEAD
| Data | `data/prices.json` for prices; PostgreSQL 16 for the USSD request log |
| Testing | pytest + pytest-cov (80% coverage gate) |
| Linting | Ruff |
| Containerisation | Docker (multi-stage, non-root) and Docker Compose |
| CI/CD | GitHub Actions (lint, test, Docker build and smoke test; image publish to GHCR) |
=======
| Database | PostgreSQL 16 (optional request log) |
| Testing | pytest, pytest-cov |
| Linting | Ruff |
| Containerisation | Docker (multi-stage) and Docker Compose |
| CI/CD | GitHub Actions |
| Image registry | GitHub Container Registry (ghcr.io) |
>>>>>>> origin/main
| Cloud / IaC (planned) | Terraform on a cloud provider |
| USSD gateway (planned) | Africa's Talking |

---

## 5. Quick Start with Docker Compose (recommended)

This starts the app **and** its PostgreSQL database with a single command.

### Prerequisites
<<<<<<< HEAD
- Git
- **Docker Desktop / Docker Engine with the Compose plugin** (for Options B and C), or
- Python 3.11+ (3.12 recommended) (for Option A)

### Option A: Run locally (no Docker)
=======
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (includes Docker Compose) or Docker Engine with the Compose plugin
- Git

### Run it
>>>>>>> origin/main

```bash
# 1. Clone the repository
git clone https://github.com/jessewalu/sokoprice-formative1.git
cd sokoprice-formative1

# 2. (Optional) change settings such as passwords or the port
cp .env.example .env             # Windows PowerShell: copy .env.example .env

<<<<<<< HEAD
# 3. Install dependencies (add -dev for tests and linting)
pip install -r requirements-dev.txt

# 4. (Optional) set up environment variables
cp .env.example .env             # Windows: copy .env.example .env

# 5. Start the app
python run.py
```

The app runs at **http://localhost:5000**. With `DATABASE_URL` unset the database features are simply disabled.

### Option B: Run with Docker Compose (recommended)

One command starts the app **and** PostgreSQL:

```bash
cp .env.example .env             # optional: change passwords/ports (Windows: copy)
docker compose up --build
```

Open **http://localhost:5000/health**. Details are in [section 7](#7-docker-compose).

### Option C: Run only the container

```bash
docker build -t sokoprice .
docker run --rm -p 5000:5000 sokoprice
=======
# 3. Build and start everything
docker compose up --build
>>>>>>> origin/main
```

Wait until you see the `app` service start, then open **http://localhost:5000**.
Press `Ctrl+C` to stop. Useful commands:

```bash
docker compose up --build -d     # start in the background
docker compose ps                # show services and their health
docker compose logs -f app       # follow the app logs
docker compose down              # stop and remove containers (data is kept)
docker compose down -v           # stop AND delete the database volume (data is lost)
```

> The older `docker-compose` (with a hyphen) command works the same way.
> If port 5000 is already in use, run with another port: `APP_PORT=5001 docker compose up --build`
> (PowerShell: `$env:APP_PORT=5001; docker compose up --build`).

### What Compose starts

| Service | Image | Purpose | Reachable from |
|---------|-------|---------|----------------|
| `app` | built from `Dockerfile` | Flask + Gunicorn API and USSD service | your computer on port 5000 |
| `db` | `postgres:16-alpine` | stores the USSD request log | `app` only (private network) |

- **Networks:** `frontend` (app ↔ your computer) and `backend` (app ↔ database, marked `internal` so the database cannot be reached from outside).
- **Volume:** `pgdata` keeps the database files, so data survives restarts and rebuilds.
- **Health checks and start order:** the app only starts after PostgreSQL reports healthy, and both services restart automatically unless stopped.
- **Configuration:** all settings come from environment variables (`.env`), nothing secret is hard-coded in the image.

### Try it out

```bash
curl http://localhost:5000/health
curl http://localhost:5000/api/crops
curl http://localhost:5000/api/prices/maize
curl http://localhost:5000/api/best-market/beans
<<<<<<< HEAD
curl http://localhost:5000/api/stats
```

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/` | Service name and endpoint list |
| GET | `/health` | Liveness check (`{"status": "ok"}`) |
| GET | `/api/crops` | Tracked crops and markets |
| GET | `/api/prices/<crop>` | Per-market prices (404 for unknown crop) |
| GET | `/api/best-market/<crop>` | Best market to sell and cheapest to buy |
| GET | `/api/stats` | Request-log status and USSD request count |
| POST | `/ussd` | USSD gateway endpoint (form field `text`) |

Example response for `/api/prices/maize`:
```json
{
  "crop": "maize",
  "currency": "RWF",
  "unit": "kg",
  "updated": "2026-10-20",
  "prices": {"Kimironko": 450, "Nyabugogo": 420, "Musanze": 400}
}
```

**USSD simulation** (mimics what the USSD gateway sends)
```bash
# Dial: main menu
=======

# USSD simulation: main menu, then "Check price" > crop 3 (Maize)
>>>>>>> origin/main
curl -X POST http://localhost:5000/ussd -d "text="
curl -X POST http://localhost:5000/ussd -d "text=1*3"

# The request above was saved in PostgreSQL:
curl http://localhost:5000/api/stats
```

Example `/api/stats` response: `{"database": "connected", "ussd_requests": 1}`

> On Windows PowerShell use `curl.exe` instead of `curl`.

**USSD menu flow**
```
Welcome to SokoPrice
1. Check crop price      -> [select crop] -> prices per market
2. Best market to sell   -> [select crop] -> best market + price
3. Cheapest market to buy-> [select crop] -> cheapest market + price
0. Exit
```

<<<<<<< HEAD
### Run the tests and the linter

```bash
pip install -r requirements-dev.txt
ruff check .                                   # lint (must report no errors)
pytest -q --cov=app --cov-fail-under=80        # tests + coverage gate
```

The PostgreSQL integration test is skipped unless `TEST_DATABASE_URL` is set (CI sets it automatically). To run it locally against the Compose database, start `docker compose up -d db`, temporarily publish its port, and export the URL.

---

## 6. Containerisation with Docker

The [`Dockerfile`](Dockerfile) is a **multi-stage build**:

| Stage | Purpose |
|-------|---------|
| `builder` | Creates a virtual environment and installs `requirements.txt` (layer-cached: only re-runs when requirements change) |
| `runtime` | Copies only the virtual environment and app code into a clean `python:3.12-slim-bookworm` image |

Best practices applied (each instruction is commented in the file):

- **Pinned base image** (`python:3.12-slim-bookworm`), never `latest`.
- **Non-root user**: a system user `appuser` (UID/GID 10001) with no shell and no home directory; the container runs as that user.
- **Layer caching**: `requirements.txt` is copied and installed before the application code.
- **Small image and context**: slim base, no build tools in the final image, and a [`.dockerignore`](.dockerignore) that keeps `.git`, `.env`, tests, docs and caches out of the build.
- **Health check**: `HEALTHCHECK` runs `scripts/healthcheck.py`, which calls `/health` using only the standard library (slim images have no `curl`).
- **Production server**: Gunicorn (2 workers) runs as PID 1 via `exec`, so it receives `SIGTERM` for clean shutdowns.
- **Configuration through environment variables** (`PORT`, `DATABASE_URL`, `FLASK_DEBUG`); no secrets are baked into the image.
- **OCI labels** with title, description, source and license.

Useful commands:

```bash
docker build -t sokoprice .                 # build
docker run --rm -p 5000:5000 sokoprice      # run
docker ps                                   # STATUS shows "(healthy)" after a few seconds
docker exec <container> id                  # prints uid=10001(appuser): proves non-root
```

## 7. Docker Compose

[`docker-compose.yml`](docker-compose.yml) runs the whole stack with a single command.

```bash
docker compose up --build        # build and start app + database
docker compose up -d --wait      # start in the background and wait until healthy
docker compose logs -f app       # follow application logs
docker compose down              # stop, KEEP database data
docker compose down -v           # stop and DELETE database data (named volume)
```

| Service | Image | Role |
|---------|-------|------|
| `app` | built from `./Dockerfile` (`runtime` stage) | Flask API + USSD service on gunicorn, published on `localhost:${APP_PORT:-5000}` |
| `db` | `postgres:16-alpine` | Stores the USSD request log; **no published port** |

How the requirements are met:

- **Networking**: two networks. `frontend` connects the app to the host (published port). `backend` is `internal: true` and connects only `app` and `db`, so the database is unreachable from outside. The app reaches Postgres at the hostname `db`.
- **Persistence**: the named volume `pgdata` stores `/var/lib/postgresql/data`, so data survives `docker compose down` and rebuilds.
- **Environment variables**: every value has a safe development default and can be overridden through a `.env` file (copy [`.env.example`](.env.example)). `.env` is git-ignored.
- **Start-up order**: `app` waits for `db` to be healthy (`depends_on: condition: service_healthy`).
- **Health checks and restarts**: both services have health checks and `restart: unless-stopped`.
- **Hardening**: `init: true`, `read_only: true` root filesystem with a `tmpfs` for `/tmp`, `cap_drop: ALL`, `no-new-privileges`, and log rotation.

| Variable | Default | Meaning |
|----------|---------|---------|
| `APP_PORT` | `5000` | Host port the app is published on |
| `FLASK_DEBUG` | `0` | Flask debug mode (keep off) |
| `POSTGRES_DB` | `sokoprice` | Database name |
| `POSTGRES_USER` | `sokoprice` | Database user |
| `POSTGRES_PASSWORD` | `sokoprice_dev_password` | Database password (**change for anything shared**) |

Verify the stack end to end:

```bash
docker compose up -d --build --wait
curl http://localhost:5000/health
curl -X POST http://localhost:5000/ussd -d "text=1*3"
curl http://localhost:5000/api/stats       # {"database":"connected","ussd_requests":1}
docker compose down -v
```

**Troubleshooting**

| Problem | Fix |
|---------|-----|
| `port is already allocated` | Set `APP_PORT=5001` in `.env` |
| `/api/stats` shows `unavailable` | Database still starting or wrong password; run `docker compose logs db` |
| Changed `POSTGRES_PASSWORD` but login fails | The old volume keeps the old password; run `docker compose down -v` |

---

## 8. Continuous Integration (GitHub Actions)

Workflow: [`.github/workflows/ci.yml`](.github/workflows/ci.yml)

**Triggers**

- `push` to **any branch except `main`**
- `pull_request` **targeting `main`**

Superseded runs on the same ref are cancelled (`concurrency`), and the workflow has read-only `contents` permission (least privilege).

**Jobs**

```
 lint ──┐
        ├──> docker-build
 test ──┘   (needs lint and test)
 (py3.11, py3.12)
```

| Job | What it does | Fails when |
|-----|--------------|------------|
| `lint` | Checkout, set up Python 3.12 (pip cache), install dependencies, `ruff check .` | Ruff reports any error |
| `test (py3.11)` / `test (py3.12)` | Matrix over two Python versions with a real PostgreSQL 16 service container; runs `pytest --cov=app --cov-fail-under=80`; uploads `test-results.xml` and `coverage.xml` as artifacts | A test fails, coverage is under 80%, or a dependency cannot be installed |
| `docker-build` | Builds the image with Buildx and GitHub Actions layer cache, smoke-tests the container (waits for `healthy`, calls `/health`, `/api/prices/maize`, `/ussd`), then validates and runs the full Compose stack and checks `/api/stats` reports `connected` | The image fails to build, the container is not healthy, any request fails, or Compose cannot start |

`docker-build` only starts after `lint` and `test` pass, and any failing step fails the whole pipeline.

**Publishing:** [`.github/workflows/publish.yml`](.github/workflows/publish.yml) runs on every push to `main` (i.e. after a PR is merged). It builds the image and pushes it to GitHub Container Registry as `ghcr.io/jessewalu/sokoprice-formative1:latest` and `:sha-<short>`, authenticating with the automatic `GITHUB_TOKEN` (no stored credentials).

**Reproduce CI locally**

```bash
ruff check .
pytest -q --cov=app --cov-fail-under=80
docker build --target runtime -t sokoprice-app:local .
docker compose up -d --wait && curl --fail http://localhost:5000/health && docker compose down -v
```

## 9. Branch Protection and Collaboration Evidence

### Branch protection on `main`

Settings → Branches → rule for `main`:

| Rule | Why it matters |
|------|----------------|
| Require a pull request before merging | No one pushes directly to `main`; every change is visible and discussed |
| Require 1 approval (Code owners review) | A second pair of eyes catches bugs; [`CODEOWNERS`](.github/CODEOWNERS) assigns reviewers |
| Dismiss stale approvals on new commits | An approval only counts for the code that was actually reviewed |
| **Require status checks to pass:** `lint`, `test (py3.11)`, `test (py3.12)`, `docker-build` | Broken, unlinted or un-buildable code cannot be merged |
| Require branches to be up to date | Changes are tested against the latest `main` |
| Require conversation resolution | Review comments cannot be ignored |
| Include administrators | The rules apply to everyone, with no exceptions |

> The status check names must match the job names above exactly. Because `test` uses a matrix, GitHub lists it as `test (py3.11)` and `test (py3.12)`.

### CI evidence

Links to real runs and pull requests (fill in the URLs from the Actions and Pull requests tabs):

| Evidence | Requirement | Link |
|----------|-------------|------|
| Successful run #1 | ≥ 3 successful runs | _add link_ |
| Successful run #2 | | _add link_ |
| Successful run #3 | | _add link_ |
| Failed run (lint or test) | ≥ 1 failed run | _add link_ |
| Fix that turned it green | failed run then fixed | _add link_ |
| Pull request with CI checks and review | ≥ 1 PR with review | _add link_ |
| Branch protection screenshot | Required checks enabled | `docs/screenshots/branch-protection.png` |

### Team collaboration

- Work is done on branches and merged through pull requests reviewed by a different teammate.
- Contribution tracking sheet: https://docs.google.com/spreadsheets/d/1k8UOI845SVSR8oId_86h8xpJYibwzxaeQ3t5jsGJFbw/edit?usp=sharing
- Planning and status live on the GitHub Projects board (see section 12).

---

## 10. Project Structure
=======
---

## 6. Run Without Docker (local development)

```bash
git clone https://github.com/jessewalu/sokoprice-formative1.git
cd sokoprice-formative1

python -m venv .venv
source .venv/bin/activate        # Windows: .venv\Scripts\activate

pip install -r requirements-dev.txt   # app + test + lint tools
python run.py                         # http://localhost:5000
```

The database is optional here. To record USSD requests, set `DATABASE_URL`
(see `.env.example`); without it the app simply skips logging.

### Run the checks locally (same as CI)

```bash
ruff check .                                   # lint
pytest --cov=app --cov-fail-under=80           # tests + coverage
docker build -t sokoprice .                    # build the image
```

The PostgreSQL integration test runs only when `TEST_DATABASE_URL` is set; otherwise it is skipped.

---

## 7. Docker Image

The `Dockerfile` is a **multi-stage build**:

1. **builder** installs the Python dependencies into a virtual environment.
2. **runtime** copies only that environment and the app code, so the final image has no build tools and stays small.

Security and quality features: pinned base image (`python:3.12-slim-bookworm`), runs as a **non-root user (UID 10001)**, dependency layer cached separately from code, `HEALTHCHECK` on `/health`, production server (Gunicorn), and a `.dockerignore` that keeps secrets, tests and Git history out of the image. In Compose the app container additionally runs with a read-only filesystem, all Linux capabilities dropped and `no-new-privileges`.

After every merge to `main`, the image is published to `ghcr.io/jessewalu/sokoprice-formative1` (tags `latest` and the commit SHA).

---

## 8. Continuous Integration (GitHub Actions)

`.github/workflows/ci.yml` runs on **every push to any branch except `main`** and on **every pull request targeting `main`**.

| Job (status check) | What it does | Fails the pipeline when |
|--------------------|--------------|-------------------------|
| `lint` | Installs dependencies, runs `ruff check` | any lint error is found |
| `test (py3.11)`, `test (py3.12)` | Runs pytest with coverage against a real PostgreSQL service, uploads test and coverage reports as artifacts | any test fails or coverage is below 80% |
| `docker-build` | Builds the image (with layer cache), starts it and checks it becomes healthy, then runs the whole Compose stack and verifies the app talks to PostgreSQL | the build fails, the container is unhealthy, or any smoke test fails |

`docker-build` only starts after `lint` and `test` pass. A newer push to the same branch cancels the older run. A second workflow, `publish.yml`, pushes the image to GHCR on merges to `main` using the built-in `GITHUB_TOKEN` secret (no passwords stored in the repo).

CI evidence (runs, failed-then-fixed run, pull requests) is listed in [`docs/F2_EVIDENCE_GUIDE.md`](docs/F2_EVIDENCE_GUIDE.md).

---

## 9. Project Structure

The code separates concerns so each part can later become its own service
(pricing data, USSD gateway, API, request log).
>>>>>>> origin/main

```
sokoprice-formative1/
├── app/
│   ├── __init__.py          # Flask app factory + REST endpoints
│   ├── prices.py            # Price logic (best/cheapest market), no web code
│   ├── ussd.py              # USSD menu state machine, no web code
<<<<<<< HEAD
│   └── db.py                # Optional PostgreSQL USSD request log
├── data/prices.json         # Sample price dataset
├── scripts/healthcheck.py   # Container health probe (stdlib only)
=======
│   └── db.py                # Optional PostgreSQL request log
├── data/prices.json         # Sample price dataset
├── scripts/healthcheck.py   # Container health probe
>>>>>>> origin/main
├── tests/
│   ├── test_app.py          # REST API + USSD endpoint tests
│   ├── test_db.py           # Request-log tests (Postgres test runs in CI)
│   ├── test_prices.py       # Price logic unit tests
<<<<<<< HEAD
│   └── test_ussd.py         # USSD menu unit tests
├── docs/PROJECT_BOARD.md    # GitHub Projects backlog, user stories, status
├── .github/
│   ├── workflows/ci.yml       # CI: lint, test (matrix), Docker build + smoke test
│   ├── workflows/publish.yml  # Push image to GHCR after merge to main
│   └── CODEOWNERS             # Required reviewers
├── Dockerfile               # Multi-stage, non-root, health check, gunicorn
├── docker-compose.yml       # App + PostgreSQL, networks, volume, health checks
├── .dockerignore            # Keeps the build context small and secret-free
├── requirements.txt         # Runtime dependencies (installed in the image)
├── requirements-dev.txt     # + pytest, pytest-cov, ruff
├── ruff.toml                # Lint rules
=======
│   ├── test_ussd.py         # USSD menu unit tests
│   └── test_db.py           # Request log unit + PostgreSQL integration tests
├── docs/
│   ├── PROJECT_BOARD.md     # Backlog, user stories, board setup
│   └── F2_EVIDENCE_GUIDE.md # CI evidence, board items, branch protection
├── .github/
│   ├── workflows/ci.yml     # CI: lint, test, Docker build
│   ├── workflows/publish.yml# Publish image to GHCR on merge to main
│   ├── pull_request_template.md
│   └── CODEOWNERS           # Required reviewers
├── Dockerfile               # Multi-stage, non-root, health check
├── docker-compose.yml       # app + PostgreSQL, networks, volume
├── .dockerignore
├── requirements.txt         # Runtime dependencies (go into the image)
├── requirements-dev.txt     # + pytest, pytest-cov, ruff
├── ruff.toml                # Linter configuration
>>>>>>> origin/main
├── pytest.ini
├── .env.example             # Template for settings (real .env is git-ignored)
├── .gitignore
├── LICENSE                  # MIT
└── run.py                   # Entry point
```

<<<<<<< HEAD
## 11. Security Practices ("shift left")

- Comprehensive `.gitignore` excluding secrets (`.env`, keys, credentials), IDE files, dependencies and build artifacts/logs.
- Configuration is read from **environment variables**; only `.env.example` (placeholders) is committed.
- Docker image runs as a **non-root user** (UID 10001); Compose adds a read-only filesystem, dropped capabilities and `no-new-privileges`.
- The database is on an **internal network** with no published port.
- Debug mode is **off by default**.
- The USSD log stores only the menu path, **never phone numbers**.
- CI uses least-privilege `permissions`, and image publishing uses the short-lived `GITHUB_TOKEN`.
- `main` is protected by branch protection rules (section 9).
=======
## 10. Security Practices ("shift left")

- Comprehensive `.gitignore` excluding secrets (`.env`, keys, credentials), IDE files, dependencies and build artifacts/logs.
- Configuration is read from **environment variables**; only `.env.example` (placeholders) is committed.
- Docker image runs as a **non-root user**; Compose adds a read-only filesystem, dropped capabilities and `no-new-privileges`.
- The database has **no published port** and sits on an internal network.
- The request log stores **no phone numbers or personal data**.
- CI workflow permissions are limited to `contents: read`; publishing uses the short-lived `GITHUB_TOKEN`.
- Debug mode is **off by default**.
>>>>>>> origin/main

## 12. Project Management

<<<<<<< HEAD
Work is tracked on our GitHub Projects Kanban board (Backlog / In Progress / Done) with user stories, acceptance criteria, labels, assignees and milestones. The full backlog, current status and acceptance criteria are documented in [`docs/PROJECT_BOARD.md`](docs/PROJECT_BOARD.md).

## 13. Contributing

1. Create a branch from `main` (`feature/<name>` or `fix/<name>`). CI runs on every push.
2. Commit with clear messages (`feat:`, `fix:`, `docs:`, `build:`, `test:`).
3. Run `ruff check .` and `pytest -q` locally before pushing.
4. Open a pull request into `main`, linked to its issue (e.g. `Closes #5`).
5. Wait for green checks (`lint`, `test`, `docker-build`) and one teammate's approval, resolve all review conversations, then merge.

=======
| Rule | Why it matters |
|------|----------------|
| Require a pull request before merging | No one pushes directly to `main`; every change is visible and discussed |
| Require 1 approval | A second pair of eyes catches bugs and spreads knowledge |
| Dismiss stale approvals on new commits | An approval only counts for the code that was actually reviewed |
| Require status checks: `lint`, `test (py3.11)`, `test (py3.12)`, `docker-build` | Code that fails linting, tests or the Docker build cannot be merged |
| Require branches to be up to date | Changes are tested against the latest `main`, avoiding merge surprises |
| Require conversation resolution | Review comments cannot be ignored |
| Include administrators | The rules apply to everyone, with no exceptions |

## 11. Project Management

Work is tracked on our GitHub Projects Kanban board (Backlog / In Progress / Done) with user stories, acceptance criteria, labels, assignees and milestones. The backlog is documented in [`docs/PROJECT_BOARD.md`](docs/PROJECT_BOARD.md).

Team contribution tracker: [Google Sheet](https://docs.google.com/spreadsheets/d/1k8UOI845SVSR8oId_86h8xpJYibwzxaeQ3t5jsGJFbw/edit?usp=sharing)

## 12. Contributing

1. Create a branch from `main` (`feature/<name>`, `fix/<name>` or `docs/<name>`).
2. Commit with clear messages (`feat:`, `fix:`, `docs:`, `build:`, `test:`, `ci:`).
3. Open a pull request using the template and link its issue (e.g. `Closes #13`).
4. Wait for all CI checks to pass and for one teammate's approval, then merge.

## 13. Troubleshooting

| Problem | Fix |
|---------|-----|
| `port is already allocated` | Another program uses port 5000. Start with `APP_PORT=5001 docker compose up --build` |
| `/api/stats` shows `"database": "unavailable"` | The database is still starting or the password in `.env` changed after the volume was created. Run `docker compose down -v` and start again |
| Changed `.env` but nothing happens | Run `docker compose up --build` again so containers are recreated |
| `docker: command not found` / daemon not running | Start Docker Desktop and wait until it says it is running |

>>>>>>> origin/main
## 14. Team

| Name | GitHub | Role |
|------|--------|------|
| Jesse Kisaale Walusansa | [@jessewalu](https://github.com/jessewalu) | Backend & CI/CD Lead (Team Lead) |
| Karabo Innocent Pamela Ojiambo | [@Karabo-jpg](https://github.com/Karabo-jpg) | Testing, Docker & Documentation Lead |
| Kadi Matou Koita | [@Kkadi20](https://github.com/Kkadi20) | Repository Security & Project Management Lead |

<<<<<<< HEAD
Team contribution sheet: https://docs.google.com/spreadsheets/d/1k8UOI845SVSR8oId_86h8xpJYibwzxaeQ3t5jsGJFbw/edit?usp=sharing

=======
>>>>>>> origin/main
## 15. License

Released under the [MIT License](LICENSE).
