# SokoPrice 

> **Know the market price before you sell.**
> Crop price tracking for Rwandan smallholder farmers, accessible from any phone via USSD or a simple web API.

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
git clone https://github.com/<your-org>/soko-price.git
cd soko-price

# 2. Create and activate a virtual environment
python -m venv .venv
source .venv/bin/activate        # Windows: .venv\Scripts\activate

# 3. Install dependencies
pip install -r requirements.txt

# 4. (Optional) set up environment variables
cp .env.example .env

# 5. Start the app
python run.py
```

The app runs at **http://localhost:5000**.

### Option B: Run with Docker

```bash
docker build -t soko-price .
docker run -p 5000:5000 soko-price
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

```
soko-price/
├── app/
│   ├── __init__.py      # Flask app factory + REST endpoints
│   ├── prices.py        # Price logic (best/cheapest market)
│   └── ussd.py          # USSD menu state machine
├── data/prices.json     # Sample price dataset
├── tests/test_app.py    # Unit + API tests
├── docs/PROJECT_BOARD.md# GitHub Projects backlog & setup guide
├── .github/workflows/ci.yml
├── Dockerfile
├── requirements.txt
├── .env.example         # Template for secrets (real .env is git-ignored)
├── .gitignore
└── run.py
```

## 7. Security Practices

- Comprehensive `.gitignore` excluding secrets (`.env`, keys, credentials), IDE files (`.idea/`, `.vscode/`), dependencies (`venv/`, `node_modules/`) and build artifacts/logs.
- Configuration is read from **environment variables**; only `.env.example` (placeholders) is committed.
- Docker image runs as a **non-root user**.
- Debug mode is **off by default**.

## 8. Project Management

Work is tracked on our GitHub Projects Kanban board (Backlog / In Progress / Done) with user stories, labels and milestones. See [`docs/PROJECT_BOARD.md`](docs/PROJECT_BOARD.md).

## 9. Team

| Name | Role |
|------|------|
| _Member 1_ | _e.g. Backend / Project lead_ |
| _Member 2_ | _e.g. DevOps / CI-CD_ |
| _Member 3_ | _e.g. Testing / Documentation_ |
| _Member 4_ | _e.g. Data / USSD_ |

## 10. License

For educational use as part of a university course project.
