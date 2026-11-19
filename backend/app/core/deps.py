"""Dependency wiring. Swap the mock connector for real ones here."""

from __future__ import annotations

from functools import lru_cache

from app.connectors.base import ReadOnlyConnector
from app.connectors.mock.connector import MockConnector
from app.services.currency import CurrencyService


@lru_cache
def get_connector() -> ReadOnlyConnector:
    return MockConnector()


@lru_cache
def get_fx() -> CurrencyService:
    return CurrencyService()
