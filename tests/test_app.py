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


# ---- business logic ----
def test_best_market_to_sell(data):
    assert p.best_market_to_sell(data, "maize") == ("Kimironko", 450)


def test_cheapest_market_to_buy(data):
    assert p.cheapest_market_to_buy(data, "potatoes") == ("Musanze", 300)


def test_unknown_crop_returns_none(data):
    assert p.get_prices(data, "gold") is None
    assert p.best_market_to_sell(data, "gold") is None


def test_crop_lookup_is_case_insensitive(data):
    assert p.get_prices(data, " Maize ") == p.get_prices(data, "maize")


# ---- USSD ----
def test_ussd_main_menu(data):
    assert handle_ussd(data, "").startswith("CON Welcome to SokoPrice")


def test_ussd_second_level_lists_crops(data):
    out = handle_ussd(data, "1")
    assert out.startswith("CON") and "Maize" in out and "Beans" in out


def test_ussd_price_lookup(data):
    # crops sorted: beans, cassava, maize, potatoes, tomatoes -> 3 = maize
    out = handle_ussd(data, "1*3")
    assert out.startswith("END Maize") and "Kimironko: 450" in out


def test_ussd_best_market(data):
    assert "Kimironko" in handle_ussd(data, "2*3")


def test_ussd_exit_and_invalid(data):
    assert handle_ussd(data, "0").startswith("END")
    assert handle_ussd(data, "9").startswith("END Invalid")
    assert handle_ussd(data, "1*99").startswith("END Invalid")


# ---- HTTP API ----
def test_health(client):
    assert client.get("/health").json == {"status": "ok"}


def test_api_prices(client):
    r = client.get("/api/prices/beans")
    assert r.status_code == 200
    assert r.json["prices"]["Musanze"] == 850


def test_api_unknown_crop_404(client):
    assert client.get("/api/prices/gold").status_code == 404


def test_ussd_endpoint(client):
    r = client.post("/ussd", data={"text": "", "sessionId": "x", "phoneNumber": "+250788000000"})
    assert r.status_code == 200 and r.text.startswith("CON")
