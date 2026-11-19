"""Portfolio aggregation across accounts.

Rules from the spec:
- Never add raw amounts in different currencies: convert to the base currency
  and report the rates used.
- Never silently drop disconnected accounts: their last-known values are
  included but the summary is flagged incomplete and lists them.
- Realized P&L comes from deals (trade deals only), never from balance deltas,
  so deposits and withdrawals do not count as profit.
"""

from __future__ import annotations

from collections import defaultdict
from datetime import datetime, timedelta, timezone
from decimal import Decimal

from app.models.domain import (
    ApiModel,
    ConnectionStatus,
    Deal,
    DealKind,
    Money,
    PendingOrder,
    Position,
    Side,
    TradingAccount,
)
from app.services.currency import CurrencyService, FxRate
from app.services.freshness import effective_status, is_live

ZERO = Decimal(0)


class PortfolioSummary(ApiModel):
    base_currency: str
    total_balance: Money
    total_equity: Money
    floating_pnl: Money
    realized_pnl_today: Money
    total_pnl_today: Money
    open_positions: int
    pending_orders: int
    accounts_total: int
    accounts_live: int
    stale_account_ids: tuple[str, ...]
    is_complete: bool
    fx_rates: tuple[FxRate, ...]
    as_of: datetime


class SymbolExposure(ApiModel):
    symbol: str
    accounts: int
    buy_volume: Money
    sell_volume: Money
    net_volume: Money
    floating_pnl: Money  # base currency
    positions: int
    same_direction_multi_account: bool
    note: str = "Raw lot totals; contract sizes may differ between brokers."


def start_of_day_utc(now: datetime) -> datetime:
    return now.replace(hour=0, minute=0, second=0, microsecond=0)


def with_effective_status(accounts: list[TradingAccount], now: datetime) -> list[TradingAccount]:
    out = []
    for a in accounts:
        status = effective_status(a, now)
        out.append(a if status == a.connection_status else a.model_copy(update={"connection_status": status}))
    return out


def summarize(
    accounts: list[TradingAccount],
    positions: list[Position],
    orders: list[PendingOrder],
    deals_today: list[Deal],
    fx: CurrencyService,
    base_currency: str,
    now: datetime | None = None,
) -> PortfolioSummary:
    now = now or datetime.now(timezone.utc)
    ccy_by_account = {a.account_id: a.currency for a in accounts}
    used_ccys: set[str] = set()

    def conv(amount: Decimal, ccy: str) -> Decimal:
        if ccy != base_currency:
            used_ccys.add(ccy)
        return fx.convert(amount, ccy, base_currency)

    balance = equity = floating = ZERO
    stale: list[str] = []
    for a in accounts:
        balance += conv(a.balance, a.currency)
        equity += conv(a.equity, a.currency)
        floating += conv(a.floating_pnl, a.currency)
        if not is_live(a.connection_status):
            stale.append(a.account_id)

    realized = ZERO
    for d in deals_today:
        if d.kind is DealKind.TRADE and d.account_id in ccy_by_account:
            realized += conv(d.net, d.currency)

    return PortfolioSummary(
        base_currency=base_currency,
        total_balance=balance,
        total_equity=equity,
        floating_pnl=floating,
        realized_pnl_today=realized,
        total_pnl_today=realized + floating,
        open_positions=len(positions),
        pending_orders=len(orders),
        accounts_total=len(accounts),
        accounts_live=len(accounts) - len(stale),
        stale_account_ids=tuple(stale),
        is_complete=not stale,
        fx_rates=tuple(fx.rate(c, base_currency) for c in sorted(used_ccys)),
        as_of=now,
    )


def exposure_by_symbol(positions: list[Position], fx: CurrencyService, base_currency: str) -> list[SymbolExposure]:
    groups: dict[str, list[Position]] = defaultdict(list)
    for p in positions:
        groups[p.symbol].append(p)
    out = []
    for sym, ps in groups.items():
        buy = sum((p.volume for p in ps if p.side is Side.BUY), ZERO)
        sell = sum((p.volume for p in ps if p.side is Side.SELL), ZERO)
        accounts = {p.account_id for p in ps}
        sides = {p.side for p in ps}
        out.append(SymbolExposure(
            symbol=sym, accounts=len(accounts), buy_volume=buy, sell_volume=sell, net_volume=buy - sell,
            floating_pnl=sum((fx.convert(p.floating_pnl, p.currency, base_currency) for p in ps), ZERO),
            positions=len(ps), same_direction_multi_account=len(accounts) > 1 and len(sides) == 1,
        ))
    return sorted(out, key=lambda e: (-e.positions, e.symbol))


def day_window(now: datetime) -> tuple[datetime, datetime]:
    start = start_of_day_utc(now)
    return start, start + timedelta(days=1)


__all__ = ["PortfolioSummary", "SymbolExposure", "summarize", "exposure_by_symbol",
           "with_effective_status", "day_window", "ConnectionStatus"]
