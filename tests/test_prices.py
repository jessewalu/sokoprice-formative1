from app import prices


def test_load_data_and_listings():
    data = prices.load_data()

    assert prices.list_crops(data) == [
        "beans",
        "cassava",
        "maize",
        "potatoes",
        "tomatoes",
    ]
    assert prices.list_markets(data) == ["Kimironko", "Nyabugogo", "Musanze"]


def test_get_prices_normalizes_crop_name():
    data = prices.load_data()

    assert prices.get_prices(data, " MAIZE ") == {
        "Kimironko": 450,
        "Nyabugogo": 420,
        "Musanze": 400,
    }


def test_best_and_cheapest_market():
    data = prices.load_data()

    assert prices.best_market_to_sell(data, "maize") == ("Kimironko", 450)
    assert prices.cheapest_market_to_buy(data, "maize") == ("Musanze", 400)


def test_unknown_crop_has_no_price_or_recommendation():
    data = prices.load_data()

    assert prices.get_prices(data, "unknown") is None
    assert prices.best_market_to_sell(data, "unknown") is None
    assert prices.cheapest_market_to_buy(data, "unknown") is None
