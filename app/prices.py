"""Price data access and business logic for SokoPrice."""
import json
from pathlib import Path

DATA_FILE = Path(__file__).resolve().parent.parent / "data" / "prices.json"


def load_data(path=DATA_FILE):
    """Load the price dataset from disk."""
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def list_crops(data):
    return sorted(data["crops"].keys())


def list_markets(data):
    return list(data["markets"])


def get_prices(data, crop):
    """Return {market: price} for a crop, or None if the crop is unknown."""
    return data["crops"].get(crop.strip().lower())


def best_market_to_sell(data, crop):
    """Market with the highest price (best for a farmer selling)."""
    prices = get_prices(data, crop)
    if not prices:
        return None
    market = max(prices, key=prices.get)
    return market, prices[market]


def cheapest_market_to_buy(data, crop):
    """Market with the lowest price (best for a buyer)."""
    prices = get_prices(data, crop)
    if not prices:
        return None
    market = min(prices, key=prices.get)
    return market, prices[market]
