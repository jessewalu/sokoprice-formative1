# SokoPrice 🌽

> **Know the market price before you sell.**
> Crop price tracking for Rwandan smallholder farmers, accessible from any phone via USSD or a simple web API.

[![CI](https://github.com/jessewalu/sokoprice-formative1/actions/workflows/ci.yml/badge.svg)](https://github.com/jessewalu/sokoprice-formative1/actions/workflows/ci.yml)

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
5. **REST API**: JSON endpoints for crops, prices and best markets, plus a health check for deployment.

*Planned (backlog):* price-change SMS alerts, price submission by market agents, Kinyarwanda language support, database storage.

## 4. Technology Stack

| Layer | Technology |
|-------|-----------|
| Language | Python 3.12 |
| Framework | Flask 3 |
| Production server | Gunicorn |
| Data (current) | JSON file → PostgreSQL planned |
| Testing | pytest |
| Containerisation | Docker |
| CI/CD | GitHub Actions |
| Cloud / IaC (planned) | Terraform on a cloud provider |
| USSD gateway (planned) | Africa's Talking |

---

## 5. How to Run the App

### Prerequisites
- Python 3.10+ (3.12 recommended)
- Git
- (Optional) Docker

### Option A: Run locally

```bash
# 1. Clone the repository
git clone https://github.com/jessewalu/sokoprice-formative1.git
cd sokoprice-formative1

# 2. Create and activate a virtual environment
python -m venv .venv
source .venv/bin/activate        # Windows: .venv\Scripts\activate

# 3. Install dependencies
pip install -r requirements.txt

# 4. (Optional) set up environment variables
cp .env.example .env             # Windows: copy .env.example .env

# 5. Start the app
python run.py
```

The app runs at **http://localhost:5000**.

### Option B: Run with Docker

```bash
docker build -t sokoprice .
docker run -p 5000:5000 sokoprice
```

### Try it out

**REST API**
```bash
curl http://localhost:5000/health
curl http://localhost:5000/api/crops
curl http://localhost:5000/api/prices/maize
curl http://localhost:5000/api/best-market/beans
```

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

### Run the tests

```bash
pytest -q
```

---

## 6. Project Structure

The code separates concerns so each part can later become its own service
(pricing data, USSD gateway, API).

```
sokoprice-formative1/
├── app/
│   ├── __init__.py          # Flask app factory + REST endpoints
│   ├── prices.py            # Price logic (best/cheapest market), no web code
│   └── ussd.py              # USSD menu state machine, no web code
├── data/prices.json         # Sample price dataset
├── tests/
│   ├── test_app.py          # REST API + USSD endpoint tests
│   ├── test_prices.py       # Price logic unit tests
│   └── test_ussd.py         # USSD menu unit tests
├── docs/PROJECT_BOARD.md    # GitHub Projects backlog, user stories, setup guide
├── .github/
│   ├── workflows/ci.yml     # CI: run tests, then build Docker image
│   └── CODEOWNERS           # Required reviewers
├── Dockerfile               # Non-root, gunicorn
├── requirements.txt
├── pytest.ini
├── .env.example             # Template for secrets (real .env is git-ignored)
├── .gitignore
├── LICENSE                  # MIT
└── run.py                   # Entry point
```

## 7. Security Practices ("shift left")

- Comprehensive `.gitignore` excluding secrets (`.env`, keys, credentials), IDE files (`.idea/`, `.vscode/`), dependencies (`venv/`, `node_modules/`) and build artifacts/logs.
- Configuration is read from **environment variables**; only `.env.example` (placeholders) is committed.
- Docker image runs as a **non-root user**.
- Debug mode is **off by default**.
- `main` is protected by branch protection rules (see below).

### Branch Protection on `main`

| Rule | Why it matters |
|------|----------------|
| Require a pull request before merging | No one pushes directly to `main`; every change is visible and discussed |
| Require 1 approval | A second pair of eyes catches bugs and spreads knowledge |
| Dismiss stale approvals on new commits | An approval only counts for the code that was actually reviewed |
| Require status checks (`test`, `docker-build`) | Broken code or a broken image cannot be merged |
| Require branches to be up to date | Changes are tested against the latest `main`, avoiding merge surprises |
| Require conversation resolution | Review comments cannot be ignored |
| Include administrators | The rules apply to everyone, with no exceptions |

## 8. Project Management

Work is tracked on our GitHub Projects Kanban board (Backlog / In Progress / Done) with user stories, acceptance criteria, labels, assignees and milestones. The full backlog is documented in [`docs/PROJECT_BOARD.md`](docs/PROJECT_BOARD.md).

## 9. Contributing

1. Create a branch from `main` (`feature/<name>` or `fix/<name>`).
2. Commit with clear messages (`feat:`, `fix:`, `docs:`, `build:`, `test:`).
3. Open a pull request linked to its issue (e.g. `Closes #5`).
4. Get one teammate's approval and a green CI before merging.

## 10. Team

| Name | GitHub | Role |
|------|--------|------|
| Jesse Walusansa | [@jessewalu](https://github.com/jessewalu) | Backend & DevOps (CI/CD) |
| Karabo Ojiambo | [@Karabo-jpg](https://github.com/Karabo-jpg) | Testing, Docker & Documentation |
| K. Koita | [@Kkadi20](https://github.com/Kkadi20) | Repository security & Project management |

## 11. License

Released under the [MIT License](LICENSE).
