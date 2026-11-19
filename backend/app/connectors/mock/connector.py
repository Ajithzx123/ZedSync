"""Mock connector: a fictional multi-platform portfolio for Phase 1.

Prices drift a little on every fetch so the app has something live-looking to
show. One account is deliberately disconnected and one is in EUR so the UI has
to deal with stale data and currency conversion from day one.
"""

from __future__ import annotations

import random
from datetime import datetime, timedelta, timezone
from decimal import Decimal

from app.connectors.base import ReadOnlyConnector
from app.models.domain import (
    AccountType,
    ConnectionStatus,
    Deal,
    DealEntry,
    DealKind,
    Environment,
    OrderType,
    PendingOrder,
    Platform,
    Position,
    Side,
    TradingAccount,
)

D = Decimal

# (accountId, platform, platformId, name, broker, propFirm, server, type, env, ccy, balance, leverage, tags)
_ACCOUNTS = [
    ("acc_mt5_f1", Platform.MT5, "51023481", "MT5 · Funded 01", "FTMO", "FTMO", "FTMO-Server3",
     AccountType.FUNDED, Environment.LIVE, "USD", D("10000"), 100, ("funded",)),
    ("acc_mt5_f2", Platform.MT5, "51077210", "MT5 · Funded 02", "FTMO", "FTMO", "FTMO-Server2",
     AccountType.FUNDED, Environment.LIVE, "USD", D("25000"), 100, ("funded",)),
    ("acc_mt5_l1", Platform.MT5, "8812004", "MT5 · Live 01", "IC Markets", None, "ICMarketsSC-Live07",
     AccountType.PERSONAL, Environment.LIVE, "USD", D("4200"), 500, ("personal",)),
    ("acc_tl_c1", Platform.TRADELOCKER, "L#712233", "TradeLocker · Challenge", "Example Prop", "Example Prop",
     "EXPROP-LIVE", AccountType.EVALUATION, Environment.LIVE, "USD", D("50000"), 50, ("challenge",)),
    ("acc_ct_l1", Platform.CTRADER, "3409911", "cTrader · Live", "Pepperstone", None, "live",
     AccountType.PERSONAL, Environment.LIVE, "EUR", D("6100"), 200, ("personal",)),
    ("acc_ct_d1", Platform.CTRADER, "5500127", "cTrader · Practice", "Pepperstone", None, "demo",
     AccountType.PERSONAL, Environment.DEMO, "USD", D("100000"), 500, ("demo",)),
]

_DISCONNECTED = {"acc_mt5_f2"}

# (positionId, accountId, platformId, symbol, originalSymbol, side, volume, entry, sl, tp, contract, hoursAgo)
_POSITIONS = [
    ("pos_1", "acc_mt5_f1", "120045671", "XAUUSD", "XAUUSD", Side.BUY, D("0.10"), D("4050.20"),
     D("4040.00"), D("4075.00"), D("100"), 3),
    ("pos_2", "acc_mt5_f1", "120045702", "EURUSD", "EURUSD", Side.SELL, D("0.50"), D("1.08420"),
     D("1.08800"), D("1.07900"), D("100000"), 5),
    ("pos_3", "acc_mt5_l1", "88120931", "XAUUSD", "XAUUSD.pro", Side.BUY, D("0.05"), D("4061.80"),
     D("4045.00"), None, D("100"), 1),
    ("pos_4", "acc_ct_l1", "77341", "XAUUSD", "XAUUSD", Side.BUY, D("0.20"), D("4048.90"),
     None, D("4090.00"), D("100"), 20),
    ("pos_5", "acc_mt5_f2", "120988110", "US30", "US30.cash", Side.SELL, D("1.00"), D("44120.0"),
     D("44300.0"), D("43800.0"), D("1"), 26),
]

_BASE_PRICES = {"XAUUSD": D("4055.20"), "EURUSD": D("1.08310"), "US30": D("44080.0")}
_EURUSD_FOR_PNL = D("1.0831")


