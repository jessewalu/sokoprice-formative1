from app.prices import load_data
from app.ussd import MAIN_MENU, handle_ussd


def test_empty_text_shows_main_menu():
    assert handle_ussd(load_data(), "") == MAIN_MENU


def test_exit_closes_session():
    assert handle_ussd(load_data(), "0").startswith("END ")


def test_invalid_menu_choice_closes_session():
    assert handle_ussd(load_data(), "9") == (
        "END Invalid choice. Please dial again."
    )


def test_crop_menu_lists_available_crops():
    response = handle_ussd(load_data(), "1")

    assert response.startswith("CON Select crop:")
    assert "1. Beans" in response
    assert "5. Tomatoes" in response


def test_price_selection_returns_all_market_prices():
    response = handle_ussd(load_data(), "1*3")

    assert response == (
        "END Maize (RWF/kg):\n"
        "Kimironko: 450\n"
        "Nyabugogo: 420\n"
        "Musanze: 400"
    )


def test_sell_and_buy_options_return_recommendations():
    data = load_data()

    assert handle_ussd(data, "2*3") == (
        "END Best place to sell maize: Kimironko at 450 RWF/kg."
    )
    assert handle_ussd(data, "3*3") == (
        "END Cheapest place to buy maize: Musanze at 400 RWF/kg."
    )


def test_invalid_crop_selection_closes_session():
    assert handle_ussd(load_data(), "1*9") == (
        "END Invalid crop. Please dial again."
    )
