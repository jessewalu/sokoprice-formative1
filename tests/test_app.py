import pytest

from app import create_app
from app import prices as p
from app.ussd import handle_ussd


@pytest.fixture
def client():
    app = create_app()
    app.config["TESTING"] = True
    return app.test_client()


@pytest.fixture
def data():
    return p.load_data()


def test_best_market_to_sell(data):
    assert p.best_market_to_sell(data, "maize") == ("Kimironko", 450)


def test_cheapest_market_to_buy(data):
    assert p.cheapest_market_to_buy(data, "potatoes") == ("Musanze", 300)


def test_unknown_crop_returns_none(data):
    assert p.get_prices(data, "gold") is None
    assert p.best_market_to_sell(data, "gold") is None


def test_crop_lookup_is_case_insensitive(data):
    assert p.get_prices(data, " Maize ") == p.get_prices(data, "maize")


def test_ussd_main_menu(data):
    assert handle_ussd(data, "").startswith("CON Welcome to SokoPrice")


def test_ussd_second_level_lists_crops(data):
    response = handle_ussd(data, "1")
    assert response.startswith("CON")
    assert "Maize" in response
    assert "Beans" in response


def test_ussd_price_lookup(data):
    response = handle_ussd(data, "1*3")
    assert response.startswith("END Maize")
    assert "Kimironko: 450" in response


def test_ussd_best_market(data):
    assert "Kimironko" in handle_ussd(data, "2*3")


def test_ussd_exit_and_invalid(data):
    assert handle_ussd(data, "0").startswith("END")
    assert handle_ussd(data, "9").startswith("END Invalid")
    assert handle_ussd(data, "1*99").startswith("END Invalid")


def test_health_and_index_endpoints(client):
    assert client.get("/health").json == {"status": "ok"}
    assert client.get("/").json["name"] == "SokoPrice"


def test_crop_and_price_endpoints(client):
    crops = client.get("/api/crops").json
    assert "maize" in crops["crops"]
    assert "Kimironko" in crops["markets"]

    response = client.get("/api/prices/MAIZE")
    assert response.status_code == 200
    assert response.json == {
        "crop": "maize",
        "currency": "RWF",
        "unit": "kg",
        "updated": "2026-10-20",
        "prices": {
            "Kimironko": 450,
            "Nyabugogo": 420,
            "Musanze": 400,
        },
    }


def test_api_prices(client):
    response = client.get("/api/prices/beans")
    assert response.status_code == 200
    assert response.json["prices"]["Musanze"] == 850


def test_unknown_crop_returns_not_found(client):
    response = client.get("/api/prices/unknown")
    assert response.status_code == 404
    assert response.json == {"error": "Unknown crop 'unknown'"}


def test_best_market_endpoint_returns_buy_and_sell_recommendations(client):
    response = client.get("/api/best-market/maize")

    assert response.status_code == 200
    assert response.json["best_to_sell"] == {
        "market": "Kimironko",
        "price": 450,
    }
    assert response.json["cheapest_to_buy"] == {
        "market": "Musanze",
        "price": 400,
    }


def test_ussd_endpoint_returns_plain_text(client):
    response = client.post(
        "/ussd",
        data={
            "text": "",
            "sessionId": "x",
            "phoneNumber": "+250788000000",
        },
    )

    assert response.status_code == 200
    assert response.mimetype == "text/plain"
    assert response.get_data(as_text=True).startswith("CON Welcome to SokoPrice")
