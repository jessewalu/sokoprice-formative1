# SokoPrice 🌽

> **Know the market price before you sell.**
> Crop price tracking for Rwandan smallholder farmers, accessible from any phone via USSD or a simple web API.

[![CI](https://github.com/jessewalu/sokoprice-formative1/actions/workflows/ci.yml/badge.svg)](https://github.com/jessewalu/sokoprice-formative1/actions/workflows/ci.yml)
[![Publish image](https://github.com/jessewalu/sokoprice-formative1/actions/workflows/publish.yml/badge.svg)](https://github.com/jessewalu/sokoprice-formative1/actions/workflows/publish.yml)

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
5. **REST API**: JSON endpoints for crops, prices, best markets, usage stats and a health check.
6. **Request log (PostgreSQL)**: every USSD menu path is stored (no phone numbers) so we can see which crops farmers ask about most.

*Planned (backlog):* price-change SMS alerts, price submission by market agents, Kinyarwanda language support, Terraform cloud deployment.

## 4. Technology Stack

| Layer | Technology |
|-------|-----------|
| Language | Python 3.12 (CI also tests 3.11) |
| Framework | Flask 3 |
| Production server | Gunicorn |
| Database | PostgreSQL 16 (optional request log) |
| Testing | pytest, pytest-cov |
| Linting | Ruff |
| Containerisation | Docker (multi-stage) and Docker Compose |
| CI/CD | GitHub Actions |
| Image registry | GitHub Container Registry (ghcr.io) |
| Cloud / IaC (planned) | Terraform on a cloud provider |
| USSD gateway (planned) | Africa's Talking |

---

## 5. Quick Start with Docker Compose (recommended)

This starts the app **and** its PostgreSQL database with a single command.

### Prerequisites
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (includes Docker Compose) or Docker Engine with the Compose plugin
- Git

### Run it

```bash
# 1. Clone the repository
git clone https://github.com/jessewalu/sokoprice-formative1.git
cd sokoprice-formative1

# 2. (Optional) change settings such as passwords or the port
cp .env.example .env             # Windows PowerShell: copy .env.example .env

# 3. Build and start everything
docker compose up --build
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

# USSD simulation: main menu, then "Check price" > crop 3 (Maize)
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

```
sokoprice-formative1/
├── app/
│   ├── __init__.py          # Flask app factory + REST endpoints
│   ├── prices.py            # Price logic (best/cheapest market), no web code
│   ├── ussd.py              # USSD menu state machine, no web code
│   └── db.py                # Optional PostgreSQL request log
├── data/prices.json         # Sample price dataset
├── scripts/healthcheck.py   # Container health probe
├── tests/
│   ├── test_app.py          # REST API + USSD endpoint tests
│   ├── test_prices.py       # Price logic unit tests
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
├── pytest.ini
├── .env.example             # Template for settings (real .env is git-ignored)
├── .gitignore
├── LICENSE                  # MIT
└── run.py                   # Entry point
```

## 10. Security Practices ("shift left")

- Comprehensive `.gitignore` excluding secrets (`.env`, keys, credentials), IDE files, dependencies and build artifacts/logs.
- Configuration is read from **environment variables**; only `.env.example` (placeholders) is committed.
- Docker image runs as a **non-root user**; Compose adds a read-only filesystem, dropped capabilities and `no-new-privileges`.
- The database has **no published port** and sits on an internal network.
- The request log stores **no phone numbers or personal data**.
- CI workflow permissions are limited to `contents: read`; publishing uses the short-lived `GITHUB_TOKEN`.
- Debug mode is **off by default**.

### Branch Protection on `main`

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

## 14. Team

| Name | GitHub | Role |
|------|--------|------|
| Jesse Kisaale Walusansa | [@jessewalu](https://github.com/jessewalu) | Backend & CI/CD Lead (Team Lead) |
| Karabo Innocent Pamela Ojiambo | [@Karabo-jpg](https://github.com/Karabo-jpg) | Testing, Docker & Documentation Lead |
| Kadi Matou Koita | [@Kkadi20](https://github.com/Kkadi20) | Repository Security & Project Management Lead |

## 15. License

Released under the [MIT License](LICENSE).
