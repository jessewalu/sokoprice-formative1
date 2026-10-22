"""SokoPrice Flask application factory."""
import os

from flask import Flask, jsonify, request

from . import prices as p
from .ussd import handle_ussd


def create_app(data_path=None):
    app = Flask(__name__)
    # Secrets/config come from environment variables, never hard-coded.
    app.config["DEBUG"] = os.getenv("FLASK_DEBUG", "0") == "1"
    data = p.load_data(data_path) if data_path else p.load_data()

    @app.get("/")
    def index():
        return jsonify(
            name="SokoPrice",
            tagline="Know the market price before you sell.",
            endpoints=["/health", "/api/crops", "/api/prices/<crop>",
                       "/api/best-market/<crop>", "POST /ussd"],
        )

    @app.get("/health")
    def health():
        return jsonify(status="ok")

    @app.get("/api/crops")
    def crops():
        return jsonify(crops=p.list_crops(data), markets=p.list_markets(data))

    @app.get("/api/prices/<crop>")
    def prices(crop):
        result = p.get_prices(data, crop)
        if result is None:
            return jsonify(error=f"Unknown crop '{crop}'"), 404
        return jsonify(crop=crop.lower(), currency=data["currency"],
                       unit=data["unit"], updated=data["updated"], prices=result)

    @app.get("/api/best-market/<crop>")
    def best_market(crop):
        best = p.best_market_to_sell(data, crop)
        cheap = p.cheapest_market_to_buy(data, crop)
        if best is None:
            return jsonify(error=f"Unknown crop '{crop}'"), 404
        return jsonify(
            crop=crop.lower(),
            best_to_sell={"market": best[0], "price": best[1]},
            cheapest_to_buy={"market": cheap[0], "price": cheap[1]},
        )

    @app.post("/ussd")
    def ussd():
        # Africa's Talking posts form data: sessionId, phoneNumber, text
        text = request.form.get("text", "")
        return handle_ussd(data, text), 200, {"Content-Type": "text/plain"}

    return app
