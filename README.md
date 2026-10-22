# SokoPrice

SokoPrice helps farmers and buyers compare crop prices across local markets.
It provides a JSON API for connected clients and a USSD menu for feature phones.

## Run locally

Use Python 3.12 or newer. Create and activate a virtual environment, then install
the dependencies:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
python -m flask --app "app:create_app()" run
```

The service runs at `http://127.0.0.1:5000`.

## API

- `GET /health` — service status
- `GET /api/crops` — available crops and markets
- `GET /api/prices/<crop>` — prices for a crop in each market
- `GET /api/best-market/<crop>` — best market to sell and cheapest to buy
- `POST /ussd` — USSD menu handler; send the gateway's `text` field as form data

For example:

```text
GET /api/prices/maize
```

returns prices in RWF per kilogram. Unknown crop names return HTTP 404.

## Tests

```powershell
python -m pytest -q
```

## Docker

Build and run the container:

```powershell
docker build -t sokoprice .
docker run --rm -p 5000:5000 sokoprice
```
