import inspect
import warnings
from datetime import datetime, timedelta, timezone
from decimal import Decimal

import pytest

with warnings.catch_warnings():
    warnings.simplefilter("ignore")
    from fastapi.testclient import TestClient

from app.connectors.base import ReadOnlyConnector
from app.main import app
from app.models.domain import ConnectionStatus, Deal, DealKind
from app.services.currency import CurrencyService
from app.services.freshness import effective_status
from app.services.portfolio import summarize

client = TestClient(app)
API = "/api/v1"


# --- Read-only guarantee ----------------------------------------------------

def test_api_exposes_only_get_routes():
    for route in app.routes:
        methods = getattr(route, "methods", None) or set()
        assert methods <= {"GET", "HEAD"}, f"{route.path} allows {methods}"


def test_connector_contract_has_no_trading_methods():
    forbidden = ("order_send", "place", "open_position", "close", "modify", "cancel", "execute", "trade")
    names = [n for n, _ in inspect.getmembers(ReadOnlyConnector, inspect.isfunction)]
    assert all(n.startswith("fetch_") or n.startswith("_") for n in names), names
    assert not any(f in n for n in names for f in forbidden)


@pytest.mark.parametrize("method", ["post", "put", "patch", "delete"])
def test_write_methods_rejected(method):
    r = getattr(client, method)(f"{API}/positions")
    assert r.status_code == 405


# --- Portfolio --------------------------------------------------------------

def test_summary_flags_disconnected_account_instead_of_hiding_it():
    s = client.get(f"{API}/portfolio/summary").json()
    assert s["accountsTotal"] == 6
    assert s["accountsLive"] == 5
    assert s["staleAccountIds"] == ["acc_mt5_f2"]
    assert s["isComplete"] is False


def test_summary_filtered_by_account_ids():
    s = client.get(f"{API}/portfolio/summary", params={"account_ids": "acc_mt5_f1,acc_mt5_l1"}).json()
    assert s["accountsTotal"] == 2
    assert s["isComplete"] is True
    assert s["openPositions"] == 3
    assert s["fxRates"] == []


def test_summary_reports_fx_rates_used():
    s = client.get(f"{API}/portfolio/summary").json()
    assert [(r["base"], r["quote"]) for r in s["fxRates"]] == [("EUR", "USD")]
    assert s["fxRates"][0]["asOf"]


def test_summary_in_other_base_currency():
    s = client.get(f"{API}/portfolio/summary", params={"base": "eur"}).json()
    assert s["baseCurrency"] == "EUR"
    assert client.get(f"{API}/portfolio/summary", params={"base": "XYZ"}).status_code == 422


def test_realized_pnl_excludes_deposits_and_uses_net_of_costs():
    now = datetime(2026, 11, 19, 12, tzinfo=timezone.utc)
    deals = [
        Deal(deal_id="1", account_id="a", platform_deal_id="1", kind=DealKind.DEPOSIT,
             profit=Decimal("5000"), currency="USD", executed_at=now),
        Deal(deal_id="2", account_id="a", platform_deal_id="2", kind=DealKind.TRADE,
             profit=Decimal("100"), commission=Decimal("-3"), swap=Decimal("-1"),
             currency="USD", executed_at=now),
    ]
    accounts = client.get(f"{API}/accounts").json()
    from app.models.domain import TradingAccount
    acc = TradingAccount.model_validate({**accounts[0], "accountId": "a"})
    s = summarize([acc], [], [], deals, CurrencyService(), "USD", now)
    assert s.realized_pnl_today == Decimal("96")


def test_exposure_detects_same_direction_across_accounts():
    xau = next(e for e in client.get(f"{API}/portfolio/exposure").json() if e["symbol"] == "XAUUSD")
    assert xau["accounts"] == 3
    assert xau["sameDirectionMultiAccount"] is True


# --- Freshness --------------------------------------------------------------

def test_connected_but_old_data_becomes_delayed():
    acc = client.get(f"{API}/accounts/acc_mt5_f1").json()
    from app.models.domain import TradingAccount
    a = TradingAccount.model_validate(acc)
    later = a.last_synced_at + timedelta(minutes=5)
    assert effective_status(a, later) is ConnectionStatus.DELAYED
    assert effective_status(a, a.last_synced_at) is ConnectionStatus.CONNECTED


# --- Normalization ----------------------------------------------------------

def test_positions_keep_platform_ids_and_original_symbols():
    ps = client.get(f"{API}/positions").json()
    pro = next(p for p in ps if p["originalSymbol"] == "XAUUSD.pro")
    assert pro["symbol"] == "XAUUSD"
    assert all(p["platformPositionId"] for p in ps)


def test_partial_close_kept_as_separate_deals():
    deals = client.get(f"{API}/history/deals", params={"account_id": "acc_mt5_f1"}).json()
    outs = [d for d in deals if d["platformPositionId"] == "120040001" and d["entry"] == "OUT"]
    assert len(outs) == 2
    assert {d["volume"] for d in outs} == {0.1}


def test_unknown_account_404():
    assert client.get(f"{API}/accounts/nope").status_code == 404
