"""Connector contract.

A connector is READ-ONLY by design. It exposes no method that could place,
modify or cancel orders, and tests assert that stays true. Each platform
(MT5 worker, TradeLocker, cTrader) implements this interface and returns
normalized domain models.
"""

from __future__ import annotations

from abc import ABC, abstractmethod
from datetime import datetime

from app.models.domain import Deal, PendingOrder, Platform, Position, TradingAccount


class ReadOnlyConnector(ABC):
    platform: Platform | None = None  # None for the mock, which spans platforms

    @abstractmethod
    async def fetch_accounts(self) -> list[TradingAccount]: ...

    @abstractmethod
    async def fetch_positions(self) -> list[Position]: ...

    @abstractmethod
    async def fetch_pending_orders(self) -> list[PendingOrder]: ...

    @abstractmethod
    async def fetch_deals(self, since: datetime, until: datetime) -> list[Deal]: ...
