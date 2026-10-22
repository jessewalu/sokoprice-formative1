"""USSD menu logic for SokoPrice.

Follows the Africa's Talking convention: the gateway sends the full
navigation history as a '*'-separated string in `text` (empty on first
dial). We reply with 'CON ...' to continue a session or 'END ...' to close.

Menu tree:
  Main menu
   1. Check crop price      -> choose crop -> prices in all markets
   2. Best market to sell   -> choose crop -> best market + price
   3. Cheapest market to buy-> choose crop -> cheapest market + price
   0. Exit
"""
from . import prices as p

MAIN_MENU = (
    "CON Welcome to SokoPrice\n"
    "1. Check crop price\n"
    "2. Best market to sell\n"
    "3. Cheapest market to buy\n"
    "0. Exit"
)


def _crop_menu(data, title):
    crops = p.list_crops(data)
    lines = [f"CON {title}"]
    lines += [f"{i}. {c.capitalize()}" for i, c in enumerate(crops, 1)]
    return "\n".join(lines)


def _pick_crop(data, choice):
    crops = p.list_crops(data)
    if choice.isdigit() and 1 <= int(choice) <= len(crops):
        return crops[int(choice) - 1]
    return None


def handle_ussd(data, text):
    """Return the USSD response string for the given navigation text."""
    steps = [s for s in (text or "").split("*") if s != ""]
    unit, cur = data["unit"], data["currency"]

    if not steps:
        return MAIN_MENU

    option = steps[0]
    if option == "0":
        return "END Thank you for using SokoPrice. Goodbye!"
    if option not in ("1", "2", "3"):
        return "END Invalid choice. Please dial again."

    titles = {
        "1": "Select crop:",
        "2": "Sell which crop?",
        "3": "Buy which crop?",
    }
    if len(steps) == 1:
        return _crop_menu(data, titles[option])

    crop = _pick_crop(data, steps[1])
    if crop is None:
        return "END Invalid crop. Please dial again."

    if option == "1":
        prices = p.get_prices(data, crop)
        lines = [f"END {crop.capitalize()} ({cur}/{unit}):"]
        lines += [f"{m}: {v}" for m, v in prices.items()]
        return "\n".join(lines)
    if option == "2":
        market, price = p.best_market_to_sell(data, crop)
        return f"END Best place to sell {crop}: {market} at {price} {cur}/{unit}."
    market, price = p.cheapest_market_to_buy(data, crop)
    return f"END Cheapest place to buy {crop}: {market} at {price} {cur}/{unit}."
