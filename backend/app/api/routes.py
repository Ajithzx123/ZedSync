"""HTTP API. Every route is GET: this release is monitoring-only.

Trade execution (open/close/modify/cancel) is deliberately not implemented,
and tests fail if a non-GET route appears.
"""

from __future__ import annotations

from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException, Query

from app.connectors.base import ReadOnlyConnector
from app.core.deps import get_connector, get_fx
from app.models.domain import Deal, PendingOrder, Position, TradingAccount
from app.services.currency import CurrencyService
from app.services.portfolio import (
    PortfolioSummary,
    SymbolExposure,
    day_window,
    exposure_by_symbol,
    summarize,
    with_effective_status,
)

router = APIRouter(prefix="/api/v1")


def _base(fx: CurrencyService, base: str) -> str:
    base = base.upper()
    if base not in fx.supported():
        raise HTTPException(422, f"Unsupported base currency {base}")
    return base


@router.get("/health")
async def health() -> dict:
    return {"status": "ok", "mode": "read-only", "time": datetime.now(timezone.utc)}


@router.get("/portfolio/summary", response_model=PortfolioSummary, response_model_by_alias=True)
async def portfolio_summary(
    base: str = Query("USD", description="Portfolio base currency"),
    account_ids: str | None = Query(None, description="Comma-separated account IDs to include; all if omitted"),
    conn: ReadOnlyConnector = Depends(get_connector),
    fx: CurrencyService = Depends(get_fx),
):
    now = datetime.now(timezone.utc)
    accounts = with_effective_status(await conn.fetch_accounts(), now)
    if account_ids is not None:
        wanted = {i for i in account_ids.split(",") if i}
        accounts = [a for a in accounts if a.account_id in wanted]
    ids = {a.account_id for a in accounts}
    start, end = day_window(now)
    positions = [p for p in await conn.fetch_positions() if p.account_id in ids]
    orders = [o for o in await conn.fetch_pending_orders() if o.account_id in ids]
    deals = [d for d in await conn.fetch_deals(start, end) if d.account_id in ids]
    return summarize(accounts, positions, orders, deals, fx, _base(fx, base), now)


@router.get("/portfolio/exposure", response_model=list[SymbolExposure], response_model_by_alias=True)
async def portfolio_exposure(
    base: str = "USD",
    conn: ReadOnlyConnector = Depends(get_connector),
    fx: CurrencyService = Depends(get_fx),
):
    return exposure_by_symbol(await conn.fetch_positions(), fx, _base(fx, base))


@router.get("/accounts", response_model=list[TradingAccount], response_model_by_alias=True)
async def list_accounts(conn: ReadOnlyConnector = Depends(get_connector)):
    return with_effective_status(await conn.fetch_accounts(), datetime.now(timezone.utc))


@router.get("/accounts/{account_id}", response_model=TradingAccount, response_model_by_alias=True)
async def get_account(account_id: str, conn: ReadOnlyConnector = Depends(get_connector)):
    for a in with_effective_status(await conn.fetch_accounts(), datetime.now(timezone.utc)):
        if a.account_id == account_id:
            return a
    raise HTTPException(404, "Account not found")


@router.get("/positions", response_model=list[Position], response_model_by_alias=True)
async def list_positions(account_id: str | None = None, conn: ReadOnlyConnector = Depends(get_connector)):
    ps = await conn.fetch_positions()
    return [p for p in ps if account_id is None or p.account_id == account_id]


@router.get("/orders", response_model=list[PendingOrder], response_model_by_alias=True)
async def list_orders(account_id: str | None = None, conn: ReadOnlyConnector = Depends(get_connector)):
    os_ = await conn.fetch_pending_orders()
    return [o for o in os_ if account_id is None or o.account_id == account_id]


@router.get("/history/deals", response_model=list[Deal], response_model_by_alias=True)
async def list_deals(
    days: int = Query(7, ge=1, le=365),
    account_id: str | None = None,
    conn: ReadOnlyConnector = Depends(get_connector),
):
    now = datetime.now(timezone.utc)
    _, end = day_window(now)
    deals = await conn.fetch_deals(end - timedelta(days=days), end)
    deals = [d for d in deals if account_id is None or d.account_id == account_id]
    return sorted(deals, key=lambda d: d.executed_at, reverse=True)