class MockConnector(ReadOnlyConnector):
    def __init__(self, seed: int | None = None) -> None:
        self._rng = random.Random(seed)
        self._prices = dict(_BASE_PRICES)
        self._now = lambda: datetime.now(timezone.utc)
        self._last_tick: datetime | None = None

    def _tick(self) -> None:
        # At most one price move per second so one request sees one consistent snapshot.
        now = self._now()
        if self._last_tick and (now - self._last_tick).total_seconds() < 1:
            return
        self._last_tick = now
        for sym, px in self._prices.items():
            step = px * D(str(self._rng.uniform(-0.0004, 0.0004)))
            self._prices[sym] = (px + step).quantize(D("0.00001") if sym == "EURUSD" else D("0.01"))

    def _position_pnl(self, row, account_ccy: str) -> Decimal:
        _, _, _, sym, _, side, vol, entry, _, _, contract, _ = row
        diff = self._prices[sym] - entry
        if side is Side.SELL:
            diff = -diff
        pnl_usd = diff * vol * contract
        if account_ccy == "EUR":
            pnl_usd = pnl_usd / _EURUSD_FOR_PNL
        return pnl_usd.quantize(D("0.01"))

    async def fetch_positions(self) -> list[Position]:
        self._tick()
        now = self._now()
        ccy = {a[0]: a[9] for a in _ACCOUNTS}
        out = []
        for row in _POSITIONS:
            pid, acc, ppid, sym, osym, side, vol, entry, sl, tp, _, hours = row
            out.append(Position(
                position_id=pid, account_id=acc, platform_position_id=ppid, symbol=sym,
                original_symbol=osym, side=side, volume=vol, entry_price=entry,
                current_price=self._prices[sym], stop_loss=sl, take_profit=tp,
                floating_pnl=self._position_pnl(row, ccy[acc]),
                swap=D("-1.20") if hours > 12 else D(0), currency=ccy[acc],
                opened_at=now - timedelta(hours=hours),
            ))
        return out

    async def fetch_accounts(self) -> list[TradingAccount]:
        positions = await self.fetch_positions()
        now = self._now()
        out = []
        for (aid, plat, paid, name, broker, prop, server, atype, env, ccy, bal, lev, tags) in _ACCOUNTS:
            floating = sum((p.floating_pnl + p.swap for p in positions if p.account_id == aid), D(0))
            margin = sum((p.volume * p.entry_price * D(100) / D(lev) for p in positions
                          if p.account_id == aid and p.symbol == "XAUUSD"), D(0)).quantize(D("0.01"))
            equity = bal + floating
            disconnected = aid in _DISCONNECTED
            out.append(TradingAccount(
                account_id=aid, platform=plat, platform_account_id=paid, account_name=name,
                broker=broker, prop_firm=prop, server=server, account_type=atype, environment=env,
                currency=ccy, tags=tags, balance=bal, equity=equity, floating_pnl=floating,
                margin=margin, free_margin=equity - margin,
                margin_level=(equity / margin * 100).quantize(D("0.01")) if margin else None,
                leverage=lev,
                connection_status=ConnectionStatus.DISCONNECTED if disconnected else ConnectionStatus.CONNECTED,
                status_message="Broker server unreachable" if disconnected else None,
                last_synced_at=now - timedelta(minutes=25) if disconnected else now,
            ))
        return out

    async def fetch_pending_orders(self) -> list[PendingOrder]:
        now = self._now()
        return [
            PendingOrder(order_id="ord_1", account_id="acc_mt5_f1", platform_order_id="120046001",
                         symbol="GBPUSD", original_symbol="GBPUSD", order_type=OrderType.BUY_LIMIT,
                         volume=D("0.30"), entry_price=D("1.26500"), stop_loss=D("1.26100"),
                         take_profit=D("1.27300"), created_at=now - timedelta(hours=2)),
            PendingOrder(order_id="ord_2", account_id="acc_tl_c1", platform_order_id="TL-99812",
                         symbol="XAUUSD", original_symbol="XAUUSD", order_type=OrderType.SELL_STOP,
                         volume=D("0.50"), entry_price=D("4030.00"), stop_loss=D("4045.00"),
                         take_profit=D("4000.00"), created_at=now - timedelta(hours=7)),
        ]

    async def fetch_deals(self, since: datetime, until: datetime) -> list[Deal]:
        now = self._now()
        today = now.replace(hour=0, minute=0, second=0, microsecond=0)

        def deal(i, acc, kind, t, profit, ccy="USD", **kw):
            return Deal(deal_id=f"deal_{i}", account_id=acc, platform_deal_id=str(900000 + i),
                        kind=kind, profit=D(profit), currency=ccy, executed_at=t, **kw)

        deals = [
            deal(1, "acc_mt5_f1", DealKind.DEPOSIT, today - timedelta(days=20), "10000"),
            # A position opened yesterday, partially closed today in two steps.
            deal(2, "acc_mt5_f1", DealKind.TRADE, today - timedelta(hours=10), "0", entry=DealEntry.IN,
                 symbol="XAUUSD", original_symbol="XAUUSD", side=Side.BUY, volume=D("0.20"),
                 price=D("4020.00"), platform_position_id="120040001", commission=D("-1.40")),
            deal(3, "acc_mt5_f1", DealKind.TRADE, now - timedelta(minutes=50), "250.00", entry=DealEntry.OUT,
                 symbol="XAUUSD", original_symbol="XAUUSD", side=Side.SELL, volume=D("0.10"),
                 price=D("4045.00"), platform_position_id="120040001", commission=D("-0.70")),
            deal(4, "acc_mt5_f1", DealKind.TRADE, now - timedelta(minutes=20), "200.00", entry=DealEntry.OUT,
                 symbol="XAUUSD", original_symbol="XAUUSD", side=Side.SELL, volume=D("0.10"),
                 price=D("4040.00"), platform_position_id="120040001", commission=D("-0.70")),
            deal(5, "acc_mt5_l1", DealKind.TRADE, now - timedelta(minutes=35), "-120.00",
                 entry=DealEntry.OUT, symbol="EURUSD", original_symbol="EURUSD.pro", side=Side.BUY,
                 volume=D("0.40"), price=D("1.08450"), platform_position_id="88120001",
                 commission=D("-2.80"), swap=D("-0.60")),
            deal(6, "acc_ct_l1", DealKind.TRADE, now - timedelta(minutes=70), "95.00", ccy="EUR",
                 entry=DealEntry.OUT, symbol="XAUUSD", original_symbol="XAUUSD", side=Side.SELL,
                 volume=D("0.10"), price=D("4052.10"), platform_position_id="77300"),
            deal(7, "acc_tl_c1", DealKind.TRADE, today - timedelta(days=1, hours=3), "640.00",
                 entry=DealEntry.OUT, symbol="NAS100", original_symbol="NAS100", side=Side.SELL,
                 volume=D("2.00"), price=D("21250.0"), platform_position_id="TLP-5521"),
            deal(8, "acc_ct_l1", DealKind.WITHDRAWAL, today - timedelta(days=3), "-500.00", ccy="EUR"),
        ]
        return [d for d in deals if since <= d.executed_at < until and d.executed_at <= now]
