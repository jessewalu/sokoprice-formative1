# SokoPrice

> **Know the market price before you sell.**
> Crop price tracking for Rwandan smallholder farmers, accessible from any phone via USSD or a simple web API.

[![CI](https://github.com/jessewalu/sokoprice-formative1/actions/workflows/ci.yml/badge.svg)](https://github.com/jessewalu/sokoprice-formative1/actions/workflows/ci.yml)
[![Publish image](https://github.com/jessewalu/sokoprice-formative1/actions/workflows/publish.yml/badge.svg)](https://github.com/jessewalu/sokoprice-formative1/actions/workflows/publish.yml)

**Contents:** [Problem](#1-problem-statement) · [Users](#2-target-users) · [Features](#3-core-features) · [Stack](#4-technology-stack) · [Run locally](#5-how-to-run-the-app) · [Docker](#6-containerisation-with-docker) · [Docker Compose](#7-docker-compose) · [CI pipeline](#8-continuous-integration-github-actions) · [Branch protection](#9-branch-protection-and-collaboration-evidence) · [Structure](#10-project-structure) · [Security](#11-security-practices-shift-left) · [Project management](#12-project-management) · [Contributing](#13-contributing) · [Team](#14-team) · [License](#15-license)

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
5. **REST API**: JSON endpoints for crops, prices, best markets and request statistics, plus a `/health` check used by Docker and CI.
6. **Optional PostgreSQL request log**: every USSD menu path is stored (no phone numbers, no personal data) so the team can see which crops farmers ask about most. The app works without the database.

*Planned (backlog):* prices stored in PostgreSQL, price submission by market agents, price-change SMS alerts, Kinyarwanda language support, Terraform cloud deployment.

## 4. Technology Stack

| Layer | Technology |
|-------|-----------|
| Language | Python 3.12 (CI also tests 3.11) |
| Framework | Flask 3 |
| Production server | Gunicorn |
| Data | `data/prices.json` for prices; PostgreSQL 16 for the USSD request log |
| Testing | pytest + pytest-cov (80% coverage gate) |
| Linting | Ruff |
| Containerisation | Docker (multi-stage, non-root) and Docker Compose |
| CI/CD | GitHub Actions (lint, test, Docker build and smoke test; image publish to GHCR) |
| Cloud / IaC (planned) | Terraform on a cloud provider |
| USSD gateway (planned) | Africa's Talking |

---

## 5. How to Run the App

### Prerequisites
- Git
- **Docker Desktop / Docker Engine with the Compose plugin** (for Options B and C), or
- Python 3.11+ (3.12 recommended) (for Option A)

### Option A: Run locally (no Docker)

```bash
# 1. Clone the repository
git clone https://github.com/jessewalu/sokoprice-formative1.git
cd sokoprice-formative1

# 2. Create and activate a virtual environment
python -m venv .venv
source .venv/bin/activate        # Windows: .venv\Scripts\activate

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
```

### Try it out

**REST API**
```bash
curl http://localhost:5000/health
curl http://localhost:5000/api/crops
curl http://localhost:5000/api/prices/maize
curl http://localhost:5000/api/best-market/beans
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
curl -X POST http://localhost:5000/ussd -d "text="

# Option 1 (check price) -> list of crops
curl -X POST http://localhost:5000/ussd -d "text=1"

# Option 1 -> crop 3 (Maize) -> prices in all markets
curl -X POST http://localhost:5000/ussd -d "text=1*3"

# Option 2 (best market to sell) -> crop 1 (Beans)
curl -X POST http://localhost:5000/ussd -d "text=2*1"
```

> On Windows PowerShell use `curl.exe` instead of `curl`.

**USSD menu flow**
```
Welcome to SokoPrice
1. Check crop price      -> [select crop] -> prices per market
2. Best market to sell   -> [select crop] -> best market + price
3. Cheapest market to buy-> [select crop] -> cheapest market + price
0. Exit
```

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
| Successful run #1 | ≥ 3 successful runs | https://github.com/jessewalu/sokoprice-formative1/actions/runs/41121356911 |
| Successful run #2 | | https://github.com/jessewalu/sokoprice-formative1/actions/runs/41044648209 |
| Successful run #3 | | https://github.com/jessewalu/sokoprice-formative1/actions/runs/41121607373 |
| Failed run (lint or test) | ≥ 1 failed run | https://github.com/jessewalu/sokoprice-formative1/actions/runs/41034821146 |
| Fix that turned it green | failed run then fixed | https://github.com/jessewalu/sokoprice-formative1/actions/runs/41121356911 |
| Pull request with CI checks and review | ≥ 1 PR with review | https://github.com/jessewalu/sokoprice-formative1/pull/16 |
| Branch protection screenshot | Required checks enabled | `docs/screenshots/branch-protection.png` |

### Team collaboration

- Work is done on branches and merged through pull requests reviewed by a different teammate.
- Contribution tracking sheet: https://docs.google.com/spreadsheets/d/1k8UOI845SVSR8oId_86h8xpJYibwzxaeQ3t5jsGJFbw/edit?usp=sharing
- Planning and status live on the GitHub Projects board (see section 12).

---

## 10. Project Structure

```
sokoprice-formative1/
├── app/
│   ├── __init__.py          # Flask app factory + REST endpoints
│   ├── prices.py            # Price logic (best/cheapest market), no web code
│   ├── ussd.py              # USSD menu state machine, no web code
│   └── db.py                # Optional PostgreSQL USSD request log
├── data/prices.json         # Sample price dataset
├── scripts/healthcheck.py   # Container health probe (stdlib only)
├── tests/
│   ├── test_app.py          # REST API + USSD endpoint tests
│   ├── test_db.py           # Request-log tests (Postgres test runs in CI)
│   ├── test_prices.py       # Price logic unit tests
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
├── pytest.ini
├── .env.example             # Template for secrets (real .env is git-ignored)
├── .gitignore
├── LICENSE                  # MIT
└── run.py                   # Entry point
```

## 11. Security Practices ("shift left")

- Comprehensive `.gitignore` excluding secrets (`.env`, keys, credentials), IDE files, dependencies and build artifacts/logs.
- Configuration is read from **environment variables**; only `.env.example` (placeholders) is committed.
- Docker image runs as a **non-root user** (UID 10001); Compose adds a read-only filesystem, dropped capabilities and `no-new-privileges`.
- The database is on an **internal network** with no published port.
- Debug mode is **off by default**.
- The USSD log stores only the menu path, **never phone numbers**.
- CI uses least-privilege `permissions`, and image publishing uses the short-lived `GITHUB_TOKEN`.
- `main` is protected by branch protection rules (section 9).

## 12. Project Management

Work is tracked on our GitHub Projects Kanban board (Backlog / In Progress / Done) with user stories, acceptance criteria, labels, assignees and milestones. The full backlog, current status and acceptance criteria are documented in [`docs/PROJECT_BOARD.md`](docs/PROJECT_BOARD.md).

## 13. Contributing

1. Create a branch from `main` (`feature/<name>` or `fix/<name>`). CI runs on every push.
2. Commit with clear messages (`feat:`, `fix:`, `docs:`, `build:`, `test:`).
3. Run `ruff check .` and `pytest -q` locally before pushing.
4. Open a pull request into `main`, linked to its issue (e.g. `Closes #5`).
5. Wait for green checks (`lint`, `test`, `docker-build`) and one teammate's approval, resolve all review conversations, then merge.

## 14. Team

| Name | GitHub | Role |
|------|--------|------|
| Jesse Walusansa | [@jessewalu](https://github.com/jessewalu) | Backend & DevOps (CI/CD) |
| Karabo Ojiambo | [@Karabo-jpg](https://github.com/Karabo-jpg) | Testing, Docker & Documentation |
| K. Koita | [@Kkadi20](https://github.com/Kkadi20) | Repository security & Project management |

Team contribution sheet: https://docs.google.com/spreadsheets/d/1k8UOI845SVSR8oId_86h8xpJYibwzxaeQ3t5jsGJFbw/edit?usp=sharing

## 15. License

Released under the [MIT License](LICENSE).
