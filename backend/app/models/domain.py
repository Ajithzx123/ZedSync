"""Normalized domain models shared by every connector.

Every connector (MT5, TradeLocker, cTrader, mock) converts its platform data
into these models. The rest of the backend and the mobile app only ever see
these shapes. Platform identifiers are always retained (platform*Id fields)
so records can be reconciled against the source.

Money is held as Decimal internally and serialized as a JSON number.
"""

from __future__ import annotations

from datetime import datetime
from decimal import Decimal
from enum import StrEnum
from typing import Annotated

from pydantic import BaseModel, ConfigDict, PlainSerializer
from pydantic.alias_generators import to_camel

Money = Annotated[Decimal, PlainSerializer(float, return_type=float, when_used="json")]


class ApiModel(BaseModel):
    """Base model: camelCase on the wire, snake_case in Python."""

    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True, frozen=True)


class Platform(StrEnum):
    MT5 = "MT5"
    TRADELOCKER = "TRADELOCKER"
    CTRADER = "CTRADER"


class AccountType(StrEnum):
    PERSONAL = "PERSONAL"
    EVALUATION = "EVALUATION"
    FUNDED = "FUNDED"
    INSTANT_FUNDED = "INSTANT_FUNDED"
    OTHER = "OTHER"


class Environment(StrEnum):
    LIVE = "LIVE"
    DEMO = "DEMO"


class ConnectionStatus(StrEnum):
    CONNECTED = "CONNECTED"
    SYNCING = "SYNCING"
    DELAYED = "DELAYED"
    DISCONNECTED = "DISCONNECTED"
    AUTH_EXPIRED = "AUTH_EXPIRED"
    ERROR = "ERROR"
    MAINTENANCE = "MAINTENANCE"
    NOT_AUTHORIZED = "NOT_AUTHORIZED"


class Side(StrEnum):
    BUY = "BUY"
    SELL = "SELL"


class OrderType(StrEnum):
    BUY_LIMIT = "BUY_LIMIT"
    SELL_LIMIT = "SELL_LIMIT"
    BUY_STOP = "BUY_STOP"
    SELL_STOP = "SELL_STOP"
    BUY_STOP_LIMIT = "BUY_STOP_LIMIT"
    SELL_STOP_LIMIT = "SELL_STOP_LIMIT"


class DealEntry(StrEnum):
    """Whether a deal opened, closed or reversed a position (MT5 semantics)."""

    IN = "IN"
    OUT = "OUT"
    INOUT = "INOUT"


class DealKind(StrEnum):
    TRADE = "TRADE"
    DEPOSIT = "DEPOSIT"
    WITHDRAWAL = "WITHDRAWAL"
    ADJUSTMENT = "ADJUSTMENT"


class TradingAccount(ApiModel):
    """Account metadata plus the latest platform-reported snapshot."""

    account_id: str
    platform: Platform
    platform_account_id: str
    account_name: str
    broker: str
    prop_firm: str | None = None
    server: str | None = None
    account_type: AccountType
    environment: Environment
    currency: str
    tags: tuple[str, ...] = ()
    group_id: str | None = None

    # Platform-reported values. Authoritative: never derive equity ourselves.
    balance: Money
    equity: Money
    floating_pnl: Money
    credit: Money = Decimal(0)
    margin: Money
    free_margin: Money
    margin_level: Money | None = None
    leverage: int | None = None

    connection_status: ConnectionStatus
    status_message: str | None = None
    last_synced_at: datetime | None


class Position(ApiModel):
    position_id: str
    account_id: str
    platform_position_id: str
    symbol: str
    original_symbol: str
    side: Side
    volume: Money
    entry_price: Money
    current_price: Money
    stop_loss: Money | None = None
    take_profit: Money | None = None
    floating_pnl: Money
    swap: Money = Decimal(0)
    currency: str
    opened_at: datetime


class PendingOrder(ApiModel):
    order_id: str
    account_id: str
    platform_order_id: str
    symbol: str
    original_symbol: str
    order_type: OrderType
    volume: Money
    entry_price: Money
    stop_loss: Money | None = None
    take_profit: Money | None = None
    created_at: datetime
    status: str = "PLACED"


class Deal(ApiModel):
    """A single execution or balance operation, kept close to the source record.

    Closed-trade views are built on top of deals; we never collapse partial
    closes or multiple fills into one invented record.
    """

    deal_id: str
    account_id: str
    platform_deal_id: str
    platform_order_id: str | None = None
    platform_position_id: str | None = None
    kind: DealKind
    entry: DealEntry | None = None
    symbol: str | None = None
    original_symbol: str | None = None
    side: Side | None = None
    volume: Money | None = None
    price: Money | None = None
    profit: Money
    commission: Money = Decimal(0)
    swap: Money = Decimal(0)
    currency: str
    executed_at: datetime

    @property
    def net(self) -> Decimal:
        return self.profit + self.commission + self.swap
